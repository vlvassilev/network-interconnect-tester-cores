module bram_io #(
           parameter DATA_WIDTH = 32,
           parameter ADDR_WIDTH = 8
       ) (
           input wire                   rst,

           input  wire                  i_clk,
           input  wire                  i_wr,
           input  wire [ADDR_WIDTH-1:0] i_addr,
           input  wire [DATA_WIDTH-1:0] i_data,

           input  wire                  o_clk,
           input  wire [ADDR_WIDTH-1:0] o_addr,
           output reg  [DATA_WIDTH-1:0] o_data
       );

localparam DATA_DEPTH = 2**ADDR_WIDTH;
integer addr;
integer data;

reg [DATA_WIDTH-1:0] mem [DATA_DEPTH-1:0];

always @(posedge i_clk) begin
    if (i_wr) begin
        mem[i_addr] <= i_data;
        addr = i_addr;
        data = i_data;
    end
end

always @(posedge o_clk) begin
    if (rst) begin
        o_data <= 0;
    end
    else begin
        o_data  <= mem[o_addr];
    end
end
endmodule
