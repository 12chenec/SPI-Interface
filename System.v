module System(
    input clk,
    input rst,
    input en,
    input cpol,
    input cpha,
   
    input rw,
    input [6:0] addr,
    input [7:0] w_data,
   
    // new explicit outputs
    output [7:0] master_r_data,
    output [7:0] slave_w_data
    );
 
    wire sclk;
    wire cs;
    wire mosi;
    wire miso;
   
    // Master module
    Master master(
        .m_clk(clk),
        .m_rst(rst),
        .m_en(en),
        .m_rw(rw),
        .m_addr(addr),
        .m_w_data(w_data),
        .m_r_data(master_r_data),   // expose Master's received data
        .m_cpol(cpol),
        .m_cpha(cpha),
        .m_miso(miso),
        .m_sclk(sclk),
        .m_cs(cs),
        .m_mosi(mosi)
    );
   
    // Slave module
    Slave slave(
        .s_rst(rst),
        .s_cpol(cpol),
        .s_cpha(cpha),
        .s_sclk(sclk),
        .s_cs(cs),
        .s_mosi(mosi),
        .s_miso(miso),
        .s_w_data(slave_w_data)       // expose Slave's written data
    );
 
Endmodule
