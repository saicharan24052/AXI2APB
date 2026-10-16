`timescale 1ns / 1ps

module tb_axi4_to_apb4;

    // Parameters
    parameter AW = 32;
    parameter DW = 32;
    parameter LW = 4;
    parameter IW = 4;
    parameter SLAVE0_BASE_ADDR = 32'h4000_0000;
    parameter SLAVE1_BASE_ADDR = 32'h4000_1000;
    parameter SLAVE2_BASE_ADDR = 32'h4000_2000;
    parameter SLAVE3_BASE_ADDR = 32'h4000_3000;
    parameter SLAVE4_BASE_ADDR = 32'h4000_4000;
    parameter SLAVE5_BASE_ADDR = 32'h4000_5000;
    parameter SLAVE6_BASE_ADDR = 32'h4000_6000;
    parameter SLAVE7_BASE_ADDR = 32'h4000_7000;
    parameter SLAVE8_BASE_ADDR = 32'h4000_8000;
    parameter SLAVE9_BASE_ADDR = 32'h4000_9000;
    parameter SLAVE10_BASE_ADDR = 32'h4000_A000;
    parameter OFFSET = 32'h0000_0FFF;

    // DUT signals
    reg PCLK_i;
    reg PRESETn_i;
    wire [9:0] PSELx_o;
    wire [AW-1:0] PADDR_o;
    wire PENABLE_o;
    wire PWRITE_o;
    wire [2:0] PPROT_o;
    wire [DW-1:0] PWDATA_o;
    wire [(DW/8)-1:0] PSTRB_o;
    reg [9:0] PREADY_i;
    reg [DW-1:0] PRDATA_i_0;
    reg [DW-1:0] PRDATA_i_1;
    reg [DW-1:0] PRDATA_i_2;
    reg [DW-1:0] PRDATA_i_3;
    reg [DW-1:0] PRDATA_i_4;
    reg [DW-1:0] PRDATA_i_5;
    reg [DW-1:0] PRDATA_i_6;
    reg [DW-1:0] PRDATA_i_7;
    reg [DW-1:0] PRDATA_i_8;
    reg [DW-1:0] PRDATA_i_9;
    reg [9:0] PSLVERR_i;

    // AXI4 Slave signals
    reg ACLK_i;
    reg ARESETn_i;

    // AXI Write Address Channel
    reg [IW-1:0] AWID_i;
    reg [AW-1:0] AWADDR_i;
    reg [LW-1:0] AWLEN_i;
    reg [2:0] AWSIZE_i;
    reg [1:0] AWBURST_i;
    reg [2:0] AWPROT_i;
    reg AWVALID_i;
    wire AWREADY_o;

    // AXI Write Data Channel
    reg [DW-1:0] WDATA_i;
    reg [(DW/8)-1:0] WSTRB_i;
    reg WLAST_i;
    reg WVALID_i;
    wire WREADY_o;

    // AXI Write Response Channel
    wire [IW-1:0] BID_o;
    wire [1:0] BRESP_o;
    wire BVALID_o;
    reg BREADY_i;

    // AXI Read Address Channel
    reg [IW-1:0] ARID_i;
    reg [AW-1:0] ARADDR_i;
    reg [LW-1:0] ARLEN_i;
    reg [2:0] ARSIZE_i;
    reg [1:0] ARBURST_i;
    reg [2:0] ARPROT_i;
    reg ARVALID_i;
    wire ARREADY_o;

    // AXI Read Data Channel
    wire [IW-1:0] RID_o;
    wire [DW-1:0] RDATA_o;
    wire [1:0] RRESP_o;
    wire RLAST_o;
    wire RVALID_o;
    reg RREADY_i;

    // local variables
    integer i,j,p,q,k;

    axi4_to_apb4 #(
        .AW(AW),
        .DW(DW),
        .LW(LW),
        .IW(IW),
        .SLAVE0_BASE_ADDR(SLAVE0_BASE_ADDR),
        .SLAVE1_BASE_ADDR(SLAVE1_BASE_ADDR),
        .SLAVE2_BASE_ADDR(SLAVE2_BASE_ADDR),
        .SLAVE3_BASE_ADDR(SLAVE3_BASE_ADDR),
        .SLAVE4_BASE_ADDR(SLAVE4_BASE_ADDR),
        .SLAVE5_BASE_ADDR(SLAVE5_BASE_ADDR),
        .SLAVE6_BASE_ADDR(SLAVE6_BASE_ADDR),
        .SLAVE7_BASE_ADDR(SLAVE7_BASE_ADDR),
        .SLAVE8_BASE_ADDR(SLAVE8_BASE_ADDR),
        .SLAVE9_BASE_ADDR(SLAVE9_BASE_ADDR),
        .SLAVE10_BASE_ADDR(SLAVE10_BASE_ADDR),
        .OFFSET(OFFSET)
    ) dut (
        .PCLK_i(PCLK_i),
        .PRESETn_i(PRESETn_i),
        .PSELx_o(PSELx_o),
        .PADDR_o(PADDR_o),
        .PENABLE_o(PENABLE_o),
        .PWRITE_o(PWRITE_o),
        .PPROT_o(PPROT_o),
        .PWDATA_o(PWDATA_o),
        .PSTRB_o(PSTRB_o),
        .PREADY_i(PREADY_i),
        .PRDATA_i_0(PRDATA_i_0),
        .PRDATA_i_1(PRDATA_i_1),
        .PRDATA_i_2(PRDATA_i_2),
        .PRDATA_i_3(PRDATA_i_3),
        .PRDATA_i_4(PRDATA_i_4),
        .PRDATA_i_5(PRDATA_i_5),
        .PRDATA_i_6(PRDATA_i_6),
        .PRDATA_i_7(PRDATA_i_7),
        .PRDATA_i_8(PRDATA_i_8),
        .PRDATA_i_9(PRDATA_i_9),
        .PSLVERR_i(PSLVERR_i),
        .ACLK_i(ACLK_i),
        .ARESETn_i(ARESETn_i),
        .AWID_i(AWID_i),
        .AWADDR_i(AWADDR_i),
        .AWLEN_i(AWLEN_i),
        .AWSIZE_i(AWSIZE_i),
        .AWBURST_i(AWBURST_i),
        .AWPROT_i(AWPROT_i),
        .AWVALID_i(AWVALID_i),
        .AWREADY_o(AWREADY_o),
        .WDATA_i(WDATA_i),
        .WSTRB_i(WSTRB_i),
        .WLAST_i(WLAST_i),
        .WVALID_i(WVALID_i),
        .WREADY_o(WREADY_o),
        .BID_o(BID_o),
        .BRESP_o(BRESP_o),
        .BVALID_o(BVALID_o),
        .BREADY_i(BREADY_i),
        .ARID_i(ARID_i),
        .ARADDR_i(ARADDR_i),
        .ARLEN_i(ARLEN_i),
        .ARSIZE_i(ARSIZE_i),
        .ARBURST_i(ARBURST_i),
        .ARPROT_i(ARPROT_i),
        .ARVALID_i(ARVALID_i),
        .ARREADY_o(ARREADY_o),
        .RID_o(RID_o),
        .RDATA_o(RDATA_o),
        .RRESP_o(RRESP_o),
        .RLAST_o(RLAST_o),
        .RVALID_o(RVALID_o),
        .RREADY_i(RREADY_i)
    );

    // Clock Generation
    always #5 ACLK_i = ~ACLK_i;
    always #10 PCLK_i = ~PCLK_i; // 10

    task reset_dut;
        begin
            ARESETn_i = 1'b0;
            PRESETn_i = 1'b0;
            #40;
            ARESETn_i = 1'b1;
            PRESETn_i = 1'b1;
        end
    endtask

    // Task to initialize all signals
    task init_signals;
        begin
            // Initialize clocks
            PCLK_i = 0;
            ACLK_i = 0;

            // Reset signals
            PRESETn_i = 1;
            ARESETn_i = 1;

            // Initialize all inputs to default
            PREADY_i = 0;
            PRDATA_i_0 = 0;
            PRDATA_i_1 = 0;
            PRDATA_i_2 = 0;
            PRDATA_i_3 = 0;
            PRDATA_i_4 = 0;
            PRDATA_i_5 = 0;
            PRDATA_i_6 = 0;
            PRDATA_i_7 = 0;
            PRDATA_i_8 = 0;
            PRDATA_i_9 = 0;
            PSLVERR_i = 0;

            AWID_i = 0;
            AWADDR_i = 0;
            AWLEN_i = 0;
            AWSIZE_i = 0;
            AWBURST_i = 0;
            AWPROT_i = 0;
            AWVALID_i = 0;

            WDATA_i = 0;
            WSTRB_i = 0;
            WLAST_i = 0;
            WVALID_i = 0;

            BREADY_i = 0;

            ARID_i = 0;
            ARADDR_i = 0;
            ARLEN_i = 0;
            ARSIZE_i = 0;
            ARBURST_i = 0;
            ARPROT_i = 0;
            ARVALID_i = 0;

            RREADY_i = 0;
            #10;
        end
    endtask

    // Task to send the axi write address and control information
    // (Corrected cut-off inputs from screenshot)
     task  axi_write_address(
        input [IW-1:0] aw_id,
        input [AW-1:0] aw_addr,
        input [LW-1:0] aw_len,
        input [2:0]    aw_size,
        input [1:0]    aw_burst,
        input [2:0]    aw_prot
    );
        begin
            @(posedge ACLK_i)
            AWID_i = aw_id;
            AWADDR_i = aw_addr;
            AWLEN_i = aw_len;
            AWSIZE_i = aw_size;
            AWBURST_i = aw_burst;
            AWPROT_i = aw_prot;
            AWVALID_i = 1'b1;
            wait(AWREADY_o)
            @(posedge ACLK_i)
            AWVALID_i = 1'b0;
        end
    endtask

    // Task to send the axi write data and strobe
     task  axi_write_data(input [LW-1:0] len, input [DW-1:0] data);
        begin
            for(i=0; i<=len; i=i+1)
                begin
                    @(posedge ACLK_i)
                    WVALID_i = 1'b1;
                    WDATA_i = data;
                    WSTRB_i = $random;
                    if(i == len)
                        WLAST_i = 1'b1;
                    else
                        WLAST_i = 1'b0;
                    wait(WREADY_o)
                    @(posedge ACLK_i)
                    WVALID_i = 1'b0;
                    WLAST_i = 1'b0;
                end
        end
    endtask

    // Task to receive the axi write response
     task  axi_write_response;
        begin
            @(posedge ACLK_i)
            BREADY_i = 1'b1;
            wait(BVALID_o)
            @(posedge ACLK_i)
            BREADY_i = 1'b0;
        end
    endtask

    // Task to send the axi read address and control information
    // (Corrected cut-off inputs from screenshot)
     task  axi_read_address(
        input [IW-1:0] ar_id,
        input [AW-1:0] ar_addr,
        input [LW-1:0] ar_len,
        input [2:0]    ar_size,
        input [1:0]    ar_burst,
        input [2:0]    ar_prot
    );
        begin
            @(posedge ACLK_i);
            ARID_i = ar_id;
            ARADDR_i = ar_addr;
            ARLEN_i = ar_len;
            ARSIZE_i = ar_size;
            ARBURST_i = ar_burst;
            ARPROT_i = ar_prot;
            ARVALID_i = 1'b1;
            wait(ARREADY_o)
            @(posedge ACLK_i);
            ARVALID_i = 1'b0;
        end
    endtask

    // Task to receive the axi read data
     task  axi_read_data(input [LW-1:0] r_len);
        begin
            for(j=0 ; j<= r_len; j=j+1)
                begin
                    @(posedge ACLK_i)
                    RREADY_i = 1'b1;
                    wait(RVALID_o)
                    @(posedge ACLK_i)
                    RREADY_i = 1'b0;
                end
        end
    endtask

    // Task to send or receive the APB data based on the PWRITE and PSELx
     task  apb_operation(input [LW:0] len, input resp);
        begin
            for(k =0; k<= len; k=k+1)
                begin
                    @(posedge PCLK_i)
                    wait(PSELx_o);
                        begin
                            if(PWRITE_o)
                                begin
                                    case(PSELx_o)
                                        10'b0000000001 : begin
                                            PREADY_i = 10'b0000000001;
                                            PSLVERR_i = {9'b0, resp};
                                        end
                                        10'b0000000010 : begin
                                            PREADY_i = 10'b0000000010;
                                            PSLVERR_i = {8'b0, resp, 1'b0};
                                        end
                                        10'b0000000100 : begin
                                            PREADY_i = 10'b0000000100;
                                            PSLVERR_i = {7'b0, resp, 2'b0};
                                        end
                                        10'b0000001000 : begin
                                            PREADY_i = 10'b0000001000;
                                            PSLVERR_i = {6'b0, resp, 3'b0};
                                        end
                                        10'b0000010000 : begin
                                            PREADY_i = 10'b0000010000;
                                            PSLVERR_i = {5'b0, resp, 4'b0};
                                        end
                                        10'b0000100000 : begin
                                            PREADY_i = 10'b0000100000;
                                            PSLVERR_i = {4'b0, resp, 5'b0};
                                        end
                                        10'b0001000000 : begin
                                            PREADY_i = 10'b0001000000;
                                            PSLVERR_i = {3'b0, resp, 6'b0};
                                        end
                                        10'b0010000000 : begin
                                            PREADY_i = 10'b0010000000;
                                            PSLVERR_i = {2'b0, resp, 7'b0};
                                        end
                                        10'b0100000000 : begin
                                            PREADY_i = 10'b0100000000;
                                            PSLVERR_i = {1'b0, resp, 8'b0};
                                        end
                                        10'b1000000000 : begin
                                            PREADY_i = 10'b1000000000;
                                            PSLVERR_i = {resp, 9'b0};
                                        end
                                        default        : begin
                                            PREADY_i = 10'b0000000000;
                                            PSLVERR_i = 10'b0;
                                        end
                                    endcase
                                    wait(PWRITE_o && PENABLE_o)
                                    @(posedge PCLK_i)
                                    PREADY_i = 1'b0;
                                end
                            else
                                begin
                                    case(PSELx_o)
                                        10'b0000000001 : begin
                                            PREADY_i = 10'b0000000001;
                                            PSLVERR_i = {9'b0, resp};
                                            PRDATA_i_0 = $random;
                                        end
                                        10'b0000000010 : begin
                                            PREADY_i = 10'b0000000010;
                                            PSLVERR_i = {8'b0, resp, 1'b0};
                                            PRDATA_i_1 = $random;
                                        end
                                        10'b0000000100 : begin
                                            PREADY_i = 10'b0000000100;
                                            PSLVERR_i = {7'b0, resp, 2'b0};
                                            PRDATA_i_2 = $random;
                                        end
                                        10'b0000001000 : begin
                                            PREADY_i = 10'b0000001000;
                                            PSLVERR_i = {6'b0, resp, 3'b0};
                                            PRDATA_i_3 = $random;
                                        end
                                        10'b0000010000 : begin
                                            PREADY_i = 10'b0000010000;
                                            PSLVERR_i = {5'b0, resp, 4'b0};
                                            PRDATA_i_4 = $random;
                                        end
                                        10'b0000100000 : begin
                                            PREADY_i = 10'b0000100000;
                                            PSLVERR_i = {4'b0, resp, 5'b0};
                                            PRDATA_i_5 = $random;
                                        end
                                        10'b0001000000 : begin
                                            PREADY_i = 10'b0001000000;
                                            PSLVERR_i = {3'b0, resp, 6'b0};
                                            PRDATA_i_6 = $random;
                                        end
                                        10'b0010000000 : begin
                                            PREADY_i = 10'b0010000000;
                                            PSLVERR_i = {2'b0, resp, 7'b0};
                                            PRDATA_i_7 = $random;
                                        end
                                        10'b0100000000 : begin
                                            PREADY_i = 10'b0100000000;
                                            PSLVERR_i = {1'b0, resp, 8'b0};
                                            PRDATA_i_8 = $random;
                                        end
                                        10'b1000000000 : begin
                                            PREADY_i = 10'b1000000000;
                                            PSLVERR_i = {resp, 9'b0};
                                            PRDATA_i_9 = $random;
                                        end
                                        default        : begin
                                            PREADY_i = 10'b0000000000;
                                            PSLVERR_i = 10'b0;
                                        end
                                    endcase
                                    wait(!PWRITE_o && PENABLE_o)
                                    @(posedge PCLK_i)
                                    PREADY_i = 1'b0;
                                end
                        end
                end
        end
    endtask

    initial
        begin

            // Operation : Intialize all input signals to zero
            init_signals;

            // Operation : Reset the DUT
            reset_dut;

            // Operation : write to the csr (to set the use_mwerr_resp as 0 and
            // wr_rd_ratio as 0)
            fork
                axi_write_address(4'hA, 32'h4000_A000, 4'h0, 3'h0, 2'h1, 3'h5);
                axi_write_data(4'h0, 32'h0000_0000);

                axi_write_response;
                $display("1st axi_write_response completed");
            join

            // Operation : AXI Write Operation for  6th slave
            // call tasks axi_write_address, axi_write_data, axi_write_response
            // and apb operation in the fork join block for concurrent operation
            fork
                axi_write_address(4'hA, 32'h4000_5040, 4'h3, 3'h2, 2'h1, 3'h5);
                axi_write_data(4'h3, $random);
                axi_write_response;
                $display("2nd axi_write_response completed");
                apb_operation(4'h3, 1'b1);
            join

            // opertaion: AXI write operations for the 8th slave
            fork
            	$display("3rd entered");
                axi_write_address(4'hA, 32'h4000_7040, 4'h3, 3'h2, 2'h1, 3'h5);
                $display("3rd axi_write_address completed");
                axi_write_data(4'h3, $random);  
                $display("3rd axi_write_data completed");
                axi_write_response;
                $display("3rd axi_write_response completed");
                apb_operation(4'h3, 1'b1);
            join

            // operation: AXI Write Operations to verify the multiple outstanding
            // transactions
            fork
                begin
                    axi_write_address(4'hA, 32'h4000_1040, 4'h3, 3'h2, 2'h1, 3'h5);
                    axi_write_address(4'hA, 32'h4000_4040, 4'h3, 3'h2, 2'h1, 3'h5);
                    axi_write_address(4'hA, 32'h4000_6040, 4'h3, 3'h2, 2'h1, 3'h5);
                    axi_write_address(4'hA, 32'h4000_5040, 4'h3, 3'h2, 2'h1, 3'h5);
                end
                begin
                    axi_write_data(4'h3, $random);
                    axi_write_data(4'h3, $random);
                    axi_write_data(4'h3, $random);
                    axi_write_data(4'h3, $random);
                end
                begin
                    axi_write_response;
                    axi_write_response;
                    axi_write_response;
                    axi_write_response;
                end
                begin
                    apb_operation(4'h3, 1'b1);
                    apb_operation(4'h3, 1'b1);
                    apb_operation(4'h3, 1'b1);
                    apb_operation(4'h3, 1'b1);
                end
            join

            // Operation : write to the Configuration Register
            // (to set the use_mwerr_resp =1 and wr_rd_ratio =2)
            fork
                axi_write_address(4'hA, 32'h4000_A000, 4'h7, 3'h0, 2'h1, 3'h5);
                axi_write_data(4'h7, 32'h8000_0002);
                axi_write_response;
            join

            //operation : read from configuration register
            fork
                axi_read_address(4'h5, 32'h4000_A000, 4'h3, 3'h0, 2'h1, 3'h5);
                axi_read_data(4'h3);
            join

            // Operation:AXI Write Operation to verify the decode error
            // Here apb operations task is not called because, since address is out
            // of range design will not convert to APB transactions and will return
            // a BRESP as decode error
            fork
                axi_write_address(4'hA, 32'hCAFEBABE, 4'h7, 3'h2, 2'h1, 3'h5);
                axi_write_data(4'h7, $random);
                axi_write_response;
            join
            #50
            //Operation:AXI Write operation for the 5th slave
            fork
                axi_write_address(4'hA, 32'h4000_2040, 4'h3, 3'h2, 2'h1, 3'h5);
                axi_write_data(4'h3, $random);
                axi_write_response;
                apb_operation(4'h3, 1'b1);
            join
            #30

            // Operation: AXI Read Operation to verify the decode error
            // Here apb operations task is not called because, since address is out
            // of range design will not convert to APB transactions and will return
            // a RRESP as decode error
            fork
                axi_read_address(4'h5, 32'h1DEDBABA, 4'h3, 3'h1, 2'h0, 3'h3);
                axi_read_data(4'h3);
            join

            //Operation: AXI Read Operations for 7th Slave
            fork
                axi_read_address(4'hB, 32'h4000_6853, 4'hB, 3'h2, 2'h1, 3'h7);
                axi_read_data(4'hB);
                apb_operation(4'hB, 1'b0);
            join

            #50 $stop;
        end

endmodule