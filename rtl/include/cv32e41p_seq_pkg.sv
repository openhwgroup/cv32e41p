package cv32e41p_sequencer_pkg;


  typedef logic [31:0] insn_32_t;
  typedef logic [3:0] rlist4_t;
  typedef logic [2:0] rlist3_t;
  typedef logic [4:0] spimm_t;
  typedef logic [1:0] ret_val2_t;
  typedef logic [4:0] regnum_t;
  typedef logic [4:0] seq_i;

  localparam REG_ZERO = 5'd0;
  localparam REG_RA = 5'd1;
  localparam REG_SP = 5'd2;

  typedef enum logic [3:0] {
    INVALID_INST,
    C_PUSH,
    C_POP,
    C_POPRET,
    PUSH,
    POP,
    POPRET,
    C_MVA01_S07,
    C_TBLJALM,
    C_TBLJ,
    C_TBLJAL
  } Instruction;

  typedef enum logic [3:0] {
    R_NONE = 4'd0,
    S0     = 4'd1,
    S0_S1  = 4'd2,
    S0_S2  = 4'd3,
    S0_S3  = 4'd4,
    S0_S4  = 4'd5,
    S0_S5  = 4'd6,
    S0_S6  = 4'd7,
    S0_S7  = 4'd8,
    S0_S8  = 4'd9,
    S0_S9  = 4'd10,
    S0_S10 = 4'd11,
    S0_S11 = 4'd12
  } pushpop_rlist_e;

  typedef enum logic [2:0] {
    A_NONE = 3'd0,
    A0     = 3'd1,
    A0_A1  = 3'd2,
    A0_A2  = 3'd3,
    A0_A3  = 3'd4
  } pushpop_alist_e;


  typedef struct packed {
    logic [4:0] complete_seq_len;
    logic [11:0] register_stack_adj;
    pushpop_rlist_e sregisters_saved;
    logic [11:0] additional_stack_adj;
    logic [11:0] total_stack_adj;  //Redundant
    logic [11:0] current_stack_adj;
    logic do_return;
    logic [11:0] return_value;
    regnum_t sreg;
    regnum_t areg;
  } pushpop_decode_s;


  function automatic regnum_t sn_to_regnum(regnum_t snum);
    case (snum)
      0, 1: sn_to_regnum = regnum_t'(snum + 8);
      default: sn_to_regnum = regnum_t'(snum + 16);
    endcase
  endfunction

  function automatic regnum_t an_to_regnum(regnum_t anum);
    an_to_regnum = regnum_t'(anum + 10);
  endfunction

  function automatic logic [11:0] align_16(logic [11:0] number);
    align_16 = 12'((number + 12'hF) & 12'hFF0);
  endfunction

  function automatic pushpop_alist_e rlist_to_alist(pushpop_rlist_e rlist);
    case (rlist)
      R_NONE:  rlist_to_alist = A_NONE;
      S0:      rlist_to_alist = A0;
      S0_S1:   rlist_to_alist = A0_A1;
      S0_S2:   rlist_to_alist = A0_A2;
      default: rlist_to_alist = A0_A3;
    endcase
  endfunction

  function automatic pushpop_rlist_e pushpop_reg_length_c(logic [2:0] rlist3);
    case (rlist3)
      'd0:     pushpop_reg_length_c = R_NONE;
      'd1:     pushpop_reg_length_c = S0;
      'd2:     pushpop_reg_length_c = S0_S1;
      'd3:     pushpop_reg_length_c = S0_S2;
      'd4:     pushpop_reg_length_c = S0_S3;
      'd5:     pushpop_reg_length_c = S0_S5;
      'd6:     pushpop_reg_length_c = S0_S7;
      'd7:     pushpop_reg_length_c = S0_S11;
      default: pushpop_reg_length_c = R_NONE;
    endcase
  endfunction

  function automatic pushpop_rlist_e pushpop_reg_length(logic [3:0] rlist4);
    case (rlist4)
      'd0:     pushpop_reg_length = R_NONE;
      'd1:     pushpop_reg_length = S0;
      'd2:     pushpop_reg_length = S0_S1;
      'd3:     pushpop_reg_length = S0_S2;
      'd4:     pushpop_reg_length = S0_S3;
      'd5:     pushpop_reg_length = S0_S4;
      'd6:     pushpop_reg_length = S0_S5;
      'd7:     pushpop_reg_length = S0_S6;
      'd8:     pushpop_reg_length = S0_S7;
      'd9:     pushpop_reg_length = S0_S8;
      'd10:    pushpop_reg_length = S0_S9;
      'd11:    pushpop_reg_length = S0_S10;
      'd12:    pushpop_reg_length = S0_S11;
      default: pushpop_reg_length = R_NONE;
    endcase
  endfunction

endpackage
