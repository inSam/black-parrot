/**
 *
 * Name:
 *   bp_cce_hybrid_pending_queue.sv
 *
 * Description:
 *   This module holds requests that are blocked due to an existing outstanding request.
 *
 *   The initial implementation is a pair of FIFOs for header and data.
 *
 */

`include "bp_common_defines.svh"
`include "bp_me_defines.svh"

module bp_cce_hybrid_pending_queue
  import bp_common_pkg::*;
  import bp_me_pkg::*;
  #(parameter bp_params_e bp_params_p = e_bp_default_cfg
    `declare_bp_proc_params(bp_params_p)

    , parameter lce_data_width_p = dword_width_gp
    , parameter header_els_p     = 2
    , parameter data_els_p       = 2

    // interface widths
    `declare_bp_bedrock_lce_if_widths(paddr_width_p, lce_data_width_p, lce_id_width_p, cce_id_width_p, lce_assoc_p, lce)
  )
  (input                                            clk_i
   , input                                          reset_i

   // LCE Request
   // BedRock Burst protocol: ready&valid
   , input [lce_req_msg_header_width_lp-1:0]        lce_req_header_i
   , input                                          lce_req_header_v_i
   , output logic                                   lce_req_header_ready_and_o
   , input                                          lce_req_has_data_i
   , input [lce_data_width_p-1:0]                   lce_req_data_i
   , input                                          lce_req_data_v_i
   , output logic                                   lce_req_data_ready_and_o
   , input                                          lce_req_last_i

   // raised if either header or data buffer is full
   , output logic                                   full_o

   // BedRock Burst using valid->yumi
   , output logic [lce_req_msg_header_width_lp-1:0] lce_req_header_o
   , output logic                                   lce_req_header_v_o
   , input                                          lce_req_header_yumi_i
   , output logic                                   lce_req_has_data_o
   , output logic [lce_data_width_p-1:0]            lce_req_data_o
   , output logic                                   lce_req_data_v_o
   , input                                          lce_req_data_yumi_i
   , output logic                                   lce_req_last_o
   );

  `declare_bp_bedrock_lce_if(paddr_width_p, lce_data_width_p, lce_id_width_p, cce_id_width_p, lce_assoc_p, lce);

  bp_bedrock_lce_req_msg_header_s lce_req_header_li, lce_req_header_lo;
  assign lce_req_header_li = lce_req_header_i;
  assign lce_req_header_o = lce_req_header_lo;

  // LCE Request Header Buffer
  bsg_fifo_1r1w_small
    #(.width_p(lce_req_msg_header_width_lp+1)
      ,.els_p(header_els_p)
      )
    header_buffer
     (.clk_i(clk_i)
      ,.reset_i(reset_i)
      ,.ready_o(lce_req_header_ready_and_o)
      ,.data_i({lce_req_has_data_i, lce_req_header_li})
      ,.v_i(lce_req_header_v_i)
      ,.v_o(lce_req_header_v_o)
      ,.data_o({lce_req_has_data_o, lce_req_header_lo})
      ,.yumi_i(lce_req_header_yumi_i)
      );

  // LCE Request Data Buffer
  bsg_fifo_1r1w_small
    #(.width_p(lce_data_width_p+1)
      ,.els_p(data_els_p)
      )
    data_buffer
     (.clk_i(clk_i)
      ,.reset_i(reset_i)
      ,.ready_o(lce_req_data_ready_and_o)
      ,.data_i({lce_req_last_i, lce_req_data_i})
      ,.v_i(lce_req_data_v_i)
      ,.v_o(lce_req_data_v_o)
      ,.data_o({lce_req_last_o, lce_req_data_o})
      ,.yumi_i(lce_req_data_yumi_i)
      );

  assign full_o = ~lce_req_header_ready_and_o | ~lce_req_data_ready_and_o;

  /*
  // Combinational Logic
  always_comb begin
  end

  // Sequential Logic
  always_ff @(posedge clk_i) begin
    if (reset_i) begin
    end else begin
    end
  end
  */

endmodule
