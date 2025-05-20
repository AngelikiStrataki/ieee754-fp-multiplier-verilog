`timescale 1ns/1ps
`include "fp_mult_top.sv"

module test_status_bits(
    input logic clk,
    input logic rst,
    input logic zero_f,
    input logic inf_f,
    input logic nan_f,
    input logic huge_f,
    input logic tiny_f
);

    always_comb begin
        a1: assert (!(zero_f && inf_f)) else $fatal("Error: Zero and Inf asserted together");
        a2: assert (!(zero_f && nan_f)) else $fatal("Error: Zero and NaN asserted together");
        a3: assert (!(zero_f && huge_f)) else $fatal("Error: Zero and Huge asserted together");
        a4: assert (!(inf_f && nan_f)) else $fatal("Error: Inf and NaN asserted together");
        a5: assert (!(inf_f && huge_f)) else $fatal("Error: Inf and Huge asserted together");
        a6: assert (!(nan_f && huge_f)) else $fatal("Error: NaN and Huge asserted together");
        a7: assert (!(nan_f && tiny_f)) else $fatal("Error: NaN and Tiny asserted together");
        a8: assert (!(huge_f && tiny_f)) else $fatal("Error: Huge and Tiny asserted together");
    end

endmodule

module test_status_z_combinations(
    input logic clk,
    input logic rst,
    input logic zero_f,
    input logic inf_f,
    input logic nan_f,
    input logic huge_f,
    input logic tiny_f,
    input logic [31:0] a,
    input logic [31:0] b,
    input logic [31:0] z
);

    logic [7:0] exp_z, exp_a, exp_b;
    logic [22:0] mantissa_z;
    assign exp_z = z[30:23];
    assign exp_a = a[30:23];
    assign exp_b = b[30:23];
    assign mantissa_z = z[22:0];

    // If zero status bit asserts to 1, then all exponent bits of z must be 0.
    property zero_exp_zero;
        @(posedge clk) disable iff (rst) zero_f |-> (exp_z == 8'b00000000);
    endproperty
    assert property (zero_exp_zero)
        else $fatal("Error: Zero status bit is 1, but exponent of z is not all zeros.");

    // If inf status bit asserts to 1, then all exponent bits of z must be 1.
    property inf_exp_one;
        @(posedge clk) disable iff (rst) inf_f |-> (exp_z == 8'b11111111);
    endproperty
    assert property (inf_exp_one)
        else $fatal("Error: Inf status bit is 1, but exponent of z is not all ones.");

    // If nan status bit asserts to 1, then 2 cycles before, the exponent of a must be 0 and the exponent of b must be 1 or the opposite.
    property nan_exp_ab;
        @(posedge clk) disable iff (rst) nan_f |-> ##2 ((exp_a == 8'b00000000 && exp_b == 8'b11111111) || (exp_a == 8'b11111111 && exp_b == 8'b00000000));
    endproperty
    assert property (nan_exp_ab)
        else $fatal("Error: Nan status bit is 1, but 2 cycles before exponents of a and b do not match the required condition.");

    // If huge status bit asserts to 1, then all exponent bits of z must be 1, or all bits except the LSB must be 1, the LSB must be 0 and all mantissa bits of z must be 1.
    property huge_exp_max;
        @(posedge clk) disable iff (rst) huge_f |-> (exp_z == 8'b11111111 || (exp_z == 8'b11111110 && mantissa_z == 23'b11111111111111111111111));
    endproperty
    assert property (huge_exp_max)
        else $fatal("Error: Huge status bit is 1, but exponent of z does not match the required condition.");

    // If tiny status bit asserts to 1, then all exponent bits of z must be 0, ? ??? ?? bits ????? ??? ?? LSB ?????? ?? ????? 0, ?? LSB ?????? ?? ????? 1 ??? ??? ?? mantissa bits ??? z ?????? ?? ????? 0.
    property tiny_exp_min;
        @(posedge clk) disable iff (rst) tiny_f |-> (exp_z == 8'b00000000 || (exp_z == 8'b00000001 && mantissa_z == 23'b00000000000000000000000));
    endproperty
    assert property (tiny_exp_min)
        else $fatal("Error: Tiny status bit is 1, but exponent of z does not match the required condition.");

endmodule


module test_dut;

    // Define ports and wires as needed
    bit sys_clk;
    bit sys_req;
    bit zero_f, inf_f, nan_f, huge_f, tiny_f, a, b, z;


    // Instantiate the modules
    test_status_bits tsb_1 (
        .clk(sys_clk),
        .rst(1'b0), // Example: Provide appropriate connections
	.zero_f(zero_f),
    	.inf_f(inf_f),
    	.nan_f(nan_f),
    	.huge_f(huge_f),
    	.tiny_f(tiny_f)
    );

    test_status_z_combinations test_status_z_combinations (
        .clk(sys_clk),
        .rst(1'b0),
  	.zero_f(zero_f),
    	.inf_f(inf_f),
    	.nan_f(nan_f),
    	.huge_f(huge_f),
    	.tiny_f(tiny_f),
    	.a(a),
   	.b(b),
    	.z(z)
    );

    // Bind statement to associate the two modules
    bind test_status_bits tsc_2 (
        .clk(sys_clk),
        .req(sys_req),
  	.zero_f(zero_f),
    	.inf_f(inf_f),
    	.nan_f(nan_f),
    	.huge_f(huge_f),
    	.tiny_f(tiny_f),
    	.a(a),
   	.b(b),
    	.z(z)
    );

    initial begin
        // Your initial block code
        // Example display statement:
        $display($time, " clk=%b req=%b gnt=%b", sys_clk, sys_req, sys_gnt);
        
        // Example clock toggle every 10 time units
        forever #10 sys_clk = ~sys_clk;
    end

endmodule

