`timescale 1ns/1ps
`include "multiplication.sv"
`include "fp_mult_top.sv"


module testbench;
	localparam NUM_RANDOM_TESTS = 50;
	localparam CLK_PERIOD = 15ns;

	logic clk;
  	logic rst;

    	logic [31:0] a, b, z, z_calc;
   	logic [2:0] rnd;
	logic overflow, underflow, inexact, round;
    	logic zero_f, inf_f, nan_f, tiny_f, huge_f, inexact_f;
	logic [7:0] status;

	string rounding_modes [6] = {"IEEE_near", "IEEE_zero", "IEEE_pinf", "IEEE_ninf", "near_up", "away_zero"};

	typedef enum logic [2:0] {
		IEEE_near=3'b000, 
		IEEE_zero=3'b001, 
		IEEE_pinf=3'b010, 
		IEEE_ninf=3'b011,
		near_up=3'b100, 
		away_zero=3'b101
	} rounding_mode_t;

	fp_mult_top fp(
		.clk(clk),
		.rst(rst),
		.rnd(rnd),
		.a(a),       
    		.b(b),
    		.z(z),       
    		.status(status)
	);

	// Clock Generation
  	always @(posedge clk) begin
		#(CLK_PERIOD/2) clk = ~clk;
            	// Generate random values for a and b
	end


	// Initialization
  	initial begin
    		clk = 0;
    		rst = 1;
		#(CLK_PERIOD * 2) rst = 0;

    		// Part 1: Random Testing
    		random_testing();

    		// Part 2: Corner Case Testing
    		corner_case_testing();

    		// Finish simulation
    		$finish;
  	end

	// Random Testing Task
	task random_testing();
    		for (int i = 0; i < NUM_RANDOM_TESTS; i++) begin
      			for (int j = 0; j < 6; j++) begin
            			a = $urandom();
            			b = $urandom();
				for (int j = 0; j < 6; j++) begin
        				simulate_multiplication(rounding_modes[j]);
        				#CLK_PERIOD;
				end
      			end	
    		end
  	endtask


	task automatic simulate_multiplication(input string rounding_mode);
       		begin
            	// Set the rounding mode
            	case (rounding_mode)
                	"IEEE_near": rnd = 3'b000;
                	"IEEE_zero": rnd = 3'b001;
                	"IEEE_pinf": rnd = 3'b010;
                	"IEEE_ninf": rnd = 3'b011;
                	"near_up": rnd = 3'b100;
                	"away_zero": rnd = 3'b101;
                	default: rnd = 3'b000;
            	endcase

            		// Call the multiplication function (assuming it's a DPI-C function)
            		z_calc = multiplication(rounding_mode, a, b);

			if (z !== z_calc) begin
                		$display("Error: Mismatch for rounding mode %s. a=%h, b=%h, z_calc=%h, z=%h", rounding_mode, a, b, z_calc, z);
            		end else begin
                		$display("Success: Match for rounding mode %s. a=%h, b=%h, z_calc=%h, z=%h", rounding_mode, a, b, z_calc, z);
            		end
        	end
    	endtask



	typedef enum logic [3:0] {
        	NEG_SNAN,
        	POS_SNAN,
        	NEG_QNAN,
        	POS_QNAN,
        	NEG_INF,
        	POS_INF,
        	NEG_NORMAL,
        	POS_NORMAL,
        	NEG_DENORMAL,
        	POS_DENORMAL,
        	NEG_ZERO,
        	POS_ZERO
    	} corner_case_t;

	
    	logic [31:0] corner_values [corner_case_t];
   	initial begin
        	corner_values[NEG_SNAN] = 32'hFF800001;
        	corner_values[POS_SNAN] = 32'h7F800001;
        	corner_values[NEG_QNAN] = 32'hFFC00000;
        	corner_values[POS_QNAN] = 32'h7FC00000;
        	corner_values[NEG_INF] = 32'hFF800000;
        	corner_values[POS_INF] = 32'h7F800000;
        	corner_values[NEG_NORMAL] = 32'hBF800000; // Random negative normal
        	corner_values[POS_NORMAL] = 32'h3F800000; // Random positive normal
        	corner_values[NEG_DENORMAL] = 32'h80000001; // Random negative denormal
        	corner_values[POS_DENORMAL] = 32'h00000001; // Random positive denormal
        	corner_values[NEG_ZERO] = 32'h80000000;
        	corner_values[POS_ZERO] = 32'h00000000;
    	end

	// Corner Case Testing Task
    	task corner_case_testing();
        	for (int i = 0; i < 12; i++) begin
            		for (int j = 0; j < 12; j++) begin
                		a = corner_values[corner_case_t'(i)];
                		b = corner_values[corner_case_t'(j)];
                		for (int k = 0; k < 6; k++) begin
                    			round = k;  // Set the rounding mode
                    			#CLK_PERIOD;
                    			z_calc = multiplication(rounding_modes[k], a, b);
                    			if (z !== z_calc) begin
                        			$display("Error: Mismatch for a=%s(%h), b=%s(%h), rounding mode=%s, z_calc=%h, z=%h",
                                 		corner_case_t'(i), a, corner_case_t'(j), b, rounding_modes[k], z_calc, z);
                    			end else begin
                        			$display("Success: Match for a=%s(%h), b=%s(%h), rounding mode=%s, z_calc=%h, z=%h",
                                 		corner_case_t'(i), a, corner_case_t'(j), b, rounding_modes[k], z_calc, z);
                    			end
                		end
            		end
        	end
    	endtask

initial begin
    #1000;
    $finish;
end

endmodule