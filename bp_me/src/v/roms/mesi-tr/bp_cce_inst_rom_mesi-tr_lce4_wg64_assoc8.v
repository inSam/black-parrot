// auto-generated by bsg_ascii_to_rom.py from /home/wysem/blackparrot/pre-alpha-release/bp_me/src/asm/microcode/cce/mesi-tr.mem; do not modify
module bp_cce_inst_rom #(parameter width_p=-1, addr_width_p=-1)
(input  [addr_width_p-1:0] addr_i
,output logic [width_p-1:0]      data_o
);
always_comb case(addr_i)
         0: data_o = width_p ' (48'b010001000001001100000000000000000000000000000000); // 0x441300000000
         1: data_o = width_p ' (48'b010001000011001100000000010000000000000000000000); // 0x443300400000
         2: data_o = width_p ' (48'b001101000010000000000000000001100000000000000000); // 0x342000060000
         3: data_o = width_p ' (48'b101000000000000000000000000000000000000000000000); // 0xA00000000000
         4: data_o = width_p ' (48'b000000000000000010010000000000000000000000000000); // 0x000090000000
         5: data_o = width_p ' (48'b001111000000000000000000000000100000000000000000); // 0x3C0000020000
         6: data_o = width_p ' (48'b010001000001001100000000010000000000000000000000); // 0x441300400000
         7: data_o = width_p ' (48'b001010000001000100000000000100010000000000000000); // 0x281100110000
         8: data_o = width_p ' (48'b000001000000000010010000000000000000000000000000); // 0x040090000000
         9: data_o = width_p ' (48'b010001000011001100000000000001000000000000000000); // 0x443300040000
        10: data_o = width_p ' (48'b001010000011000100000000000001110000000000000000); // 0x283100070000
        11: data_o = width_p ' (48'b000001000010000110010000000000000000000000000000); // 0x042190000000
        12: data_o = width_p ' (48'b010001000101001100000000000010000000000000000000); // 0x445300080000
        13: data_o = width_p ' (48'b001010000101000100000000000010100000000000000000); // 0x2851000A0000
        14: data_o = width_p ' (48'b000001000100001010010000000000000000000000000000); // 0x044290000000
        15: data_o = width_p ' (48'b101001000001010110000000000000000000000000000000); // 0xA41580000000
        16: data_o = width_p ' (48'b001111000000000000000000000011010000000000000000); // 0x3C00000D0000
        17: data_o = width_p ' (48'b010001000001001100000000000000000000000000000000); // 0x441300000000
        18: data_o = width_p ' (48'b010001000011001100000000000001000000000000000000); // 0x443300040000
        19: data_o = width_p ' (48'b001101000010000000000000000111000000000000000000); // 0x3420001C0000
        20: data_o = width_p ' (48'b010001000101001100000000000000000000000000000000); // 0x445300000000
        21: data_o = width_p ' (48'b010001000111001100000000010000000000000000000000); // 0x447300400000
        22: data_o = width_p ' (48'b001101000110001000000000000110100000000000000000); // 0x3462001A0000
        23: data_o = width_p ' (48'b111001000010000101000000000000000000000000000000); // 0xE42140000000
        24: data_o = width_p ' (48'b000000000100001010010000000000000000000000000000); // 0x004290000000
        25: data_o = width_p ' (48'b001111000000000000000000000101100000000000000000); // 0x3C0000160000
        26: data_o = width_p ' (48'b000000000000000010010000000000000000000000000000); // 0x000090000000
        27: data_o = width_p ' (48'b001111000000000000000000000100110000000000000000); // 0x3C0000130000
        28: data_o = width_p ' (48'b010001000001001100000000000000000000000000000000); // 0x441300000000
        29: data_o = width_p ' (48'b010001000011001100000000000001000000000000000000); // 0x443300040000
        30: data_o = width_p ' (48'b001101000010000000000000001000100000000000000000); // 0x342000220000
        31: data_o = width_p ' (48'b111001000000001101000000000000000000000000000000); // 0xE40340000000
        32: data_o = width_p ' (48'b000000000000000010010000000000000000000000000000); // 0x000090000000
        33: data_o = width_p ' (48'b001111000000000000000000000111100000000000000000); // 0x3C00001E0000
        34: data_o = width_p ' (48'b001010000001000100000000001001110000000000000000); // 0x281100270000
        35: data_o = width_p ' (48'b111000010000000000000000000000000000000000000000); // 0xE10000000000
        36: data_o = width_p ' (48'b111010100000000000000000000000000000000000000000); // 0xEA0000000000
        37: data_o = width_p ' (48'b000001000000000010010000000000000000000000000000); // 0x040090000000
        38: data_o = width_p ' (48'b001111000000000000000000001000100000000000000000); // 0x3C0000220000
        39: data_o = width_p ' (48'b001111000000000000000000001010000000000000000000); // 0x3C0000280000
        40: data_o = width_p ' (48'b111000100000000000000000000000000000000000000000); // 0xE20000000000
        41: data_o = width_p ' (48'b001010110001001000000000001010110000000000000000); // 0x2B12002B0000
        42: data_o = width_p ' (48'b001111000000000000000000100000100000000000000000); // 0x3C0000820000
        43: data_o = width_p ' (48'b111010000000000000000000000000000000000000000000); // 0xE80000000000
        44: data_o = width_p ' (48'b100000100000000000000000000000000000000000000000); // 0x820000000000
        45: data_o = width_p ' (48'b001010010111001000000000100000100000000000000000); // 0x297200820000
        46: data_o = width_p ' (48'b100001100000000000000000000000000000000000000000); // 0x860000000000
        47: data_o = width_p ' (48'b110000000000000000000000000000000000000000000000); // 0xC00000000000
        48: data_o = width_p ' (48'b001111000000000000000000001100010000000000000000); // 0x3C0000310000
        49: data_o = width_p ' (48'b001010001001001000000000001110000000000000000000); // 0x289200380000
        50: data_o = width_p ' (48'b001010001011001000000000001101100000000000000000); // 0x28B200360000
        51: data_o = width_p ' (48'b001010011011001000000000001101100000000000000000); // 0x29B200360000
        52: data_o = width_p ' (48'b010001100011001100000000000000100000000000000000); // 0x463300020000
        53: data_o = width_p ' (48'b001111000000000000000000001110010000000000000000); // 0x3C0000390000
        54: data_o = width_p ' (48'b010001100011001100000000000000010000000000000000); // 0x463300010000
        55: data_o = width_p ' (48'b001111000000000000000000001110010000000000000000); // 0x3C0000390000
        56: data_o = width_p ' (48'b010001100011001100000000000000110000000000000000); // 0x463300030000
        57: data_o = width_p ' (48'b001010011011001000000000001110110000000000000000); // 0x29B2003B0000
        58: data_o = width_p ' (48'b001111000000000000000000010011000000000000000000); // 0x3C00004C0000
        59: data_o = width_p ' (48'b010001000001001100000000000000000000000000000000); // 0x441300000000
        60: data_o = width_p ' (48'b010001000011001100000000000001000000000000000000); // 0x443300040000
        61: data_o = width_p ' (48'b010001000101001100000000000000000000000000000000); // 0x445300000000
        62: data_o = width_p ' (48'b001101000010000000000000010001100000000000000000); // 0x342000460000
        63: data_o = width_p ' (48'b001010101101000100000000010001000000000000000000); // 0x2AD100440000
        64: data_o = width_p ' (48'b001010101000000000000000010001000000000000000000); // 0x2A8000440000
        65: data_o = width_p ' (48'b000000000100001010010000000000000000000000000000); // 0x004290000000
        66: data_o = width_p ' (48'b111001001100001000100000000000000000000000000000); // 0xE4C220000000
        67: data_o = width_p ' (48'b101010100000110100000000000000000000000000000000); // 0xAA0D00000000
        68: data_o = width_p ' (48'b000000000000000010010000000000000000000000000000); // 0x000090000000
        69: data_o = width_p ' (48'b001111000000000000000000001111100000000000000000); // 0x3C00003E0000
        70: data_o = width_p ' (48'b001010000101000100000000010010110000000000000000); // 0x2851004B0000
        71: data_o = width_p ' (48'b111000010000000000000000000000000000000000000000); // 0xE10000000000
        72: data_o = width_p ' (48'b111010100000000000000000000000000000000000000000); // 0xEA0000000000
        73: data_o = width_p ' (48'b000001000100001010010000000000000000000000000000); // 0x044290000000
        74: data_o = width_p ' (48'b001111000000000000000000010001100000000000000000); // 0x3C0000460000
        75: data_o = width_p ' (48'b001111000000000000000000010011000000000000000000); // 0x3C00004C0000
        76: data_o = width_p ' (48'b001010011001001000000000010011100000000000000000); // 0x2992004E0000
        77: data_o = width_p ' (48'b001111000000000000000000010100110000000000000000); // 0x3C0000530000
        78: data_o = width_p ' (48'b101010100100100000000000000000000000000000000000); // 0xAA4800000000
        79: data_o = width_p ' (48'b111001001011001000000000000000000000000000000000); // 0xE4B200000000
        80: data_o = width_p ' (48'b111000010000000000000000000000000000000000000000); // 0xE10000000000
        81: data_o = width_p ' (48'b111010100000000000000000000000000000000000000000); // 0xEA0000000000
        82: data_o = width_p ' (48'b001111000000000000000000001010000000000000000000); // 0x3C0000280000
        83: data_o = width_p ' (48'b001010010011001000000000010101010000000000000000); // 0x293200550000
        84: data_o = width_p ' (48'b001111000000000000000000010111100000000000000000); // 0x3C00005E0000
        85: data_o = width_p ' (48'b111001000111001010110000000000000000000000000000); // 0xE472B0000000
        86: data_o = width_p ' (48'b111000001000000000000000000000000000000000000000); // 0xE08000000000
        87: data_o = width_p ' (48'b111010101000000000000000000000000000000000000000); // 0xEA8000000000
        88: data_o = width_p ' (48'b101000100000000000010000000000000000000000000000); // 0xA20010000000
        89: data_o = width_p ' (48'b011001010101000000000000000000000000000000000000); // 0x655000000000
        90: data_o = width_p ' (48'b111001110001101101000000000000000000000000000000); // 0xE71B40000000
        91: data_o = width_p ' (48'b011001010100000000000000000000000000000000000000); // 0x654000000000
        92: data_o = width_p ' (48'b111000000100000000000000000000000000000000000000); // 0xE04000000000
        93: data_o = width_p ' (48'b001111000000000000000000011101100000000000000000); // 0x3C0000760000
        94: data_o = width_p ' (48'b001010010001001000000000011000000000000000000000); // 0x291200600000
        95: data_o = width_p ' (48'b001111000000000000000000011100010000000000000000); // 0x3C0000710000
        96: data_o = width_p ' (48'b101001100100101000000000000000000000000000000000); // 0xA64A00000000
        97: data_o = width_p ' (48'b111001001001001000110000000000000000000000000000); // 0xE49230000000
        98: data_o = width_p ' (48'b111001000101011000010000000000000000000000000000); // 0xE45610000000
        99: data_o = width_p ' (48'b111001000111011000010000000000000000000000000000); // 0xE47610000000
       100: data_o = width_p ' (48'b111000001000000000000000000000000000000000000000); // 0xE08000000000
       101: data_o = width_p ' (48'b111010101000000000000000000000000000000000000000); // 0xEA8000000000
       102: data_o = width_p ' (48'b001010001111001000000000011011100000000000000000); // 0x28F2006E0000
       103: data_o = width_p ' (48'b101000100000000000010000000000000000000000000000); // 0xA20010000000
       104: data_o = width_p ' (48'b011001010100000000000000000000000000000000000000); // 0x654000000000
       105: data_o = width_p ' (48'b111001110001101101001000000000000000000000000000); // 0xE71B48000000
       106: data_o = width_p ' (48'b111000000100000000000000000000000000000000000000); // 0xE04000000000
       107: data_o = width_p ' (48'b111010001000000000000000000000000000000000000000); // 0xE88000000000
       108: data_o = width_p ' (48'b101000100000000000000000000000000000000000000000); // 0xA20000000000
       109: data_o = width_p ' (48'b011001011111000000000000000000000000000000000000); // 0x65F000000000
       110: data_o = width_p ' (48'b111000010000000000000000000000000000000000000000); // 0xE10000000000
       111: data_o = width_p ' (48'b111010100000000000000000000000000000000000000000); // 0xEA0000000000
       112: data_o = width_p ' (48'b001111000000000000000000001010000000000000000000); // 0x3C0000280000
       113: data_o = width_p ' (48'b101000100000000000010000000000000000000000000000); // 0xA20010000000
       114: data_o = width_p ' (48'b101001100100101000000000000000000000000000000000); // 0xA64A00000000
       115: data_o = width_p ' (48'b111001100001101101000000000000000000000000000000); // 0xE61B40000000
       116: data_o = width_p ' (48'b111000000010000000000000000000000000000000000000); // 0xE02000000000
       117: data_o = width_p ' (48'b001111000000000000000000011110110000000000000000); // 0x3C00007B0000
       118: data_o = width_p ' (48'b111010001000000000000000000000000000000000000000); // 0xE88000000000
       119: data_o = width_p ' (48'b101000100000000000000000000000000000000000000000); // 0xA20000000000
       120: data_o = width_p ' (48'b001010010101001000000000010111100000000000000000); // 0x2952005E0000
       121: data_o = width_p ' (48'b011001011111000000000000000000000000000000000000); // 0x65F000000000
       122: data_o = width_p ' (48'b001111000000000000000000001010000000000000000000); // 0x3C0000280000
       123: data_o = width_p ' (48'b111010010000000000000000000000000000000000000000); // 0xE90000000000
       124: data_o = width_p ' (48'b101000100000000000000000000000000000000000000000); // 0xA20000000000
       125: data_o = width_p ' (48'b111001010001101101000000000000000000000000000000); // 0xE51B40000000
       126: data_o = width_p ' (48'b111001001001001000110000000000000000000000000000); // 0xE49230000000
       127: data_o = width_p ' (48'b111000010000000000000000000000000000000000000000); // 0xE10000000000
       128: data_o = width_p ' (48'b111010100000000000000000000000000000000000000000); // 0xEA0000000000
       129: data_o = width_p ' (48'b001111000000000000000000001010000000000000000000); // 0x3C0000280000
       130: data_o = width_p ' (48'b110111000000000000000000000000000000000000000000); // 0xDC0000000000
   default: data_o = 'X;
endcase
endmodule
