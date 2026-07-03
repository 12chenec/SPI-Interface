`timescale 1ns/100ps
 
module System_test;
 
    // Local Vars
    reg clk   = 0;
    reg rst   = 0;
    reg en    = 0;
   
    // Configure RW instruction
    reg rw    = 0;          // 0 = write, 1 = read
    reg [6:0] addr = 0;
    reg [7:0] w_data = 0;
   
    // Configure SPI Mode
    reg cpol  = 0;
    reg cpha  = 0;
 
    // Observed outputs
    wire [7:0] master_r_data;
    wire [7:0] slave_w_data;
 
    // VCD Dump
    initial begin
        $dumpfile("System_test.vcd");
        $dumpvars;
    end
 
    // System Module
    System system(
        .clk           (clk),
        .rst           (rst),
        .en            (en),
        .rw            (rw),
        .addr          (addr),
        .w_data        (w_data),
        .cpol          (cpol),
        .cpha          (cpha),
        .master_r_data (master_r_data),
        .slave_w_data  (slave_w_data)
    );
 
    // Clock
    always begin
        #2.5 clk = ~clk;
    end
  
    // Main Test Logic
    initial begin
        // Clock changes based on polarity
        // CPOL == 0 means clock starts low
        // CPOL == 1 means clock starts high
        clk = cpol;
   
        // Reset the system
        $display("\nResetting the system...");
        #1; rst = 1; @(posedge clk);
        #1; rst = 0; @(posedge clk);
 
        // Perform a WRITE transaction
        $display("\nStarting WRITE transaction...");
        rw = 0; // write
        addr = 7'h3F;
        w_data = 8'hC3;
        #1; en = 1; @(posedge clk);
 
        // Let it run for a few cycles
        repeat (16) @(posedge clk);
        en = 0;
 
        $display("Slave latched data: %h", slave_w_data);
 
        // Perform a READ transaction
        $display("\nStarting READ transaction...");
        rw = 1; // read
        addr = 7'b1010101;
        #1; en = 1; @(posedge clk);
 
        // Let the transaction run
        repeat (16) @(posedge clk);
        en = 0;
 
        $display("Master received data: %h", master_r_data);
 
        #20;
        $finish;
    end
 
endmodule
