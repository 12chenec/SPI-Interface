module Master (
    input               m_hclk,
    input               m_rst,
    input               m_en,
    
    // testbench to rd_wr_shift
    input               m_rw,
    input       [6:0]   m_addr,
    input       [31:0]  m_w_data,
    // testbench to data_rem
    input       [3:0]   m_transfer_len,
    // tesetbench to sclk_gen
    input       [2:0]   m_clk_div_val,
    
    // SPI modes
    input               m_cpol,
    input               m_cpha,
    
    // SPI interface
    input               m_miso,
    output reg          m_sclk,
    output reg          m_cs,
    output reg          m_mosi
    );
    
    // states
    reg [1:0] m_state, m_next_state;
    localparam IDLE =   2'd0;
    localparam ADDR =   2'd1;
    localparam READ =   2'd2;
    localparam WRITE =  2'd3;
    
    // signals from datapath
    // bit_cnt
    reg m_byte_done;
    // data_rem
    reg m_transfer_done;
    // sclk_gen
    wire m_falling_edge;
    wire m_rising_edge;
    wire m_latch_en;
    wire m_cnt_en;
    
    // signals from controller
    wire m_drive_shift_addr;
    wire m_drive_shift_write;
    
    // registers in datapath
    // rd_wr_shift
    reg [7:0] m_sample_shift;
    reg [7:0] m_drive_shift;
    reg [31:0] m_r_data;
    reg [31:0] m_w_data_rem;
    // bit_cnt
    reg [3:0] m_bit_cnt;
    // data_rem
    reg [3:0] m_data_rem;
    // sclk_div
    reg [2:0] m_clk_cnt;
    reg       m_sclk_in;
    reg       m_sclk_prev;
    
    // ===== DATAPATH =====
    
    // === rd_wr_shift ===
    
    // sample_shift
    always @(posedge m_hclk or posedge m_rst) begin
        if (m_rst) begin
            m_sample_shift <= 8'd0;
        end
        else if (m_latch_en) begin
            m_sample_shift <= {m_sample_shift[6:0], m_miso};
        end
    end
    // r_data
    always @(posedge m_hclk or posedge m_rst) begin
        if (m_rst || m_en) begin
            m_r_data <= 32'd0;
        end
        else if (m_state == READ && m_byte_done && m_cnt_en) begin
            m_r_data <= {m_r_data[23:0], m_sample_shift};
        end
    end
    // drive_shift
    always @(posedge m_hclk or posedge m_rst) begin
        if (m_rst || m_cs) begin
            m_drive_shift <= 8'd0;
        end
        else if (m_drive_shift_addr) begin
            m_drive_shift <= {m_rw, m_addr};
        end
        else if (m_drive_shift_write) begin
                m_drive_shift <= m_w_data_rem[7:0];
        end
        else begin
            if (m_cnt_en) begin
                m_drive_shift <= {m_drive_shift[6:0], 1'b0};
            end
        end
    end
    // w_data_rem
    always @(posedge m_hclk or posedge m_rst) begin
        if (m_rst) begin
            m_w_data_rem <= 32'd0;
        end
        else if (m_en && !m_rw) begin
            m_w_data_rem <= m_w_data;
        end
        else if (m_drive_shift_write) begin
            m_w_data_rem <= {8'd0, m_w_data_rem[31:8]};
        end
    end
    // mosi
    always @(*) begin
        if (m_rst) begin
            m_mosi = 0;
        end
        else if (m_state == ADDR || m_state == WRITE) begin
            m_mosi = m_drive_shift[7];
        end
        else begin
            m_mosi = 0;
        end
    end
    
    // === bit_cnt ===
    // bit_cnt
    always @(posedge m_hclk or posedge m_rst) begin
        if (m_rst) begin
            m_bit_cnt <= {3'd0, ~m_cpha};
        end
        else if (m_next_state == IDLE || m_state == IDLE) begin
            m_bit_cnt <= {3'd0, ~m_cpha};
        end
        else if (m_byte_done && m_cnt_en) begin
            m_bit_cnt <= 4'd1;
        end
        else if (m_cnt_en) begin
            m_bit_cnt <= m_bit_cnt + 4'd1;
        end
    end
    // byte_done
    always @(*) begin
        if (m_rst) begin
            m_byte_done = 0;
        end
        else if (m_bit_cnt == 4'd8) begin
            m_byte_done = 1;
        end
        else begin
            m_byte_done = 0;
        end
    end
    
    // === data_rem ===
    // data_rem
    always @(posedge m_hclk or posedge m_rst) begin
        if (m_rst) begin
            m_data_rem <= 4'd0;
        end
        else if (m_state == ADDR && m_next_state != ADDR) begin
            m_data_rem <= m_transfer_len;
        end
        else if (m_byte_done && m_cnt_en) begin
            m_data_rem <= m_data_rem - 4'd1;
        end
    end
    // transfer_done
    always @(*) begin
        if (m_rst) begin
            m_transfer_done = 0;
        end
        else if (m_data_rem == 4'd1 && m_byte_done && m_cnt_en) begin
            m_transfer_done = 1;
        end
        else begin
            m_transfer_done = 0;
        end
    end
    
    // === sclk_gen ===
    // clk_cnt
    always @(posedge m_hclk or posedge m_rst) begin
        if (m_rst) begin
            m_clk_cnt <= 3'd1;
        end
        else if (m_state == IDLE || m_clk_cnt == m_clk_div_val) begin
            m_clk_cnt <= 3'd1;
        end
        else begin
            m_clk_cnt <= m_clk_cnt + 3'd1;
        end
    end
    
    // sclk_in
    always @(posedge m_hclk or posedge m_rst) begin
        if (m_rst || m_cs) begin
            m_sclk_in <= 1'b0;
        end
        else if (m_clk_cnt == m_clk_div_val) begin
            m_sclk_in <= ~m_sclk_in;
        end
    end
    
    // sclk
    always @(*) begin
        if (m_rst || m_state == IDLE || m_next_state == IDLE) begin
            m_sclk = m_cpol;
        end
        else begin
            m_sclk = m_sclk_in ^ m_cpol;
        end
    end
    
    // sclk_prev
    always @(posedge m_hclk or posedge m_rst) begin
        if (m_rst) begin
            m_sclk_prev <= 1'b0;
        end
        else begin
            m_sclk_prev <= m_sclk_in ^ m_cpol;
        end
    end
    
    assign m_falling_edge = ~(m_sclk_in ^ m_cpol) & m_sclk_prev & ~m_cs;
    assign m_rising_edge = (m_sclk_in ^ m_cpol) & ~m_sclk_prev & ~m_cs;
    
    assign m_latch_en = (m_cpol ^ m_cpha) ? m_falling_edge : m_rising_edge;
    assign m_cnt_en = (m_cpol ^ m_cpha) ? m_rising_edge : m_falling_edge;
    
    // ===== CONTROLLER =====
    
    // drive_shift_addr
    assign m_drive_shift_addr = !m_cs && !m_cnt_en && m_bit_cnt == 3'd1 && m_state == ADDR;
    // drive_shift_write
    assign m_drive_shift_write = ((m_state == ADDR && !m_rw) || m_state == WRITE) && m_byte_done && m_cnt_en;
    
    // cs
    always @(*) begin
        if (m_rst || m_state == IDLE) begin
            m_cs = 1;
        end
        else begin
            m_cs = 0;
        end
    end
    
    // current state logic
    always @(posedge m_hclk or posedge m_rst) begin
        if (m_rst) begin
            m_state <= IDLE;
        end
        else begin
            m_state <= m_next_state;
        end
    end
    
    // next state logic
    always @(*) begin
        m_next_state = IDLE;
        if (m_rst) begin
            m_next_state = IDLE;
        end
        else begin
            case (m_state)
                IDLE: begin
                    if (m_en) begin
                        m_next_state = ADDR;
                    end
                    else begin
                        m_next_state = IDLE;
                    end
                end
                ADDR: begin
                    if (m_rw && m_cnt_en && m_byte_done) begin
                        m_next_state = READ;
                    end
                    else if (!m_rw && m_cnt_en && m_byte_done) begin
                        m_next_state = WRITE;
                    end
                    else begin
                        m_next_state = ADDR;
                    end
                end
                READ: begin
                    if (m_transfer_done) begin
                        m_next_state = IDLE;
                    end
                    else begin
                        m_next_state = READ;
                    end
                end
                WRITE: begin
                    if (m_transfer_done) begin
                        m_next_state = IDLE;
                    end
                    else begin
                        m_next_state = WRITE;
                    end
                end
                default: begin
                    m_next_state = IDLE;
                end
            endcase
        end
    end
endmodule
