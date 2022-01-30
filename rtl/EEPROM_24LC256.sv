// 24C01, 24C02 EEPROM support
// by GreyRogue for NES MiSTer

module EEPROM_24LC0X
(
	input                       clk,
	input                       ce,
	input                       reset,
	input                       SCL,            // Serial Clock
	input                       SDA_in,         // Serial Data (same pin as below, split for convenience)
	output  reg                 SDA_out,        // Serial Data (same pin as above, split for convenience)
	input   [2:0]               E_id,           // Chip Enable ID aka A0-A2
	input                       WC_n,           // ~Write Control
	input   [7:0]               data_from_ram,  // Data read from RAM
	output  [7:0]               data_to_ram,    // Data written to RAM
	output  [ADDR_WIDTH-1:0]    ram_addr,       // RAM Address
	output  reg                 ram_read,       // RAM read
	output  reg                 ram_write,      // RAM write
	input                       ram_done        // RAM access done
);

	parameter ADDR_WIDTH = 15;
	parameter PAGE_WIDTH = 6;

	typedef enum bit [2:0] {
		STATE_STANDBY,      // Do nothing
		STATE_TEST,         // ???
		STATE_ADDRESS,      // Set the address
		STATE_WRITE,        // Write address + 1 byte
		STATE_READ          // Read one byte at current address
	} mystate;

	mystate state;
	
	reg [9:0] command;
	reg [31:0] address, address_buffer;
	reg [8:0] data; // 8 bits data, plus ack bit
	reg last_SCL;
	reg last_SDA;
	reg [7:0] a_bytes_left;
	
	integer byte_w = (ADDR_WIDTH >> 2'd3) + (|ADDR_WIDTH[2:0] ? 1'd1 : 1'd0);
	wire [7:0] address_bytes = byte_w[7:0];
	
	always @(posedge clk) if (reset) begin
		state <= STATE_STANDBY;
		command <= 0;
		last_SCL <= 0;
		last_SDA <= 0;
		SDA_out <= 1;  //NoAck
		ram_read <= 0;
		address <= '0;
		ram_write <= 0;
	end else if (ce) begin
		last_SCL <= SCL;
		last_SDA <= SDA_in;
		if (ram_write && ram_done) begin
			ram_write <= 0;
			address[PAGE_WIDTH-1:0] <= address[PAGE_WIDTH-1:0] + 1'b1;
		end
		if (ram_read && ram_done) begin
			ram_read <= 0;
			data <= {data_from_ram, 1'b1};  //NoAck at end
			address <= address + 8'b1;
		end
		if (SCL && last_SCL && !SDA_in && last_SDA) begin
			state <= STATE_TEST;
			command <= 10'd2;
		end else if (SCL && last_SCL && SDA_in && !last_SDA) begin
			state <= STATE_STANDBY;
			command <= 10'd0;
		end else if (state == STATE_STANDBY) begin
			// Do nothing
		end else if (SCL && !last_SCL) begin
			command <= {command[8:0], SDA_in };
		end else if (!SCL && last_SCL) begin
			SDA_out <= 1;  //NoAck
			if (state == STATE_READ) begin
				SDA_out <= data[8];
				if (!ram_read) begin
					data[8:1] <= data[7:0];
				end
			end
			if (command[9]) begin
				if (state == STATE_TEST) begin
					a_bytes_left <= address_bytes;
					if (command[7:1] == {4'b1010, E_id}) begin
						if (command[0]) begin
							state <= STATE_READ;
							ram_read <= 1;
						end else begin
							state <= STATE_ADDRESS;
						end
						SDA_out <= 0; //Ack
					end
					command <= 10'd1;
				end else if (state == STATE_ADDRESS) begin
					a_bytes_left <= a_bytes_left - 1'd1;
					if (a_bytes_left == 1) begin
						state <= STATE_WRITE;
						address <= (address_buffer | command[7:0]) & {ADDR_WIDTH-1{1'b1}};
					end else begin
						address_buffer[{a_bytes_left-1'b1, 3'b000}+:8] <= command[7:0];
					end
					SDA_out <= 0; //Ack
					command <= 10'd1;
				end else if (state == STATE_WRITE) begin
					data <= {command[7:0], 1'b0};
					if (!WC_n) begin
						ram_write <= 1;
						SDA_out <= 0; //Ack
					end
					command <= 10'd1;
				end else if (state == STATE_READ) begin
					ram_read <= 1;
					 SDA_out <= 1; //NoAck
					command <= 10'd1;
				end
			end
		end
	end
	
	assign ram_addr = address[ADDR_WIDTH-1:0];
	assign data_to_ram = data[8:1];

endmodule
