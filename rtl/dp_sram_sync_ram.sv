module sync_ram #(
    parameter AW = 4,
    parameter DW = 16,
    parameter DEPTH = 16
)
(
    input                   clk,
    input  [AW-1:0]         waddr,
    input  [AW-1:0]         raddr,
    input  [DW-1:0]         wdata,
    output reg [DW-1:0]     rdata,
    input                   wen,
    input                   ren
);

reg [DW-1:0] mem [0:DEPTH-1];

always @(posedge clk) begin
    if (wen)
        mem[waddr] <= wdata;

    if (ren)
        rdata <= mem[raddr];
end

endmodule


module dp_sram #(
    parameter AW = 5,
    parameter DW = 32
)
(
    input                  wclk,
    input                  rclk,
    input  [AW-1:0]        waddr,
    input  [AW-1:0]        raddr,
    input  [DW-1:0]        wdata,
    output reg [DW-1:0]    rdata,
    input                  wen,
    input                  ren
);

reg [DW-1:0] mem [0:(1<<AW)-1];

always @(posedge wclk) begin
    if (wen)
        mem[waddr] <= wdata;
end

always @(posedge rclk) begin
    if (ren)
        rdata <= mem[raddr];
end

endmodule
