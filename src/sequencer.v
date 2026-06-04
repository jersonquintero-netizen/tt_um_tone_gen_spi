`default_nettype none
`timescale 1ns/1ps

module sequencer (
    input  wire        clk,
    input  wire        rst,
    input  wire        play,
    input  wire [1:0]  song_sel,
    output reg         spi_start,
    output reg  [23:0] spi_addr,
    input  wire [7:0]  spi_data,
    input  wire        spi_data_valid,
    input  wire        spi_busy,
    output reg  [7:0]  note_id,
    output reg         note_active
);

localparam [31:0] TICK_CYCLES = 32'd1250000;

localparam S_IDLE      = 3'd0;
localparam S_START_SPI = 3'd1;
localparam S_WAIT_NOTE = 3'd2;
localparam S_WAIT_DUR  = 3'd3;
localparam S_WAIT_DONE = 3'd4;
localparam S_PLAY      = 3'd5;

reg [2:0]  state;
reg [7:0]  cur_note;
reg [31:0] tick_cnt;
reg [31:0] tick_limit;
reg [23:0] cur_addr;
reg [1:0]  cur_song;

always @(posedge clk or posedge rst) begin
    if (rst) begin
        state       <= S_IDLE;
        spi_start   <= 1'b0;
        spi_addr    <= 24'h000000;
        note_id     <= 8'h00;
        note_active <= 1'b0;
        cur_note    <= 8'h00;
        tick_cnt    <= 32'd0;
        tick_limit  <= 32'd0;
        cur_addr    <= 24'h000000;
        cur_song    <= 2'd0;
    end else begin
        spi_start <= 1'b0;

        case (state)

            S_IDLE: begin
                note_id     <= 8'h00;
                note_active <= 1'b0;
                if (play) begin
                    cur_song <= song_sel;
                    cur_addr <= {14'd0, song_sel, 8'd0};
                    state    <= S_START_SPI;
                end
            end

            S_START_SPI: begin
                if (song_sel != cur_song) begin
                    note_id     <= 8'h00;
                    note_active <= 1'b0;
                    cur_song    <= song_sel;
                    cur_addr    <= {14'd0, song_sel, 8'd0};
                end
                if (!spi_busy) begin
                    spi_addr  <= cur_addr;
                    spi_start <= 1'b1;
                    state     <= S_WAIT_NOTE;
                end
                if (!play) state <= S_IDLE;
            end

            S_WAIT_NOTE: begin
                if (spi_data_valid) begin
                    cur_note <= spi_data;
                    cur_addr <= cur_addr + 1'b1;
                    if (spi_data == 8'hFF) begin
                        cur_addr <= {14'd0, cur_song, 8'd0};
                        state    <= S_WAIT_DONE;
                    end else begin
                        state <= S_WAIT_DUR;
                    end
                end
                if (!play) state <= S_IDLE;
            end

            S_WAIT_DUR: begin
                if (spi_data_valid) begin
                    cur_addr    <= cur_addr + 1'b1;
                    note_id     <= cur_note;
                    note_active <= (cur_note != 8'h00);
                    tick_cnt    <= 32'd0;
                    tick_limit  <= TICK_CYCLES * {24'd0, spi_data};
                    state       <= S_WAIT_DONE;
                end
                if (!play) state <= S_IDLE;
            end

            S_WAIT_DONE: begin
                if (!spi_busy) begin
                    if (cur_note == 8'hFF) begin
                        state <= S_START_SPI;
                    end else begin
                        state <= S_PLAY;
                    end
                end
                if (!play) state <= S_IDLE;
            end

            S_PLAY: begin
                if (!play) begin
                    note_id     <= 8'h00;
                    note_active <= 1'b0;
                    state       <= S_IDLE;
                end else if (song_sel != cur_song) begin
                    note_id     <= 8'h00;
                    note_active <= 1'b0;
                    cur_song    <= song_sel;
                    cur_addr    <= {14'd0, song_sel, 8'd0};
                    tick_cnt    <= 32'd0;
                    state       <= S_START_SPI;
                end else if (tick_limit > 0 && tick_cnt >= tick_limit - 1) begin
                    note_id     <= 8'h00;
                    note_active <= 1'b0;
                    tick_cnt    <= 32'd0;
                    state       <= S_START_SPI;
                end else begin
                    tick_cnt <= tick_cnt + 1'b1;
                end
            end

            default: state <= S_IDLE;
        endcase
    end
end

endmodule