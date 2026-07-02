// ============================================================================
// Project: AHB-to-Wishbone Bridge Verification
// File: ahb2wb_bridge.sv
// Author: [Your Name]
// Date: [Current Date]
// Description: RTL implementation of an AHB-to-Wishbone bridge. Translates 
//              pipelined AHB transfers into flat Wishbone B.3 transfers.
//              Utilizes HREADYOUT to stall AHB during Wishbone wait states.
// ============================================================================

module ahb2wb_bridge (
    // --- AHB Slave Interface ---
    input  logic         HCLK, 
    input  logic         HRESETn, 
    input  logic         HSEL, 
    input  logic         HREADY, 
    input  logic         HWRITE,
    input  logic [31:0]  HADDR, 
    input  logic [31:0]  HWDATA,
    input  logic [1:0]   HTRANS, 
    input  logic [2:0]   HSIZE,
    output logic         HREADYOUT, 
    output logic [31:0]  HRDATA, 
    output logic [1:0]   HRESP,

    // --- Wishbone Master Interface ---
    output logic         CYC_O, 
    output logic         STB_O, 
    output logic         WE_O, 
    output logic [31:0]  ADR_O, 
    output logic [31:0]  DAT_O, 
    output logic [3:0]   SEL_O,
    input  logic [31:0]  DAT_I, 
    input  logic         ACK_I, 
    input  logic         ERR_I
);

    // FSM State Encoding
    typedef enum logic [2:0] {IDLE, LATCH_ADDR, WB_ACTIVE, WAIT_ACK, COMPLETE} state_t;
    state_t state, next_state;
    
    // Internal Latches for AHB Address Phase Data
    logic [31:0] latched_addr;
    logic        latched_write;
    logic [2:0]  latched_size;

    // Stall AHB bus when FSM is actively processing a Wishbone transfer
    assign HREADYOUT = (state == IDLE || state == COMPLETE);
    assign HRESP     = ERR_I ? 2'b01 : 2'b00;

    // FSM: Sequential State Register
    always_ff @(posedge HCLK or negedge HRESETn) begin
        if (!HRESETn) state <= IDLE;
        else          state <= next_state;
    end

    // FSM: Combinational Next-State Logic
    always_comb begin
        next_state = state;
        case (state)
            IDLE:       next_state = (HSEL && HTRANS[1]) ? LATCH_ADDR : IDLE; // Wait for NONSEQ/SEQ
            LATCH_ADDR: next_state = WB_ACTIVE;                               // Transition to active phase
            WB_ACTIVE:  next_state = WAIT_ACK;                                // Wait for WB slave response
            WAIT_ACK:   next_state = (ACK_I || ERR_I) ? COMPLETE : WAIT_ACK;  // Handshake complete
            COMPLETE:   next_state = IDLE;                                    // Recover and ready next cycle
            default:    next_state = IDLE;
        endcase
    end

    // Latch AHB Address Phase inputs to align with AHB Data Phase
    always_ff @(posedge HCLK) begin
        if (state == LATCH_ADDR) begin
            latched_addr  <= HADDR;
            latched_write <= HWRITE;
            latched_size  <= HSIZE;
        end
    end

    // Decode AHB HSIZE into Wishbone SEL_O (Byte Lane Enables)
    always_comb begin
        unique case (latched_size)
            3'b000:  SEL_O = 4'b0001 << latched_addr[1:0];      // 8-bit Byte
            3'b001:  SEL_O = 4'b0011 << {latched_addr[1], 1'b0}; // 16-bit Half-Word
            default: SEL_O = 4'b1111;                            // 32-bit Word
        endcase
    end

    // Map outputs to Wishbone interface
    assign {CYC_O, STB_O} = (state == WB_ACTIVE || state == WAIT_ACK) ? 2'b11 : 2'b00;
    assign ADR_O  = latched_addr;
    assign WE_O   = latched_write;
    assign DAT_O  = HWDATA;
    assign HRDATA = DAT_I;

endmodule