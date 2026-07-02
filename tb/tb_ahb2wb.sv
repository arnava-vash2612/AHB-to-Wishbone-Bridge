// ============================================================================
// Project: AHB-to-Wishbone Bridge Verification
// File: tb_ahb2wb.sv
// Author: [Your Name]
// Date: [Current Date]
// Description: Testbench integrating the bridge and dummy slave. Verifies 
//              protocol translation and AHB HREADYOUT stalling behavior.
// ============================================================================

module tb_ahb2wb;

    // Clock and Reset Generation
    logic HCLK = 0, HRESETn = 0;
    always #5 HCLK = ~HCLK;

    // AHB Signals - Initialized to 0 to prevent X-propagation logic failures
    logic        HSEL   = 0;
    logic        HREADY = 1;
    logic        HWRITE = 0;
    logic [31:0] HADDR  = 0;
    logic [31:0] HWDATA = 0;
    logic [1:0]  HTRANS = 0;
    logic [2:0]  HSIZE  = 0;
    
    // AHB Bridge Outputs
    logic        HREADYOUT;
    logic [31:0] HRDATA;
    logic [1:0]  HRESP;

    // Wishbone Signals
    logic        CYC_O, STB_O, WE_O, ACK_I, ERR_I;
    logic [31:0] ADR_O, DAT_O, DAT_I;
    logic [3:0]  SEL_O;

    // Instantiate the Device Under Test (Bridge)
    ahb2wb_bridge bridge_dut (.*);

    // Instantiate the Dummy Slave Target
    wb_dummy_slave slave_dut (
        .CLK_I(HCLK), 
        .RST_I(~HRESETn), 
        .CYC_I(CYC_O), 
        .STB_I(STB_O), 
        .ACK_I(ACK_I)
    );
    
    // Tie off unused slave inputs to prevent 'X' logic failures during simulation
    assign DAT_I = 32'h00000000;
    assign ERR_I = 1'b0;

    initial begin
        // Enable waveform dumping for EDA Playground (EPWave)
        $dumpfile("dump.vcd"); 
        $dumpvars(0, tb_ahb2wb);
        
        // Assert Reset to initialize system
        #15 HRESETn = 1;
        @(posedge HCLK);
        
        // Stimulus: Initiate AHB Write NONSEQ Transfer
        @(posedge HCLK);
        HSEL   = 1; 
        HTRANS = 2'b10;      // NONSEQ (Initiator)
        HADDR  = 32'h1000; 
        HWRITE = 1;          // Write Mode
        HSIZE  = 3'b010;     // 32-bit Word size
        HWDATA = 32'hA5A5A5A5;
        
        // Return AHB bus to IDLE after initiating the transfer
        @(posedge HCLK);
        HSEL   = 0;
        HTRANS = 2'b00;      // IDLE
        
        // Allow enough time for the FSM to process wait-states and finish
        #100 $finish;
    end

endmodule