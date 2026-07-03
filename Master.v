module Master(
    input m_clk,
    input m_rst,
   
    // testbench
    input m_en,
    input m_rw,
    input [6:0] m_addr,
    input [7:0] m_w_data,
    output reg [7:0] m_r_data,
   
    // spi mode parameters
    input m_cpol,
    input m_cpha,
   
    // spi interface
    input m_miso,
    output reg m_sclk,
    output reg m_cs,
    output reg m_mosi
    );
   
    // states
    reg [2:0] m_state, m_next_state;
    localparam IDLE     = 3'd0;
    localparam ADDR     = 3'd1;
    localparam READ     = 3'd2;
    localparam WRITE    = 3'd3;
   
    // internal registers
    reg [15:0] m_sr;
    reg [3:0] m_bitcount;
 
   
    // output logic
    always @(*) begin
        // SCLK timing based on mode
        //  m_sclk = (m_cpol) ? ~m_clk : m_clk;
        m_sclk = m_clk;
       
        case (m_state)
            ADDR, READ, WRITE: begin
                m_mosi = m_sr[15];
            end
            default: begin
                m_mosi = 0;
            end
        endcase
    end
   
    
    // next state logic
    always @(*) begin
        case (m_state)
            IDLE: begin
                m_next_state = m_en ? ADDR : IDLE;
            end
            ADDR: begin
                m_next_state = (m_bitcount == 7) ? (m_rw ? READ : WRITE) : ADDR;
            end
            READ: begin
                m_next_state = (m_bitcount == 15) ? IDLE : READ;
            end
            WRITE: begin
                m_next_state = (m_bitcount == 15) ? IDLE : WRITE;
            end
            default: begin
                m_next_state = IDLE;
            end
        endcase
    end
   
    // sequential logic
   
    // internal clock for sampling/shifting
    wire m_in_clk;
    assign m_in_clk = (m_cpol ^ m_cpha) ? ~m_clk : m_clk;
   
    // negedge state update
    always @(negedge m_clk or posedge m_rst) begin
        if (m_rst) begin
            m_bitcount <= 0;
            m_state <= IDLE;
            m_sr <= 0;
        end else begin
           
            m_state <= m_next_state;
       
            case (m_state)
                IDLE: begin
                    m_bitcount <= 0;
                    m_sr <= {m_rw, m_addr, (m_rw ? 8'h00 : m_w_data)};
                end
                ADDR: begin
                    m_bitcount <= m_bitcount + 1;
                    m_sr <= {m_sr[14:0], 1'b0};
                end
                READ: begin
                    m_bitcount <= m_bitcount + 1;
                    m_sr <= {m_sr[14:0], 1'b0};
                end
                WRITE: begin
                    m_bitcount <= m_bitcount + 1;
                    m_sr <= {m_sr[14:0], 1'b0};
                end
                default: begin
                    m_bitcount <= 0;
                end
            endcase
        end
    end
 
    // sequential logic
    always @(posedge m_in_clk or posedge m_rst) begin
        if (m_rst) begin
            m_cs <= 1;
            m_r_data <= 0;
           
        end else begin
           
            case (m_state)
                IDLE: begin
                    m_cs <= 1;
                end
                ADDR: begin
                    m_cs <= 0;
                end
                READ: begin
                    m_r_data <= {m_r_data[6:0], m_miso};
                    m_cs <= 0;
                end
                WRITE: begin
                    m_cs <= 0;
                end
                default: begin
                    m_cs <= 1;
                end
            endcase
        end
    end
   
endmodule
