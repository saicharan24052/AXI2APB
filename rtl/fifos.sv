module sync_fifo #(
    parameter AW = 3,
    parameter DW = 8
)
(
    input clk,
    input rstn,
    input push,
    input [DW-1:0] write_data,
    input pop,
    output [DW-1:0] read_data,
    output empty,
    output almost_full
);

localparam DEPTH = (1 << AW);
localparam ALMOST_FULL = (DEPTH > 3) ? (DEPTH - 3) : (DEPTH - 1);

wire full;
wire wr_vld;
wire rd_vld;

reg [AW:0] fifo_count;
reg [AW-1:0] wr_ptr;
reg [AW-1:0] rd_ptr;

assign empty      = (fifo_count == 0);
assign full       = (fifo_count == DEPTH);
assign almost_full = (fifo_count >= ALMOST_FULL);

assign wr_vld = push && !full;
assign rd_vld = pop  && !empty;

sync_ram #(
    .AW(AW),
    .DW(DW),
    .DEPTH(DEPTH)
) u_ram (
    .clk   (clk),
    .waddr (wr_ptr),
    .raddr (rd_ptr),
    .wdata (write_data),
    .rdata (read_data),
    .wen   (wr_vld),
    .ren   (rd_vld)
);

always @(posedge clk or negedge rstn) begin
    if (!rstn)
        wr_ptr <= 'b0;
    else if (wr_vld)
        wr_ptr <= wr_ptr + 1'b1;
end

always @(posedge clk or negedge rstn) begin
    if (!rstn)
        rd_ptr <= 'b0;
    else if (rd_vld)
        rd_ptr <= rd_ptr + 1'b1;
end

always @(posedge clk or negedge rstn) begin
    if (!rstn)
        fifo_count <= 'b0;
    else if (wr_vld && !rd_vld)
        fifo_count <= fifo_count + 1'b1;
    else if (!wr_vld && rd_vld)
        fifo_count <= fifo_count - 1'b1;
end

endmodule


module dp_fifo #(
    parameter AW = 3,
    parameter DW = 8,
    parameter AFULL_GUARD = 1
)
(
    input               wrstn,
    input               wclk,
    input               rrstn,
    input               rclk,
    input               push,
    input               pop,
    input  [DW-1:0]     wdata,
    output [DW-1:0]     rdata,
    output reg          empty,
    output reg          full,
    output reg          almost_full
);

localparam DEPTH = (1 << AW);
localparam [AW:0] ALMOST_FULL_LEVEL = DEPTH - AFULL_GUARD;

/*
 * Binary and Gray pointers use AW+1 bits.  The extra bit distinguishes
 * equal lower addresses after one complete buffer wrap.
 */
reg [AW:0] wp_binary, wp_gray;
reg [AW:0] rp_binary, rp_gray;

wire w_accept = push && !full;
wire r_accept = pop  && !empty;

wire [AW:0] wp_binary_inc  = wp_binary + 1'b1;
wire [AW:0] rp_binary_inc  = rp_binary + 1'b1;
wire [AW:0] wp_binary_next = w_accept ? wp_binary_inc : wp_binary;
wire [AW:0] rp_binary_next = r_accept ? rp_binary_inc : rp_binary;
wire [AW:0] wp_gray_next   = wp_binary_next ^ (wp_binary_next >> 1);
wire [AW:0] rp_gray_next   = rp_binary_next ^ (rp_binary_next >> 1);

reg [AW:0] wp_meta, wp_sync_2r;
reg [AW:0] rp_meta, rp_sync_2w;

wire [AW:0] rp_sync_2w_bin;
wire [AW:0] wp_sync_2r_gray = wp_sync_2r;

function [AW:0] gray_to_binary;
    input [AW:0] gray;
    integer i;
    begin
        gray_to_binary[AW] = gray[AW];
        for (i = AW-1; i >= 0; i = i-1)
            gray_to_binary[i] = gray_to_binary[i+1] ^ gray[i];
    end
endfunction

assign rp_sync_2w_bin = gray_to_binary(rp_sync_2w);

/*
 * Full is evaluated in binary after the synchronized Gray read pointer has
 * been converted back to binary.  One extra pointer bit represents the
 * completed wrap, so full is exactly "read pointer + DEPTH".
 */
wire [AW:0] rp_full_compare = rp_sync_2w_bin + {1'b1, {AW{1'b0}}};
wire full_next  = (wp_binary_next == rp_full_compare);
wire empty_next = (rp_gray_next == wp_sync_2r_gray);
wire [AW:0] used_count_next = wp_binary_next - rp_sync_2w_bin;
wire almost_full_next = (used_count_next >= ALMOST_FULL_LEVEL);

dp_sram #(
    .AW(AW),
    .DW(DW)
) fifo_mem (
    .wclk  (wclk),
    .rclk  (rclk),
    .waddr (wp_binary[AW-1:0]),
    .raddr (rp_binary[AW-1:0]),
    .wdata (wdata),
    .rdata (rdata),
    .wen   (w_accept),
    .ren   (r_accept)
);

