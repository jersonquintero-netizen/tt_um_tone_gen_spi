`default_nettype none
`timescale 1ns/1ps

module spi_controller #(
    parameter CLK_DIV = 4
)(
    input  wire        clk,
    input  wire        rst,
    input  wire        start,
    input  wire [23:0] addr,
    input  wire [1:0]  num_bytes,
    output reg  [7:0]  data_out,
    output reg         data_valid,
    output reg         busy,
    output reg         sclk,
    output reg         cs_n,
    output reg         mosi,
    input  wire        miso
);

localparam S_IDLE  = 3'd0;
localparam S_CMD   = 3'd1;
localparam S_READ  = 3'd2;
localparam S_DONE  = 3'd3;
localparam S_STOP  = 3'd4;

reg [2:0]  state;
reg [5:0]  bit_cnt;
reg [31:0] shift_reg;
reg [3:0]  clk_cnt;
reg        clk_edge;
reg [1:0]  bytes_left;

always @(posedge clk or posedge rst) begin
    if (rst) begin
        state      <= S_IDLE;
        sclk       <= 1'b0;
        cs_n       <= 1'b1;
        mosi       <= 1'b0;
        data_out   <= 8'd0;
        data_valid <= 1'b0;
        busy       <= 1'b0;
        bit_cnt    <= 6'd0;
        shift_reg  <= 32'd0;
        clk_cnt    <= 4'd0;
        clk_edge   <= 1'b0;
        bytes_left <= 2'd0;
    end else begin
        data_valid <= 1'b0;

        case (state)

            S_IDLE: begin
                cs_n  <= 1'b1;
                sclk  <= 1'b0;
                mosi  <= 1'b0;
                busy  <= 1'b0;
                if (start) begin
                    shift_reg  <= {8'h03, addr};
                    bit_cnt    <= 6'd31;
                    clk_cnt    <= 4'd0;
                    clk_edge   <= 1'b0;
                    cs_n       <= 1'b0;
                    busy       <= 1'b1;
                    bytes_left <= num_bytes;
                    state      <= S_CMD;
                end
            end

            S_CMD: begin
                if (clk_cnt < CLK_DIV - 1) begin
                    clk_cnt <= clk_cnt + 1'b1;
                end else begin
                    clk_cnt <= 4'd0;
                    if (!clk_edge) begin
                        mosi     <= shift_reg[31];
                        sclk     <= 1'b1;
                        clk_edge <= 1'b1;
                    end else begin
                        sclk      <= 1'b0;
                        clk_edge  <= 1'b0;
                        shift_reg <= {shift_reg[30:0], 1'b0};
                        if (bit_cnt == 6'd0) begin
                            shift_reg <= 32'd0;
                            bit_cnt   <= 6'd7;
                            state     <= S_READ;
                        end else begin
                            bit_cnt <= bit_cnt - 1'b1;
                        end
                    end
                end
            end

            S_READ: begin
                if (clk_cnt < CLK_DIV - 1) begin
                    clk_cnt <= clk_cnt + 1'b1;
                end else begin
                    clk_cnt <= 4'd0;
                    if (!clk_edge) begin
                        shift_reg <= {shift_reg[30:0], miso};
                        sclk      <= 1'b1;
                        clk_edge  <= 1'b1;
                    end else begin
                        sclk     <= 1'b0;
                        clk_edge <= 1'b0;
                        if (bit_cnt == 6'd0) begin
                            state <= S_DONE;
                        end else begin
                            bit_cnt <= bit_cnt - 1'b1;
                        end
                    end
                end
            end

            S_DONE: begin
                data_out   <= shift_reg[7:0];
                data_valid <= 1'b1;
                bit_cnt    <= 6'd7;
                shift_reg  <= 32'd0;
                clk_cnt    <= 4'd0;
                clk_edge   <= 1'b0;
                if (bytes_left <= 2'd1) begin
                    state <= S_STOP;
                end else begin
                    bytes_left <= bytes_left - 1'b1;
                    state      <= S_READ;
                end
            end

            S_STOP: begin
                cs_n  <= 1'b1;
                sclk  <= 1'b0;
                mosi  <= 1'b0;
                busy  <= 1'b0;
                state <= S_IDLE;
            end

            default: state <= S_IDLE;
        endcase
    end
end

endmodule