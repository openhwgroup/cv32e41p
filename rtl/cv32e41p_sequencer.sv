

module cv32e41p_sequencer
import cv32e41p_pkg::*; import cv32e41p_sequencer_pkg::*;
 (
    input logic clk, n_rst,
    input logic [31:0] instr_rdata_i,
    input logic if_valid_i,
    output logic [31:0] instruction_o,
    output logic is_sequenced_o,
    output logic seq_finished_o,
    output logic seq_write_reg_zero_o
);

    seq_i instr_cnt_q;
    logic seq_running_q;
    pushpop_decode_s decode;
    Instruction decoded_inst;

    logic [4:0] linked_register;

    always_ff @( posedge clk, negedge n_rst) begin
        if (~n_rst || ~is_sequenced_o) begin
            seq_running_q   <= 1'b0;
            instr_cnt_q     <= 1'b0;
        end
        else if (is_sequenced_o && if_valid_i) begin
            if (!seq_running_q) begin
                seq_running_q <= 1'b1;
            end
            if (instr_cnt_q < decode.complete_seq_len-1'd1) begin
                instr_cnt_q <= instr_cnt_q+1'd1;
            end
            else
            begin
                seq_running_q  <= 1'b0;
                instr_cnt_q    <= 1'b0;
            end
        end
    end

    assign seq_finished_o = instr_cnt_q == decode.complete_seq_len-1'b1;

    always_comb begin : sequenced_instructions_decoder
        decoded_inst = INVALID_INST;
        case(instr_rdata_i[1:0])
        // 16 Bit sequenced instructions
            2'b00: begin
                case (instr_rdata_i[15:13])
                    3'b100: begin
                        case (instr_rdata_i[12:10])
                            3'b011: begin
                                case (instr_rdata_i[6])
                                    1'b1:
                                        decoded_inst = C_PUSH;
                                    1'b0:
                                        decoded_inst = instr_rdata_i[9:8] != 2'b11 ? C_POPRET : C_POP;
                                endcase
                            end
                            3'b010: begin
                                case ({|instr_rdata_i[9:7],|instr_rdata_i[9:5]})
                                    2'b00:
                                        decoded_inst = C_TBLJALM;
                                    2'b01:
                                        decoded_inst = C_TBLJ;
                                    2'b10,2'b11:
                                        decoded_inst = C_TBLJAL;
                                endcase
                            end
                        endcase
                    end
                endcase
            end
            2'b01: begin
                if (instr_rdata_i[15:10] == 6'b100111 && instr_rdata_i[6:5] == 2'b11)
                    decoded_inst = C_MVA01_S07;
            end
            // 32 Bit sequenced instructions
            2'b11: begin
                case (instr_rdata_i[5:2])
                    4'b1010: begin
                        case (instr_rdata_i[14:12])
                            3'b100:
                                decoded_inst = PUSH;
                            3'b101:
                                decoded_inst = POP;
                            3'b110:
                                decoded_inst = POPRET;
                        endcase
                    end
                endcase
            end
        endcase
    end

    always_comb begin : tbljal_linked_register
        case (decoded_inst)
            C_TBLJALM:
                linked_register = 5'd5;
            C_TBLJ:
                linked_register = 5'd0;
            C_TBLJAL:
                linked_register = 5'd1;
            default:
                linked_register = 'X;
        endcase
    end

    assign is_sequenced_o = decoded_inst != INVALID_INST;

    assign decode.sregisters_saved = instr_rdata_i[1:0] != 2'b11 ? pushpop_reg_length_c(instr_rdata_i[4:2]) : pushpop_reg_length(instr_rdata_i[19:16]);
    assign decode.register_stack_adj = align_16(12'((decode.sregisters_saved+1)<<2));


    always_comb begin : additional_stack_adj

        case (decoded_inst)
            C_PUSH,C_POPRET: begin
                decode.additional_stack_adj = {3'd0,instr_rdata_i[9:7],4'd0};
            end
            C_POP: begin
                decode.additional_stack_adj = {5'd0,instr_rdata_i[7],4'd0};
            end
            PUSH,POP,POPRET: begin
                decode.additional_stack_adj = {1'd0,instr_rdata_i[11:7],4'd0};
            end
            default:
                decode.additional_stack_adj = '0;
        endcase

    end

    assign decode.total_stack_adj = decode.register_stack_adj + decode.additional_stack_adj;

    always_comb begin : current_stack_adj
            // factor {{instr_cnt_q+1'b1}<<2}  outside 
         case (decoded_inst)
            PUSH,C_PUSH: begin
                decode.current_stack_adj = -{{instr_cnt_q+12'b1}<<2};
            end
            C_POP,POP,C_POPRET,POPRET: begin
                decode.current_stack_adj = decode.total_stack_adj-12'({instr_cnt_q+5'b1}<<2);
            end
            default:
                decode.current_stack_adj = '0;
        endcase
    end

    always_comb begin : return_value

         case (decoded_inst)
            C_POPRET: begin
                decode.do_return = instr_rdata_i[5];
                decode.return_value = 12'd0;
            end
            POPRET: begin
                case (instr_rdata_i[21:20])
                    2'b00: begin
                        decode.do_return = 1'b0;
                        decode.return_value = 12'd0;
                    end
                    2'b01: begin
                        decode.do_return = 1'b1;
                        decode.return_value = 12'd0;
                    end
                    2'b10: begin
                        decode.do_return = 1'b1;
                        decode.return_value = 12'd1;
                    end
                    2'b11: begin
                        decode.do_return = 1'b1;
                        decode.return_value = 12'(-1);
                    end
                endcase
            end
            default: begin
                decode.do_return = 1'b0;
                decode.return_value = 12'd0;
            end

        endcase

    end

    always_comb begin : areg

        if ((decoded_inst == PUSH && instr_rdata_i[20] ) || decoded_inst == C_PUSH)
            decode.areg = rlist_to_alist(decode.sregisters_saved);
        else
            decode.areg = 0;

    end

    always_comb begin : complete_seq_len

        case (decoded_inst)
            C_PUSH,PUSH:
                decode.complete_seq_len = decode.sregisters_saved+4'd1+4'd1+decode.areg;
            C_POP,POP:
                decode.complete_seq_len = decode.sregisters_saved+4'd2;
            C_POPRET,POPRET:
                decode.complete_seq_len = decode.sregisters_saved+4'd3+decode.do_return;
            C_MVA01_S07:
                decode.complete_seq_len = 5'd2;
            C_TBLJALM,C_TBLJ,C_TBLJAL:
                decode.complete_seq_len = 5'd3;
            default:
                decode.complete_seq_len = 0;
        endcase

    end

    always_comb begin : sreg

        case (decoded_inst)
            PUSH,C_PUSH: begin
                decode.sreg = decode.sregisters_saved-instr_cnt_q-4'd1;
            end
            C_POP,POP: begin
                decode.sreg = decode.complete_seq_len-instr_cnt_q - 4'd3;
            end
            C_POPRET,POPRET: begin
                decode.sreg = decode.complete_seq_len-instr_cnt_q - 4'd4 - decode.do_return;;
            end
            default:
                decode.sreg = '0;
        endcase

    end

    always_comb begin : sequencer_state_machine

        instruction_o = instr_rdata_i;
        seq_write_reg_zero_o = 1'b0;
        case(decoded_inst)
            C_PUSH,PUSH:begin
                // Length of various stages of push instruction
                if (instr_cnt_q < decode.sregisters_saved)
                // Generate normal Stores
                    instruction_o = {decode.current_stack_adj[11:5],sn_to_regnum(decode.sreg),5'd2,3'b010,decode.current_stack_adj[4:0],OPCODE_STORE};
                // Store RA
                else if (instr_cnt_q == decode.sregisters_saved)
                    instruction_o = {decode.current_stack_adj[11:5],5'd1,5'd2,3'b010,decode.current_stack_adj[4:0],OPCODE_STORE};
                // Embedded Moves TODO check if we have a switch for this one !
                else if (instr_cnt_q > decode.sregisters_saved && instr_cnt_q < decode.complete_seq_len-4'b1)
                    instruction_o = {12'd0,an_to_regnum(5'(instr_cnt_q-decode.sregisters_saved-5'b1)),3'b0,sn_to_regnum(5'(instr_cnt_q-decode.sregisters_saved-5'b1)),OPCODE_OPIMM};
                // Adjust stack back
                else
                    instruction_o = {-decode.total_stack_adj,5'd2,3'b0,5'd2,OPCODE_OPIMM};
            end
            //C_POPRET,POPRET
            C_POPRET,POPRET:begin
                // LW back stored values
                if (instr_cnt_q < decode.sregisters_saved) begin
                    instruction_o = {decode.current_stack_adj,REG_SP,3'b010,sn_to_regnum(decode.sreg),OPCODE_LOAD};
                end
                else if (instr_cnt_q == decode.sregisters_saved) begin
                    // LW back RA value
                    instruction_o = {decode.current_stack_adj,REG_SP,3'b010,REG_RA,OPCODE_LOAD};
                end
                else if (instr_cnt_q > decode.sregisters_saved)
                    // Load immediate value
                    if (decode.do_return && instr_cnt_q ==  decode.sregisters_saved+4'd1)
                        instruction_o = {decode.return_value,5'd0,3'b0,5'd10,OPCODE_OPIMM};
                    // Adjust the stack back (addi)
                    else if (instr_cnt_q ==  decode.sregisters_saved+4'd1+4'(decode.do_return))
                        instruction_o = {decode.total_stack_adj,REG_SP,3'b0,REG_SP,OPCODE_OPIMM};
                    // Generate return instruction
                    else if (instr_cnt_q ==  decode.sregisters_saved+4'd2+4'(decode.do_return))
                        instruction_o = {12'b0,REG_RA,3'b0,5'b0,OPCODE_JALR};
            end
            //C_POP,POP
            C_POP,POP:begin
                // LW back stored values
                if (instr_cnt_q < decode.sregisters_saved) begin
                    instruction_o = {decode.current_stack_adj,REG_SP,3'b010,sn_to_regnum(decode.sreg),OPCODE_LOAD};
                end
                // LW back RA value
                else if (instr_cnt_q == decode.sregisters_saved) begin
                    instruction_o = {decode.current_stack_adj,REG_SP,3'b010,REG_RA,OPCODE_LOAD};
                end
                // Adjust stack back
                else if (instr_cnt_q ==  decode.sregisters_saved+4'd1)
                    instruction_o = {decode.total_stack_adj,REG_SP,3'b0,REG_SP,OPCODE_OPIMM};

            end
            // Double moves ! 
            C_MVA01_S07:begin
                if (instr_cnt_q == '0)
                    instruction_o = {7'b0, sn_to_regnum(5'(instr_rdata_i[9:7])), 5'b0, 3'b0,5'd10 , OPCODE_OP};
                else
                    instruction_o = {7'b0, sn_to_regnum(5'(instr_rdata_i[4:2])), 5'b0, 3'b0,5'd11 , OPCODE_OP};
            end
            C_TBLJALM,C_TBLJ,C_TBLJAL:begin
                seq_write_reg_zero_o = 1'b1;
                case (instr_cnt_q)
                    // csrr    zero,0x800
                    seq_i'(0): begin
                        instruction_o = 32'h80002073;
                    end
                    // lw
                    seq_i'(1): begin
                        instruction_o = {12'(instr_rdata_i[9:2]<<2),REG_ZERO,3'b010,REG_ZERO,OPCODE_LOAD};
                    end
                    // jalr ra,x0
                    seq_i'(2):
                        instruction_o = {12'b0, 5'd0, 3'b0, linked_register, OPCODE_JALR};
                endcase
            end

        endcase


    end


    `ifdef CV32E41P_ASSERT_ON
        p_seq_finished: assert property (@(posedge clk) disable iff (!n_rst) ~seq_running_q && $past(seq_running_q) |-> $past(instr_cnt_q) == $past(decode.complete_seq_len)-1'd1);
    `endif

endmodule
