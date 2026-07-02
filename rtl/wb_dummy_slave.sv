module wb_dummy_slave (
    input  logic CLK_I, 
    input  logic RST_I, 
    input  logic CYC_I, 
    input  logic STB_I, 
    output logic ACK_I
);
    logic [1:0] count;

    always_ff @(posedge CLK_I) begin
        if (RST_I || !STB_I) begin
            count <= 0;
        end else if (CYC_I && STB_I && count < 2) begin
            count <= count + 1;
        end
    end
    
    assign ACK_I = (count == 2);

endmodule