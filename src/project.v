`default_nettype none

module tt_um_vga_example(
    input wire [7:0] ui_in,  // Dedizierte Eingänge
    output wire [7:0] uo_out, // Dedizierte Ausgänge
    input wire [7:0] uio_in,  // IOs: Eingangs-Pfad
    output wire [7:0] uio_out, // IOs: Ausgangs-Pfad
    output wire [7:0] uio_oe,  // IOs: Enable-Pfad (aktiv High: 0=Eingang, 1=Ausgang)
    input wire ena,            // Immer 1, solange das Design mit Strom versorgt ist - kann ignoriert werden
    input wire clk,            // Takt
    input wire rst_n           // reset_n - Low = Reset
);

    // VGA-Signale
    wire hsync;
    wire vsync;
    wire [1:0] R;
    wire [1:0] G;
    wire [1:0] B;
    wire video_active;
    wire [9:0] pix_x;
    wire [9:0] pix_y;

    // TinyVGA PMOD
    assign uo_out = {hsync, B[0], G[0], R[0], vsync, B[1], G[1], R[1]};

    // Ungenutzte Ausgänge auf 0 setzen
    assign uio_out = 0;
    assign uio_oe  = 0;

    // Suppress unused signals warning
    wire _unused_ok = &{ena, uio_in};

    // VGA-Signalgenerator instanziieren
    hvsync_generator hvsync_gen(
        .clk(clk),
        .reset(~rst_n),
        .hsync(hsync),
        .vsync(vsync),
        .display_on(video_active),
        .hpos(pix_x),
        .vpos(pix_y)
    );

    // Parameter und Register für das Rechteck
    localparam RECT_WIDTH = 200;   // Breite des Rechtecks
    localparam RECT_HEIGHT = 150;  // Höhe des Rechtecks
    reg [9:0] rect_x_start = 100;  // Variable X-Startposition initialisieren

    // Timing für die Bewegung
    reg [24:0] move_counter = 0;  // Zählt, um die Bewegungsfrequenz zu steuern
    reg move_tick;                // Signalisiert eine Bewegung, wenn ein weiterer Bewegungszyklus abgeschlossen ist

    always @(posedge clk) begin
        if (~rst_n) begin
            rect_x_start <= 100; // Zurücksetzen der Startposition bei Reset
            move_counter <= 0;
        end else begin
            move_counter <= move_counter + 1;
            // Bestimme die Frequenz der Bewegung (z.B. alle 2^20 Takte eine Bewegung)
            if (move_counter == 25'd1_000_000) begin // Größe von move_counter anpassen für gewünschte Geschwindigkeit
                move_counter <= 0;
                move_tick <= 1;
            end else begin
                move_tick <= 0;
            end

            // Bewegung basierend auf den Eingabesignalen
            if (move_tick) begin
                if (ui_in[0] && !ui_in[1]) begin
                    rect_x_start <= rect_x_start + 1; // Bewege das Rechteck nach rechts, falls Pin 0 High ist
                end else if (ui_in[1] && !ui_in[0]) begin
                    rect_x_start <= rect_x_start - 1; // Bewege das Rechteck nach links, falls Pin 1 High ist
                end
            end
        end
    end

    // Zeichnen des roten Rechtecks
    assign R = (video_active && 
                pix_x >= rect_x_start && pix_x < (rect_x_start + RECT_WIDTH) &&
                pix_y >= 100 && pix_y < (100 + RECT_HEIGHT)) ? 2'b11 : 2'b00;
    assign G = 2'b00; // Grün auf 0
    assign B = 2'b00; // Blau auf 0

endmodule
