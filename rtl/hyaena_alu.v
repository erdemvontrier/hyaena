module hyaena_alu(
    input wire [3 : 0] operator,
    input wire [31 : 0] a,
    input wire [31 : 0] b,
    output reg [31 : 0] result,
    output reg zero,
    output reg overflow,
    output reg carry,
    output reg negative,
    output reg parity   
); 

    reg [32 : 0] tmp;

endmodule