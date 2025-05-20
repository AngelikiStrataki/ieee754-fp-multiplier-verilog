module normalize_mult(
	input logic [47:0] P,            // 48-bit multiplication result
    	input logic [9:0] exp_sum,       // 10-bit sum of exponents minus bias
    	output logic sticky,             // Sticky bit
    	output logic guard,              // Guard bit
    	output logic [22:0] mantissa,    // 23-bit normalized mantissa
    	output logic [9:0] exponent      // 10-bit normalized exponent
);
	
	// Intermediate signals
    	logic [47:0] normalized_P;
	logic [47:0] sticky_calc;

    	// Normalize the mantissa and calculate the exponent
    	always_comb begin
        	if (P[47]) begin
            		// MSB is 1, shift left by 1
            		normalized_P = P >> 1;
            		mantissa = normalized_P[46:24];
			guard = P[23];
            		exponent = exp_sum + 1;
			sticky_calc = normalized_P[22:0];
       	 	end else begin
            		// MSB is 0, no shift
            		normalized_P = P;
            		mantissa = normalized_P[45:23];
			guard = P[22];
            		exponent = exp_sum;
			sticky_calc = normalized_P[21:0];
        end
        sticky = |sticky_calc;
    end

endmodule