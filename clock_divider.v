module clock_divider(
    input clk_in,             // 10 MHz input clock
    output reg clk_out = 0,       // 10 Hz output clock
    output wire counter_0,    // LSB of the counter
    output wire counter_1     // Second LSB of the counter
);
    reg [13:0] counter = 0;   // 20-bit counter (for divide-by-1,000,000)

    always @(posedge clk_in) begin
        if (counter == 20'd9999) begin
            clk_out <= ~clk_out;  // Toggle the output clock
            counter <= 0;         // Reset the counter
        end else begin
            counter <= counter + 1; // Increment the counter
        end
    end

    // Assign the LSBs of the counter to outputs
    assign counter_0 = counter[0];
    assign counter_1 = counter[1];
endmodule
