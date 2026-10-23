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

    localparam OP_ADD  = 4'h1;
    localparam OP_SUB  = 4'h2;
    localparam OP_AND  = 4'h3;
    localparam OP_OR   = 4'h4;
    localparam OP_XOR  = 4'h5;
    localparam OP_NOT  = 4'h6;
    localparam OP_SHL  = 4'h7;
    localparam OP_SHR  = 4'h8;
    localparam OP_ASR  = 4'h9;
    localparam OP_ROR  = 4'hA;
    localparam OP_MUL  = 4'hB;
    localparam OP_MULH = 4'hC;

    always @(*) begin
        tmp = 33'b0;

        case(operator)
            OP_ADD: tmp = a_33 + b_33; // add
            OP_SUB: tmp = a_33 - b_33; // sub
            OP_AND: tmp = a_33 & b_33; // and
            OP_OR: tmp = a_33 | b_33; // or
            OP_XOR: tmp = a_33 ^ b_33; // xor
            OP_NOT: tmp = {1'b0, ~a}; // not
            OP_SHL: tmp = a_33 << shift_ctr; // shl
            OP_SHR: tmp = a_33 >> shift_ctr;// shr
            OP_ASR: tmp = {1'b0, $signed(a)>>> shift_ctr}; // asr
            OP_ROR: tmp = {1'b0, (a_merged >> shift_ctr) & 32'hFFFFFFFF}; // ror
            OP_MUL: tmp = {1'b0, mul_result[31:0]}; // mul
            OP_MULH: tmp = {1'b0, mul_result[63:32]}; // mulh
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