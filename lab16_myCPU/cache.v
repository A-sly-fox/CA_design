module cache(
    input           clk_g     ,
    input           resetn    ,
    
    input           valid     ,
    input           op        ,
    input   [  7:0] index     ,
    input   [  3:0] offset    ,
    input   [ 19:0] tag       ,
    input   [  3:0] wstrb     ,
    input   [ 31:0] wdata     ,
    
    output          addr_ok   ,
    output          data_ok   ,
    output  [ 31:0] rdata     ,
    
    output          rd_req    ,
    output  [  2:0] rd_type   ,
    output  [ 31:0] rd_addr   ,
    input           rd_rdy    ,
    input           ret_valid ,
    input           ret_last  ,
    input   [ 31:0] ret_data  ,
    
    output          wr_req    ,
    output  [  2:0] wr_type   ,
    output  [ 31:0] wr_addr   , 
    output  [  3:0] wr_wstrb  ,
    output  [127:0] wr_data   ,
    input           wr_rdy
);

wire        look_enable ;
wire        enable = 1'b1;
wire [ 7:0] cache_addr;

// ********************RAM IP核的例化******************** //
// Tag_and_V
wire tagv_0_we;
wire [20:0] tagv_0_wvalue;
wire [20:0] tagv_0_rvalue;
TAGV_RAM tagv_0
(
    .clka (clk_g        ),
    .ena  (enable       ),
    .wea  (tagv_0_we    ),
    .addra(cache_addr   ),
    .dina (tagv_0_wvalue),
    .douta(tagv_0_rvalue)
);

wire tagv_1_we;
wire [20:0] tagv_1_wvalue;
wire [20:0] tagv_1_rvalue;
TAGV_RAM tagv_1
(
    .clka (clk_g        ),
    .ena  (enable       ),
    .wea  (tagv_1_we    ),
    .addra(cache_addr   ),
    .dina (tagv_1_wvalue),
    .douta(tagv_1_rvalue)
);

// DATA
wire [ 3:0] bank_0_0_we;
wire [31:0] bank_0_0_wvalue;
wire [31:0] bank_0_0_rvalue;
bank_RAM bank_0_0
(
    .clka (clk_g          ),
    .ena  (enable         ),
    .wea  (bank_0_0_we    ),
    .addra(cache_addr     ),
    .dina (bank_0_0_wvalue),
    .douta(bank_0_0_rvalue)
);

wire [ 3:0] bank_0_1_we;
wire [31:0] bank_0_1_wvalue;
wire [31:0] bank_0_1_rvalue;
bank_RAM bank_0_1
(
    .clka (clk_g          ),
    .ena  (enable         ),
    .wea  (bank_0_1_we    ),
    .addra(cache_addr     ),
    .dina (bank_0_1_wvalue),
    .douta(bank_0_1_rvalue)
);

wire [ 3:0] bank_0_2_we;
wire [31:0] bank_0_2_wvalue;
wire [31:0] bank_0_2_rvalue;
bank_RAM bank_0_2
(
    .clka (clk_g          ),
    .ena  (enable         ),
    .wea  (bank_0_2_we    ),
    .addra(cache_addr     ),
    .dina (bank_0_2_wvalue),
    .douta(bank_0_2_rvalue)
);

wire [ 3:0] bank_0_3_we;
wire [31:0] bank_0_3_wvalue;
wire [31:0] bank_0_3_rvalue;
bank_RAM bank_0_3
(
    .clka (clk_g          ),
    .ena  (enable         ),
    .wea  (bank_0_3_we    ),
    .addra(cache_addr     ),
    .dina (bank_0_3_wvalue),
    .douta(bank_0_3_rvalue)
);

wire [ 3:0] bank_1_0_we;
wire [31:0] bank_1_0_wvalue;
wire [31:0] bank_1_0_rvalue;
bank_RAM bank_1_0
(
    .clka (clk_g          ),
    .ena  (enable         ),
    .wea  (bank_1_0_we    ),
    .addra(cache_addr     ),
    .dina (bank_1_0_wvalue),
    .douta(bank_1_0_rvalue)
);

wire [ 3:0] bank_1_1_we;
wire [31:0] bank_1_1_wvalue;
wire [31:0] bank_1_1_rvalue;
bank_RAM bank_1_1
(
    .clka (clk_g          ),
    .ena  (enable         ),
    .wea  (bank_1_1_we    ),
    .addra(cache_addr     ),
    .dina (bank_1_1_wvalue),
    .douta(bank_1_1_rvalue)
);

