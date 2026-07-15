module System (
    input             hclk,
    input             rst,
    input             en,
    input             rw,
    input      [6:0]  addr,
    input      [31:0] w_data,
    input      [3:0]  transfer_len,
    input      [2:0]  clk_div_val,
    input             cpol,
    input             cpha
    );
    
    wire sclk;
    wire cs;
    wire mosi;
    wire miso;
    
    Master master (
        .m_hclk         (hclk),
        .m_rst          (rst),
        .m_en           (en),
        
        // testbench to rd_wr_shift
        .m_rw           (rw),
        .m_addr         (addr),
        .m_w_data       (w_data),
        
        // testbench to data_rem
        .m_transfer_len (transfer_len),
        
        // tesetbench to sclk_gen
        .m_clk_div_val  (clk_div_val),
        
        // SPI modes
        .m_cpol         (cpol),
        .m_cpha         (cpha),
        
        // SPI interface
        .m_miso         (miso),
        .m_sclk         (sclk),
        .m_cs           (cs),
        .m_mosi         (mosi)
    );
    
    Slave slave (
        .s_rst (rst),
        
        // spi mode parameters
        .s_cpol(cpol),
        .s_cpha(cpha),
        
        // spi interface
        .s_sclk(sclk),
        .s_cs  (cs),
        .s_mosi(mosi),
        .s_miso(miso)
    );
    
endmodule
