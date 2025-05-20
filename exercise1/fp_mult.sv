`include "normalize_mult.sv"
`include "round_mult.sv"
`include "exception_mult.sv"


module fp_mult (
    input logic [31:0] a,         // First operand
    input logic [31:0] b,         // Second operand
    input logic [2:0] rnd,        // Rounding mode
    output logic [31:0] z,        // Multiplication result
    output logic [7:0] status     // Status flags
);

    // Intermediate signals
    	logic sign;
    	logic [9:0] exponent;
    	logic [47:0] mantissa;
    	logic [31:0] F;
    	logic [31:0] MinNorm = 32'h00800000; // Minimum normal number for single precision
    	logic [31:0] MaxNorm = 32'h7F7FFFFF; // Maximum normal number for single precision

	logic [22:0] normalized_mantissa;
    	logic [9:0] normalized_exponent;
    	logic guard, sticky;
    	logic [24:0] rounded_mantissa;
    	logic inexact;
	logic overflow, underflow;
    	logic [22:0] final_mantissa;
    	logic [7:0] final_exponent;
    	logic [31:0] z_calc;
	logic [47:0] P;
	logic [9:0] exp_sum;

	logic [31:0] temp_z;

	 // Normalize and Rounding modules
    	normalize_mult normalization (
        	.P(P),
        	.exp_sum(exp_sum),
        	.sticky(sticky),
        	.guard(guard),
        	.mantissa(normalized_mantissa),
        	.exponent(normalized_exponent)
    	);

    	round_mult round (
        	.mantissa_in({1'b1, normalized_mantissa}),
        	.guard(guard),
        	.sticky(sticky),
        	.sign(sign),
        	.round(rnd),
        	.mantissa_out(rounded_mantissa),
        	.inexact(inexact)
    	);
	
	always_comb begin
    		// Calculate sign
    		sign = a[31] ^ b[31];

    		// Add exponents
    		exponent = a[30:23] + b[30:23] - 8'd127;

    		// Multiply mantissas
    		mantissa = {1'b1, a[22:0]} * {1'b1, b[22:0]};
	

    	// Calculate F and apply rounding
        	if (mantissa[47]) begin
           		F = {sign, exponent + 1, mantissa[46:24]};
        	end else begin
            		F = {sign, exponent, mantissa[45:23]};
        	end
    	

        	if (rounded_mantissa[24]) begin
            		final_exponent = normalized_exponent + 1;
            		final_mantissa = rounded_mantissa[23:1]; //???????
        	end else begin
            		final_exponent = normalized_exponent[7:0];
            		final_mantissa = rounded_mantissa[22:0]; //????????
        	end

    	// Create z_calc
    	 z_calc = {sign, final_exponent, final_mantissa};

    	// Overflow and Underflow detection
    	overflow = (final_exponent > 8'hFE);
    	underflow = (final_exponent < 8'h01);
	end

    	// Exception handling module
    	exception_mult exception (
        	.a(a),
        	.b(b),
        	.z_calc(z_calc),
        	.overflow(overflow),
        	.underflow(underflow),
        	.inexact(inexact),
        	.round(rnd),
        	.z(z),
        	.zero_f(status[0]),
        	.inf_f(status[1]),
        	.nan_f(status[2]),
        	.tiny_f(status[3]),
        	.huge_f(status[4]),
        	.inexact_f(status[5])
    	);


endmodule

