module exception_mult (
	input logic [31:0] a,              // First 32-bit input value
    	input logic [31:0] b,              // Second 32-bit input value
    	input logic [31:0] z_calc,         // Calculated 32-bit output value after rounding
    	input logic overflow,              // Overflow flag
    	input logic underflow,             // Underflow flag
    	input logic inexact,               // Inexact result flag
    	input logic [2:0] round,                 // Round input
    	output logic [31:0] z,             // Final result after exception handling
    	output logic zero_f,               // Zero flag
    	output logic inf_f,                // Infinity flag
    	output logic nan_f,                // NaN flag
    	output logic tiny_f,               // Tiny flag (underflow)
    	output logic huge_f,               // Huge flag (overflow)
    	output logic inexact_f             // Inexact flag
);

	
	typedef enum logic [2:0]{
		ZERO = 3'b000,
        	INF = 3'b001,
        	NORM = 3'b010,
        	MIN_NORM = 3'b011,
        	MAX_NORM = 3'b100
	} interp_t;

	typedef enum logic [2:0] {
        	IEEE_near = 3'b000, // Round to nearest even
        	IEEE_zero = 3'b001, // Round toward zero
        	IEEE_pinf = 3'b010, // Round up (toward +inf)
        	IEEE_ninf = 3'b011, // Round down (toward -inf)
       		near_up = 3'b100,  // Round to nearest (ties away from zero)
		away_zero = 3'b101 // Round away from zero
    	} rounding_mode_t;
	
	rounding_mode_t mode;

	function interp_t num_interp (logic [31:0] value);
		logic [7:0] exponent;
		exponent = value[30:23];
		if (exponent == 8'h00) // Zero or denormal
            		return ZERO;
        	else if (exponent == 8'hFF) // Inf or NaN
            		return INF;
        	else // Normal number
            		return NORM;
    	endfunction

	function logic [30:0] z_num(input interp_t interp);
		case (interp)
			ZERO: return 31'b0;                     // Zero value
            		INF: return 31'h7F800000 >> 1;          // Infinity representation (shift right to get 31 bits)
            		default: return 31'b0;                  // Default to zero for undefined cases (NORM is not handled here)
        	endcase
	endfunction

	interp_t a_interp, b_interp;
    	logic sign_a, sign_b;

	logic [7:0] exp_z;
   	assign exp_z = z_calc[30:23];
	


	always_comb begin
		// Default values
        	zero_f = 0;
        	inf_f = 0;
        	nan_f = 0;
        	tiny_f = 0;
        	huge_f = 0;
        	inexact_f = 0;
        	//exception = 0;
		//status = 0;

		// Get the signs of the inputs
        	sign_a = a[31];
        	sign_b = b[31];

		mode = rounding_mode_t'(round);
        	
		// Default values
        	z = z_calc;

		// Interpret the floating point numbers
        	a_interp = num_interp(a);
        	b_interp = num_interp(b);

		 case ({a_interp, b_interp})
            		{ZERO, ZERO}: begin
                		z = {sign_a ^ sign_b, z_num(ZERO)}; // Zero result with combined sign
                		zero_f = 1;
            		end
            		{ZERO, NORM}, {NORM, ZERO}: begin
                		z = {sign_a ^ sign_b, z_num(ZERO)}; // Zero result with combined sign
                		zero_f = 1;
            		end
            		{ZERO, INF}: begin
                		z = {sign_b, z_num(INF)}; // Infinity result with sign of B
                		inf_f = 1;
            		end
            		{INF, ZERO}: begin
                		z = {sign_a, z_num(INF)}; // Infinity result with sign of A
                		inf_f = 1;
            		end
            		{INF, INF}: begin
                		z = {sign_a ^ sign_b, z_num(INF)}; // Infinity result with combined sign
                		inf_f = 1;
            		end
            		{INF, NORM}: begin
                		z = {sign_a ^ sign_b, z_num(INF)}; // Infinity result with combined sign
                		inf_f = 1;
            		end
            		{NORM, INF}: begin
                		z = {sign_a ^ sign_b, z_num(INF)}; // Infinity result with combined sign
                		inf_f = 1;
            		end
			{NORM, NORM}: begin       
            			if (overflow) begin
            				huge_f= 1'b1;
        				if ((mode == away_zero) || (mode == IEEE_near)) begin
            					z={z_calc[31], z_num(INF)}; // round to Infinity in any case
            					inf_f= 1'b1;
        				end else if ((mode == IEEE_zero)) begin
            					z={z_calc[31], z_num(MAX_NORM)}; // round to maxNormal
            					end else if (((mode == IEEE_pinf) && !z_calc[31]) || (mode == IEEE_ninf && z_calc[31])) begin
            					z={z_calc[31], z_num(INF)}; // round to Infinity
            					inf_f= 1'b1;
        				end else if (mode == near_up) begin 
            					z={z_calc[31], z_num(INF)}; // round to maxNormal
        				end else begin
            					z={z_calc[31], z_num(MAX_NORM)}; // round to maxNormal
        				end
    				end else if (underflow) begin
        				tiny_f= 1'b1;
        				if ((mode == IEEE_near)) begin
            				z={z_calc[31], z_num(ZERO)}; // round to MinNormal in any case
        			end else if ((mode == away_zero)) begin
            				z={z_calc[31], z_num(MIN_NORM)};
        			end else if ((mode == IEEE_zero)) begin
             				z={z_calc[31], z_num(ZERO)}; // round to zero
            				zero_f= 1'b1;
        			end else if(mode==near_up) begin
            				z={z_calc[31], z_num(ZERO)}; // round to zero
        			end
         			else if (((mode == IEEE_pinf) && !z_calc[31]) || (mode == IEEE_ninf && z_calc[31])) begin
             				z={z_calc[31], z_num(MIN_NORM)}; // round to Min_Normal
        			end else if (mode == near_up) begin 
            				z={z_calc[31], z_num(ZERO)}; // round to maxNormal
        			end else begin
            				z={z_calc[31], z_num(ZERO)};
            				zero_f=1'b1; // round to zero
        			end //end comment_section
    			end else begin
        		z=z_calc;
       			inexact_f= inexact;
    	end
            		end
           		default: begin
                		z = z_calc; // Default case
           		end
		endcase
	end


endmodule
