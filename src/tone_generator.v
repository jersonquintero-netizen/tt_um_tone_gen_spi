`default_nettype none
`timescale 1ns/1ps

module tone_generator (
    input  wire        clk,
    input  wire        rst,
    input  wire [15:0] divisor,
    output reg         audio_out
);

reg [15:0] counter;

always @(posedge clk or posedge rst) begin
    if (rst) begin
        counter   <= 16'd0;
        audio_out <= 1'b0;
    end else begin
        if (divisor == 16'd0) begin
            counter   <= 16'd0;
            audio_out <= 1'b0;
        end else begin
            if (counter >= divisor - 1) begin
                counter   <= 16'd0;
                audio_out <= ~audio_out;
            end else begin
                counter <= counter + 1'b1;
            end
        end
    end
end

endmodule