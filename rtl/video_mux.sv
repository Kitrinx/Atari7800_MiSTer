// k7800 (c) by Jamie Blanks

// k7800 is licensed under a
// Creative Commons Attribution-NonCommercial 4.0 International License.

// You should have received a copy of the license along with this
// work. If not, see http://creativecommons.org/licenses/by-nc/4.0/.


module video_mux
(
	input  logic       clk_sys,
	input  logic [3:0] maria_luma,
	input  logic [3:0] maria_chroma,
	input  logic       maria_hblank,
	input  logic       maria_vblank,
	input  logic       maria_hsync,
	input  logic       maria_vsync,
	input  logic       maria_pix_ce,

	input  logic [2:0] tia_luma,
	input  logic [3:0] tia_chroma,
	input  logic       tia_hblank,
	input  logic       tia_vblank,
	input  logic       tia_hsync,
	input  logic       tia_vsync,
	input  logic       tia_pix_ce,
 
	input  logic       is_maria,
	input  logic [1:0] pal_temp,
	input  logic       is_PAL,

	output logic       hblank,
	output logic       vblank,
	output logic       hsync,
	output logic       vsync,
	output logic [7:0] red,
	output logic [7:0] green,
	output logic [7:0] blue,
	output logic       pix_ce
);

logic [23:0] out_color, nwarm_color, ncool_color, nhot_color,
	pwarm_color, pcool_color, phot_color;

// If luma alternates intensity at 320 pixels per line:
// If colorburst is low, it will manifest as +blue
// If colorburst is high, it will manifest as +yellow
// Luma will become filtered and blend
// Chroma will end up blending more smoothly

wire pix_ce_immediate = is_maria ? maria_pix_ce : tia_pix_ce;
logic pix_ce_delayed;
logic [7:0] yuv_index;

always_comb begin
	out_color = nwarm_color;

	yuv_index = {maria_chroma, maria_luma};
	if (~is_maria)
		yuv_index = {tia_chroma, {tia_luma, 1'b0}};

	case ({is_PAL, pal_temp})
		0: out_color = nwarm_color;
		1: out_color = ncool_color;
		2: out_color = nhot_color;
		4: out_color = pwarm_color;
		5: out_color = pcool_color;
		6: out_color = phot_color;
	 default: ;
	endcase
end

always @(posedge clk_sys) begin
	pix_ce_delayed <= pix_ce_immediate;
	pix_ce <= pix_ce_delayed;
	if (pix_ce_delayed) begin
		{red, green, blue} <= out_color;
		vsync <= is_maria ? maria_vsync : tia_vsync;
		vblank <= is_maria ? maria_vblank : tia_vblank;
		hsync <= is_maria ? maria_hsync : tia_hsync;
		hblank <= is_maria ? maria_hblank : tia_hblank;
	end
end

// Palletes research by Robert Tuccitto represents three different console temperatures for each of
// the two video standards. Because the 7800 dramatically shifted it's UV color angle as it warmed
// up, having a range of options for whatever the game developer happened to optimize towards is a
// good idea. According to Robert, the three temperatures represent the following chroma shifts:
// warm is 26.7 degrees, cool is 25.7 degrees, and hot is 27.7 degrees.
// Last updated 3/13/2021

spram #(
	.addr_width(8),
	.data_width(24),
	.mem_init_file("rtl/palettes/NWARM.mif")
) nwarm
(
	.clock   (clk_sys),
	.address (yuv_index),
	.q       (nwarm_color)
);

spram #(
	.addr_width(8),
	.data_width(24),
	.mem_init_file("rtl/palettes/NCOOL.mif")
) ncool
(
	.clock   (clk_sys),
	.address (yuv_index),
	.q       (ncool_color)
);

spram #(
	.addr_width(8),
	.data_width(24),
	.mem_init_file("rtl/palettes/NHOT.mif")
) nhot
(
	.clock   (clk_sys),
	.address (yuv_index),
	.q       (nhot_color)
);

spram #(
	.addr_width(8),
	.data_width(24),
	.mem_init_file("rtl/palettes/PWARM.mif")
) pwarm
(
	.clock   (clk_sys),
	.address (yuv_index),
	.q       (pwarm_color)
);

spram #(
	.addr_width(8),
	.data_width(24),
	.mem_init_file("rtl/palettes/PCOOL.mif")
) pcool
(
	.clock   (clk_sys),
	.address (yuv_index),
	.q       (pcool_color)
);

spram #(
	.addr_width(8),
	.data_width(24),
	.mem_init_file("rtl/palettes/PHOT.mif")
) phot
(
	.clock   (clk_sys),
	.address (yuv_index),
	.q       (phot_color)
);

endmodule