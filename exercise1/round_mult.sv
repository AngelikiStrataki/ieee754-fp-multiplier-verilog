module round_mult(
	input logic [23:0] mantissa_in, // 24-bit mantissa (leading one + 23-bit normalized mantissa)
	input logic guard,
	input logic sticky,
	input logic sign,
	input logic [2:0] round, // Rounding mode
	output logic [24:0] mantissa_out, // 25-bit rounded mantissa
    	output logic inexact           // Inexact signal
);
	typedef enum logic [2:0] {
        	IEEE_near = 3'b000, // Round to nearest even
        	IEEE_zero = 3'b001, // Round toward zero
        	IEEE_pinf = 3'b010, // Round up (toward +inf)
        	IEEE_ninf = 3'b011, // Round down (toward -inf)
       		near_up = 3'b100,  // Round to nearest (ties away from zero)
		away_zero = 3'b101 // Round away from zero
    	} rounding_mode_t;
	
	rounding_mode_t rounding_mode;

	always_comb begin
		rounding_mode = rounding_mode_t'(round);  // Cast input round to enum type

        	inexact = !(guard && sticky);
        	
		case (rounding_mode)

            		IEEE_near: begin
                		// Round to nearest even
                		if (guard && (sticky || mantissa_in[0])) begin
                    			mantissa_out = mantissa_in + 1;
                		end else begin
                    			mantissa_out = mantissa_in;
                		end
			end

            		IEEE_zero: begin
                		// Round toward zero (truncate)
                		mantissa_out = mantissa_in;
            		end

            		IEEE_pinf: begin
                		// Round up (toward +inf)
                		if (!sign && (guard || sticky)) begin
                    			mantissa_out = mantissa_in + 1;
                		end else begin
                    			mantissa_out = mantissa_in;
                		end
            		end

            		IEEE_ninf: begin
                		// Round down (toward -inf)
                		if (inexact && sign) begin
                    			mantissa_out = mantissa_in + 1;
                		end else begin
                    			mantissa_out = mantissa_in;
                		end
            		end

            		near_up: begin
                		// Round to nearest, ties away from zero
                		if (guard) begin
                    			mantissa_out = mantissa_in + 1;
                		end else begin
                    			mantissa_out = mantissa_in;
                		end
            		end

            		away_zero: begin
                		// Round away from zero
                		if (inexact) begin
                    			mantissa_out = mantissa_in + 1;
                		end else begin
                    			mantissa_out = mantissa_in;
                		end
           		 end

            		default: begin
                		// Default to round to nearest even if invalid rounding mode
                		if (guard && (sticky || mantissa_in[0])) begin
                    			mantissa_out = mantissa_in + 1;
                		end else begin
                    			mantissa_out = mantissa_in;
                		end
            		end
        	endcase
        	
	
		if (mantissa_out[24]) begin
            		mantissa_out = mantissa_out >> 1;
            		mantissa_out[23] = 1;
        	end


	end

endmodule
