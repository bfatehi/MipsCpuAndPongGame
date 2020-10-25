//////////////////////////////////////////////////////////////////////////////////
//
// Montek Singh
// 11/3/2017 
//
//////////////////////////////////////////////////////////////////////////////////

`timescale 1ns / 1ps
`default_nettype none

module top #(
    //parameter imem_init="imem_screentest.mem", 	        // use this line for synthesis/board deployment
    parameter imem_init="imem_screentest_nopause.mem",  // use this line for simulation/testing
    parameter dmem_init="dmem_screentest.mem",          // file to initialize data memory
    parameter smem_init="smem_screentest.mem", 	        // file to initialize screen memory
    parameter bmem_init="bmem_screentest.mem" 	        // file to initialize bitmap memory
)(
    input wire clk, reset
    ...						// add I/O signals here
    ...						// incl. VGA signals
);
   wire [31:0] pc, instr, mem_readdata, mem_writedata, mem_addr;
   wire mem_wr;
   wire clk100, clk50, clk25, clk12;

   wire [10:0] smem_addr;
   wire [3:0] charcode;
   wire [31:0] keyb_char;
   wire enable = 1'b1;			// we will use this later for debugging

   // Uncomment *only* one of the following two lines:
   //    when synthesizing, use the first line
   //    when simulating, get rid of the clock divider, and use the second line
   //
   //clockdivider_Nexys4 clkdv(clk, clk100, clk50, clk25, clk12);   // use this line for synthesis/board deployment
   assign clk100=clk; assign clk50=clk; assign clk25=clk; assign clk12=clk;  // use this line for simulation/testing

   // For synthesis:  use an appropriate clock frequency(ies) below
   //   clk100 will work for hardly anyone
   //   clk50 or clk 25 should work for the vast majority
   //   clk12 should work for everyone!  I'd say use this!
   //
   // Use the same clock frequency for the MIPS and data memory/memIO modules
   // The VGA display and 8-digit display should keep the 100 MHz clock.
   // For example:

   mips mips(clk12, reset, enable, pc, ... );
   imem #(.Nloc(128), .Dbits(32), .initfile(imem_init)) imem(pc[31:0], instr);
   memIO #(.Nloc(16), .Dbits(32), .dmem_init(dmem_init), .smem_init(smem_init)) memIO(clk12, ... );
   vgadisplaydriver #(bmem_init) display(clk100, ... );

endmodule