wire [ 3:0] bank_1_2_we;
wire [31:0] bank_1_2_wvalue;
wire [31:0] bank_1_2_rvalue;
bank_RAM bank_1_2
(
    .clka (clk_g          ),
    .ena  (enable         ),
    .wea  (bank_1_2_we    ),
    .addra(cache_addr     ),
    .dina (bank_1_2_wvalue),
    .douta(bank_1_2_rvalue)
);

wire [ 3:0] bank_1_3_we;
wire [31:0] bank_1_3_wvalue;
wire [31:0] bank_1_3_rvalue;
bank_RAM bank_1_3
(
    .clka (clk_g          ),
    .ena  (enable         ),
    .wea  (bank_1_3_we    ),
    .addra(cache_addr     ),
    .dina (bank_1_3_wvalue),
    .douta(bank_1_3_rvalue)
);

//Dirty
wire [7:0] d_0_addr_7;
wire [7:0] d_1_addr_7;
wire d_0_we;
wire d_0_out;
wire d_1_we;
wire d_1_out;

Dirty_RAM d_0
(
    .clka (clk_g),
    .wea  (d_0_we ), 
    .addra(d_0_addr_7),
    .dina (d_0_we  ),
    .douta(d_0_out )
);

Dirty_RAM d_1
(
    .clka (clk_g),
    .wea  (d_1_we ), 
    .addra(d_1_addr_7),
    .dina (d_1_we  ),
    .douta(d_1_out )
);

reg [68:0] request_buffer;
wire        op_request     = request_buffer[68];
wire [ 7:0] index_request  = request_buffer[67:60];
wire [19:0] tag_request    = request_buffer[59:40];
wire [ 3:0] offset_request = request_buffer[39:36];
wire [ 3:0] wstrb_request  = request_buffer[35:32];
wire [31:0] wdata_request  = request_buffer[31: 0];

reg  [48:0] write_buffer;
wire        way_write    = write_buffer[48];
wire [ 7:0] index_write  = write_buffer[47:40];
wire [ 3:0] offset_write = write_buffer[39:36];
wire [ 3:0] wstrb_write  = write_buffer[35:32];
wire [31:0] wdata_write  = write_buffer[31: 0];

reg  [150:0] miss_buffer;
wire         way_miss   = miss_buffer[150];
wire         d_miss     = miss_buffer[149];
wire [ 19:0] tag_miss   = miss_buffer[148:129];
wire         v_miss     = miss_buffer[128];
wire [127:0] data_miss  = miss_buffer[127:0];

// ********************状态机部分******************** //
//主状态机
localparam IDLE     = 5'b00001;
localparam LOOKUP   = 5'b00010;
localparam MISS     = 5'b00100;
localparam REPLACE  = 5'b01000;
localparam REFILL   = 5'b10000;
wire state_idle    = State == IDLE;
wire state_lookup  = State == LOOKUP;
wire state_miss    = State == MISS;
wire state_replace = State == REPLACE;
wire state_refill  = State == REFILL;

reg [4:0] State;
reg [4:0] State_next;
always @(posedge clk_g) begin
    if(~resetn)
        State <= IDLE;
    else 
        State <= State_next;
end

always @(*) begin
    case (State)
        IDLE:begin
            if (look_enable)       
                State_next = LOOKUP;
            else
                State_next = IDLE;
        end

        LOOKUP:begin
            if (look_enable & cache_hit)
                State_next = LOOKUP;
            else if (~look_enable & cache_hit)
                State_next = IDLE;
            else if (~cache_hit)
                State_next = MISS;
        end

        MISS:begin
            if (wr_rdy)        
                State_next = REPLACE;
            else
                State_next = MISS;
        end

        REPLACE:begin
            if (rd_rdy) 
                State_next = REFILL;
            else
                State_next = REPLACE;
        end

        REFILL:begin
            if (refill_end)
                State_next = IDLE;
            else 
                State_next = REFILL;
        end

        default: State_next = IDLE;
    endcase
end

//Write Buffer状态机
localparam IDLE_W = 2'b01;
localparam WRITE  = 2'b10;
wire state_idle_w = State_wr == IDLE_W;
wire state_write  = State_wr == WRITE;

reg [1:0] State_wr;
reg [1:0] State_next_wr;
always @(posedge clk_g) begin
    if(~resetn)
        State_wr <= IDLE_W;
    else 
        State_wr <= State_next_wr;
end

