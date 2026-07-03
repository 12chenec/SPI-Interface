module Slave(
    input s_rst,
   
    // spi mode parameters
    input s_cpol,
    input s_cpha,
   
    // spi interface
    input s_sclk,
    input s_cs,
    input s_mosi,
    output reg s_miso,
   
    // testbench
    output reg [6:0] s_addr,
    output reg [7:0] s_w_data
);
 
    // clock
    wire s_in_clk;
    assign s_in_clk = (s_cpol ^ s_cpha) ? ~s_sclk : s_sclk; // for Modes 1 and 2, invert clock to simulate negedge
   
    // internal regs
    reg [3:0] s_bitcount;
    reg [2:0] s_state, s_next_state;
   
    // state names
    localparam IDLE = 3'd0;
    localparam ADDR = 3'd1;
    localparam READ = 3'd2;
    localparam WRITE = 3'd3;
 
    // data registers
    reg s_rw;
    reg [7:0] s_r_data;
 
    // output logic
    always @(*) begin
        case (s_state)
            READ:    s_miso = s_r_data[7];
            default: s_miso = 0;
        endcase
    end
 
    // next state logic
    always @(*) begin
        case (s_state)
            IDLE:   s_next_state = s_cs ? IDLE : ADDR;
            ADDR:   s_next_state = (s_bitcount == 7) ? (s_rw ? READ : WRITE) : ADDR;
            READ:   s_next_state = (s_bitcount == 15) ? IDLE : READ;
            WRITE:  s_next_state = (s_bitcount == 15) ? IDLE : WRITE;
            default: s_next_state = IDLE;
        endcase
    end
 
    // negedge state updates
    always @(negedge s_in_clk or posedge s_rst) begin
        if (s_rst) begin
            s_state <= IDLE;
        end
        else if (s_cs)
            s_state <= IDLE;
        else
            s_state <= s_next_state;
    end
   
    // negedge s_r_data update
    always @(negedge s_in_clk or posedge s_rst) begin
        if (s_rst) begin
            s_r_data <= 8'h77; // TEMPORARY
        end else begin
            if (s_state == READ)
                s_r_data <= {s_r_data[6:0], 1'b0};
        end
    end
 
    // negedge bitcount update
    always @(negedge s_in_clk or posedge s_rst) begin
        if (s_rst) begin
            s_bitcount <= 0;
        end else begin
            if (s_state != IDLE)
                s_bitcount <= s_bitcount + 1;
            else
                s_bitcount <= 0;
        end
    end
   
    // ===== POSEDGE SAMPLING ==========================
 
    // posedge sample RW bit from instruction
    always @(posedge s_in_clk or posedge s_rst) begin
        if (s_rst) begin
            s_rw <= 0;
        end else begin
            if (s_state == ADDR && s_bitcount == 0)
                s_rw <= s_mosi;
        end
    end
   
    // posedge sample address bits from instruction
    always @(posedge s_in_clk or posedge s_rst) begin
        if (s_rst) begin
            s_addr <= 0;
        end else begin
            if (s_state == ADDR && s_bitcount != 0)
                s_addr <= {s_addr[5:0], s_mosi};
        end
    end
 
    // sequential state + counter update
    always @(posedge s_in_clk or posedge s_rst) begin
        if (s_rst) begin
            s_w_data <= 0;
        end else begin
            if (s_state == WRITE)
                s_w_data <= {s_w_data[6:0], s_mosi};
        end
    end
   
endmodule
