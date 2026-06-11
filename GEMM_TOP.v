`timescale 1ns / 1ps

module GEMM_TOP
#(
    parameter integer C_S_AXI_DATA_WIDTH = 32,
    parameter integer C_S_AXI_ADDR_WIDTH = 4
)
(
    //----------------------------------
    // AXI-Lite Control
    //----------------------------------
    input wire  S_AXI_ACLK,
    input wire  S_AXI_ARESETN,

    input wire [C_S_AXI_ADDR_WIDTH-1:0] S_AXI_AWADDR,
    input wire [2:0] S_AXI_AWPROT,
    input wire S_AXI_AWVALID,
    output wire S_AXI_AWREADY,

    input wire [C_S_AXI_DATA_WIDTH-1:0] S_AXI_WDATA,
    input wire [(C_S_AXI_DATA_WIDTH/8)-1:0] S_AXI_WSTRB,
    input wire S_AXI_WVALID,
    output wire S_AXI_WREADY,

    output wire [1:0] S_AXI_BRESP,
    output wire S_AXI_BVALID,
    input wire S_AXI_BREADY,

    input wire [C_S_AXI_ADDR_WIDTH-1:0] S_AXI_ARADDR,
    input wire [2:0] S_AXI_ARPROT,
    input wire S_AXI_ARVALID,
    output wire S_AXI_ARREADY,

    output wire [C_S_AXI_DATA_WIDTH-1:0] S_AXI_RDATA,
    output wire [1:0] S_AXI_RRESP,
    output wire S_AXI_RVALID,
    input wire S_AXI_RREADY,

    //----------------------------------
    // Feature AXIS Slave
    //----------------------------------
    input  wire         feature_axis_aclk,
    input  wire         feature_axis_aresetn,
    output wire         feature_axis_tready,
    input  wire [127:0] feature_axis_tdata,
    input  wire [15:0]  feature_axis_tstrb,
    input  wire         feature_axis_tlast,
    input  wire         feature_axis_tvalid,

    //----------------------------------
    // Weight AXIS Slave
    //----------------------------------
    input  wire         weight_axis_aclk,
    input  wire         weight_axis_aresetn,
    output wire         weight_axis_tready,
    input  wire [127:0] weight_axis_tdata,
    input  wire [15:0]  weight_axis_tstrb,
    input  wire         weight_axis_tlast,
    input  wire         weight_axis_tvalid,

    //----------------------------------
    // Result AXIS Master
    //----------------------------------
    input  wire         result_axis_aclk,
    input  wire         result_axis_aresetn,
    output wire         result_axis_tvalid,
    output wire [127:0] result_axis_tdata,
    output wire [15:0]  result_axis_tstrb,
    output wire         result_axis_tlast,
    input  wire         result_axis_tready
);


//=====================================================
// AXI-Lite Control Registers
//=====================================================

wire [9:0] shift;
wire [8:0] F_length;
wire [4:0] F_width;
wire [4:0] W_width;

axi4lite_v1_0_S0_AXI4Lite #(
    .C_S_AXI_DATA_WIDTH(C_S_AXI_DATA_WIDTH),
    .C_S_AXI_ADDR_WIDTH(C_S_AXI_ADDR_WIDTH)
)
u_axi_ctrl
(
    .shift_out(shift),
    .F_length_out(F_length),
    .F_width_out(F_width),
    .W_width_out(W_width),

    .S_AXI_ACLK(S_AXI_ACLK),
    .S_AXI_ARESETN(S_AXI_ARESETN),

    .S_AXI_AWADDR(S_AXI_AWADDR),
    .S_AXI_AWPROT(S_AXI_AWPROT),
    .S_AXI_AWVALID(S_AXI_AWVALID),
    .S_AXI_AWREADY(S_AXI_AWREADY),

    .S_AXI_WDATA(S_AXI_WDATA),
    .S_AXI_WSTRB(S_AXI_WSTRB),
    .S_AXI_WVALID(S_AXI_WVALID),
    .S_AXI_WREADY(S_AXI_WREADY),

    .S_AXI_BRESP(S_AXI_BRESP),
    .S_AXI_BVALID(S_AXI_BVALID),
    .S_AXI_BREADY(S_AXI_BREADY),

    .S_AXI_ARADDR(S_AXI_ARADDR),
    .S_AXI_ARPROT(S_AXI_ARPROT),
    .S_AXI_ARVALID(S_AXI_ARVALID),
    .S_AXI_ARREADY(S_AXI_ARREADY),

    .S_AXI_RDATA(S_AXI_RDATA),
    .S_AXI_RRESP(S_AXI_RRESP),
    .S_AXI_RVALID(S_AXI_RVALID),
    .S_AXI_RREADY(S_AXI_RREADY)
);


//=====================================================
// AXIS Signals
//=====================================================

wire [127:0] feature_data;
wire         feature_valid;
wire         feature_last;
wire         feature_ready;

wire [127:0] weight_data;
wire         weight_valid;
wire         weight_last;
wire         weight_ready;

wire [127:0] result_data;
wire         result_valid;
wire         result_last;
wire         result_ready;


//=====================================================
// Feature AXIS
//=====================================================

feature_axis_v1_0 u_feature_axis
(
    .feature_data(feature_data),
    .feature_valid(feature_valid),
    .feature_last(feature_last),
    .feature_ready(feature_ready),

    .feature_axis_aclk(feature_axis_aclk),
    .feature_axis_aresetn(feature_axis_aresetn),
    .feature_axis_tready(feature_axis_tready),
    .feature_axis_tdata(feature_axis_tdata),
    .feature_axis_tstrb(feature_axis_tstrb),
    .feature_axis_tlast(feature_axis_tlast),
    .feature_axis_tvalid(feature_axis_tvalid)
);


//=====================================================
// Weight AXIS
//=====================================================

weight_axis_v1_0 u_weight_axis
(
    .weight_data(weight_data),
    .weight_valid(weight_valid),
    .weight_last(weight_last),
    .weight_ready(weight_ready),

    .weight_axis_aclk(weight_axis_aclk),
    .weight_axis_aresetn(weight_axis_aresetn),
    .weight_axis_tready(weight_axis_tready),
    .weight_axis_tdata(weight_axis_tdata),
    .weight_axis_tstrb(weight_axis_tstrb),
    .weight_axis_tlast(weight_axis_tlast),
    .weight_axis_tvalid(weight_axis_tvalid)
);


//=====================================================
// GEMM Core
//=====================================================

MM_ultra u_mm
(
    .clk(S_AXI_ACLK),
    .rst_n(S_AXI_ARESETN),

    .shift_in(shift),
    .F_length_in(F_length),
    .F_width_block_num_in(F_width),
    .W_width_block_num_in(W_width),

    .in_F_valid(feature_valid),
    .in_F_last(feature_last),
    .in_F_ready(feature_ready),
    .in_F_data(feature_data),

    .in_W_valid(weight_valid),
    .in_W_last(weight_last),
    .in_W_ready(weight_ready),
    .in_W_data(weight_data),

    .out_data_valid(result_valid),
    .out_data_ready(result_ready),
    .out_data_last(result_last),
    .out_data(result_data)
);


//=====================================================
// Result AXIS
//=====================================================

result_axis_v1_0 u_result_axis
(
    .result_data(result_data),
    .result_valid(result_valid),
    .result_last(result_last),
    .result_ready(result_ready),

    .result_axis_aclk(result_axis_aclk),
    .result_axis_aresetn(result_axis_aresetn),

    .result_axis_tvalid(result_axis_tvalid),
    .result_axis_tdata(result_axis_tdata),
    .result_axis_tstrb(result_axis_tstrb),
    .result_axis_tlast(result_axis_tlast),
    .result_axis_tready(result_axis_tready)
);

endmodule