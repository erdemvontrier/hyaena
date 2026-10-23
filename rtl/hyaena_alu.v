module hyaena_alu(
    input wire [3:0] operator,
    input wire [31:0] a,
    input wire [31:0] b,
    output reg [31:0] result,
    output reg zero,
    output reg overflow,
    output reg carry,
    output reg negative,
    output reg parity

); 

    reg [32:0] tmp;
    reg b_sign;
    wire [32:0] a_33 = {1'b0, a};
    wire [32:0] b_33 = {1'b0, b};
    wire [5:0] shift_ctr = b[4:0];
    wire [63:0] a_merged = {a,a};
    wire [63:0] mul_result = a * b;
    always @(*) begin
        tmp = 33'b0;

        case(operator)
            4'h1: tmp = a_33 + b_33; // add
            4'h2: tmp = a_33 - b_33; // sub
            4'h3: tmp = a_33 & b_33; // and
            4'h4: tmp = a_33 | b_33; // or
            4'h5: tmp = a_33 ^ b_33; // xor
            4'h6: tmp = {1'b0, ~a}; // not
            4'h7: tmp = a_33 << shift_ctr; // shl
            4'h8: tmp = a_33 >> shift_ctr;// shr
            4'h9: tmp = {1'b0, $signed(a)>>> shift_ctr}; // asr
            4'hA: tmp = {1'b0, (a_merged >> shift_ctr) & 32'hFFFFFFFF}; // ror
            4'hB: tmp = {1'b0, mul_result[31:0]}; // mul
            4'hC: tmp = {1'b0, mul_result[63:32]}; // mulh
            default: tmp = 33h'0;
        endcase

        result = tmp[31:0];
        zero = result == 32'b0; //zero
        carry = tmp[32]; // carry
        negative = result[31]; // negative
        parity = tmp[0]; //parity
        b_sign = (operator == 4h'2) ? ~b[31] : b[31];
        // if op = sub , reverse b
        overflow = (a[31] && b_sign && ~result[31]) || (~a[31] && ~b_sign && result[31]); //overflow
        // overlofw ( positive + positive = negative) or (negative + negative = positive)


    end
endmodule