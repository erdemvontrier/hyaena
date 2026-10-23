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
            $display("a: ", a, " b: ", b, " result: ", result);
            $display("flags; zero: ", zero, " overflow: ", overflow, " carry: ", carry);
            $display("       negative: ", negative, " parity: ", parity, "\n");
        end
    endtask

    task tb_test_add;
        begin
            a <= 2;
            b <= 5;
            operator <= 1;
            #1;
            if(result !== 7) begin
                $display("ERROR [T=%0t]: + operator fails", $time);
                tb_show_registers;
                error_ctr = error_ctr + 1;
            end
        end
    endtask

    initial begin
        `ifdef DUMP
            $dumpfile("output.vcd");
            $dumpvars(0, hyaena_alu_tb);
        `endif
        tb_init;
        tb_test_add;
        $display("Error count: ", error_ctr);
        $finish;
    end
endmodule