always @(posedge wclk or negedge wrstn) begin
    if (!wrstn) begin
        wp_binary <= 'b0;
        wp_gray   <= 'b0;
    end
    else if (w_accept) begin
        wp_binary <= wp_binary_next;
        wp_gray   <= wp_gray_next;
    end
end

always @(posedge rclk or negedge rrstn) begin
    if (!rrstn) begin
        rp_binary <= 'b0;
        rp_gray   <= 'b0;
    end
    else if (r_accept) begin
        rp_binary <= rp_binary_next;
        rp_gray   <= rp_gray_next;
    end
end

always @(posedge rclk or negedge rrstn) begin
    if (!rrstn) begin
        wp_meta    <= 'b0;
        wp_sync_2r <= 'b0;
    end
    else begin
        wp_meta    <= wp_gray;
        wp_sync_2r <= wp_meta;
    end
end

always @(posedge wclk or negedge wrstn) begin
    if (!wrstn) begin
        rp_meta    <= 'b0;
        rp_sync_2w <= 'b0;
    end
    else begin
        rp_meta    <= rp_gray;
        rp_sync_2w <= rp_meta;
    end
end

always @(posedge wclk or negedge wrstn) begin
    if (!wrstn) begin
        full        <= 1'b0;
        almost_full <= 1'b0;
    end
    else begin
        full        <= full_next;
        almost_full <= almost_full_next;
    end
end

always @(posedge rclk or negedge rrstn) begin
    if (!rrstn)
        empty <= 1'b1;
    else
        empty <= empty_next;
end

endmodule


module fifos #(
    parameter DW = 32,
    parameter AW = 32,
    parameter IW = 4,
    parameter LW = 4
)
(
    input                           s_rstn,
    input                           s_clk,
    input                           m_rstn,
    input                           m_clk,

    input                           wa_push,
    input                           wa_pop,
    input  [AW+IW+LW+7:0]           wa_wdata,
    output [AW+IW+LW+7:0]           wa_rdata,
    output                          wa_empty,
    output                          wa_full,

    input                           wd_push,
    input                           wd_pop,
    input  [(DW/8)+DW:0]            wd_wdata,
    output [(DW/8)+DW:0]            wd_rdata,
    output                          wd_empty,
    output                          wd_full,

    input                           ra_push,
    input                           ra_pop,
    input  [AW+IW+LW+7:0]           ra_wdata,
    output [AW+IW+LW+7:0]           ra_rdata,
    output                          ra_empty,
    output                          ra_full,

    input                           rd_push,
    input                           rd_pop,
    input  [DW+IW+2:0]               rd_wdata,
    output [DW+IW+2:0]               rd_rdata,
    output                          rd_empty,
    output                          rd_full,
    output                          rd_almost_full
);

wire wa_almost_full_unused;
wire wd_almost_full_unused;
wire ra_almost_full_unused;

dp_fifo #(.AW(2), .DW(AW+IW+LW+8)) u_wafifo (
    .wrstn (s_rstn),
    .wclk  (s_clk),
    .rrstn (m_rstn),
    .rclk  (m_clk),
    .push  (wa_push),
    .pop   (wa_pop),
    .wdata (wa_wdata),
    .rdata       (wa_rdata),
    .empty       (wa_empty),
    .full        (wa_full),
    .almost_full (wa_almost_full_unused)
);

dp_fifo #(.AW(2+LW), .DW((DW/8)+DW+1)) u_wdfifo (
    .wrstn (s_rstn),
    .wclk  (s_clk),
    .rrstn (m_rstn),
    .rclk  (m_clk),
    .push  (wd_push),
    .pop   (wd_pop),
    .wdata (wd_wdata),
    .rdata       (wd_rdata),
    .empty       (wd_empty),
    .full        (wd_full),
    .almost_full (wd_almost_full_unused)
);

dp_fifo #(.AW(2), .DW(AW+LW+IW+8)) u_rafifo (
    .wrstn (s_rstn),
    .wclk  (s_clk),
    .rrstn (m_rstn),
    .rclk  (m_clk),
    .push  (ra_push),
    .pop   (ra_pop),
    .wdata (ra_wdata),
    .rdata       (ra_rdata),
    .empty       (ra_empty),
    .full        (ra_full),
    .almost_full (ra_almost_full_unused)
);

dp_fifo #(
    .AW(2+LW),
    .DW(DW+IW+3),
    .AFULL_GUARD(1 << LW)
) u_rdfifo (
    .wrstn      (m_rstn),
    .wclk       (m_clk),
    .rrstn      (s_rstn),
    .rclk       (s_clk),
    .push       (rd_push),
    .pop        (rd_pop),
    .wdata      (rd_wdata),
    .rdata      (rd_rdata),
    .empty      (rd_empty),
    .full       (rd_full),
    .almost_full(rd_almost_full)
);

endmodule
