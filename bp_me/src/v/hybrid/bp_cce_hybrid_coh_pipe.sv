/**
 *
 * Name:
 *   bp_cce_hybrid_coh_pipe.sv
 *
 * Description:
 *   This module process cached or uncached requests to cacheable memory.
 *
 */

`include "bp_common_defines.svh"
`include "bp_me_defines.svh"

module bp_cce_hybrid_coh_pipe
  import bp_common_pkg::*;
  import bp_me_pkg::*;
  #(parameter bp_params_e bp_params_p = e_bp_default_cfg
    `declare_bp_proc_params(bp_params_p)

    , parameter lce_data_width_p           = dword_width_gp
    , parameter mem_data_width_p           = dword_width_gp
    , parameter pending_header_els_p       = 2
    , parameter pending_data_els_p         = 2
    , parameter pending_wbuf_els_p         = 2

    , localparam lg_num_lce_lp             = `BSG_SAFE_CLOG2(num_lce_p)
    , localparam lg_lce_assoc_lp           = `BSG_SAFE_CLOG2(lce_assoc_p)

    // maximal number of tag sets stored in the directory for all LCE types
    , localparam max_tag_sets_lp           = `BSG_CDIV(lce_sets_p, num_cce_p)
    , localparam lg_max_tag_sets_lp        = `BSG_SAFE_CLOG2(max_tag_sets_lp)

    , localparam counter_max_lp = 256
    , localparam counter_width_lp = `BSG_SAFE_CLOG2(counter_max_lp+1)

    // interface widths
    `declare_bp_bedrock_lce_if_widths(paddr_width_p, lce_data_width_p, lce_id_width_p, cce_id_width_p, lce_assoc_p, lce)
    `declare_bp_bedrock_mem_if_widths(paddr_width_p, mem_data_width_p, lce_id_width_p, lce_assoc_p, cce)
  )
  (input                                            clk_i
   , input                                          reset_i

   // control
   , input bp_cce_mode_e                            cce_mode_i
   , input [cce_id_width_p-1:0]                     cce_id_i
   , output logic                                   empty_o

   // LCE-CCE Interface
   // BedRock Burst protocol: ready&valid
   , input [lce_req_msg_header_width_lp-1:0]        lce_req_header_i
   , input                                          lce_req_header_v_i
   , output logic                                   lce_req_header_ready_and_o
   , input                                          lce_req_has_data_i
   , input [lce_data_width_p-1:0]                   lce_req_data_i
   , input                                          lce_req_data_v_i
   , output logic                                   lce_req_data_ready_and_o
   , input                                          lce_req_last_i

   , output logic [lce_cmd_msg_header_width_lp-1:0] lce_cmd_header_o
   , output logic                                   lce_cmd_header_v_o
   , input                                          lce_cmd_header_ready_and_i
   , output logic                                   lce_cmd_has_data_o
   , output logic [lce_data_width_p-1:0]            lce_cmd_data_o
   , output logic                                   lce_cmd_data_v_o
   , input                                          lce_cmd_data_ready_and_i
   , output logic                                   lce_cmd_last_o

   , input                                          inv_yumi_i
   , input                                          coh_yumi_i
   , input                                          wb_yumi_i

   // CCE-MEM Interface
   // BedRock Stream protocol: ready&valid
   , output logic [cce_mem_msg_header_width_lp-1:0] mem_cmd_header_o
   , output logic [mem_data_width_p-1:0]            mem_cmd_data_o
   , output logic                                   mem_cmd_v_o
   , input                                          mem_cmd_ready_and_i
   , output logic                                   mem_cmd_last_o

   // Spec bits write port - to memory response pipe
   , output logic                                   spec_w_v_o
   , output logic [paddr_width_p-1:0]               spec_w_addr_o
   , output logic                                   spec_w_addr_bypass_hash_o
   , output logic                                   spec_v_o
   , output logic                                   spec_squash_v_o
   , output logic                                   spec_fwd_mod_v_o
   , output logic                                   spec_state_v_o
   , output bp_cce_spec_s                           spec_bits_o

   // Pending bits write port - from memory response pipe
   , input                                          mem_resp_pending_w_v_i
   , output logic                                   mem_resp_pending_w_yumi_o
   , input [paddr_width_p-1:0]                      mem_resp_pending_w_addr_i
   , input                                          mem_resp_pending_w_addr_bypass_hash_i
   , input                                          mem_resp_pending_up_i
   , input                                          mem_resp_pending_down_i
   , input                                          mem_resp_pending_clear_i

   // Pending bits write port - from memory command pipe
   , input                                          mem_cmd_pending_w_v_i
   , output logic                                   mem_cmd_pending_w_yumi_o
   , input [paddr_width_p-1:0]                      mem_cmd_pending_w_addr_i
   , input                                          mem_cmd_pending_w_addr_bypass_hash_i
   , input                                          mem_cmd_pending_up_i
   , input                                          mem_cmd_pending_down_i
   , input                                          mem_cmd_pending_clear_i

   // Pending bits write port - from LCE response pipe (coherence ack)
   , input                                          lce_resp_pending_w_v_i
   , output logic                                   lce_resp_pending_w_yumi_o
   , input [paddr_width_p-1:0]                      lce_resp_pending_w_addr_i
   , input                                          lce_resp_pending_w_addr_bypass_hash_i
   , input                                          lce_resp_pending_up_i
   , input                                          lce_resp_pending_down_i
   , input                                          lce_resp_pending_clear_i
   );

  // Define structure variables for output queues
  `declare_bp_bedrock_lce_if(paddr_width_p, lce_data_width_p, lce_id_width_p, cce_id_width_p, lce_assoc_p, lce);
  `declare_bp_bedrock_mem_if(paddr_width_p, mem_data_width_p, lce_id_width_p, lce_assoc_p, cce);

  bp_bedrock_lce_cmd_msg_header_s  lce_cmd_header_lo;
  assign lce_cmd_header_o = lce_cmd_header_lo;

  // MSHR
  `declare_bp_cce_mshr_s(lce_id_width_p, lce_assoc_p, paddr_width_p);
  bp_cce_mshr_s mshr_r, mshr_n;

  // Pending Bits and Queue
  logic pending_empty;
  logic buf_lce_req_header_v_li, buf_lce_req_header_ready_and_lo, buf_lce_req_has_data_li;
  bp_bedrock_lce_req_msg_header_s  buf_lce_req_header_li;
  logic buf_lce_req_data_v_li, buf_lce_req_data_ready_and_lo, buf_lce_req_last_li;
  logic [lce_data_width_p-1:0]  buf_lce_req_data_li;

  // FSM pending write signals
  logic pending_fsm_w_v, pending_fsm_w_yumi, pending_fsm_w_addr_bypass_hash;
  logic pending_fsm_up, pending_fsm_down, pending_fsm_clear;
  logic [paddr_width_p-1:0] pending_fsm_w_addr;

  // pending bits write input
  // these must be arbitrated between the three write ports: FSM, LCE Response, Mem Response
  logic pending_w_v, pending_w_yumi, pending_w_addr_bypass_hash;
  logic pending_up, pending_down, pending_clear;
  logic [paddr_width_p-1:0] pending_w_addr;

  bp_cce_hybrid_pending
    #(.bp_params_p(bp_params_p)
      ,.lce_data_width_p(lce_data_width_p)
      ,.header_els_p(pending_header_els_p)
      ,.data_els_p(pending_data_els_p)
      )
    pending_bits_and_queue
     (.clk_i(clk_i)
      ,.reset_i(reset_i)
      // request from input port
      // guaranteed to target cacheable memory space (cached or uncached)
      ,.lce_req_header_i(lce_req_header_i)
      ,.lce_req_header_v_i(lce_req_header_v_i)
      ,.lce_req_header_ready_and_o(lce_req_header_ready_and_o)
      ,.lce_req_has_data_i(lce_req_has_data_i)
      ,.lce_req_data_i(lce_req_data_i)
      ,.lce_req_data_v_i(lce_req_data_v_i)
      ,.lce_req_data_ready_and_o(lce_req_data_ready_and_o)
      ,.lce_req_last_i(lce_req_last_i)
      // request to pipeline
      // guaranteed to be ready for execution
      ,.lce_req_header_o(buf_lce_req_header_li)
      ,.lce_req_header_v_o(buf_lce_req_header_v_li)
      ,.lce_req_header_ready_and_i(buf_lce_req_header_ready_and_lo)
      ,.lce_req_has_data_o(buf_lce_req_has_data_li)
      ,.lce_req_data_o(buf_lce_req_data_li)
      ,.lce_req_data_v_o(buf_lce_req_data_v_li)
      ,.lce_req_data_ready_and_i(buf_lce_req_data_ready_and_lo)
      ,.lce_req_last_o(buf_lce_req_last_li)
      // Pending bits write port - from memory response pipe wbuf or FSM
      ,.pending_w_v_i(pending_w_v)
      ,.pending_w_yumi_o(pending_w_yumi)
      ,.pending_w_addr_i(pending_w_addr)
      ,.pending_w_addr_bypass_hash_i(pending_w_addr_bypass_hash)
      ,.pending_up_i(pending_up)
      ,.pending_down_i(pending_down)
      ,.pending_clear_i(pending_clear)
      // control
      ,.empty_o(pending_empty)
      );

  // Header Buffer
  logic lce_req_header_v_li, lce_req_header_yumi_lo, lce_req_has_data_li;
  bp_bedrock_lce_req_msg_header_s  lce_req_header_li;
  bsg_fifo_1r1w_small
    #(.width_p(lce_req_msg_header_width_lp+1)
      ,.els_p(header_fifo_els_p)
      )
    header_buffer
     (.clk_i(clk_i)
      ,.reset_i(reset_i)
      // input
      ,.v_i(buf_lce_req_header_v_i)
      ,.ready_o(buf_lce_req_header_ready_and_o)
      ,.data_i({buf_lce_req_has_data_i, buf_lce_req_header_i})
      // output
      ,.v_o(lce_req_header_v_li)
      ,.yumi_i(lce_req_header_yumi_lo)
      ,.data_o({lce_req_has_data_li, lce_req_header_li})
      );

  // Data buffer
  logic lce_req_data_v_li, lce_req_data_yumi_lo, lce_req_last_li;
  logic [lce_data_width_p-1:0]  lce_req_data_li;
  bsg_fifo_1r1w_small
    #(.width_p(lce_data_width_p+1)
      ,.els_p(data_fifo_els_p)
      )
    data_buffer
     (.clk_i(clk_i)
      ,.reset_i(reset_i)
      // input
      ,.v_i(buf_lce_req_data_v_i)
      ,.ready_o(buf_lce_req_data_ready_and_o)
      ,.data_i({buf_lce_req_last_i, buf_lce_req_data_i})
      // output
      ,.v_o(lce_req_data_v_li)
      ,.yumi_i(lce_req_data_yumi_lo)
      ,.data_o({lce_req_last_li, lce_req_data_li})
      );

  // Directory signals
  logic dir_r_v, dir_w_v;
  bp_cce_inst_minor_dir_op_e dir_cmd;
  logic sharers_v_lo;
  logic [num_lce_p-1:0] sharers_hits_lo;
  logic [num_lce_p-1:0][lg_lce_assoc_lp-1:0] sharers_ways_lo;
  bp_coh_states_e [num_lce_p-1:0] sharers_coh_states_lo;
  logic dir_lru_v_lo;
  logic [paddr_width_p-1:0] dir_lru_addr_lo, dir_addr_lo;
  bp_coh_states_e dir_lru_coh_state_lo;
  logic dir_busy_lo;

  logic [paddr_width_p-1:0] dir_addr_li;
  logic dir_addr_bypass_li;
  logic [lce_id_width_p-1:0] dir_lce_li;
  logic [lg_lce_assoc_lp-1:0] dir_way_li, dir_lru_way_li;
  bp_coh_states_e dir_coh_state_li;

  // GAD signals
  logic [lg_lce_assoc_lp-1:0] gad_req_addr_way_lo;
  logic [lce_id_width_p-1:0] gad_owner_lce_lo;
  logic [lg_lce_assoc_lp-1:0] gad_owner_lce_way_lo;
  bp_coh_states_e gad_owner_coh_state_lo;
  logic gad_replacement_flag_lo;
  logic gad_upgrade_flag_lo;
  logic gad_cached_shared_flag_lo;
  logic gad_cached_exclusive_flag_lo;
  logic gad_cached_modified_flag_lo;
  logic gad_cached_owned_flag_lo;
  logic gad_cached_forward_flag_lo;

  // Directory
  bp_cce_dir
    #(.bp_params_p(bp_params_p)
      )
    directory
     (.clk_i(clk_i)
      ,.reset_i(reset_i)
      // Inputs
      ,.addr_i(dir_addr_li)
      ,.addr_bypass_i(dir_addr_bypass_li)
      ,.lce_i(dir_lce_li)
      ,.way_i(dir_way_li)
      ,.lru_way_i(mshr_r.lru_way_id)
      ,.coh_state_i(dir_coh_state_li)
      ,.addr_dst_gpr_i(e_opd_r0) // only used for RDE
      ,.cmd_i(dir_cmd)
      ,.r_v_i(dir_r_v)
      ,.w_v_i(dir_w_v)
      // Outputs
      ,.busy_o(dir_busy_lo)
      ,.sharers_v_o(sharers_v_lo)
      ,.sharers_hits_o(sharers_hits_lo)
      ,.sharers_ways_o(sharers_ways_lo)
      ,.sharers_coh_states_o(sharers_coh_states_lo)
      ,.lru_v_o(dir_lru_v_lo)
      ,.lru_coh_state_o(dir_lru_coh_state_lo)
      ,.lru_addr_o(dir_lru_addr_lo)
      ,.addr_v_o() // only for RDE, can be left unconnected in FSM CCE
      ,.addr_o()
      ,.addr_dst_gpr_o()
      // Debug
      ,.cce_id_i(cce_id_i)
      );

  // GAD logic - auxiliary directory information logic
  bp_cce_gad
    #(.bp_params_p(bp_params_p)
      )
    gad
     (.clk_i(clk_i)
      ,.reset_i(reset_i)
      ,.gad_v_i(sharers_v_lo & ~dir_busy_lo)

      ,.sharers_v_i(sharers_v_lo)
      ,.sharers_hits_i(sharers_hits_lo)
      ,.sharers_ways_i(sharers_ways_lo)
      ,.sharers_coh_states_i(sharers_coh_states_lo)

      ,.req_lce_i(mshr_r.lce_id)
      ,.req_type_flag_i(mshr_r.flags[e_opd_rqf])
      ,.lru_coh_state_i(mshr_r.lru_coh_state)
      ,.atomic_req_flag_i(mshr_r.flags[e_opd_arf])
      ,.uncached_req_flag_i(mshr_r.flags[e_opd_ucf])

      ,.req_addr_way_o(gad_req_addr_way_lo)
      ,.owner_lce_o(gad_owner_lce_lo)
      ,.owner_way_o(gad_owner_lce_way_lo)
      ,.owner_coh_state_o(gad_owner_coh_state_lo)
      ,.replacement_flag_o(gad_replacement_flag_lo)
      ,.upgrade_flag_o(gad_upgrade_flag_lo)
      ,.cached_shared_flag_o(gad_cached_shared_flag_lo)
      ,.cached_exclusive_flag_o(gad_cached_exclusive_flag_lo)
      ,.cached_modified_flag_o(gad_cached_modified_flag_lo)
      ,.cached_owned_flag_o(gad_cached_owned_flag_lo)
      ,.cached_forward_flag_o(gad_cached_forward_flag_lo)
      );

  // Memory Command Stream Pump
  localparam stream_words_lp = cce_block_width_p / mem_data_width_p;
  localparam data_len_width_lp = `BSG_SAFE_CLOG2(stream_words_lp);
  bp_bedrock_cce_mem_msg_header_s mem_cmd_base_header_lo;
  logic mem_cmd_v_lo, mem_cmd_ready_and_li;
  logic mem_cmd_stream_new_li, mem_cmd_stream_done_li;
  logic [mem_data_width_p-1:0] mem_cmd_data_lo;
  logic [data_len_width_lp-1:0] mem_cmd_stream_cnt_li;
  bp_me_stream_pump_out
    #(.bp_params_p(bp_params_p)
      ,.stream_data_width_p(mem_data_width_p)
      ,.block_width_p(cce_block_width_p)
      ,.payload_width_p(cce_mem_payload_width_lp)
      ,.msg_stream_mask_p(mem_cmd_payload_mask_gp)
      ,.fsm_stream_mask_p(mem_cmd_payload_mask_gp)
      )
    mem_cmd_stream_pump
     (.clk_i(clk_i)
      ,.reset_i(reset_i)
      // to memory command output
      ,.msg_header_o(mem_cmd_header_o)
      ,.msg_data_o(mem_cmd_data_o)
      ,.msg_v_o(mem_cmd_v_o)
      ,.msg_last_o(mem_cmd_last_o)
      ,.msg_ready_and_i(mem_cmd_ready_and_i)
      // from uncacheable pipe
      ,.fsm_base_header_i(mem_cmd_base_header_lo)
      ,.fsm_data_i(mem_cmd_data_lo)
      ,.fsm_v_i(mem_cmd_v_lo)
      ,.fsm_ready_and_o(mem_cmd_ready_and_li)
      ,.fsm_cnt_o(mem_cmd_stream_cnt_li)
      ,.fsm_new_o(mem_cmd_stream_new_li)
      ,.fsm_last_o(/* unused */)
      ,.fsm_done_o(mem_cmd_stream_done_li)
      );

  // Counter for invalidation send/receive
  logic cnt_rst;
  logic [`BSG_WIDTH(1)-1:0] cnt_inc, cnt_dec;
  logic [`BSG_WIDTH(num_lce_p+1)-1:0] cnt;
  bsg_counter_up_down
    #(.max_val_p(num_lce_p+1)
      ,.init_val_p(0)
      ,.max_step_p(1)
      )
    counter
    (.clk_i(clk_i)
     ,.reset_i(reset_i | cnt_rst)
     ,.up_i(cnt_inc)
     ,.down_i(cnt_dec)
     ,.count_o(cnt)
     );

  // General use counter
  logic cnt_0_clr, cnt_0_inc;
  logic [`BSG_SAFE_CLOG2(counter_max_lp+1)-1:0] cnt_0;
  bsg_counter_clear_up
    #(.max_val_p(counter_max_lp)
      ,.init_val_p(0)
     )
    counter_0
     (.clk_i(clk_i)
      ,.reset_i(reset_i)
      ,.clear_i(cnt_0_clr)
      ,.up_i(cnt_0_inc)
      ,.count_o(cnt_0)
      );

  // General use counter
  logic cnt_1_clr, cnt_1_inc;
  logic [`BSG_SAFE_CLOG2(counter_max_lp+1)-1:0] cnt_1;
  bsg_counter_clear_up
    #(.max_val_p(counter_max_lp)
      ,.init_val_p(0)
     )
    counter_1
     (.clk_i(clk_i)
      ,.reset_i(reset_i)
      ,.clear_i(cnt_1_clr)
      ,.up_i(cnt_1_inc)
      ,.count_o(cnt_1)
      );

  // One hot of request LCE ID
  logic [num_lce_p-1:0] req_lce_id_one_hot;
  bsg_decode
    #(.num_out_p(num_lce_p))
    req_lce_id_to_one_hot
    (.i(mshr_r.lce_id[0+:lg_num_lce_lp])
     ,.o(req_lce_id_one_hot)
     );

  // One hot of owner LCE ID
  logic [num_lce_p-1:0] owner_lce_id_one_hot;
  bsg_decode
    #(.num_out_p(num_lce_p))
    owner_lce_id_to_one_hot
    (.i(mshr_r.owner_lce_id[0+:lg_num_lce_lp])
     ,.o(owner_lce_id_one_hot)
     );

  // Extract index of first bit set in sharers hits
  // Provides LCE ID to send invalidation to
  logic [num_lce_p-1:0] pe_sharers_r, pe_sharers_n;
  logic [lg_num_lce_lp-1:0] pe_lce_id;
  logic pe_v;
  bsg_priority_encode
    #(.width_p(num_lce_p)
      ,.lo_to_hi_p(1)
      )
    sharers_pri_enc
    (.i(pe_sharers_r)
     ,.addr_o(pe_lce_id)
     ,.v_o(pe_v)
     );

  logic [num_lce_p-1:0][lg_lce_assoc_lp-1:0] sharers_ways_r, sharers_ways_n;
  logic [num_lce_p-1:0] sharers_hits_r, sharers_hits_n;

  // Convert first index back to one hot
  logic [num_lce_p-1:0] pe_lce_id_one_hot;
  bsg_decode
    #(.num_out_p(num_lce_p))
    pe_lce_id_to_one_hot
    (.i(pe_lce_id)
     ,.o(pe_lce_id_one_hot)
     );

  // flags for cacheable requests
  // transfer occurs if any cache has block in E, M, O, or F (ownerhsip states)
  // and not doing an upgrade and not uncached access.
  wire transfer_flag = (mshr_r.flags[e_opd_cef] | mshr_r.flags[e_opd_cmf]
                        | mshr_r.flags[e_opd_cof] | mshr_r.flags[e_opd_cff])
                       & ~mshr_r.flags[e_opd_uf] & ~mshr_r.flags[e_opd_ucf];
  // Upgrade with block in O or F in other LCE should invalidate owner.
  // No need to writeback because requestor will get read/write permissions and has up-to-date block
  wire upgrade_inv_owner = mshr_r.flags[e_opd_uf]
                           & (mshr_r.flags[e_opd_cof] | mshr_r.flags[e_opd_cff]);
  // invalidations occur if write request and any block in S state (shared, not owner)
  // also need to invalidate owner in O or F when doing upgrade
  wire inv_sharers = (mshr_r.flags[e_opd_rqf] & mshr_r.flags[e_opd_csf]);

  // flags for uncached requests
  // all sharers need to be invalidated, regardless of read or write request
  wire uc_inv_sharers = mshr_r.flags[e_opd_csf];
  wire uc_inv_owner = mshr_r.flags[e_opd_cff] | mshr_r.flags[e_opd_cef]
                      | mshr_r.flags[e_opd_cmf] | mshr_r.flags[e_opd_cof];

  wire invalidate_flag = inv_sharers | uc_inv_sharers | upgrade_inv_owner;

  typedef enum logic [4:0] {
    e_reset
    ,e_clear_dir
    ,e_ready
    ,e_read_mem_spec
    ,e_read_dir
    ,e_wait_dir_gad
    ,e_write_next_state
    ,e_inv_cmd
    ,e_inv_ack
    ,e_replacement
    ,e_replacement_wb_resp
    ,e_uc_coherent_cmd
    ,e_uc_coherent_resp
    ,e_uc_coherent_mem_cmd
    ,e_uc_coherent_write_pending
    ,e_upgrade_stw_cmd
    ,e_transfer
    ,e_transfer_wb_resp
    ,e_resolve_speculation
    ,e_error
  } state_e;

  state_e state_r, state_n;

  always_comb begin
    empty_o = pending_empty & (state_r == e_ready) & ~lce_req_header_v_li;

    state_n = state_r;
    mshr_n = mshr_r;
    sharers_ways_n = sharers_ways_r;
    sharers_hits_n = sharers_hits_r;
    pe_sharers_n = pe_sharers_r;

    // LCE request
    lce_req_header_yumi_lo = '0;
    lce_req_data_yumi_lo = '0;

    // memory command defaults
    mem_cmd_base_header_lo = '0;
    mem_cmd_data_lo = '0;
    mem_cmd_v_lo = 1'b0;

    // lce command defaults
    lce_cmd_header_lo = '0;
    lce_cmd_header_lo.payload.src_id = cce_id_i;
    lce_cmd_header_v_o = '0;
    lce_cmd_has_data_o = '0;
    lce_cmd_data_o = '0;
    lce_cmd_data_v_o = '0;
    lce_cmd_last_o = '0;

    // spec bits write
    spec_w_v_o = '0;
    spec_w_addr_o = mshr_r.paddr;
    spec_w_addr_bypass_hash_o = '0;
    spec_v_o = '0;
    spec_squash_v_o = '0;
    spec_fwd_mod_v_o = '0;
    spec_state_v_o = '0;
    spec_bits_o = '0;

    pending_w_v = 1'b0;
    pending_w_addr_bypass_hash = 1'b0;
    pending_up = 1'b0;
    pending_down = 1'b0;
    pending_clear = 1'b0;
    pending_w_addr = '0;

    dir_r_v = '0;
    dir_w_v = '0;
    dir_cmd = e_rdw_op;
    dir_lce_li = mshr_r.lce_id;
    dir_way_li = mshr_r.way_id;
    dir_lru_way_li = mshr_r.lru_way_id;
    dir_addr_li = mshr_r.paddr;
    dir_addr_bypass_li = '0;
    dir_coh_state_li = mshr_r.next_coh_state;

    cnt_inc = '0;
    cnt_dec = '0;
    cnt_rst = '0;

    cnt_1_clr = '0;
    cnt_1_inc = '0;
    cnt_0_clr = '0;
    cnt_0_inc = '0;

    case (state_r)
      e_reset: begin
        state_n = e_clear_dir;
        cnt_rst = 1'b1;
        cnt_0_clr = 1'b1;
        cnt_1_clr = 1'b1;
      end // e_reset

      // After reset, clear the directory, then operate based on the current operating mode
      // If normal mode is set, perform the sync sequence with the LCEs
      e_clear_dir: begin
        dir_w_v = 1'b1;
        dir_cmd = e_clr_op;

        // increment through maximal number of tag sets (outer loop) and all LCE's (inner loop)
        // tag set number is cnt_0
        // LCE is cnt_1

        // bypass the address hashing in bp_cce_dir_segment, using dir_addr_li directly as the
        // tag set number for the operation
        dir_addr_bypass_li = 1'b1;
        dir_addr_li = '0;
        dir_addr_li[0+:lg_max_tag_sets_lp] = cnt_0[0+:lg_max_tag_sets_lp];
        dir_lce_li = cnt_1[0+:lce_id_width_p];

        // inner loop - LCE
        // clear the LCE counter back to 0 after reaching max LCE ID to reset for next tag set
        cnt_1_clr = (cnt_1 == (num_lce_p-1));
        // increment the LCE counter if not clearing
        cnt_1_inc = ~cnt_1_clr;

        // outer loop - tag set
        // cnt_0 clears after all LCEs in the last tag set have been cleared
        cnt_0_clr = (cnt_0 == (max_tag_sets_lp-1)) & cnt_1_clr;
        // move to next tag set when cnt_1 clears back to LCE 0
        // don't increment when exiting this state (and clearing the counter)
        cnt_0_inc = cnt_1_clr & ~cnt_0_clr;

        // Stay in e_clear_dir until cnt_0_clr goes high
        state_n = cnt_0_clr ? e_ready : e_clear_dir;
      end // e_clear_dir

      // Process requests that have cleared pending bit check
      // Coherent/cacheable memory space has three request types:
      // 1. normal, cached request
      // 2. uncached request
      // 3. amo request
      // only normal, cached requests will issue a speculative memory read
      e_ready: begin
        // clear counters
        cnt_0_clr = 1'b1;
        cnt_1_clr = 1'b1;
        cnt_rst = 1'b1;

        // populate MSHR fields from LCE request
        mshr_n = '0;
        mshr_n.msg_type.req = lce_req_header_li.msg_type.req;
        mshr_n.msg_subop = lce_req_header_li.subop;
        mshr_n.paddr = lce_req_header_li.addr;
        mshr_n.msg_size = lce_req_header_li.size;
        mshr_n.lce_id = lce_req_header_li.payload.src_id;
        mshr_n.lru_way_id = lce_req_header_li.payload.lru_way_id;
        mshr_n.flags[e_opd_nerf] = lce_req_header_li.payload.non_exclusive;
        mshr_n.flags[e_opd_rcf] = 1'b1;

        unique case (lce_req_header_li.msg_type.req)
          e_bedrock_req_rd_miss: begin
            // write pending bit for speculative memory read
            // do write this cycle to make spec memory read logic simpler
            pending_w_v = lce_req_header_v_li;
            pending_up = 1'b1;
            pending_w_addr = lce_req_header_li.addr;
            lce_req_header_yumi_lo = lce_req_header_v_li & pending_w_yumi;
            state_n = lce_req_header_yumi_lo ? e_read_mem_spec : state_r;
          end
          e_bedrock_req_wr_miss: begin
            mshr_n.flags[e_opd_rqf] = 1'b1;
            // write pending bit for speculative memory read
            // do write this cycle to make spec memory read logic simpler
            pending_w_v = lce_req_header_v_li;
            pending_up = 1'b1;
            pending_w_addr = lce_req_header_li.addr;
            lce_req_header_yumi_lo = lce_req_header_v_li & pending_w_yumi;
            state_n = lce_req_header_yumi_lo ? e_read_mem_spec : state_r;
          end
          e_bedrock_req_uc_rd: begin
            mshr_n.flags[e_opd_ucf] = 1'b1;
            lce_req_header_yumi_lo = lce_req_header_v_li;
            state_n = lce_req_header_v_li ? e_read_dir : state_r;
          end
          e_bedrock_req_uc_wr: begin
            mshr_n.flags[e_opd_ucf] = 1'b1;
            mshr_n.flags[e_opd_rqf] = 1'b1;
            lce_req_header_yumi_lo = lce_req_header_v_li;
            state_n = lce_req_header_v_li ? e_read_dir : state_r;
          end
          e_bedrock_req_uc_amo: begin
            // TODO: implement amo requests
            mshr_n.flags[e_opd_ucf] = 1'b1;
            mshr_n.flags[e_opd_arf] = 1'b1;
            mshr_n.flags[e_opd_anrf] = 1'b0; // TODO: amo no return property
            lce_req_header_yumi_lo = lce_req_header_v_li;
            state_n = lce_req_header_v_li ? e_error : state_r;
          end
          default: begin
            state_n = e_error;
          end
        endcase
      end // e_ready

      // issue speculative memory read command
      // associated pending bit write occurred last cycle
      e_read_mem_spec: begin
        // r&v on mem_cmd
        mem_cmd_v_lo = 1'b1;
        mem_cmd_base_header_lo.msg_type.mem = e_bedrock_mem_rd;
        mem_cmd_base_header_lo.addr = mshr_r.paddr;
        // TODO: requires LCE to set size field properly - could also have CCE set for block size
        mem_cmd_base_header_lo.size = mshr_r.msg_size;
        mem_cmd_base_header_lo.payload.lce_id = mshr_r.lce_id;
        mem_cmd_base_header_lo.payload.way_id = mshr_r.lru_way_id;
        // speculatively issue request for E state
        mem_cmd_base_header_lo.payload.state = e_COH_E;
        mem_cmd_base_header_lo.payload.speculative = 1'b1;

        // set the spec bit and clear all other bits for this entry
        // this write is idempotent - write each cycle until memory command sends
        spec_w_v_o = 1'b1;
        spec_v_o = 1'b1;
        spec_squash_v_o = 1'b1;
        spec_fwd_mod_v_o = 1'b1;
        spec_state_v_o = 1'b1;
        spec_bits_o.spec = 1'b1;
        spec_bits_o.squash = 1'b0;
        spec_bits_o.fwd_mod = 1'b0;
        spec_bits_o.state = e_COH_I;

        state_n = (mem_cmd_stream_done_li) ? e_read_dir : e_read_mem_spec;

      end // e_read_mem_spec

      e_read_dir: begin
        // initiate the directory read
        // At the earliest, data will be valid in the next cycle
        dir_r_v = 1'b1;
        dir_addr_li = mshr_r.paddr;
        dir_cmd = e_rdw_op;
        dir_lce_li = mshr_r.lce_id;
        dir_lru_way_li = mshr_r.lru_way_id;
        state_n = e_wait_dir_gad;
      end // e_read_dir

      e_wait_dir_gad: begin

        // capture LRU outputs when they appear
        if (dir_lru_v_lo) begin
          mshr_n.lru_paddr = dir_lru_addr_lo;
          mshr_n.lru_coh_state = dir_lru_coh_state_lo;
        end

        // capture sharer information when it appears
        if (sharers_v_lo) begin
          sharers_ways_n = sharers_ways_lo;
          sharers_hits_n = sharers_hits_lo;
        end

        // process directory output when read completes
        if (sharers_v_lo & ~dir_busy_lo) begin

          mshr_n.way_id = gad_req_addr_way_lo;

          mshr_n.flags[e_opd_rf] = gad_replacement_flag_lo;
          mshr_n.flags[e_opd_uf] = gad_upgrade_flag_lo;
          mshr_n.flags[e_opd_csf] = gad_cached_shared_flag_lo;
          mshr_n.flags[e_opd_cef] = gad_cached_exclusive_flag_lo;
          mshr_n.flags[e_opd_cmf] = gad_cached_modified_flag_lo;
          mshr_n.flags[e_opd_cof] = gad_cached_owned_flag_lo;
          mshr_n.flags[e_opd_cff] = gad_cached_forward_flag_lo;

          mshr_n.owner_lce_id = gad_owner_lce_lo;
          mshr_n.owner_way_id = gad_owner_lce_way_lo;
          mshr_n.owner_coh_state = gad_owner_coh_state_lo;

          // determine next state for MOESIF protocol
          // atomic or uncached requests to coherent memory will set block to Invalid if it is
          // present in the requesting LCE
          // write requests get block in M
          // read request gets block in S if non-exclusive request or block cached anywhere
          // else send block in E
          mshr_n.next_coh_state =
            (mshr_r.flags[e_opd_arf] | mshr_r.flags[e_opd_ucf])
            ? e_COH_I
            : (mshr_r.flags[e_opd_rqf])
              ? e_COH_M
              : (mshr_r.flags[e_opd_nerf] | gad_cached_shared_flag_lo | gad_cached_exclusive_flag_lo
                 | gad_cached_modified_flag_lo | gad_cached_owned_flag_lo | gad_cached_forward_flag_lo)
                ? e_COH_S
                : e_COH_E;

          state_n = e_write_next_state;
        end // process GAD output
      end // e_wait_dir_gad

      e_write_next_state: begin
        // writing to the directory will make the sharers_v_lo signal go low, but in this FSM
        // CCE we know that the sharers vectors are still valid in the state we need from the
        // previous read, so we perform the coherence state update for the requesting LCE anyway

        dir_lce_li = mshr_r.lce_id;
        dir_addr_li = mshr_r.paddr;
        dir_coh_state_li = mshr_r.next_coh_state;

        // upgrade detected, only change state
        if (mshr_r.flags[e_opd_uf]) begin
          dir_w_v = 1'b1;
          dir_cmd = e_wds_op;
          dir_way_li = mshr_r.way_id;

        // amo or uncached to coherent memory
        // only write directory if replacement flag is set indicating the requsting LCE has
        // the block cached already
        end else if (mshr_r.flags[e_opd_arf] | mshr_r.flags[e_opd_ucf]) begin
          dir_w_v = mshr_r.flags[e_opd_rf];
          dir_cmd = e_wds_op;
          // the block, if cached at the LCE, is in the way indicated by the way_id field of
          // the MSHR as produced by the GAD module
          dir_way_li = mshr_r.way_id;

        // normal requests, write tag and state
        end else begin
          dir_w_v = 1'b1;
          dir_cmd = e_wde_op;
          dir_way_li = mshr_r.lru_way_id;
        end

        // Ordering of coherence actions:
        // Replacement, if needed
        // - requesting LCE has a valid block in LRU way
        // - uncached or amo request and requesting LCE has target address cached
        // Invalidations, if needed
        // - cacheable write request and cached shared by other LCEs
        // - uncached request (rd or wr) and cached shared by other LCEs
        // - upgrade and cached O or F by other
        // Uncacheable access
        // or Cacheable access: Upgrade, Transfer, or Memory access (resolve speculative access)
        state_n =
          (mshr_r.flags[e_opd_rf])
          ? e_replacement
          : (invalidate_flag)
            ? e_inv_cmd
            : (mshr_r.flags[e_opd_arf] | mshr_r.flags[e_opd_ucf])
              ? uc_inv_owner
                ? e_uc_coherent_cmd
                : e_uc_coherent_mem_cmd
              : (mshr_r.flags[e_opd_uf])
                ? e_upgrade_stw_cmd
                : (transfer_flag)
                  ? e_transfer
                  : e_resolve_speculation;

        // setup required state for sending invalidations
        // only if next state is invalidations (i.e., not doing a replacement)
        if (~mshr_r.flags[e_opd_rf] & invalidate_flag) begin
          // don't invalidate the requesting LCE
          pe_sharers_n = sharers_hits_r & ~req_lce_id_one_hot;
          // if doing a transfer, also remove owner LCE since transfer
          // routine will take care of setting owner into correct new state
          pe_sharers_n = transfer_flag
                         ? pe_sharers_n & ~owner_lce_id_one_hot
                         : pe_sharers_n;
          cnt_rst = 1'b1;
        end

      end // e_write_next_state

      e_replacement: begin
        lce_cmd_header_v_o = 1'b1;
        lce_cmd_has_data_o = 1'b0;

        // set state to invalid and writeback
        lce_cmd_header_lo.msg_type.cmd = e_bedrock_cmd_st_wb;
        // for an uc/amo request, the mshr way_id field indicates the way in which the requesting
        // LCE's copy of the cache block is stored at the LCE
        if (mshr_r.flags[e_opd_arf] | mshr_r.flags[e_opd_ucf]) begin
          lce_cmd_header_lo.payload.way_id = mshr_r.way_id;
          lce_cmd_header_lo.addr = mshr_r.paddr;
        end else begin
          lce_cmd_header_lo.payload.way_id = mshr_r.lru_way_id;
          lce_cmd_header_lo.addr = mshr_r.lru_paddr;
        end
        lce_cmd_header_lo.payload.dst_id = mshr_r.lce_id;
        // Note: this state must be e_COH_I to properly handle amo or uncached access to
        // coherent memory that requires invalidating the requesting LCE if it has the block
        lce_cmd_header_lo.payload.state = e_COH_I;

        state_n = (lce_cmd_header_v_o & lce_cmd_header_ready_and_i)
                  ? e_replacement_wb_resp
                  : e_replacement;
      end // e_replacement

      e_replacement_wb_resp: begin
        // wait for signal from LCE response module
        // note: no transition for upgrade because replacement occuring implies not an upgrade
        state_n = wb_yumi_i
                  ? (invalidate_flag)
                    ? e_inv_cmd
                    : (mshr_r.flags[e_opd_arf] | mshr_r.flags[e_opd_ucf])
                      ? uc_inv_owner
                        ? e_uc_coherent_cmd
                        : e_uc_coherent_mem_cmd
                      : (transfer_flag)
                        ? e_transfer
                        : e_resolve_speculation
                  : state_r;
        // setup required state for sending invalidations
        if (invalidate_flag) begin
          // don't invalidate the requesting LCE
          pe_sharers_n = sharers_hits_r & ~req_lce_id_one_hot;
          // if doing a transfer, also remove owner LCE since transfer
          // routine will take care of setting owner into correct new state
          pe_sharers_n = transfer_flag
                         ? pe_sharers_n & ~owner_lce_id_one_hot
                         : pe_sharers_n;
          cnt_rst = 1'b1;
        end
      end // e_replacement_wb_resp

      e_inv_cmd: begin

        // only send invalidation if priority encode has valid output
        // this indicates the sharers vector has a valid bit set
        if (pe_v) begin
          lce_cmd_header_v_o = 1'b1;
          lce_cmd_has_data_o = 1'b0;
          lce_cmd_header_lo.msg_type.cmd = e_bedrock_cmd_inv;
          lce_cmd_header_lo.addr = mshr_r.paddr;

          // destination and way come from sharers information
          lce_cmd_header_lo.payload.dst_id[0+:lg_num_lce_lp] = pe_lce_id;
          lce_cmd_header_lo.payload.way_id = sharers_ways_r[pe_lce_id];

          // message sent, increment count
          cnt_inc = lce_cmd_header_v_o & lce_cmd_header_ready_and_i;
          // write directory - idempotent
          dir_w_v = lce_cmd_header_v_o;
          dir_cmd = e_wds_op;
          dir_addr_li = mshr_r.paddr;
          dir_lce_li = '0;
          dir_lce_li[0+:lg_num_lce_lp] = pe_lce_id;
          dir_way_li = sharers_ways_r[pe_lce_id];
          dir_coh_state_li = e_COH_I;

          // update sharers hit vector to feed back to priority encode module
          pe_sharers_n = (lce_cmd_header_v_o & lce_cmd_header_ready_and_i)
                         ? pe_sharers_r & ~pe_lce_id_one_hot
                         : pe_sharers_r;

          // move to response state if none of the sharer bits are set, indicating
          // that the last command is sending this cycle
          if (pe_sharers_n == '0) begin
            state_n = e_inv_ack;
          end
        end // pe_v

        // decrement counter if invalidate ack arrives
        cnt_dec = inv_yumi_i;
      end // e_inv_cmd

      e_inv_ack: begin
        // decrement counter as acks arrive
        cnt_dec = inv_yumi_i;

        // move to next state if all acks already arrived or last ack arriving in current cycle
        if ((cnt == '0) || ((cnt == 'd1) && inv_yumi_i)) begin
          state_n = (mshr_r.flags[e_opd_arf] | mshr_r.flags[e_opd_ucf])
                    ? uc_inv_owner
                      ? e_uc_coherent_cmd
                      : e_uc_coherent_mem_cmd
                    : (mshr_r.flags[e_opd_uf])
                      ? e_upgrade_stw_cmd
                      : (transfer_flag)
                        ? e_transfer
                        : e_resolve_speculation;
        end
      end // e_inv_ack

      // Process uncached request to coherent memory space
      e_uc_coherent_cmd: begin
        // at this point for amo/uncached request to coherent memory, the requesting LCE
        // has had block invalidated and written back if needed. All sharers (COH_S) blocks were
        // also invalidated.

        // if an owner has block it needs to be invalidated and written back (if required)
        if (uc_inv_owner) begin
          lce_cmd_header_v_o = 1'b1;
          lce_cmd_has_data_o = 1'b0;

          lce_cmd_header_lo.addr = mshr_r.paddr;
          lce_cmd_header_lo.payload.dst_id = mshr_r.owner_lce_id;
          lce_cmd_header_lo.payload.way_id = mshr_r.owner_way_id;
          lce_cmd_header_lo.payload.state = e_COH_I;

          // either invalidate or set tag and writeback
          // if owner is in F state, block is clean, so only need to invalidate
          // else, block in E, M, or O, need to invalidate and writeback
          lce_cmd_header_lo.msg_type.cmd = mshr_r.flags[e_opd_cff]
                                 ? e_bedrock_cmd_inv
                                 : e_bedrock_cmd_st_wb;

          // update state of owner in directory
          dir_w_v = lce_cmd_header_v_o & lce_cmd_header_ready_and_i;
          dir_cmd = e_wds_op;
          dir_addr_li = mshr_r.paddr;
          dir_lce_li = mshr_r.owner_lce_id;
          dir_way_li = mshr_r.owner_way_id;
          dir_coh_state_li = e_COH_I;

          state_n = (lce_cmd_header_v_o & lce_cmd_header_ready_and_i)
                    ? e_uc_coherent_resp
                    : e_uc_coherent_cmd;
        end
        // no other LCE is owner
        else begin
          state_n = e_uc_coherent_mem_cmd;
        end
      end // e_uc_coherent_cmd

      // amo/uc wait for replacement writeback or invalidation ack if sent
      // writeback is forwarded to memory by LCE response module
      e_uc_coherent_resp: begin
        state_n = (wb_yumi_i | inv_yumi_i)
                  ? e_uc_coherent_mem_cmd
                  : state_r;
      end // e_uc_coherent_resp

      // amo/uc after inv_ack/wb_response, issue op to memory
      // writes pending bit
      e_uc_coherent_mem_cmd: begin
        // r&v on mem_cmd
        // v->yumi on lce_req_data
        mem_cmd_v_lo = lce_req_data_v_li;
        lce_req_data_yumi_lo = mem_cmd_v_lo & mem_cmd_ready_and_li;

        // set message type based on request message type
        unique case (mshr_r.msg_type.req)
          e_bedrock_req_uc_rd: mem_cmd_base_header_lo.msg_type = e_bedrock_mem_uc_rd;
          e_bedrock_req_uc_wr: mem_cmd_base_header_lo.msg_type = e_bedrock_mem_uc_wr;
          e_bedrock_req_uc_amo: mem_cmd_base_header_lo.msg_type = e_bedrock_mem_amo;
          default: mem_cmd_base_header_lo.msg_type = e_bedrock_mem_uc_rd;
        endcase
        // uncached/amo address must be aligned appropriate to the request size
        // in the LCE request (which is stored in the MSHR)
        mem_cmd_base_header_lo.addr = mshr_r.paddr;
        mem_cmd_base_header_lo.size = mshr_r.msg_size;
        mem_cmd_base_header_lo.payload.lce_id = mshr_r.lce_id;
        mem_cmd_base_header_lo.payload.way_id = '0;
        // this op is uncached in LCE for both amo or uncached requests
        mem_cmd_base_header_lo.payload.uncached = 1'b1;
        mem_cmd_data_lo = lce_req_data_li;

        // try to write the pending bit on last beat
        // TODO: this could be a long path? pending_w_yumi depends on mem_cmd handshake
        pending_w_v = mem_cmd_stream_done_li;
        pending_w_addr = mshr_r.paddr;
        pending_up = 1'b1;

        // if last beat is acked, check if pending write happened
        state_n = mem_cmd_stream_done_li
                  ? pending_w_yumi
                    ? e_ready
                    : e_uc_coherent_write_pending
                  : e_uc_coherent_mem_cmd;

      end // e_uc_coherent_mem_cmd

      e_uc_coherent_write_pending: begin
        pending_w_v = 1'b1;
        pending_w_addr = mshr_r.paddr;
        pending_up = 1'b1;
        state_n = pending_w_yumi ? e_ready : state_r;
      end

      e_transfer: begin
        // Transfer required:
        // 1. write request: set state and transfer, invalidate owner, requestor to M
        // 2. read req w/ owner in O or F: transfer only
        // 3. read req w/ owner in M: set state, transfer, make owner O (dirty-shared)
        // 4. read req w/ owner in E: set state, transfer, writeback, make owner F (clean-shared)
        //    - WB required to ensure silent E->M is recorded
        lce_cmd_header_v_o = 1'b1;
        lce_cmd_has_data_o = 1'b0;

        lce_cmd_header_lo.payload.dst_id = mshr_r.owner_lce_id;
        lce_cmd_header_lo.payload.way_id = mshr_r.owner_way_id;

        lce_cmd_header_lo.msg_type.cmd = mshr_r.flags[e_opd_rqf] | mshr_r.flags[e_opd_cmf]
                                         ? e_bedrock_cmd_st_tr
                                         : mshr_r.flags[e_opd_cof] | mshr_r.flags[e_opd_cff]
                                           ? e_bedrock_cmd_tr
                                           // transfer, not cached in M, O, or F -> cached in E
                                           : e_bedrock_cmd_st_tr_wb;

        lce_cmd_header_lo.addr = mshr_r.paddr;

        // either Invalidate or Downgrade Owner, depending on request type
        // write request invalidates owner (can only have 1 writer!)
        // read request downgrades owner: M->O, E->F
        // else set state field to I in message, but it will not be used by LCE sending transfer
        lce_cmd_header_lo.payload.state = mshr_r.flags[e_opd_rqf]
                                          ? e_COH_I
                                          : mshr_r.flags[e_opd_cmf]
                                            ? e_COH_O
                                            : mshr_r.flags[e_opd_cef]
                                              ? e_COH_F
                                              : e_COH_I;

        // transfer information
        lce_cmd_header_lo.payload.target = mshr_r.lce_id;
        lce_cmd_header_lo.payload.target_way_id = mshr_r.lru_way_id;
        lce_cmd_header_lo.payload.target_state = mshr_r.next_coh_state;

        // update state of owner in directory if required
        // transfer from owner in O or F does not require update to owner state
        dir_w_v = lce_cmd_header_v_o & lce_cmd_header_ready_and_i
                  & (mshr_r.flags[e_opd_rqf] | mshr_r.flags[e_opd_cmf] | mshr_r.flags[e_opd_cef]);
        dir_cmd = e_wds_op;
        dir_addr_li = mshr_r.paddr;
        dir_lce_li = mshr_r.owner_lce_id;
        dir_way_li = mshr_r.owner_way_id;
        dir_coh_state_li = mshr_r.flags[e_opd_rqf]
                           ? e_COH_I
                           : mshr_r.flags[e_opd_cmf]
                             ? e_COH_O
                             : mshr_r.flags[e_opd_cef]
                               ? e_COH_F
                               : e_COH_I;

        // only transfer from owner in E requires a writeback
        state_n = (lce_cmd_header_v_o & lce_cmd_header_ready_and_i)
                  ? mshr_r.flags[e_opd_cef]
                    ? e_transfer_wb_resp
                    : e_resolve_speculation
                  : state_r;

      end // e_transfer

      e_transfer_wb_resp: begin
        state_n = wb_yumi_i ? e_resolve_speculation : state_r;
      end // e_transfer_wb_resp

      e_upgrade_stw_cmd: begin
        // r&v handshake
        lce_cmd_header_v_o = 1'b1;
        lce_cmd_has_data_o = 1'b0;

        lce_cmd_header_lo.msg_type.cmd = e_bedrock_cmd_st_wakeup;
        lce_cmd_header_lo.addr = mshr_r.paddr;
        lce_cmd_header_lo.payload.dst_id = mshr_r.lce_id;
        lce_cmd_header_lo.payload.way_id = mshr_r.way_id;
        lce_cmd_header_lo.payload.state = mshr_r.next_coh_state;

        state_n = (lce_cmd_header_v_o & lce_cmd_header_ready_and_i)
                  ? e_resolve_speculation
                  : e_upgrade_stw_cmd;
      end // e_upgrade_stw_cmd

      e_resolve_speculation: begin
        // Resolve speculation
        if (transfer_flag | mshr_r.flags[e_opd_uf]) begin
          // squash speculative memory request if transfer or upgrade
          spec_w_v = 1'b1;
          // no longer speculative
          spec_v_li = 1'b1;
          spec_bits_li.spec = 1'b0;
          // squash the response
          squash_v_li = 1'b1;
          spec_bits_li.squash = 1'b1;
        end else if (mshr_r.flags[e_opd_rqf]) begin
          // forward with M state
          spec_w_v = 1'b1;
          spec_v_li = 1'b1;
          fwd_mod_v_li = 1'b1;
          state_v_li = 1'b1;
          spec_bits_li.spec = 1'b0;
          spec_bits_li.state = e_COH_M;
          spec_bits_li.fwd_mod = 1'b1;
        end else if (mshr_r.flags[e_opd_csf] | mshr_r.flags[e_opd_nerf]) begin
          // forward with S state
          spec_w_v = 1'b1;
          spec_v_li = 1'b1;
          fwd_mod_v_li = 1'b1;
          state_v_li = 1'b1;
          spec_bits_li.spec = 1'b0;
          spec_bits_li.state = e_COH_S;
          spec_bits_li.fwd_mod = 1'b1;
        end else begin
          // forward with E state (as requested)
          spec_w_v = 1'b1;
          spec_v_li = 1'b1;
          spec_bits_li.spec = 1'b0;
        end
        state_n = e_ready;
      end // e_resolve_speculation

      e_error: begin
        state_n = e_error;
      end // e_error

      default: begin
        // use defaults above
      end

    endcase

    // Pending bit write arbitration
    // do this after the FSM code so that pending_w_v can be examined to determine if FSM is writing
    // the pending bits
    // arbitration order (high to low): FSM, mem_resp, mem_cmd, lce_resp
    mem_resp_pending_w_yumi_o = 1'b0;
    mem_cmd_pending_w_yumi_o = 1'b0;
    lce_resp_pending_w_yumi_o = 1'b0;
    if (~pending_w_v) begin
      if (mem_resp_pending_w_v_i) begin
        pending_w_v = mem_resp_pending_w_v_i;
        pending_w_addr_bypass_hash = mem_resp_pending_w_addr_bypass_hash_i;
        pending_up = mem_resp_pending_up_i;
        pending_down = mem_resp_pending_down_i;
        pending_clear = mem_resp_pending_clear_i;
        pending_w_addr = mem_resp_pending_w_addr_i;
        mem_resp_pending_w_yumi_o = pending_w_yumi;
      end
      else if (mem_cmd_pending_w_v_i) begin
        pending_w_v = mem_cmd_pending_w_v_i;
        pending_w_addr_bypass_hash = mem_cmd_pending_w_addr_bypass_hash_i;
        pending_up = mem_cmd_pending_up_i;
        pending_down = mem_cmd_pending_down_i;
        pending_clear = mem_cmd_pending_clear_i;
        pending_w_addr = mem_cmd_pending_w_addr_i;
        mem_cmd_pending_w_yumi_o = pending_w_yumi;
      end
      else if (lce_resp_pending_w_v_i) begin
        pending_w_v = lce_resp_pending_w_v_i;
        pending_w_addr_bypass_hash = lce_resp_pending_w_addr_bypass_hash_i;
        pending_up = lce_resp_pending_up_i;
        pending_down = lce_resp_pending_down_i;
        pending_clear = lce_resp_pending_clear_i;
        pending_w_addr = lce_resp_pending_w_addr_i;
        lce_resp_pending_w_yumi_o = pending_w_yumi;
      end
    end

  end // always_comb

  // Sequential Logic
  always_ff @(posedge clk_i) begin
    if (reset_i) begin
      state_r <= e_reset;
      mshr_r <= '0;
      sharers_ways_r <= '0;
      sharers_hits_r <= '0;
      pe_sharers_r <= '0;
    end else begin
      state_r <= state_n;
      mshr_r <= mshr_n;
      sharers_ways_r <= sharers_ways_n;
      sharers_hits_r <= sharers_hits_n;
      pe_sharers_r <= pe_sharers_n;
    end
  end

endmodule
