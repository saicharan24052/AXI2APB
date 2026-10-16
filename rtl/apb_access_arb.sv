module sync_2dff #(
    parameter DW = 1
)(
    input                  rstn,
    input                  clk,
    input  [DW-1:0]       d,
    output reg [DW-1:0]   q
);

reg [DW-1:0] q1;

always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
        q1 <= 'b0;
        q  <= 'b0;
    end
    else begin
        q1 <= d;
        q  <= q1;
    end
end

endmodule


module apb_access_arb (
    input        rstn,
    input        clk,
    input [2:0]  ratio,
    input        ra_avail,
    input        rd_avail,
    input        wr_avail,
    input        rd,
    input        wr,
    output reg   rd_en,
    output reg   wr_en
);

localparam IDLE    = 2'b00;
localparam RD_WAIT = 2'b01;
localparam WR_WAIT = 2'b10;

reg [1:0] state;
reg [1:0] next_state;

reg [2:0] ratio_r;
reg [1:0] pref_count;

wire read_available  = ra_avail & rd_avail;
wire write_available = wr_avail;
wire both_available  = read_available & write_available;

wire prefer_write = (state == IDLE) ? ratio[2] : ratio_r[2];
wire [1:0] quota   = ((state == IDLE) ? ratio[1:0] : ratio_r[1:0]) == 2'b00
                   ? 2'd1
                   : ((state == IDLE) ? ratio[1:0] : ratio_r[1:0]);

wire current_is_preferred_after_read  = !prefer_write;
wire current_is_preferred_after_write =  prefer_write;

/*
 * The low two bits encode the number of consecutive transfers of the
 * preferred direction before giving the other direction a turn.
 * 0 is treated as 1, so ratio=0 means strict alternation, initially
 * preferring reads; ratio=6 means two writes followed by one read, etc.
 */
always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
        state      <= IDLE;
        ratio_r    <= 3'b000;
        pref_count <= 2'b00;
    end
    else begin
        state <= next_state;

        /*
         * The configuration is only sampled when the arbiter is idle.
         * Starting a new scheduling epoch also resets the quota counter.
         */
        if (state == IDLE) begin
            ratio_r    <= ratio;
            pref_count <= 2'b00;
        end
        else if (state == RD_WAIT && rd) begin
            if (current_is_preferred_after_read) begin
                if (pref_count < quota)
                    pref_count <= pref_count + 1'b1;
            end
            else begin
                pref_count <= 2'b00;
            end
        end
        else if (state == WR_WAIT && wr) begin
            if (current_is_preferred_after_write) begin
                if (pref_count < quota)
                    pref_count <= pref_count + 1'b1;
            end
            else begin
                pref_count <= 2'b00;
            end
        end
    end
end

/*
 * Pick the next APB transfer only when the current APB transfer has
 * completed.  rd_en/wr_en are therefore one-clock scheduling pulses.
 */
always @* begin
    rd_en   = 1'b0;
    wr_en   = 1'b0;
    next_state = state;

    case (state)
        IDLE: begin
            if (both_available) begin
                if (prefer_write)
                    wr_en = 1'b1;
                else
                    rd_en = 1'b1;
            end
            else if (write_available) begin
                wr_en = 1'b1;
            end
            else if (read_available) begin
                rd_en = 1'b1;
            end

            if (wr_en)
                next_state = WR_WAIT;
            else if (rd_en)
                next_state = RD_WAIT;
            else
                next_state = IDLE;
        end

        RD_WAIT: begin
            if (rd) begin
                if (read_available && write_available) begin
                    if (!prefer_write && (pref_count >= (quota - 1'b1)))
                        wr_en = 1'b1;
                    else if (prefer_write)
                        wr_en = 1'b1;
                    else
                        rd_en = 1'b1;
                end
                else if (write_available) begin
                    wr_en = 1'b1;
                end
                else if (read_available) begin
                    rd_en = 1'b1;
                end

                if (wr_en)
                    next_state = WR_WAIT;
                else if (rd_en)
                    next_state = RD_WAIT;
                else
                    next_state = IDLE;
            end
        end

        WR_WAIT: begin
            if (wr) begin
                if (read_available && write_available) begin
                    if (prefer_write && (pref_count >= (quota - 1'b1)))
                        rd_en = 1'b1;
                    else if (!prefer_write)
                        rd_en = 1'b1;
                    else
                        wr_en = 1'b1;
                end
                else if (read_available) begin
                    rd_en = 1'b1;
                end
                else if (write_available) begin
                    wr_en = 1'b1;
                end

                if (wr_en)
                    next_state = WR_WAIT;
                else if (rd_en)
                    next_state = RD_WAIT;
                else
                    next_state = IDLE;
            end
        end

        default: begin
            next_state = IDLE;
        end
    endcase
end

endmodule
