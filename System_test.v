`define ASSERT_EQ(ONE, TWO, MSG)                                   \
    begin                                                          \
        if ((ONE) !== (TWO)) begin                                 \
            $display("\t[FAILURE]:%s", (MSG));                     \
            $display("received: %h, correct: %h", (ONE), (TWO));   \
        end                                                        \
        else begin                                                 \
            $display("\t[SUCCESS]:%s", (MSG));                     \
        end                                                        \
    end #0

module System_test;

    // ===== VARIABLES AND CONSTANTS =====
    reg hclk = 0;
    reg rst = 0;
    reg en = 0;
    
    localparam ADDR = 7'd3;
    localparam W_DATA = 32'h11111111;
    localparam CLK_DIV_VAL = 3'd4;
    
    reg       rw;
    reg [3:0] len;

    reg cpol;
    reg cpha;
    
    reg [31:0] correct_r_data;
    reg [31:0] correct_w_data;
    
    wire [31:0] received_r_data;
    wire [31:0] received_w_data;
    
    // ===== INSTANTIATE DUT =====
    System dut (
        .hclk         (hclk),
        .rst          (rst),
        .en           (en),
        .rw           (rw),
        .addr         (ADDR),
        .w_data       (W_DATA),
        .transfer_len (len),
        .clk_div_val  (CLK_DIV_VAL),
        .cpol         (cpol),
        .cpha         (cpha)
    );
    
    // System clock
    always #0.25 hclk = ~hclk;
    
    // test values
    assign received_r_data = dut.master.m_r_data;
    assign received_w_data = {dut.slave.s_rfile.rfile[ADDR],
                              dut.slave.s_rfile.rfile[ADDR + 1],
                              dut.slave.s_rfile.rfile[ADDR + 2],
                              dut.slave.s_rfile.rfile[ADDR + 3]};
    
    // ===== TESTS =====
    task read (input [3:0] r_len);
        begin
            rw = 1;
            len = r_len;
            en = 1; #1; en = 0;
            repeat ((r_len + 1.5) * 8 * CLK_DIV_VAL * 2) @(posedge hclk);
            `ASSERT_EQ(received_r_data, correct_r_data, "READ");
            #1;
        end
    endtask
    
    task write (input [3:0] w_len);
        begin
            rw = 0;
            len = w_len;
            en = 1; #1; en = 0;
            repeat ((w_len + 1.5) * 8 * CLK_DIV_VAL * 2) @(posedge hclk);
            `ASSERT_EQ(received_w_data, correct_w_data, "WRITE");
            #1;
        end
    endtask
    
    // ===== TESTING =====
    initial begin
        
        cpol = 0; cpha = 0;
        $display("\nResetting system...");
        #1; rst = 1; #1;rst = 0; #1;
        
        correct_r_data = 32'h00000003;
        read(1);
        
        correct_r_data = 32'h00000304;
        read(2);
        
        correct_r_data = 32'h00030405;
        read(3);

        correct_r_data = 32'h03040506;
        read(4);
        
        correct_w_data = 32'h11040506;
        write(1);
        
        correct_w_data = 32'h11110506;
        write(2);
        
        correct_w_data = 32'h11111106;
        write(3);
        
        correct_w_data = 32'h11111111;
        write(4);

        $finish;
    end 
endmodule
