module main_game(
    input clk,
    input reset,
    input up_p1, down_p1,		
    input up_p2, down_p2,
    output reg [7:0] rows,
    output reg [7:0] colsr, //for activating red cathodes
    output reg [7:0] colsg, //for activating green cathodes
    output [7:0] segments,
    output [2:0] cathode_sel
);

    reg [2:0] p1_pos, p2_pos;        // Paddle positions
    reg [2:0] ball_x, ball_y;        // Ball position
    reg [1:0] ball_speed_x, ball_speed_y; // Ball speed direction
	reg [3:0] score_p1, score_p2;	 // Player scores
    reg [1:0] display_state;         //counter for multiplexing
	wire counter_0;

    // Clock divider for generating slower display and update clocks
    wire clk_1k, clk_10;
    clock_divider clk_gen1(clk, clk_1k);   // 1 kHz clock for display multiplexing
    clock_divider_10 clk_gen2(clk, clk_10,counter_0); // 10 Hz clock for game logic updates

    // Initialization block
    initial 
	begin
		rows = 8'b00000000;
		colsr = 8'b00000000; // red led
		colsg = 8'b00000000; // green led
		
		p1_pos = 2;               // Initial position for paddle 1
		p2_pos = 2;               // Initial position for paddle 2
		ball_x = 4;               // Initial position for the ball
		ball_y = 4;
		
		ball_speed_x =0;
		ball_speed_y = 1;
		
		score_p1 = 0;
		score_p2 = 0;
		display_state <= 2'b00;    // Start with displaying paddle 1
	end
	
    // Display Score
    seven_seg_test display(clk, reset, score_p1, score_p2, segments, cathode_sel);

    // Sequential logic for updating paddle positions and ball mechanics
    always @(posedge clk_10 or posedge reset) 
		begin
			if (reset) 
				begin
					p1_pos = 2;
					p2_pos = 2;
					ball_x = 4;
					ball_y = 4;
					ball_speed_x =0;

					if(counter_0)        
						ball_speed_y = 1;
					else
						ball_speed_y = 2;
						
					score_p1 = 0;
					score_p2 = 0;
				end 
				else 
					begin
						// Paddle 1 controls
						if (~up_p1 && p1_pos > 0)  // Move paddle 1 up
							p1_pos = p1_pos - 1;
						if (down_p1 && p1_pos < 5) // Move paddle 1 down
							p1_pos = p1_pos + 1;

						// Paddle 2 controls
						if (~up_p2 && p2_pos > 0)  // Move paddle 2 up
							p2_pos = p2_pos - 1;
						if (down_p2 && p2_pos < 5) // Move paddle 2 down
							p2_pos = p2_pos + 1;

						// Ball mechanics
						if (ball_y == 0) 
							begin
								if (ball_x >= p1_pos && ball_x <= p1_pos + 2) begin
									if(ball_x ==p1_pos)
										ball_speed_x = 2;
									else if(ball_x ==p1_pos+1)
										ball_speed_x = 0;
									else if(ball_x ==p1_pos+2)
										ball_speed_x = 1;
										
									ball_speed_y = 1; // Reverse direction
								end 
								else 
									begin					
										score_p2 = score_p2 + 1; // Player 2 scores
										if(score_p2>=9) begin
											ball_speed_x =0;
											ball_speed_y =0;
											ball_x = 4;
											ball_y = 4;
										end
										else begin
										p1_pos = 2;
										p2_pos = 2;
										ball_x = 4;
										ball_y = 3;

										ball_speed_x =0;      
										ball_speed_y = 1;
										end		
									end
						
						end 
						else if (ball_y== 7) 
							begin
								if (ball_x >= p2_pos && ball_x <= p2_pos + 2) begin
									case(ball_x)
										p2_pos:   ball_speed_x = 2;
										p2_pos+1: ball_speed_x = 0;
										p2_pos+2: ball_speed_x = 1;
									endcase			
										ball_speed_y = 2; // Reverse direction
								end 
							else 
								begin
								score_p1 = score_p1 + 1; // Player 2 scores
								
									if(score_p1>=9) begin
										ball_speed_x =0;
										ball_speed_y =0;
										ball_x = 4;
										ball_y = 4;
									end
									else begin
									p1_pos = 2;
									p2_pos = 2;
									ball_x = 4;
									ball_y = 5;

									ball_speed_x =0;      
									ball_speed_y = 2;
									end		
								end
									
							end
						else begin
						
						// Ball boundary checks
						if (ball_x == 7)
							ball_speed_x = 2;
						else if (ball_x == 0)
							ball_speed_x = 1;
						end
							
						// Update ball position
						if (ball_speed_x == 1 && ball_x < 7)
							ball_x = ball_x + 1;
						else if (ball_speed_x == 2 && ball_x > 0)
							ball_x = ball_x - 1;
						else if (ball_speed_x==0)
							ball_x = ball_x;
							
						if (ball_speed_y == 1 && ball_y < 7)
							ball_y = ball_y + 1;
						else if (ball_speed_y == 2 && ball_y > 0)
							ball_y = ball_y - 1;
					end
					
			end
	

    //counter for multiplexing display logic
    always @(posedge clk_1k or posedge reset) begin
        if (reset) begin
            display_state = 2'b00; // Reset display state
        end else begin
            display_state = display_state + 1; // Cycle through states
        end

        case (display_state)
            2'b00: begin // Display paddle 1
				rows = 8'b00000000;   // Clear rows
                colsg = 8'b00000000;

                rows[p1_pos] = 1;
                rows[p1_pos + 1] = 1;
                rows[p1_pos + 2] = 1;
				colsg[0] = 1;
            end
            2'b01: begin // Display paddle 2
                rows = 8'b00000000;   // Clear rows
                colsg = 8'b00000000;   // Active-low for paddle 2
                rows[p2_pos] = 1;
                rows[p2_pos + 1] = 1;
                rows[p2_pos + 2] = 1;
				colsg[7] = 1;
            end
            2'b10: begin // Display ball
                rows = 8'b00000000;   // Clear rows
                colsr = 8'b00000000;   
                colsg = 8'b00000000; 

                rows[ball_x] = 1;
                colsr[ball_y] = 1;
                colsg[ball_y] = 1;
            end
            default: begin
                rows = 8'b00000000;
                colsr = 8'b00000000;
                colsg = 8'b00000000;
            end
        endcase
    end

endmodule
