module RegisterFile
    #(
        parameter N_ELEMENTS = 128, // Number of Memory Elements
        parameter ADDR_WIDTH = 7,   // Address Width (bits)
        parameter DATA_WIDTH = 8   // Data Width (bits)
    ) (
        // Clock + Reset
        input rf_clk,
        input rf_rst,
        
        // Read Address
        input [ADDR_WIDTH-1:0] rf_r_addr,
        
        // Write Address, Data Channel
        input [ADDR_WIDTH-1:0] rf_w_addr,
        input [DATA_WIDTH-1:0] rf_w_data,
        input                  rf_w_en,
        
        // Read Data Channel
        output [DATA_WIDTH-1:0] rf_r_data
    );
    
    // Memory Unit
    reg [DATA_WIDTH-1:0] rfile[N_ELEMENTS-1:0];
    
    // Continuous Read
    assign rf_r_data = rfile[rf_r_addr];
    
    // Synchronous Reset + Write
    genvar i;
    generate
        for (i = 0; i < N_ELEMENTS; i = i + 1) begin: wport
            always @(negedge rf_clk or posedge rf_rst) begin
                if (rf_rst) begin
                    rfile[i] <= i;
                end
                else if (rf_w_en && rf_w_addr == i) begin
                    rfile[i] <= rf_w_data;
                end
            end
        end
    endgenerate
    
endmodule
