`timescale 1ns / 1ps


module cpu_wrapper( clk, reset, AB, DB_IN, DB_OUT, RD, IRQ, NMI, RDY, halt_b);

input clk;              // CPU clock
input reset;            // reset signal
output [15:0] AB;       // address bus
input  [7:0] DB_IN;     // data in, 
output [7:0] DB_OUT;    // data_out, 
output RD;              // read enable
input IRQ;              // interrupt request
input NMI;              // non-maskable interrupt request
input RDY;              // Ready signal. Pauses CPU when RDY=0
input halt_b;

wire rdy_in;
wire WE_OUT;
reg holding;
wire [7:0] DB_hold;

cpu core(.clk(clk),.reset(reset),.AB(AB),.DI(DB_hold),.DO(DB_OUT),.WE(WE_OUT),.IRQ(IRQ),.NMI(NMI),.RDY(rdy_in));

assign RD = ~WE;
assign WE = WE_OUT & halt_b;
assign rdy_in = RDY & halt_b;
assign DB_hold = (holding) ? DB_hold : DB_IN;

always_ff @(holding, DB_IN)

always @(posedge clk, posedge reset, negedge rdy_in) begin
    if (reset)
        holding <= 1'b0;
    else if (~rdy_in) 
        holding <= 1'b1;
    else
        holding <= 1'b0;
end

endmodule: cpu_wrapper