always @(*) begin
    case(State_wr)
        IDLE_W:begin
            if (cache_hit & op_request)
                State_next_wr = WRITE;
            else 
                State_next_wr = IDLE_W;
        end

        WRITE:begin
            if (cache_hit & op_request)
                State_next_wr = WRITE;
            else 
                State_next_wr = IDLE_W;
        end

        default: State_next_wr = IDLE_W;
    endcase
end

wire [31:0] way0_word;
wire [31:0] way1_word;

reg [127:0] refill_data;
reg         refill_end ;
wire[ 31:0] refill_word;

wire offset_request_00 = offset_request[3:2] == 2'b00;
wire offset_request_01 = offset_request[3:2] == 2'b01;
wire offset_request_10 = offset_request[3:2] == 2'b10;
wire offset_request_11 = offset_request[3:2] == 2'b11;
wire offset_write_00   = offset_write[3:2] == 2'b00;
wire offset_write_01   = offset_write[3:2] == 2'b01;
wire offset_write_10   = offset_write[3:2] == 2'b10;
wire offset_write_11   = offset_write[3:2] == 2'b11;

// Request Buffer
always @(posedge clk_g) begin
    if (~resetn) 
        request_buffer <= 69'b0;
    else if (look_enable) begin
        request_buffer <= {op, index, tag, offset, wstrb, wdata}; 
    end
end 

// Tag Compare
wire way0_hit = tagv_0_rvalue[0] && (tagv_0_rvalue[20:1] == tag_request) && state_lookup;
wire way1_hit = tagv_1_rvalue[0] && (tagv_1_rvalue[20:1] == tag_request) && state_lookup;
wire cache_hit = way0_hit | way1_hit;

// Data Select
assign way0_word = {32{offset_request_00}} & bank_0_0_rvalue 
                 | {32{offset_request_01}} & bank_0_1_rvalue 
                 | {32{offset_request_10}} & bank_0_2_rvalue 
                 | {32{offset_request_11}} & bank_0_3_rvalue;
assign way1_word = {32{offset_request_00}} & bank_1_0_rvalue 
                 | {32{offset_request_01}} & bank_1_1_rvalue 
                 | {32{offset_request_10}} & bank_1_2_rvalue 
                 | {32{offset_request_11}} & bank_1_3_rvalue;

// Miss Buffer
always @(posedge clk_g) begin
    if (~resetn) begin
        miss_buffer <= 151'b0;
    end
    else if (state_lookup && !cache_hit) begin
        miss_buffer[150]     <= way_rand;
        miss_buffer[149]     <= way_rand ? d_1_out : d_0_out;
        miss_buffer[148:128] <= way_rand ? tagv_1_rvalue : tagv_0_rvalue;
        miss_buffer[127:  0] <= way_rand ? {bank_1_0_rvalue, bank_1_1_rvalue, bank_1_2_rvalue, bank_1_3_rvalue}
                                         : {bank_0_0_rvalue, bank_0_1_rvalue, bank_0_2_rvalue, bank_0_3_rvalue};
    end
    else if (state_idle) begin
        miss_buffer <= 151'b0;
    end
end

// Write Buffer
always @(posedge clk_g) begin
    if (~resetn) begin
        write_buffer <= 49'b0;
    end 
    else if (cache_hit & op_request) begin
        write_buffer <= {way1_hit, index_request, offset_request, wstrb_request, wdata_request};
   end 
end

// LFSR线性反馈移位寄存器
reg [7:0] rand;
wire      way_rand = rand[0];
always@(posedge clk_g) begin   
    if(~resetn)
        rand <= 4'b0001;
    else begin 
        rand[0] <= rand[3];
        rand[1] <= rand[0] ^ rand[3];
        rand[2] <= rand[1] ^ rand[3];
        rand[3] <= rand[2] ^ rand[3];
    end
end

assign look_enable = valid & (state_idle | (state_lookup  & cache_hit & ~op_request) 
                           | (state_lookup && (cache_hit & op_request) && (index_request != index))
                           | (state_write && !((offset_write[3:2] == offset[3:2]) && (index_request == index))));
assign cache_addr = state_write ? index_write  :
                    look_enable ? index        :
                                  index_request;

assign bank_0_0_we = (state_write & ~way_write & offset_write_00) ? wstrb_write :
                                         (refill_end & ~way_miss) ? 4'b1111     :
                                                                    4'b0        ;
assign bank_0_1_we = (state_write & ~way_write & offset_write_01) ? wstrb_write :
                                         (refill_end & ~way_miss) ? 4'b1111     :
                                                                    4'b0        ;
assign bank_0_2_we = (state_write & ~way_write & offset_write_10) ? wstrb_write :
                                         (refill_end & ~way_miss) ? 4'b1111     :
                                                                    4'b0        ;
