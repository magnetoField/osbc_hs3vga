/*
 * Copyright (c) 2025 Jakub Rachoń
 * SPDX-License-Identifier: Apache-2.0
 * Hackerspace Trojmiasto VGA display
 */

`default_nettype none

module tt_um_vga_example(
  input  wire [7:0] ui_in,    // Dedicated inputs
  output wire [7:0] uo_out,   // Dedicated outputs
  input  wire [7:0] uio_in,   // IOs: Input path
  output wire [7:0] uio_out,  // IOs: Output path
  output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
  input  wire       ena,      // always 1 when the design is powered, so you can ignore it
  input  wire       clk,      // clock
  input  wire       rst_n     // reset_n - low to reset
);

  // VGA signals
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

  // Unused outputs assigned to 0.
  assign uio_out = 0;
  assign uio_oe  = 0;

  // Suppress unused signals warning
  wire _unused_ok = &{ena, ui_in, uio_in};

  // Text display parameters
  parameter CHAR_WIDTH = 8;
  parameter CHAR_HEIGHT = 16;
  parameter CHARS_PER_LINE = 24;
  parameter NUM_LINES = 2;
  parameter MARGIN_X = 80;
  parameter MARGIN_Y = 60;

  // Character position calculations
  wire [8:0] char_x_unbounded = pix_x - MARGIN_X;
  wire [8:0] char_y_unbounded = pix_y - MARGIN_Y;
  wire char_in_x_range = (char_x_unbounded < (CHARS_PER_LINE * CHAR_WIDTH));
  wire char_in_y_range = (char_y_unbounded < (NUM_LINES * CHAR_HEIGHT));
  wire char_in_range = char_in_x_range && char_in_y_range && video_active;

  wire [7:0] char_x = char_x_unbounded[7:0];  // Limit to 8 bits
  wire [7:0] char_y = char_y_unbounded[7:0];  // Limit to 8 bits

  wire [4:0] char_col_idx = char_x / CHAR_WIDTH;
  wire [4:0] char_row_idx = char_y / CHAR_HEIGHT;
  wire [3:0] pixel_row = char_y % CHAR_HEIGHT;
  wire [2:0] pixel_col = char_x % CHAR_WIDTH;

  // Text memory for "Hackerspace Trojmiasto"
  reg [7:0] text_memory [0:CHARS_PER_LINE*NUM_LINES-1];

  initial begin
    // Initialize text memory
    for (integer i = 0; i < CHARS_PER_LINE*NUM_LINES; i = i + 1) begin
      text_memory[i] = " ";
    end

    // First line: "Hackerspace"
    text_memory[1]  = "H";
    text_memory[2]  = "a";
    text_memory[3]  = "c";
    text_memory[4]  = "k";
    text_memory[5]  = "e";
    text_memory[6]  = "r";
    text_memory[7]  = "s";
    text_memory[8]  = "p";
    text_memory[9]  = "a";
    text_memory[10] = "c";
    text_memory[11] = "e";

    // Second line: "Trojmiasto"
    text_memory[CHARS_PER_LINE + 1] = "T";
    text_memory[CHARS_PER_LINE + 2] = "r";
    text_memory[CHARS_PER_LINE + 3] = "o";
    text_memory[CHARS_PER_LINE + 4] = "j";
    text_memory[CHARS_PER_LINE + 5] = "m";
    text_memory[CHARS_PER_LINE + 6] = "i";
    text_memory[CHARS_PER_LINE + 7] = "a";
    text_memory[CHARS_PER_LINE + 8] = "s";
    text_memory[CHARS_PER_LINE + 9] = "t";
    text_memory[CHARS_PER_LINE + 10] = "o";
  end

  // Character ROM function
  function [7:0] char_rom(input [7:0] char_code, input [3:0] row);
    case(char_code)
      // Space
      8'h20: char_rom = 8'h00;

      // 'H' (0x48)
      8'h48: case(row)
        0: char_rom = 8'b11000011;
        1: char_rom = 8'b11000011;
        2: char_rom = 8'b11000011;
        3: char_rom = 8'b11000011;
        4: char_rom = 8'b11111111;
        5: char_rom = 8'b11111111;
        6: char_rom = 8'b11000011;
        7: char_rom = 8'b11000011;
        8: char_rom = 8'b11000011;
        9: char_rom = 8'b11000011;
        default: char_rom = 8'h00;
      endcase

      // 'a' (0x61)
      8'h61: case(row)
        3: char_rom = 8'b00111000;
        4: char_rom = 8'b01111100;
        5: char_rom = 8'b11000110;
        6: char_rom = 8'b11000110;
        7: char_rom = 8'b11111110;
        8: char_rom = 8'b11111110;
        9: char_rom = 8'b11000110;
        10: char_rom = 8'b11000110;
        default: char_rom = 8'h00;
      endcase

      // 'c' (0x63)
      8'h63: case(row)
        3: char_rom = 8'b00111100;
        4: char_rom = 8'b01111110;
        5: char_rom = 8'b11000000;
        6: char_rom = 8'b11000000;
        7: char_rom = 8'b11000000;
        8: char_rom = 8'b01111110;
        9: char_rom = 8'b00111100;
        default: char_rom = 8'h00;
      endcase

      // 'k' (0x6B)
      8'h6B: case(row)
        0: char_rom = 8'b11000110;
        1: char_rom = 8'b11001100;
        2: char_rom = 8'b11011000;
        3: char_rom = 8'b11110000;
        4: char_rom = 8'b11100000;
        5: char_rom = 8'b11110000;
        6: char_rom = 8'b11011000;
        7: char_rom = 8'b11001100;
        8: char_rom = 8'b11000110;
        default: char_rom = 8'h00;
      endcase

      // 'e' (0x65)
      8'h65: case(row)
        2: char_rom = 8'b00111000;
        3: char_rom = 8'b01111100;
        4: char_rom = 8'b11000110;
        5: char_rom = 8'b11111110;
        6: char_rom = 8'b11111100;
        7: char_rom = 8'b11000000;
        8: char_rom = 8'b01111110;
        9: char_rom = 8'b00111100;
        default: char_rom = 8'h00;
      endcase

      // 'r' (0x72)
      8'h72: case(row)
        0: char_rom = 8'b11111100;
        1: char_rom = 8'b11111110;
        2: char_rom = 8'b11000011;
        3: char_rom = 8'b11000000;
        4: char_rom = 8'b11000000;
        5: char_rom = 8'b11000000;
        6: char_rom = 8'b11000000;
        7: char_rom = 8'b11000000;
        default: char_rom = 8'h00;
      endcase

      // 's' (0x73)
      8'h73: case(row)
        2: char_rom = 8'b00111100;
        3: char_rom = 8'b01111110;
        4: char_rom = 8'b11000000;
        5: char_rom = 8'b01111100;
        6: char_rom = 8'b00111110;
        7: char_rom = 8'b00000110;
        8: char_rom = 8'b11111100;
        9: char_rom = 8'b01111000;
        default: char_rom = 8'h00;
      endcase

      // 'p' (0x70)
      8'h70: case(row)
        0: char_rom = 8'b11111100;
        1: char_rom = 8'b11111110;
        2: char_rom = 8'b11000110;
        3: char_rom = 8'b11000110;
        4: char_rom = 8'b11111110;
        5: char_rom = 8'b11111100;
        6: char_rom = 8'b11000000;
        7: char_rom = 8'b11000000;
        8: char_rom = 8'b11000000;
        default: char_rom = 8'h00;
      endcase

      // 'T' (0x54)
      8'h54: case(row)
        0: char_rom = 8'b11111111;
        1: char_rom = 8'b11111111;
        2: char_rom = 8'b00011000;
        3: char_rom = 8'b00011000;
        4: char_rom = 8'b00011000;
        5: char_rom = 8'b00011000;
        6: char_rom = 8'b00011000;
        7: char_rom = 8'b00011000;
        default: char_rom = 8'h00;
      endcase

      // 'o' (0x6F)
      8'h6F: case(row)
        2: char_rom = 8'b00111000;
        3: char_rom = 8'b01111100;
        4: char_rom = 8'b11000110;
        5: char_rom = 8'b11000110;
        6: char_rom = 8'b11000110;
        7: char_rom = 8'b11000110;
        8: char_rom = 8'b01111100;
        9: char_rom = 8'b00111000;
        default: char_rom = 8'h00;
      endcase

      // 'j' (0x6A)
      8'h6A: case(row)
        2: char_rom = 8'b00001100;
        3: char_rom = 8'b00001100;
        4: char_rom = 8'b00001100;
        5: char_rom = 8'b00001100;
        6: char_rom = 8'b00001100;
        7: char_rom = 8'b11001100;
        8: char_rom = 8'b11111100;
        9: char_rom = 8'b00111000;
        default: char_rom = 8'h00;
      endcase

      // 'm' (0x6D)
      8'h6D: case(row)
        3: char_rom = 8'b11000110;
        4: char_rom = 8'b11101111;
        5: char_rom = 8'b11111111;
        6: char_rom = 8'b11010110;
        7: char_rom = 8'b11010110;
        8: char_rom = 8'b11000110;
        9: char_rom = 8'b11000110;
        default: char_rom = 8'h00;
      endcase

      // 'i' (0x69)
      8'h69: case(row)
        1: char_rom = 8'b00011000;
        2: char_rom = 8'b00111000;
        3: char_rom = 8'b00011000;
        4: char_rom = 8'b00011000;
        5: char_rom = 8'b00011000;
        6: char_rom = 8'b00011000;
        7: char_rom = 8'b00011000;
        8: char_rom = 8'b00111100;
        default: char_rom = 8'h00;
      endcase

      // 't' (0x74)
      8'h74: case(row)
        0: char_rom = 8'b00011000;
        1: char_rom = 8'b00011000;
        2: char_rom = 8'b00111000;
        3: char_rom = 8'b11111110;
        4: char_rom = 8'b11111110;
        5: char_rom = 8'b00111000;
        6: char_rom = 8'b00111000;
        7: char_rom = 8'b00011100;
        default: char_rom = 8'h00;
      endcase

      // Default case (empty space)
      default: char_rom = 8'h00;
    endcase
  endfunction

  // Character addressing
  wire [8:0] char_address = char_row_idx * CHARS_PER_LINE + char_col_idx;
  wire [7:0] current_char = char_address < CHARS_PER_LINE*NUM_LINES ?
                            text_memory[char_address] : 8'h00;

  // Get character data from ROM
  wire [7:0] char_data = char_rom(current_char, pixel_row[3:0]);

  // Generate RGB outputs (text color = white)
  assign R = char_in_range && char_data[pixel_col] ? 2'b11 : 2'b00;
  assign G = char_in_range && char_data[pixel_col] ? 2'b11 : 2'b00;
  assign B = char_in_range && char_data[pixel_col] ? 2'b11 : 2'b00;

  hvsync_generator hvsync_gen(
    .clk(clk),
    .reset(~rst_n),
    .hsync(hsync),
    .vsync(vsync),
    .display_on(video_active),
    .hpos(pix_x),
    .vpos(pix_y)
  );

endmodule