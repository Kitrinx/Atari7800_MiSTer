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
	input  logic       pal_load,
	input  logic [7:0] pal_data,
	input  logic [9:0] pal_addr,
	input  logic       pal_wr,
	input  logic       blend,

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
	pwarm_color, pcool_color, phot_color, custom_color, old_color;

// If luma alternates intensity at 320 pixels per line:
// If colorburst is low, it will manifest as +blue
// If colorburst is high, it will manifest as +yellow
// Luma will become filtered and blend
// Chroma will end up blending more smoothly

wire pix_ce_immediate = is_maria ? maria_pix_ce : tia_pix_ce;
logic pix_ce_delayed;
logic [7:0] yuv_index;
logic [7:0][1:0] last_color;
logic [15:0] frame_ptr;
logic [7:0] frame_data;
logic [3:0] tia_chroma_region;

spram #(.addr_width(16), .mem_name("FBLN")) ram0
(
	.clock          (clk_sys),
	.address        (frame_ptr),
	.data           ({tia_vblank, yuv_index[7:1]}),
	.wren           (pix_ce_immediate && ~is_maria),
	.q              (frame_data)
);


// PAL 2600 $0x = PAL 7800 $0x
// PAL 2600 $1x = PAL 7800 $0x
// PAL 2600 $2x = PAL 7800 $2x
// PAL 2600 $3x = PAL 7800 $Dx
// PAL 2600 $4x = PAL 7800 $3x
// PAL 2600 $5x = PAL 7800 $Cx
// PAL 2600 $6x = PAL 7800 $4x
// PAL 2600 $7x = PAL 7800 $Bx
// PAL 2600 $8x = PAL 7800 $5x
// PAL 2600 $9x = PAL 7800 $Ax
// PAL 2600 $Ax = PAL 7800 $6x
// PAL 2600 $Bx = PAL 7800 $9x
// PAL 2600 $Cx = PAL 7800 $7x
// PAL 2600 $Dx = PAL 7800 $8x
// PAL 2600 $Ex = PAL 7800 $0x
// PAL 2600 $Fx = PAL 7800 $0x

wire [3:0] pal_2600_chroma[16] = '{
	4'h0, 4'h0, 4'h2, 4'hD,
	4'h3, 4'hc, 4'h4, 4'hb,
	4'h5, 4'ha, 4'h6, 4'h9,
	4'h7, 4'h8, 4'h0, 4'h0
};

always_comb begin
	tia_chroma_region = is_PAL ? pal_2600_chroma[tia_chroma] : tia_chroma;
	out_color = nwarm_color;

	yuv_index = {maria_chroma, maria_luma};
	if (~is_maria)
		yuv_index = ~pix_ce_immediate ? {frame_data[6:0], 1'b0} : {tia_chroma_region, {tia_luma, 1'b0}};

	case ({is_PAL, pal_temp})
		0: out_color = nwarm_color;
		1: out_color = ncool_color;
		2: out_color = nhot_color;
		3: out_color = custom_color;
		4: out_color = pwarm_color;
		5: out_color = pcool_color;
		6: out_color = phot_color;
		7: out_color = custom_color;
	 default: ;
	endcase

end


// wire signed [6:0] old_diff = $signed{1'b0, last_color[0][3:0]} - $signed{1'b0, last_color[1][3:0]};
// wire signed [6:0] new_diff = $signed{1'b0, last_color[0][3:0]} - $signed{1'b0, yuv_index[3:0]};
// wire signed [6:0] old_abs = 

reg [7:0] last_frame_data;
logic [15:0] pal_buff;
logic [7:0] pal_mux_addr;
logic [1:0] pal_count = 0;
logic old_vblank;

wire [23:0] blend_color = {
	{1'b0, old_color[23:17]} + out_color[23:17],
	{1'b0, old_color[15:9]} + out_color[15:9],
	{1'b0, old_color[7:1]} + out_color[7:1]
};

always @(posedge clk_sys) begin
	if (pal_load) begin
		if (pal_wr) begin
			pal_count <= pal_count == 2 ? 2'd0 : pal_count + 1'd1;
			case (pal_count)
				0: pal_buff[15:8] <= pal_data;
				1: pal_buff[7:0] <= pal_data;
				2: pal_mux_addr <= pal_mux_addr + 1'd1;
			endcase
		end
	end else begin
		pal_mux_addr <= 0;
		pal_count <= 0;
	end
	if (pix_ce_immediate) begin
		if (~tia_vblank)
			frame_ptr <= frame_ptr + 1'd1;
		old_color <= out_color;
		old_vblank <= frame_data[7];
	end

	if (tia_vsync)
		frame_ptr <= 0;
	pix_ce_delayed <= pix_ce_immediate;
	pix_ce <= pix_ce_delayed;
	if (pix_ce_delayed) begin
		last_color <= {last_color[0], yuv_index};
		{red, green, blue} <= (blend && ~is_maria) ? blend_color : out_color;
		vsync <= is_maria ? maria_vsync : tia_vsync;
		vblank <= is_maria ? maria_vblank : (blend ? (old_vblank | tia_vblank) : tia_vblank);
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

spram #(
	.addr_width(8),
	.data_width(24),
	.mem_init_file("rtl/palettes/PHOT.mif")
) custom
(
	.clock   (clk_sys),
	.data    ({pal_buff, pal_data}),
	.wren    (pal_load && pal_wr && (pal_count == 2)),
	.address (pal_load ? pal_mux_addr : yuv_index),
	.q       (custom_color)
);


endmodule

//     red   gree  blue
// 0 | 4'h7, 4'h5, 4'h0
// 1 | 4'h5, 4'h6, 4'h0 // yellow-ish
// 2 | 4'h3, 4'h7, 4'h0 // green-ish
// 3 | 4'h2, 4'h8, 4'h1 // green peak
// 4 | 4'h1, 4'h7, 4'h3
// 5 | 4'h1, 4'h7, 4'h7
// 6 | 4'h2, 4'h6, 4'ha
// 7 | 4'h3, 4'h5, 4'hc 
// 8 | 4'h5, 4'h4, 4'hc // blue peak?
// 9 | 4'h7, 4'h3, 4'hc // magenta-ish
// a | 4'h8, 4'h3, 4'ha 
// b | 4'h9, 4'h3, 4'h7 
// c | 4'h9, 4'h3, 4'h4 // red peak
// d | 4'h8, 4'h4, 4'h1 
// e | 4'h7, 4'h5, 4'h0
// f | 4'h5, 4'h5, 4'h5