module apb_csr #(
    parameter DW = 32,
    parameter AW = 32,
    parameter REGISTER_ADDRESS = 32'h4000_A000
)
(
    input                   PRESETn,
    input                   PCLK,
    input                   PSEL,
    input                   PENABLE,
    input                   PWRITE,
    output                  PREADY,
    input  [AW-1:0]         PADDR,
    input  [DW-1:0]         PWDATA,
    output [DW-1:0]         PRDATA,
    output                  PSLVERR,
    output                  use_mwerr_resp,
    output [2:0]            wr_rd_ratio
);

reg [DW-1:0] csr_reg;

/*
 * The bridge drives a normal APB setup cycle followed by an enable cycle.
 * PREADY is asserted only for the enable phase, and a bad CSR address is a
 * completed APB transfer with PSLVERR.
 */
assign PREADY  = PSEL && PENABLE;
assign PSLVERR = PSEL && PENABLE && (PADDR != REGISTER_ADDRESS);

/* CSR contains only bit 31 and bits [2:0]. */
assign PRDATA = (PSEL && PENABLE && !PWRITE && (PADDR == REGISTER_ADDRESS))
              ? csr_reg
              : 'b0;

always @(posedge PCLK or negedge PRESETn) begin
    if (!PRESETn) begin
        csr_reg <= 'b0;
    end
    else if (PSEL && PENABLE && PWRITE && (PADDR == REGISTER_ADDRESS)) begin
        csr_reg <= PWDATA & 32'h8000_0007;
    end
end

assign use_mwerr_resp = csr_reg[31];
assign wr_rd_ratio    = csr_reg[2:0];

endmodule
