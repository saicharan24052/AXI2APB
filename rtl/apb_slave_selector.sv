module apb_slave_selector #(
    parameter DW = 32,
    parameter AW = 32,
    parameter SLAVE0_BASE_ADDR  = 32'h4000_0000,
    parameter SLAVE1_BASE_ADDR  = 32'h4000_1000,
    parameter SLAVE2_BASE_ADDR  = 32'h4000_2000,
    parameter SLAVE3_BASE_ADDR  = 32'h4000_3000,
    parameter SLAVE4_BASE_ADDR  = 32'h4000_4000,
    parameter SLAVE5_BASE_ADDR  = 32'h4000_5000,
    parameter SLAVE6_BASE_ADDR  = 32'h4000_6000,
    parameter SLAVE7_BASE_ADDR  = 32'h4000_7000,
    parameter SLAVE8_BASE_ADDR  = 32'h4000_8000,
    parameter SLAVE9_BASE_ADDR  = 32'h4000_9000,
    parameter SLAVE10_BASE_ADDR = 32'h4000_A000,
    parameter OFFSET = 32'h0000_0FFF
)
(
    input                       PSEL,
    input                       PWRITE,
    input                       PENABLE,
    input      [2:0]            PPROT,
    input      [AW-1:0]         PADDR,
    input      [DW-1:0]         PWDATA,
    input      [(DW/8)-1:0]     PSTRB,

    output                     pwrite,
    output [2:0]               pprot,
    output [AW-1:0]            paddr,
    output [DW-1:0]            pwdata,
    output [(DW/8)-1:0]        pstrb,
    output reg                 PSLVERR,
    output                     penable,
    output reg                 decode_err,
    output reg [10:0]          pselx,

    input      [10:0]           pslverr,
    output reg                 PREADY,
    input      [10:0]           pready,

    output reg [DW-1:0]        PRDATA,
    input      [DW-1:0]         prdata_0,
    input      [DW-1:0]         prdata_1,
    input      [DW-1:0]         prdata_2,
    input      [DW-1:0]         prdata_3,
    input      [DW-1:0]         prdata_4,
    input      [DW-1:0]         prdata_5,
    input      [DW-1:0]         prdata_6,
    input      [DW-1:0]         prdata_7,
    input      [DW-1:0]         prdata_8,
    input      [DW-1:0]         prdata_9,
    input      [DW-1:0]         prdata_10
);

always @* begin
    pselx      = 11'b0;
    decode_err = 1'b0;

    if (PSEL) begin
        case (PADDR & (~OFFSET))
            SLAVE0_BASE_ADDR:
                pselx[0]  = 1'b1;
            SLAVE1_BASE_ADDR:
                pselx[1]  = 1'b1;
            SLAVE2_BASE_ADDR:
                pselx[2]  = 1'b1;
            SLAVE3_BASE_ADDR:
                pselx[3]  = 1'b1;
            SLAVE4_BASE_ADDR:
                pselx[4]  = 1'b1;
            SLAVE5_BASE_ADDR:
                pselx[5]  = 1'b1;
            SLAVE6_BASE_ADDR:
                pselx[6]  = 1'b1;
            SLAVE7_BASE_ADDR:
                pselx[7]  = 1'b1;
            SLAVE8_BASE_ADDR:
                pselx[8]  = 1'b1;
            SLAVE9_BASE_ADDR:
                pselx[9]  = 1'b1;
            SLAVE10_BASE_ADDR:
                pselx[10] = 1'b1;
            default:
                decode_err = 1'b1;
        endcase
    end
end

/*
 * No APB transfer is emitted for a decode error.  The master-facing PREADY
 * is still asserted in the APB enable phase so the bridge can turn the
 * decode miss directly into an AXI DECERR.
 */
assign pwrite  = !decode_err ? PWRITE  : 1'b0;
assign pprot   = !decode_err ? PPROT   : 3'b000;
assign paddr   = !decode_err ? PADDR   : 'b0;
assign pwdata  = !decode_err ? PWDATA  : 'b0;
assign pstrb   = !decode_err ? PSTRB   : 'b0;
assign penable = !decode_err ? PENABLE : 1'b0;

always @* begin
    PRDATA = 'b0;

    if (PSEL && !PWRITE) begin
        case (pselx)
            11'b00000000001: PRDATA = prdata_0;
            11'b00000000010: PRDATA = prdata_1;
            11'b00000000100: PRDATA = prdata_2;
            11'b00000001000: PRDATA = prdata_3;
            11'b00000010000: PRDATA = prdata_4;
            11'b00000100000: PRDATA = prdata_5;
            11'b00001000000: PRDATA = prdata_6;
            11'b00010000000: PRDATA = prdata_7;
            11'b00100000000: PRDATA = prdata_8;
            11'b01000000000: PRDATA = prdata_9;
            11'b10000000000: PRDATA = prdata_10;
            default:         PRDATA = 'b0;
        endcase
    end
end

always @* begin
    PREADY = 1'b0;

    if (PSEL && PENABLE) begin
        if (decode_err) begin
            PREADY = 1'b1;
        end
        else begin
            case (pselx)
                11'b00000000001: PREADY = pready[0];
                11'b00000000010: PREADY = pready[1];
                11'b00000000100: PREADY = pready[2];
                11'b00000001000: PREADY = pready[3];
                11'b00000010000: PREADY = pready[4];
                11'b00000100000: PREADY = pready[5];
                11'b00001000000: PREADY = pready[6];
                11'b00010000000: PREADY = pready[7];
                11'b00100000000: PREADY = pready[8];
                11'b01000000000: PREADY = pready[9];
                11'b10000000000: PREADY = pready[10];
                default:         PREADY = 1'b0;
            endcase
        end
    end
end

always @* begin
    PSLVERR = 1'b0;

    if (PSEL && PENABLE) begin
        if (decode_err) begin
            PSLVERR = 1'b1;
        end
        else begin
            case (pselx)
                11'b00000000001: PSLVERR = pslverr[0];
                11'b00000000010: PSLVERR = pslverr[1];
                11'b00000000100: PSLVERR = pslverr[2];
                11'b00000001000: PSLVERR = pslverr[3];
                11'b00000010000: PSLVERR = pslverr[4];
                11'b00000100000: PSLVERR = pslverr[5];
                11'b00001000000: PSLVERR = pslverr[6];
                11'b00010000000: PSLVERR = pslverr[7];
                11'b00100000000: PSLVERR = pslverr[8];
                11'b01000000000: PSLVERR = pslverr[9];
                11'b10000000000: PSLVERR = pslverr[10];
                default:         PSLVERR = 1'b0;
            endcase
        end
    end
end

endmodule
