`define  REG_ID_BITS				31:0
`define  REG_ID_WIDTH				32
`define  REG_ID_DEFAULT				32'h12300002
`define  REG_ID_ADDR				32'h0

`define  REG_VERSION_BITS				31:0
`define  REG_VERSION_WIDTH				32
`define  REG_VERSION_DEFAULT				32'h1
`define  REG_VERSION_ADDR				32'h4

`define  REG_FLIP_BITS				31:0
`define  REG_FLIP_WIDTH				32
`define  REG_FLIP_DEFAULT			32'h0
`define  REG_FLIP_ADDR				32'hC

`define  REG_CONTROL_BITS			31:0
`define  REG_CONTROL_WIDTH			32
`define  REG_CONTROL_DEFAULT			32'h0
`define  REG_CONTROL_ADDR			32'h10

`define  REG_PKTS_BITS			63:0
`define  REG_PKTS_WIDTH			64
`define  REG_PKTS_DEFAULT		64'h0
`define  REG_PKTS_ADDR			32'h20

`define  REG_OCTETS_BITS		63:0
`define  REG_OCTETS_WIDTH		64
`define  REG_OCTETS_DEFAULT		64'h0
`define  REG_OCTETS_ADDR		32'h28

`define  REG_OCTETS_IDLE_BITS		63:0
`define  REG_OCTETS_IDLE_WIDTH		64
`define  REG_OCTETS_IDLE_DEFAULT	64'h0
`define  REG_OCTETS_IDLE_ADDR		32'h30

`define  REG_TIMESTAMP_SEC_BITS		63:0
`define  REG_TIMESTAMP_SEC_WIDTH	64
`define  REG_TIMESTAMP_SEC_DEFAULT	64'h0
`define  REG_TIMESTAMP_SEC_ADDR		32'h38

`define  REG_TIMESTAMP_NSEC_BITS	31:0
`define  REG_TIMESTAMP_NSEC_WIDTH	32
`define  REG_TIMESTAMP_NSEC_DEFAULT	32'h0
`define  REG_TIMESTAMP_NSEC_ADDR	32'h40

`define  REG_FRAME_SIZE_BITS		31:0
`define  REG_FRAME_SIZE_WIDTH		32
`define  REG_FRAME_SIZE_DEFAULT		32'h0
`define  REG_FRAME_SIZE_ADDR		32'h44

`define  REG_FRAME_BUF_BITS		31:0
`define  REG_FRAME_BUF_WIDTH		32
`define  REG_FRAME_BUF_DEFAULT		32'h0
`define  REG_FRAME_BUF_ADDR		32'h50

`define  REG_BAD_CRC_PKTS_BITS			63:0
`define  REG_BAD_CRC_PKTS_WIDTH			64
`define  REG_BAD_CRC_PKTS_DEFAULT		64'h0
`define  REG_BAD_CRC_PKTS_ADDR			32'h58

`define  REG_BAD_CRC_OCTETS_BITS		63:0
`define  REG_BAD_CRC_OCTETS_WIDTH		64
`define  REG_BAD_CRC_OCTETS_DEFAULT		64'h0
`define  REG_BAD_CRC_OCTETS_ADDR		32'h60

