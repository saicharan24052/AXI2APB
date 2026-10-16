module pulse_sync (
    input        rstn,
    input        clk,
    input        d,
    output reg   p
);

always @(posedge clk or negedge rstn) begin
    if (!rstn)
        p <= 1'b0;
    else
        p <= d;
end

endmodule


module axi4_slave_interface #(
    parameter AW = 32,
    parameter DW = 32,
    parameter IW = 4,
    parameter LW = 4
)
(
    input       ACLK,
    input       ARESETn,

    /* AXI write-address channel. */
    input [IW-1:0] AWID,
    input [AW-1:0] AWADDR,
    input [LW-1:0] AWLEN,
    input [2:0] AWSIZE,
    input [1:0] AWBURST,
    input [2:0] AWPROT,
    input       AWVALID,
    output      AWREADY,

    /* AXI write-data channel. */
    input [DW-1:0] WDATA,
    input [(DW/8)-1:0] WSTRB,
    input       WLAST,
    input       WVALID,
    output      WREADY,

    /* AXI write-response channel. */
    output [IW-1:0] BID,
    output [1:0] BRESP,
    output      BVALID,
    input       BREADY,

    /* AXI read-address channel. */
    input [IW-1:0] ARID,
    input [AW-1:0] ARADDR,
    input [LW-1:0] ARLEN,
    input [2:0] ARSIZE,
    input [1:0] ARBURST,
    input [2:0] ARPROT,
    input       ARVALID,
    output      ARREADY,

    /* AXI read-data channel. */
    output [IW-1:0] RID,
    output [DW-1:0] RDATA,
    output [1:0] RRESP,
    output      RLAST,
    output      RVALID,
    input       RREADY,

    /* Internal write/read request FIFOs. */
    output [AW+IW+LW+7:0] w_addr_ctrl,
    output                w_addr_wen,
    input                 w_addr_full,
    output [(DW/8)+DW:0] w_data_ctrl,
    output                w_data_wen,
    input                 w_data_full,

    output [AW+IW+LW+7:0] r_addr_ctrl,
    output                r_addr_wen,
    input                 r_addr_full,

    /* Read response FIFO (PCLK -> ACLK). */
    input [DW+IW+2:0]     r_data_ctrl,
    output                r_data_ren,
    input                 r_data_empty,

    /* Write response FIFO (PCLK -> ACLK), payload = {BRESP, BID}. */
    input [IW+1:0]        wr_resp_ctrl,
    output                wr_resp_ren,
    input                 wr_resp_empty
);

/*
 * AXI channels are independently handshaken.  The bridge stores address,
 * write data, and read addresses independently, allowing the AXI master to
 * issue AW/W/AR in any legal order.
 */
assign w_addr_ctrl = {AWPROT, AWBURST, AWSIZE, AWLEN, AWADDR, AWID};
assign w_addr_wen  = AWVALID && AWREADY;
assign AWREADY     = !w_addr_full;

assign w_data_ctrl = {WLAST, WSTRB, WDATA};
assign w_data_wen  = WVALID && WREADY;
assign WREADY      = !w_data_full;

assign r_addr_ctrl = {ARPROT, ARBURST, ARSIZE, ARLEN, ARADDR, ARID};
assign r_addr_wen  = ARVALID && ARREADY;
assign ARREADY     = !r_addr_full;


/*
 * Write response path.
 *
 * APB write responses are stored in a CDC FIFO in the PCLK domain.  Because
 * the FIFO read port is synchronous, consume an entry in WR_RESP_IDLE and
 * present it in WR_RESP after the read-data register has been loaded.  This
 * keeps BID/BRESP stable for the complete AXI BVALID/BREADY handshake and
 * supports multiple outstanding write responses.
 */
localparam WR_RESP_IDLE = 1'b0;
localparam WR_RESP_SEND = 1'b1;

reg wr_resp_state;
reg wr_resp_state_next;

always @(posedge ACLK or negedge ARESETn) begin
    if (!ARESETn)
        wr_resp_state <= WR_RESP_IDLE;
    else
        wr_resp_state <= wr_resp_state_next;
end

always @* begin
    case (wr_resp_state)
        WR_RESP_IDLE:
            if (!wr_resp_empty)
                wr_resp_state_next = WR_RESP_SEND;
            else
                wr_resp_state_next = WR_RESP_IDLE;

        WR_RESP_SEND:
            if (BREADY)
                wr_resp_state_next = WR_RESP_IDLE;
            else
                wr_resp_state_next = WR_RESP_SEND;

        default:
            wr_resp_state_next = WR_RESP_IDLE;
    endcase
end

assign wr_resp_ren = (wr_resp_state == WR_RESP_IDLE) && !wr_resp_empty;
assign BVALID      = (wr_resp_state == WR_RESP_SEND);
assign BID         = wr_resp_ctrl[IW-1:0];
assign BRESP       = wr_resp_ctrl[IW+1:IW];


/*
 * Read response path.
 *
 * The same "read FIFO in IDLE, then present in RESP" structure is used here
 * so the synchronous FIFO read-data register is populated before RVALID
 * becomes visible.
 */
localparam RD_RESP_IDLE = 1'b0;
localparam RD_RESP_SEND = 1'b1;

reg rd_resp_state;
reg rd_resp_state_next;

wire rd_last_from_fifo = r_data_ctrl[DW+IW+2];

assign RID   = r_data_ctrl[IW-1:0];
assign RDATA = r_data_ctrl[(DW+IW)-1:IW];
assign RRESP = r_data_ctrl[DW+IW+1:DW+IW];
assign RLAST = RVALID ? rd_last_from_fifo : 1'b0;
assign RVALID = (rd_resp_state == RD_RESP_SEND);

assign r_data_ren = (rd_resp_state == RD_RESP_IDLE) && !r_data_empty;

always @(posedge ACLK or negedge ARESETn) begin
    if (!ARESETn)
        rd_resp_state <= RD_RESP_IDLE;
    else
        rd_resp_state <= rd_resp_state_next;
end

always @* begin
    case (rd_resp_state)
        RD_RESP_IDLE:
            if (!r_data_empty)
                rd_resp_state_next = RD_RESP_SEND;
            else
                rd_resp_state_next = RD_RESP_IDLE;

        RD_RESP_SEND:
            if (RREADY)
                rd_resp_state_next = RD_RESP_IDLE;
            else
                rd_resp_state_next = RD_RESP_SEND;

        default:
            rd_resp_state_next = RD_RESP_IDLE;
    endcase
end

endmodule
