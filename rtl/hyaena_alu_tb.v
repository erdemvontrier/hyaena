module hyaena_alu_tb ();
    reg [31:0] a;
    reg [31:0] b;
    reg [3:0] operator;
    wire [31:0] result;
    // flags
    wire zero;
    wire overflow;
    wire carry;
    wire negative;
    wire parity;

    // tb
    integer error_ctr;

    // flag masks ZCNVP
    localparam FLAGS_ALL         = 5'b11111;
    localparam FLAGS_CANON_LOGIC = 5'b10101;
    localparam FLAGS_RES_ONLY    = 5'b00000;

    hyaena_alu hyaena_alu_inst (
        .a(a),
        .b(b),
        .operator(operator),
        .result(result),
        .zero(zero),
        .overflow(overflow),
        .carry(carry),
        .negative(negative),
        .parity(parity)
    );

    task tb_init;
        begin
            error_ctr = 0;
            a <= 0;
            b <= 0;
            operator <= 0;
            #1;
        end
    endtask

    task tb_show_registers;
        begin
            $display("a: %h, b: %h, result: %h", a, b, result);
            $display("flags -> zero: %b, carry: %b, negative: %b, overflow: %b, parity: %b\n",
                     zero, carry, negative, overflow, parity);
        end
    endtask

    task tb_check;
        input [31:0] exp_res;
        input exp_z;
        input exp_c;
        input exp_n;
        input exp_v;
        input exp_p;
        input [4:0] flag_mask; // [4:0] ZCNVP
        input [200*8:1] desc;
        reg flag_err;
        begin
            #1;
            flag_err = 0;
            if (result !== exp_res) begin
                $display("ERROR [T=%0t] %0s: Result mismatch! Expected: %h, Got: %h", $time, desc, exp_res, result);
                tb_show_registers;
                error_ctr = error_ctr + 1;
            end else begin
                if (flag_mask[4] && (zero !== exp_z)) flag_err = 1;
                if (flag_mask[3] && (carry !== exp_c)) flag_err = 1;
                if (flag_mask[2] && (negative !== exp_n)) flag_err = 1;
                if (flag_mask[1] && (overflow !== exp_v)) flag_err = 1;
                if (flag_mask[0] && (parity !== exp_p)) flag_err = 1;

                if (flag_err) begin
                    $display("ERROR [T=%0t] %0s: Flag mismatch! Mask=%b", $time, desc, flag_mask);
                    $display("  Expected -> Z:%b C:%b N:%b V:%b P:%b", exp_z, exp_c, exp_n, exp_v, exp_p);
                    $display("  Got   -> Z:%b C:%b N:%b V:%b P:%b", zero, carry, negative, overflow, parity);
                    tb_show_registers;
                    error_ctr = error_ctr + 1;
                end
            end
        end
    endtask

    task tb_test_add;
        begin
            operator <= 4'h1;

            a <= 2; b <= 5;
            tb_check(32'd7, 0, 0, 0, 0, 1, FLAGS_ALL, "ADD: 2 + 5 = 7");

            a <= 0; b <= 0;
            tb_check(32'd0, 1, 0, 0, 0, 0, FLAGS_ALL, "ADD: 0 + 0 = 0 (Zero)");

            a <= 32'hFFFFFFFF; b <= 32'd1;
            tb_check(32'd0, 1, 1, 0, 0, 0, FLAGS_ALL, "ADD: 0xFFFFFFFF + 1 (Carry & Zero)");

            a <= 32'h7FFFFFFF; b <= 32'd1;
            tb_check(32'h80000000, 0, 0, 1, 1, 0, FLAGS_ALL, "ADD: 0x7FFFFFFF + 1 (Pos Overflow)");

            a <= 32'h80000000; b <= 32'h80000000;
            tb_check(32'd0, 1, 1, 0, 1, 0, FLAGS_ALL, "ADD: 0x80000000 + 0x80000000 (Neg Overflow)");
        end
    endtask

    task tb_test_sub;
        begin
            operator <= 4'h2;

            a <= 10; b <= 4;
            tb_check(32'd6, 0, 0, 0, 0, 0, FLAGS_ALL, "SUB: 10 - 4 = 6");

            a <= 5; b <= 5;
            tb_check(32'd0, 1, 0, 0, 0, 0, FLAGS_ALL, "SUB: 5 - 5 = 0 (Zero)");

            a <= 2; b <= 5;
            tb_check(32'hFFFFFFFD, 0, 1, 1, 0, 1, FLAGS_ALL, "SUB: 2 - 5 = -3 (Carry)");

            a <= 32'h7FFFFFFF; b <= 32'hFFFFFFFF;
            tb_check(32'h80000000, 0, 1, 1, 1, 0, FLAGS_ALL, "SUB: +MAX - (-1) (Pos Overflow)");

            a <= 32'h80000000; b <= 32'd1;
            tb_check(32'h7FFFFFFF, 0, 0, 0, 1, 1, FLAGS_ALL, "SUB: -MAX - 1 (Neg Overflow)");
        end
    endtask

    task tb_test_and;
        begin
            operator <= 4'h3;

            a <= 32'hF0F0F0F0; b <= 32'h0F0F00FF;
            tb_check(32'h000000F0, 0, 0, 0, 0, 0, FLAGS_CANON_LOGIC, "AND");

            a <= 32'hAAAA5555; b <= 32'h5555AAAA;
            tb_check(32'd0, 1, 0, 0, 0, 0, FLAGS_CANON_LOGIC, "AND (Zero)");

            a <= 32'h80000000; b <= 32'hFFFFFFFF;
            tb_check(32'h80000000, 0, 0, 1, 0, 0, FLAGS_CANON_LOGIC, "AND (Negative)");
        end
    endtask

    task tb_test_or;
        begin
            operator <= 4'h4;

            a <= 32'h12340000; b <= 32'h00005678;
            tb_check(32'h12345678, 0, 0, 0, 0, 0, FLAGS_CANON_LOGIC, "OR");

            a <= 32'h80000000; b <= 32'h00000001;
            tb_check(32'h80000001, 0, 0, 1, 0, 1, FLAGS_CANON_LOGIC, "OR (Negative)");

            a <= 32'd0; b <= 32'd0;
            tb_check(32'd0, 1, 0, 0, 0, 0, FLAGS_CANON_LOGIC, "OR (Zero)");
        end
    endtask

    task tb_test_xor;
        begin
            operator <= 4'h5;

            a <= 32'h0000FFFF; b <= 32'h55555555;
            tb_check(32'h5555AAAA, 0, 0, 0, 0, 0, FLAGS_CANON_LOGIC, "XOR");

            a <= 32'h12345678; b <= 32'h12345678;
            tb_check(32'd0, 1, 0, 0, 0, 0, FLAGS_CANON_LOGIC, "XOR (Zero)");
        end
    endtask

    task tb_test_not;
        begin
            operator <= 4'h6;

            a <= 32'hFFFFFFFF; b <= 32'd0;
            tb_check(32'd0, 1, 0, 0, 0, 0, FLAGS_CANON_LOGIC, "NOT: ~0xFFFFFFFF = 0 (Zero)");

            a <= 32'h00000000; b <= 32'd0;
            tb_check(32'hFFFFFFFF, 0, 0, 1, 0, 1, FLAGS_CANON_LOGIC, "NOT: ~0 = 0xFFFFFFFF (Negative)");
        end
    endtask

    task tb_test_shl;
        begin
            operator <= 4'h7;

            a <= 32'd1; b <= 32'd4;
            tb_check(32'h00000010, 0, 0, 0, 0, 0, FLAGS_CANON_LOGIC, "SHL: 1 << 4 = 16");

            a <= 32'd1; b <= 32'd31;
            tb_check(32'h80000000, 0, 0, 1, 0, 0, FLAGS_CANON_LOGIC, "SHL: 1 << 31 = 0x80000000 (Negative)");

            a <= 32'h10000000; b <= 32'd4;
            tb_check(32'd0, 1, 0, 0, 0, 0, FLAGS_CANON_LOGIC, "SHL: 0x10000000 << 4 = 0 (Zero)");
        end
    endtask

    task tb_test_shr;
        begin
            operator <= 4'h8;

            a <= 32'h80000000; b <= 32'd1;
            tb_check(32'h40000000, 0, 0, 0, 0, 0, FLAGS_CANON_LOGIC, "SHR: 0x80000000 >> 1 = 0x40000000 (MSB 0)");

            a <= 32'h12345678; b <= 32'd4;
            tb_check(32'h01234567, 0, 0, 0, 0, 1, FLAGS_CANON_LOGIC, "SHR: 0x12345678 >> 4");

            a <= 32'd1; b <= 32'd1;
            tb_check(32'd0, 1, 0, 0, 0, 0, FLAGS_CANON_LOGIC, "SHR: 1 >> 1 = 0 (Zero)");
        end
    endtask

    task tb_test_asr;
        begin
            operator <= 4'h9;

            a <= 32'h80000000; b <= 32'd1;
            tb_check(32'hC0000000, 0, 0, 1, 0, 0, FLAGS_CANON_LOGIC, "ASR: 0x80000000 >>> 1 = 0xC0000000 (Sign Preserved)");

            a <= 32'h40000000; b <= 32'd1;
            tb_check(32'h20000000, 0, 0, 0, 0, 0, FLAGS_CANON_LOGIC, "ASR: 0x40000000 >>> 1 = 0x20000000");

            a <= 32'hFFFFFFFF; b <= 32'd8;
            tb_check(32'hFFFFFFFF, 0, 0, 1, 0, 1, FLAGS_CANON_LOGIC, "ASR: 0xFFFFFFFF >>> 8 = 0xFFFFFFFF");
        end
    endtask

    task tb_test_ror;
        begin
            operator <= 4'hA;

            a <= 32'h12345678; b <= 32'd4;
            tb_check(32'h81234567, 0, 0, 1, 0, 1, FLAGS_CANON_LOGIC, "ROR: 0x12345678 ror 4 = 0x81234567");

            a <= 32'h80000001; b <= 32'd1;
            tb_check(32'hC0000000, 0, 0, 1, 0, 0, FLAGS_CANON_LOGIC, "ROR: 0x80000001 ror 1 = 0xC0000000");

            a <= 32'd0; b <= 32'd5;
            tb_check(32'd0, 1, 0, 0, 0, 0, FLAGS_CANON_LOGIC, "ROR: 0 ror 5 = 0 (Zero)");
        end
    endtask

    task tb_test_mul;
        begin
            operator <= 4'hB;

            a <= 32'd6; b <= 32'd7;
            tb_check(32'd42, 0, 0, 0, 0, 0, FLAGS_CANON_LOGIC, "MUL: 6 * 7 = 42");

            a <= 32'd0; b <= 32'd12345;
            tb_check(32'd0, 1, 0, 0, 0, 0, FLAGS_CANON_LOGIC, "MUL: 0 * 12345 = 0 (Zero)");

            a <= 32'h10000; b <= 32'h10000;
            tb_check(32'd0, 1, 0, 0, 0, 0, FLAGS_CANON_LOGIC, "MUL: 0x10000 * 0x10000 = low 0 (Zero)");
        end
    endtask

    task tb_test_mulh;
        begin
            operator <= 4'hC;

            a <= 32'h10000; b <= 32'h10000;
            tb_check(32'd1, 0, 0, 0, 0, 1, FLAGS_CANON_LOGIC, "MULH: 0x10000 * 0x10000 = high 1");

            a <= 32'h80000000; b <= 32'd2;
            tb_check(32'd1, 0, 0, 0, 0, 1, FLAGS_CANON_LOGIC, "MULH: 0x80000000 * 2 = high 1");

            a <= 32'd5; b <= 32'd10;
            tb_check(32'd0, 1, 0, 0, 0, 0, FLAGS_CANON_LOGIC, "MULH: 5 * 10 = high 0 (Zero)");
        end
    endtask

    initial begin
        `ifdef DUMP
            $dumpfile("output.vcd");
            $dumpvars(0, hyaena_alu_tb);
        `endif
        tb_init;
        tb_test_add;
        tb_test_sub;
        tb_test_and;
        tb_test_or;
        tb_test_xor;
        tb_test_not;
        tb_test_shl;
        tb_test_shr;
        tb_test_asr;
        tb_test_ror;
        tb_test_mul;
        tb_test_mulh;

        $display("## Hyaena ALU\n");
        $display("Total error count: %0d\n", error_ctr);

        if(error_ctr == 0) begin
            $display("Finished succesfully\n");
        end else begin
            $display("Failed with %0d errors\n", error_ctr);
        end

        $finish;
    end
endmodule