assign bank_0_3_we = (state_write & ~way_write & offset_write_11) ? wstrb_write :
                                         (refill_end & ~way_miss) ? 4'b1111     :
                                                                    4'b0        ;
assign bank_1_0_we = (state_write & way_write & offset_write_00) ? wstrb_write  :
                                         (refill_end & way_miss) ? 4'b1111      :
                                                                   4'b0         ;
assign bank_1_1_we = (state_write & way_write & offset_write_01) ? wstrb_write  :
                                         (refill_end & way_miss) ? 4'b1111      :
                                                                   4'b0         ;
assign bank_1_2_we = (state_write & way_write & offset_write_10) ? wstrb_write  :
                                         (refill_end & way_miss) ? 4'b1111      :
                                                                   4'b0         ;
assign bank_1_3_we = (state_write & way_write & offset_write_11) ? wstrb_write  :
                                         (refill_end & way_miss) ? 4'b1111      :
                                                                   4'b0         ;

assign bank_0_0_wvalue = ~way_miss ? refill_data[31:0]   : wdata_write;
assign bank_0_1_wvalue = ~way_miss ? refill_data[63:32]  : wdata_write;
assign bank_0_2_wvalue = ~way_miss ? refill_data[95:64]  : wdata_write;
assign bank_0_3_wvalue = ~way_miss ? refill_data[127:96] : wdata_write;
assign bank_1_0_wvalue =  way_miss ? refill_data[31:0]   : wdata_write;
assign bank_1_1_wvalue =  way_miss ? refill_data[63:32]  : wdata_write;
assign bank_1_2_wvalue =  way_miss ? refill_data[95:64]  : wdata_write;
assign bank_1_3_wvalue =  way_miss ? refill_data[127:96] : wdata_write;

assign d_0_we = (state_write & ~way_write) | (refill_end & ~way_miss);
assign d_1_we = (state_write &  way_write) | (refill_end &  way_miss);
assign d_0_addr_7 = (state_write & ~way_write) ? index_write : index_request;
assign d_1_addr_7 = (state_write &  way_write) ? index_write : index_request;

always @(posedge clk_g) begin
    if (~resetn)
        refill_end <= 1'b0;
    else if (state_refill && ret_valid && ret_last)
        refill_end <= 1'b1;
    else
        refill_end <= 1'b0;
end

assign tagv_0_we = ~way_miss ? refill_end : 1'b0;
assign tagv_0_wvalue = {tag_request, 1'b1};
assign tagv_1_we = way_miss ? refill_end : 1'b0;
assign tagv_1_wvalue = {tag_request, 1'b1};

reg [1:0] count;
always @(posedge clk_g) begin
    if(~resetn)
        count <= 2'b0;
    else if (ret_valid & state_refill & ~ret_last)
        count <= count + 2'b01;
    else
        count <= 2'b0;
end

always @(posedge clk_g) begin
    if (~resetn)
        refill_data <= 128'b0;
    else if (ret_valid && state_refill) begin
        if (count == 2'b00)
            refill_data[ 31: 0] <= ret_data;
        else if (count == 2'b01)
            refill_data[ 63:32] <= ret_data;
        else if (count == 2'b10)
            refill_data[ 95:64] <= ret_data;
        else if (count == 2'b11)
            refill_data[127:96] <= ret_data;
    end
end

assign refill_word = ({32{offset_request_00}} & refill_data[ 31: 0])
                   | ({32{offset_request_01}} & refill_data[ 63:32])
                   | ({32{offset_request_10}} & refill_data[ 95:64])
                   | ({32{offset_request_11}} & refill_data[127:96]);

// 端口的设计
assign addr_ok = look_enable;
assign data_ok = state_lookup & cache_hit | refill_end;
assign rdata = {32{way0_hit}}   & way0_word
             | {32{way1_hit}}   & way1_word
             | {32{~cache_hit}} & refill_word;

reg wr_req_r;
always @(posedge clk_g) begin
    if (~resetn) 
        wr_req_r <= 1'b0;
    else if (state_miss & wr_rdy & d_miss & v_miss)
        wr_req_r <= 1'b1;
    else 
        wr_req_r <= 1'b0;
end

assign wr_req = wr_req_r;
assign wr_type = 3'b100;
assign wr_addr = {tag_miss, index_request, 4'b0};
assign wr_wstrb = 4'b0;
assign wr_data = data_miss;

assign rd_req  = state_replace;
assign rd_type = 3'b100;
assign rd_addr = {tag_request, index_request, count, 2'b0};

endmodule