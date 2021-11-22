module sram_axi_trans_bridge(
    input         clk,
    input         rst,

    // inst sram
    input           inst_sram_req       ,
    input           inst_sram_wr        ,
    input   [ 1:0]  inst_sram_size      ,
    input   [ 3:0]  inst_sram_wstrb     ,
    input   [31:0]  inst_sram_addr      ,
    input   [31:0]  inst_sram_wdata     ,
    output          inst_sram_addr_ok   ,   
    output          inst_sram_data_ok   ,    
    output  [31:0]  inst_sram_rdata     ,
    // data sram
    input           data_sram_req       ,
    input           data_sram_wr        ,
    input   [ 1:0]  data_sram_size      ,
    input   [ 3:0]  data_sram_wstrb     ,
    input   [31:0]  data_sram_addr      ,
    input   [31:0]  data_sram_wdata     ,
    output          data_sram_addr_ok   ,   
    output          data_sram_data_ok   ,    
    output  [31:0]  data_sram_rdata     ,   

    // AXI
    output  [ 3:0]  arid    ,
    output  [31:0]  araddr  ,
    output  [ 7:0]  arlen   ,
    output  [ 2:0]  arsize  ,
    output  [ 1:0]  arburst ,
    output  [ 1:0]  arlock  ,
    output  [ 3:0]  arcache ,
    output  [ 2:0]  arprot  ,
    output          arvalid ,
    input           arready ,
                
    input   [ 3:0]  rid     ,
    input   [31:0]  rdata   ,
    input   [ 1:0]  rresp   ,
    input           rlast   ,
    input           rvalid  ,
    output          rready  ,
               
    output  [ 3:0]  awid    ,
    output  [31:0]  awaddr  ,
    output  [ 7:0]  awlen   ,
    output  [ 2:0]  awsize  ,
    output  [ 1:0]  awburst ,
    output  [ 1:0]  awlock  ,
    output  [ 3:0]  awcache ,
    output  [ 2:0]  awprot  ,
    output          awvalid ,
    input           awready ,
    
    output  [ 3:0]  wid     ,
    output  [31:0]  wdata   ,
    output  [ 3:0]  wstrb   ,
    output          wlast   ,
    output          wvalid  ,
    input           wready  ,
    
    input   [ 3:0]  bid     ,
    input   [ 1:0]  bresp   ,
    input           bvalid  ,
    output          bready
);

wire    r_req;
wire    ir_req;
wire    dr_req;
wire    dw_req;
assign ir_req = inst_sram_req & !inst_sram_wr;
assign dr_req = data_sram_req & !data_sram_wr;
assign dw_req = data_sram_req &  data_sram_wr;
assign  r_req = ir_req | dr_req;

// FSM
reg [ 2:0]  ar_status;
always @(posedge clk) begin
    if(!rst) begin
        ar_status <= 3'b001;
    end
    else if(ar_status[0] & r_req) begin
        ar_status <= 3'b010;
    end
    else if(ar_status[1] & arready) begin
        ar_status <= 3'b100;
    end    
    else if(ar_status[1] & !arid & !inst_sram_req) begin
        // inst req may be cancelled
        ar_status <= 3'b001;
    end
    else if(ar_status[2]) begin
        ar_status <= 3'b001;
    end
end

reg [ 1:0] r_status;
always @(posedge clk) begin
    if (!rst) begin
        r_status <= 2'b01;
    end
    else if(r_status[0] & rvalid) begin
        r_status <= 2'b10;
    end
    else if(r_status[1]) begin
        r_status <= 2'b01;
    end
end

reg [ 4:0]  aw_status;
always @(posedge clk) begin
    if(!rst) begin
        aw_status <= 5'b00001;
    end
    else if(aw_status[0] & dw_req) begin
        aw_status <= 5'b00010;
    end
    else if(aw_status[1] & awready) begin
        aw_status <= 5'b00100;
    end
    else if(aw_status[1] & wready) begin
        aw_status <= 5'b01000;
    end
    else if(aw_status[2] & wready | aw_status[3] & awready) begin
        aw_status <= 5'b10000;
    end
    else if(aw_status[4]) begin
        aw_status <= 5'b00001;
    end
end

reg [ 1:0]  b_status;
always @(posedge clk) begin
    if(!rst) begin
        b_status <= 2'b01;
    end
    else if(b_status[0] & bvalid) begin
        b_status <= 2'b10;
    end
    else if(b_status[1]) begin
        b_status <= 2'b01;
    end
end


// AXI read signal
reg [ 3:0] arid_r;
always @(posedge clk) begin
    if(ar_status[0] | ar_status[2]) begin
        arid_r <= dr_req ? 1 : 0;
    end
end
assign arid    = arid_r;
assign araddr  = arid_r ? data_sram_addr : inst_sram_addr;
assign arlen   = 8'h0;
assign arsize  = 3'h4;
assign arburst = 2'h1;
assign arlock  = 2'h0;
assign arcache = 4'h0;
assign arprot  = 3'h0;
assign arvalid = ar_status[1] & (!arid & ir_req | arid & dr_req);

assign rready  = r_status[0];

// AXI write signal
assign awid    = 1'h1;
assign awaddr  = data_sram_addr;
assign awlen   = 8'h0;
assign awsize  = 3'h4;
assign awburst = 2'h1;
assign awlock  = 2'h0;
assign awcache = 2'h0;
assign awprot  = 2'h0;
assign awvalid = aw_status[1] | aw_status[3];

assign wid     = 1'h1;
assign wdata   = data_sram_wdata;
assign wstrb   = data_sram_wstrb;
assign wlast   = 1'h1;
assign wvalid  = aw_status[1] | aw_status[2];

assign bready  = b_status[0];

// SRAM signal
reg [31:0] rdata_r;
reg [ 3:0] rid_r;
reg [ 3:0] awid_r;
reg [ 3:0] bid_r;
always @(posedge clk) begin
    rdata_r <= rdata;
    rid_r   <= rid;
    awid_r  <= awid;
    bid_r   <= bid;
end

assign inst_sram_addr_ok = !arid_r & ar_status[2];
assign inst_sram_data_ok = ! rid_r &  r_status[1];
assign inst_sram_rdata   = rdata_r;
assign data_sram_addr_ok =  arid_r & ar_status[2] | awid_r & aw_status[4];
assign data_sram_data_ok =   rid_r &  r_status[1] |  bid_r &  b_status[1];
assign data_sram_rdata   = rdata_r;

endmodule