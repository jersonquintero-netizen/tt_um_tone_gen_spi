`default_nettype none
// ============================================================
// note_table.v
// Mapea ID de nota (0-29) a divisor de frecuencia
// Clk = 10 MHz
// Divisor = 10_000_000 / (2 * frecuencia)
//
// IDs de notas:
//  0x00 = silencio
//  0x01 = Do3  (C3  - 130.81 Hz)
//  0x02 = Re3  (D3  - 146.83 Hz)
//  0x03 = Mi3  (E3  - 164.81 Hz)
//  0x04 = Fa3  (F3  - 174.61 Hz)
//  0x05 = Sol3 (G3  - 196.00 Hz)
//  0x06 = La3  (A3  - 220.00 Hz)
//  0x07 = Si3  (B3  - 246.94 Hz)
//  0x08 = Do4  (C4  - 261.63 Hz)
//  0x09 = Re4  (D4  - 293.66 Hz)
//  0x0A = Mi4  (E4  - 329.63 Hz)
//  0x0B = Fa4  (F4  - 349.23 Hz)
//  0x0C = Sol4 (G4  - 392.00 Hz)
//  0x0D = La4  (A4  - 440.00 Hz)
//  0x0E = Si4  (B4  - 493.88 Hz)
//  0x0F = Do5  (C5  - 523.25 Hz)
//  0x10 = Re5  (D5  - 587.33 Hz)
//  0x11 = Mi5  (E5  - 659.26 Hz)
//  0x12 = Fa5  (F5  - 698.46 Hz)
//  0x13 = Sol5 (G5  - 783.99 Hz)
//  0x14 = La5  (A5  - 880.00 Hz)
//  0x15 = Si5  (B5  - 987.77 Hz)
//  0xFF = fin de cancion
// ============================================================
`timescale 1ns/1ps
module note_table (
    input  wire [7:0] note_id,
    output reg  [15:0] divisor
);

always @(*) begin
    case (note_id)
        8'h01: divisor = 16'd38223;
        8'h02: divisor = 16'd34053;
        8'h03: divisor = 16'd30338;
        8'h04: divisor = 16'd28635;
        8'h05: divisor = 16'd25510;
        8'h06: divisor = 16'd22727;
        8'h07: divisor = 16'd20249;
        8'h08: divisor = 16'd19112;
        8'h09: divisor = 16'd17026;
        8'h0A: divisor = 16'd15169;
        8'h0B: divisor = 16'd14317;
        8'h0C: divisor = 16'd12755;
        8'h0D: divisor = 16'd11364;
        8'h0E: divisor = 16'd10124;
        8'h0F: divisor = 16'd9556;
        8'h10: divisor = 16'd8513;
        8'h11: divisor = 16'd7584;
        8'h12: divisor = 16'd7159;
        8'h13: divisor = 16'd6378;
        8'h14: divisor = 16'd5682;
        8'h15: divisor = 16'd5062;
        default: divisor = 16'd0;
    endcase
end

endmodule