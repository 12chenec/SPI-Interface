module Slave (
    input             s_rst,
    
    // spi mode parameters
    input             s_cpol,
    input             s_cpha,
    
    // spi interface
    input             s_sclk,
    input             s_cs,
    input             s_mosi,
    output reg        s_miso
    );
    
    // states
    reg [2:0] s_state, s_next_state;
    localparam IDLE =   3'd0;
    localparam ADDR =   3'd1;
    localparam READ =   3'd2;
    localparam WRITE =  3'd3;
    
    // signals from datapath
    reg s_byte_done;
    reg s_addr_valid;
    reg s_rw;
    // signals from controller
    wire s_w_en;
    wire s_miso_sel;
    wire s_drive_shift_load;
    
    // datapath registers
    reg [7:0] s_sample_shift;
    reg [7:0] s_drive_shift;
    reg [3:0] s_bit_cnt;
    reg [6:0] s_r_addr;
    reg [6:0] s_transfer_addr;
    reg [6:0] s_w_addr;
    wire [7:0] s_r_data;

    // internal clock
    assign s_sclk_in = (s_cpol ^ s_cpha) ? ~s_sclk : s_sclk;
    
    // ===== REGISTER FILE =====
    
    localparam REG_DEPTH = 7'd127;
    // 128-entry 8-bit register file
    RegisterFile s_rfile (
        .rf_clk    (s_sclk),
        .rf_rst    (s_rst),
        
        .rf_r_addr (s_r_addr),
        .rf_w_addr (s_w_addr),
        .rf_w_data (s_sample_shift),
        .rf_w_en   (s_w_en),
        .rf_r_data (s_r_data)
    );
    
    // ===== DATAPATH =====
    
    // SHIFT REGISTERS
    // sample_shift
    always @(posedge s_sclk_in or posedge s_rst) begin
        if (s_rst || s_cs) begin
            s_sample_shift <= 8'd0;
        end
        else begin
            s_sample_shift <= {s_sample_shift [6:0], s_mosi};
        end
    end
    
    // drive_shift
    always @(negedge s_sclk_in or posedge s_rst or posedge s_cs) begin
        if (s_rst || s_cs) begin
            s_drive_shift <= 8'd0;
        end
        else if (s_drive_shift_load) begin
            s_drive_shift <= s_r_data;
        end
        else begin
            s_drive_shift <= {s_drive_shift [6:0], 1'b0};
        end
    end
    
    // rw
    always @(posedge s_sclk_in or posedge s_rst) begin
        if (s_rst) begin
            s_rw <= 0;
        end
        else if (s_state == IDLE && s_next_state == ADDR) begin
            s_rw <= s_mosi;
        end
    end
    
    // ADDRESS
    // r_addr
    always @(*) begin
        if (s_rst || s_state == IDLE) begin
            s_r_addr = 7'd0;
        end
        else if (s_rw && s_state == ADDR && s_byte_done) begin
            s_r_addr = s_sample_shift [6:0];
        end
        else begin
            s_r_addr = s_transfer_addr;
        end
    end
    
    // transfer_addr
    always @(negedge s_sclk_in or posedge s_rst or posedge s_cs) begin
        if (s_rst || s_state == IDLE || s_cs) begin
            s_transfer_addr <= 7'd0;
        end
        else begin
            if (s_state == ADDR && s_next_state == READ) begin
                s_transfer_addr <= s_sample_shift[6:0];
            end
            else if (s_state == READ && s_bit_cnt == 6) begin
                s_transfer_addr <= s_transfer_addr + 7'd1;
            end
        end
    end
    
    // w_addr
    always @(posedge s_sclk_in or posedge s_rst or posedge s_cs) begin
        if (s_rst || s_state == IDLE || s_cs) begin
            s_w_addr <= 7'd0;
        end
        else if (s_state == ADDR && s_next_state == WRITE) begin
            s_w_addr <= s_sample_shift [6:0];
        end
        else if (s_state == WRITE && s_byte_done) begin
            s_w_addr <= s_w_addr + 7'd1;
        end
    end
    
    // addr_valid
    always @(*) begin
        if (s_rst) begin
            s_addr_valid = 0;
        end
        else if (s_rw) begin
            s_addr_valid = (s_r_addr < REG_DEPTH);
        end
        else begin
            s_addr_valid = (s_w_addr < REG_DEPTH);
        end
    end
    

    // MISO
    always @(*) begin
        if (s_rst) begin
            s_miso = 0;
        end
        else if (s_miso_sel) begin
            s_miso = s_drive_shift[7];
        end
        else begin
            s_miso = 0;
        end
    end
    
    // COUNTER
    // bit_cnt
    always @(posedge s_sclk_in or posedge s_rst) begin
        if (s_rst || s_state == IDLE) begin
            s_bit_cnt <= 4'd0;
        end
        else if (!s_byte_done) begin
            s_bit_cnt <= s_bit_cnt + 4'd1;
        end
        else begin
            s_bit_cnt <= 4'd0;
        end
    end
    
    // byte_done
    always @(*) begin
        if (s_rst || s_cs) begin
            s_byte_done = 0;
        end
        else if (s_bit_cnt == 7) begin
            s_byte_done  = 1;
        end
        else begin
            s_byte_done = 0;
        end
    end
    
    // ===== CONTROLLER =====
    
    assign s_w_en = (s_state == WRITE && s_byte_done);
 
    assign s_miso_sel = (s_state == READ);
    
    assign s_drive_shift_load = ((s_state == ADDR && s_next_state == READ && s_byte_done)
                                 || (s_state == READ && s_byte_done));

    // current state logic
    always @(posedge s_sclk_in or posedge s_rst or posedge s_cs) begin
        if (s_rst || s_cs) begin
            s_state <= IDLE;
        end
        else begin
            s_state <= s_next_state;
        end
    end
    
    // next_state logic
    always @(*) begin
        if (s_rst) begin
            s_next_state = IDLE;
        end
        else begin
            case (s_state)
                IDLE: begin
                    if (!s_cs) begin
                        s_next_state = ADDR;
                    end
                    else begin
                        s_next_state = IDLE;
                    end
                end
                ADDR: begin
                    if (s_cs) begin
                        s_next_state = IDLE;
                    end
                    else if (s_byte_done && s_addr_valid) begin
                        if (s_rw) begin
                            s_next_state = READ;
                        end
                        else begin
                            s_next_state = WRITE;
                        end
                    end
                    else begin
                        s_next_state = ADDR;
                    end
                end
                READ: begin
                    if (!s_addr_valid || s_cs) begin
                        s_next_state = IDLE;
                    end
                    else begin
                        s_next_state = READ;
                    end
                end
                WRITE: begin
                    if (!s_addr_valid || s_cs) begin
                        s_next_state = IDLE;
                    end
                    else begin
                        s_next_state = WRITE;
                    end
                end
            endcase
        end
    end
endmodule
