`timescale 1ns/1ps

module tb_system;

parameter CLK_PERIOD = 100;
parameter DEBOUNCE_SIM = 20'd15;

reg  [7:0] ui_in;
wire [7:0] uo_out;
wire [7:0] uio_out;
wire [7:0] uio_oe;
reg        clk;
reg        rst_n;
reg        ena;

wire audio_out = uo_out[0];
wire spi_cs_n  = uo_out[1];
wire spi_sclk  = uo_out[2];
wire spi_mosi  = uo_out[3];
wire spi_miso;

reg [7:0] uio_in;
initial uio_in = 8'h00;
always @(*) uio_in[0] = spi_miso;

top_music dut (
    .ui_in  (ui_in),
    .uo_out (uo_out),
    .uio_in (uio_in),
    .uio_out(uio_out),
    .uio_oe (uio_oe),
    .clk    (clk),
    .rst_n  (rst_n),
    .ena    (ena)
);

fake_flash flash_sim (
    .sclk (spi_sclk),
    .cs_n (spi_cs_n),
    .mosi (spi_mosi),
    .miso (spi_miso)
);

initial clk = 0;
always #(CLK_PERIOD/2) clk = ~clk;

initial begin
    $dumpfile("sim/system_sim.vcd");
    $dumpvars(0, tb_system);
end

// Tarea para simular pulso de boton
task pulse_button;
    input integer btn_bit;
    begin
        ui_in[btn_bit] = 1'b1;
        #(CLK_PERIOD * 500);
        ui_in[btn_bit] = 1'b0;
        #(CLK_PERIOD * 100);
    end
endtask

initial begin
    $display("=== Inicio simulacion 3 canciones ===");
    rst_n  = 0;
    ena    = 1;
    ui_in  = 8'h00;
    #(CLK_PERIOD * 20);
    rst_n = 1;
    #(CLK_PERIOD * 100);

    // ---- Presionar PLAY ----
    $display("\n--- PLAY: Cancion 1 Beat It ---");
    pulse_button(0);
    #200_000_000;

    // ---- NEXT: Cancion 2 ----
    $display("\n--- NEXT: Cancion 2 Cumpleanos ---");
    pulse_button(2);
    #3_000_000;

    // ---- NEXT: Cancion 3 ----
    $display("\n--- NEXT: Cancion 3 Super Mario ---");
    pulse_button(2);
    #3_000_000;

    // ---- NEXT: vuelve a Cancion 1 ----
    $display("\n--- NEXT: vuelve a Cancion 1 ---");
    pulse_button(2);
    #3_000_000;

    // ---- STOP ----
    $display("\n--- STOP ---");
    pulse_button(1);
    #(CLK_PERIOD * 100);

    $display("\n=== Fin simulacion ===");
    $finish;
end

// Monitor cambio de nota
reg [7:0] prev_note = 8'hFF;
always @(posedge clk) begin
    if (dut.note_id !== prev_note) begin
        prev_note = dut.note_id;
        $display("[%0t ns] song=%0d nota=0x%02X cs=%b",
                 $time, dut.u_seq.cur_song,
                 dut.note_id, spi_cs_n);
    end
end

endmodule