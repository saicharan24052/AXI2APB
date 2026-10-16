module apb_master_interface #(
    parameter AW = 32,
    parameter DW = 32,
    parameter LW = 4,
    parameter IW = 4
    //chatgpt
)
(
    input                    PCLK,
    input                    PRESETn,

    output                   PSELx,
    output                   PENABLE,
    output     [AW-1:0]      PADDR,
    output     [2:0]         PPROT,
    output                   PWRITE,
    output     [DW-1:0]      PWDATA,
    output     [(DW/8)-1:0]  PSTRB,
    input                    PREADY,
    input      [DW-1:0]      PRDATA,
    input                    PSLVERR,

    input                    decode_err,
    input      [AW+IW+LW+2:0] awaddr_ctrl,
    output                   waddr_ren,
    input                    waddr_fe,
    input      [(DW/8)+DW:0] wdata_strb,
    output                   data_ren,
    input                    data_fe,

    input      [AW+IW+LW+2:0] araddr_ctrl,
    output                   raddr_ren,
    input                    raddr_fe,
    output     [DW+IW+2:0]   rdata_serr,
    output                   rdata_wen,
    input                    rdata_ff,
    input                    rdata_almost_full,

    output     [IW+1:0]      wr_resp_ctrl,
    output                   wr_resp_valid,
    input                    wr_resp_full,
    input                    wr_resp_almost_full,
    input                    use_mwerr_resp,
    input      [2:0]         access_ratio
);

localparam IDLE    = 3'b000;
localparam WSETUP  = 3'b001;
localparam WACTIVE = 3'b010;
localparam RSETUP  = 3'b011;
localparam RACTIVE = 3'b100;

reg [2:0] cstate;
reg [2:0] nstate;

wire wfifo_ren;
wire wlast;
wire rlast;

wire apb_wr;
wire apb_rd;
wire apb_wr_complete;
wire apb_rd_complete;

wire [IW-1:0] rid;

wire [LW-1:0] awlen;
wire [LW-1:0] arlen;
wire [IW-1:0] awid;
wire [IW-1:0] arid;

reg          wr_err_slv_accum;
reg          wr_err_dec_accum;
reg          wr_mode_active;
reg          wr_burst_active;
reg          rd_burst_active;
reg [IW+1:0] wr_resp_ctrl_reg;
reg          wr_resp_valid_reg;

reg [LW:0] r_count;

assign wr_resp_ctrl  = wr_resp_ctrl_reg;
assign wr_resp_valid = wr_resp_valid_reg;

/*
 * The calculator FIFO contains {PROT, LEN, ADDR, ID}.
 * Keep all APB controls derived from the currently selected transaction.
 */
assign awlen  = awaddr_ctrl[(AW+IW+LW-1):(AW+IW)];
assign arlen  = araddr_ctrl[(AW+IW+LW-1):(AW+IW)];
assign awid   = awaddr_ctrl[IW-1:0];
assign arid   = araddr_ctrl[IW-1:0];

assign PPROT  = PWRITE
              ? awaddr_ctrl[(AW+IW+LW+2):(AW+IW+LW)]
              : araddr_ctrl[(AW+IW+LW+2):(AW+IW+LW)];

assign PADDR  = PWRITE
              ? awaddr_ctrl[(AW+IW-1):IW]
              : araddr_ctrl[(AW+IW-1):IW];

assign PSTRB  = PWRITE ? wdata_strb[(DW/8)+DW-1:DW] : 'b0;
assign PWDATA = PWRITE ? wdata_strb[DW-1:0] : 'b0;

assign PSELx   = (cstate != IDLE);
assign PWRITE  = (cstate == WSETUP) || (cstate == WACTIVE);
assign PENABLE = (cstate == WACTIVE) || (cstate == RACTIVE);

assign wlast = wdata_strb[(DW/8)+DW];
assign rid   = arid;

/*
 * APB completion pulses.
 */
assign apb_rd          = PSELx && PENABLE && !PWRITE && PREADY;
assign apb_wr          = PSELx && PENABLE &&  PWRITE && PREADY;
assign apb_wr_complete = apb_wr && wlast;
assign apb_rd_complete = apb_rd && (r_count == arlen);

/*
 * AXI read response payload is {RLAST, RRESP, RDATA, RID}.
 * RRESP mapping:
 *   00 = OKAY
 *   10 = APB slave error
 *   11 = address decode error
 */
