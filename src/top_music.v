`default_nettype none
`timescale 1ns/1ps

module top_music (
    input  wire [7:0] ui_in,
    output wire [7:0] uo_out,
    input  wire [7:0] uio_in,
    output wire [7:0] uio_out,
    output wire [7:0] uio_oe,
    input  wire       clk,
    input  wire       rst_n,
    input  wire       ena
);

wire rst = ~rst_n;

// ============================================================
// Pulsadores externos activos en alto
// ui_in[0] = btn_play  (pulsador PLAY)
// ui_in[1] = btn_stop  (pulsador STOP)
// ui_in[2] = btn_next  (pulsador NEXT cancion)
// ============================================================

localparam DEBOUNCE = 20'd200_000;

// Sincronizadores
reg btn_play_sync, btn_stop_sync, btn_next_sync;
always @(posedge clk or posedge rst) begin
    if (rst) begin
        btn_play_sync <= 1'b0;
        btn_stop_sync <= 1'b0;
        btn_next_sync <= 1'b0;
    end else begin
        btn_play_sync <= ui_in[0];
        btn_stop_sync <= ui_in[1];
        btn_next_sync <= ui_in[2];
    end
end

// Antirrebote btn_play
reg [19:0] db_cnt_play;
reg        btn_play_stable;
reg        btn_play_last;
always @(posedge clk or posedge rst) begin
    if (rst) begin
        db_cnt_play     <= 20'd0;
        btn_play_stable <= 1'b0;
        btn_play_last   <= 1'b0;
    end else begin
        btn_play_last <= btn_play_sync;
        if (btn_play_sync != btn_play_last)
            db_cnt_play <= 20'd0;
        else if (db_cnt_play < DEBOUNCE)
            db_cnt_play <= db_cnt_play + 1'b1;
        else
            btn_play_stable <= btn_play_sync;
    end
end

// Antirrebote btn_stop
reg [19:0] db_cnt_stop;
reg        btn_stop_stable;
reg        btn_stop_last;
always @(posedge clk or posedge rst) begin
    if (rst) begin
        db_cnt_stop     <= 20'd0;
        btn_stop_stable <= 1'b0;
        btn_stop_last   <= 1'b0;
    end else begin
        btn_stop_last <= btn_stop_sync;
        if (btn_stop_sync != btn_stop_last)
            db_cnt_stop <= 20'd0;
        else if (db_cnt_stop < DEBOUNCE)
            db_cnt_stop <= db_cnt_stop + 1'b1;
        else
            btn_stop_stable <= btn_stop_sync;
    end
end

// Antirrebote btn_next
reg [19:0] db_cnt_next;
reg        btn_next_stable;
reg        btn_next_last;
always @(posedge clk or posedge rst) begin
    if (rst) begin
        db_cnt_next     <= 20'd0;
        btn_next_stable <= 1'b0;
        btn_next_last   <= 1'b0;
    end else begin
        btn_next_last <= btn_next_sync;
        if (btn_next_sync != btn_next_last)
            db_cnt_next <= 20'd0;
        else if (db_cnt_next < DEBOUNCE)
            db_cnt_next <= db_cnt_next + 1'b1;
        else
            btn_next_stable <= btn_next_sync;
    end
end

// Deteccion de flanco de subida
reg btn_play_prev, btn_stop_prev, btn_next_prev;
always @(posedge clk or posedge rst) begin
    if (rst) begin
        btn_play_prev <= 1'b0;
        btn_stop_prev <= 1'b0;
        btn_next_prev <= 1'b0;
    end else begin
        btn_play_prev <= btn_play_stable;
        btn_stop_prev <= btn_stop_stable;
        btn_next_prev <= btn_next_stable;
    end
end

wire play_press = btn_play_stable && !btn_play_prev;
wire stop_press = btn_stop_stable && !btn_stop_prev;
wire next_press = btn_next_stable && !btn_next_prev;

// Play/Stop flip-flop
reg play;
always @(posedge clk or posedge rst) begin
    if (rst)
        play <= 1'b0;
    else if (play_press)
        play <= 1'b1;
    else if (stop_press)
        play <= 1'b0;
end

// Selector de cancion
reg [1:0] song_sel;
always @(posedge clk or posedge rst) begin
    if (rst)
        song_sel <= 2'd0;
    else if (next_press) begin
        if (song_sel == 2'd2)
            song_sel <= 2'd0;
        else
            song_sel <= song_sel + 1'b1;
    end
end

// ============================================================
// SPI
// ============================================================
wire spi_sclk;
wire spi_cs_n;
wire spi_mosi;
wire spi_miso = uio_in[0];

wire        spi_start;
wire [23:0] spi_addr;
wire [7:0]  spi_data;
wire        spi_data_valid;
wire        spi_busy;

wire [7:0]  note_id;
wire        note_active;
wire [15:0] divisor;
wire        audio_out;

spi_controller #(.CLK_DIV(4)) u_spi (
    .clk        (clk),
    .rst        (rst),
    .start      (spi_start),
    .addr       (spi_addr),
    .num_bytes  (2'd2),
    .data_out   (spi_data),
    .data_valid (spi_data_valid),
    .busy       (spi_busy),
    .sclk       (spi_sclk),
    .cs_n       (spi_cs_n),
    .mosi       (spi_mosi),
    .miso       (spi_miso)
);

sequencer #(
    .CLK_FREQ   (10_000_000),
    .BPM        (120),
    .TICKS_BEAT (4)
) u_seq (
    .clk            (clk),
    .rst            (rst),
    .play           (play),
    .song_sel       (song_sel),
    .spi_start      (spi_start),
    .spi_addr       (spi_addr),
    .spi_data       (spi_data),
    .spi_data_valid (spi_data_valid),
    .spi_busy       (spi_busy),
    .note_id        (note_id),
    .note_active    (note_active)
);

note_table u_notes (
    .note_id (note_id),
    .divisor (divisor)
);

tone_generator u_tone (
    .clk       (clk),
    .rst       (rst),
    .divisor   (note_active ? divisor : 16'd0),
    .audio_out (audio_out)
);

// ============================================================
// Salidas
// ============================================================
assign uo_out[0] = audio_out;
assign uo_out[1] = spi_cs_n;
assign uo_out[2] = spi_sclk;
assign uo_out[3] = spi_mosi;
assign uo_out[7:4] = 4'b0000;

assign uio_out = 8'b00000000;
assign uio_oe  = 8'b00000000;

endmodule