assign rlast      = (r_count == arlen);
assign rdata_serr = {rlast,
                     ((PSLVERR && !decode_err) ? 2'b10 :
                      decode_err               ? 2'b11 :
                                                  2'b00),
                     PRDATA,
                     rid};
assign rdata_wen  = apb_rd && !rdata_ff;

/*
 * The arbiter consumes one write-address FIFO entry and one write-data FIFO
 * entry together.  The same pulse starts the next APB write transfer.
 */
assign waddr_ren = wfifo_ren;
assign data_ren  = wfifo_ren;

/*
 * A write transaction is one complete AXI burst, not one APB beat.
 * wfifo_ren fires for every APB beat, so it must NOT be used by itself to
 * clear the accumulated error state.  wr_burst_active identifies whether
 * the currently selected APB write belongs to an already-started burst.
 *
 * The response generated on the final beat uses the accumulated errors plus
 * that beat's PSLVERR/decode_err.  If another burst is selected in the same
 * cycle, its configuration is initialized only after the old response has
 * been formed.
 */
always @(posedge PCLK or negedge PRESETn) begin
    if (!PRESETn) begin
        wr_err_slv_accum <= 1'b0;
        wr_err_dec_accum <= 1'b0;
        wr_mode_active   <= 1'b0;
        wr_burst_active  <= 1'b0;
        wr_resp_ctrl_reg <= 'b0;
        wr_resp_valid_reg <= 1'b0;
    end
    else begin
        /*
         * One-cycle delayed push pulse: the payload captured below is stable
         * throughout the following PCLK cycle when the CDC FIFO samples it.
         */
        wr_resp_valid_reg <= apb_wr_complete;

        if (apb_wr_complete) begin
            /*
             * Complete the old burst using the old burst's ID and mode.
             * The current beat's error is included before the response is
             * committed.
             */
            wr_resp_ctrl_reg <= {
                wr_mode_active
                    ? (wr_err_slv_accum | PSLVERR)
                    : 1'b0,
                wr_mode_active
                    ? (wr_err_dec_accum | decode_err)
                    : 1'b0,
                awid
            };

            /*
             * If wfifo_ren is also asserted, this edge simultaneously
             * consumes the first APB beat of the next AXI write burst.
             * Initialize state for that new burst; otherwise the completed
             * burst leaves the write-error accumulator idle.
             */
            if (wfifo_ren) begin
                wr_err_slv_accum <= 1'b0;
                wr_err_dec_accum <= 1'b0;
                wr_mode_active   <= use_mwerr_resp;
                wr_burst_active  <= 1'b1;
            end
            else begin
                wr_err_slv_accum <= 1'b0;
                wr_err_dec_accum <= 1'b0;
                wr_burst_active  <= 1'b0;
            end
        end
        else if (apb_wr) begin
            /*
             * Non-final APB beat of the current AXI write burst.
             */
            wr_err_slv_accum <= wr_err_slv_accum | PSLVERR;
            wr_err_dec_accum <= wr_err_dec_accum | decode_err;
        end
        else if (wfifo_ren && !wr_burst_active) begin
            /*
             * First beat of a newly selected AXI write burst.  No APB
             * completion has occurred yet, so initialize the burst context.
             */
            wr_err_slv_accum <= 1'b0;
            wr_err_dec_accum <= 1'b0;
            wr_mode_active   <= use_mwerr_resp;
            wr_burst_active  <= 1'b1;
        end
    end
end

/*
 * Read burst tracking.
 *
 * raddr_ren fires once for every APB beat, so it cannot by itself reset the
 * burst counter.  rd_burst_active distinguishes the first beat of a burst
 * from subsequent beats.  RLAST is generated from the beat count before the
 * APB completion edge, and the counter is reset only after the final beat.
 */
always @(posedge PCLK or negedge PRESETn) begin
    if (!PRESETn) begin
        r_count         <= 'b0;
        rd_burst_active <= 1'b0;
    end
    else if (apb_rd_complete) begin
        r_count <= 'b0;

        /*
         * A read selected on the same edge is the first beat of the next
         * burst; otherwise the completed burst leaves the tracker idle.
         */
        rd_burst_active <= raddr_ren;
    end
    else if (apb_rd) begin
        r_count         <= r_count + 1'b1;
        rd_burst_active <= 1'b1;
    end
    else if (raddr_ren && !rd_burst_active) begin
        /*
         * First beat has been fetched from the address FIFO, but APB has not
         * reached the enable/completion phase yet.
         */
        r_count         <= 'b0;
        rd_burst_active <= 1'b1;
    end
end

/*
 * APB scheduling FSM.
 */
always @(posedge PCLK or negedge PRESETn) begin
    if (!PRESETn)
        cstate <= IDLE;
    else
        cstate <= nstate;
end

always @* begin
    case (cstate)
        IDLE:
            if (wfifo_ren)
                nstate = WSETUP;
            else if (raddr_ren)
                nstate = RSETUP;
            else
                nstate = IDLE;

        WSETUP:
            nstate = WACTIVE;

        WACTIVE:
            if (!PREADY)
                nstate = WACTIVE;
            else if (wfifo_ren)
                nstate = WSETUP;
            else if (raddr_ren)
                nstate = RSETUP;
            else
                nstate = IDLE;

        RSETUP:
            nstate = RACTIVE;

        RACTIVE:
            if (!PREADY)
                nstate = RACTIVE;
            else if (raddr_ren)
                nstate = RSETUP;
            else if (wfifo_ren)
                nstate = WSETUP;
            else
                nstate = IDLE;

        default:
            nstate = IDLE;
    endcase
end

/*
 * Access arbitration.  A pending write response FIFO entry is accounted for
 * through wr_avail at the top level so APB writes cannot overrun it.
 */
apb_access_arb u_apb_access_arb (
    .rstn      (PRESETn),
    .clk       (PCLK),
    .ratio     (access_ratio),
    .ra_avail  (!raddr_fe),
    .rd_avail  (
        (!rd_burst_active && !rdata_ff && !rdata_almost_full) ||
        ( rd_burst_active && !apb_rd_complete)
    ),
    /*
     * A write burst must be allowed to drain once its first beat has been
     * accepted, even if the response FIFO becomes almost full while the
     * burst is in progress.  A new burst, however, is started only when one
     * additional response slot is reserved.
     */
    .wr_avail  (
        (!data_fe && !waddr_fe) &&
        (
            (wr_burst_active && !apb_wr_complete) ||
            (!wr_resp_full && !wr_resp_almost_full)
        )
    ),
    .rd        (apb_rd),
    .wr        (apb_wr),
    .rd_en     (raddr_ren),
    .wr_en     (wfifo_ren)
);

endmodule
