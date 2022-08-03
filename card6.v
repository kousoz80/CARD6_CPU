// CARD6 コンピュータシステム
module card6(clock,reset,adrs_bus,data_bus);
input clock,reset;
inout [17:0] adrs_bus;
inout [ 5:0] data_bus;

wire [ 7:0] c_bus;
wire [17:0] a_bus;
wire [17:0] r_bus;
wire [ 5:0] d_bus;
wire [17:0] adrs0;
wire [17:0] adrs1;
wire [ 7:0] control;
wire rd_clk,wr_clk;
wire d_clk,h_clk,m_clk,l_clk;
wire oe_r,oe_d;
wire io,pointer,ret,st,ld,ldh,ldm,ldl;

// 制御信号
assign rd_clk  = clock;
assign wr_clk  = ~clock;
assign d_clk   = rd_clk  | ld;
assign h_clk   = rd_clk  | ldh; 
assign m_clk   = rd_clk  | ldm; 
assign l_clk   = rd_clk  | ldl; 
assign oe_r    = wr_clk  | ret;
assign oe_d    = wr_clk  | st;
assign io      = control[7];
assign pointer = control[6];
assign ret     = control[5];
assign st      = control[4];
assign ld      = c_bus[3];
assign ldh     = c_bus[2];
assign ldm     = c_bus[1];
assign ldl     = c_bus[0];

// メモリ
c_field mem_c(.we(1'b1), .oe(rd_clk), .cs(1'b0), .addr(adrs_bus), .data(c_bus));
a_field mem_a(.we(oe_r), .oe(rd_clk), .cs(1'b0), .addr(adrs_bus), .data(a_bus));
r_field mem_r(.we(1'b1), .oe(rd_clk), .cs(1'b0), .addr(adrs_bus), .data(r_bus));
d_field mem_d(.we(oe_d), .oe(rd_clk), .cs(1'b0), .addr(adrs_bus), .data(d_bus));

// レジスタ
c_reg reg_c(.clk(rd_clk), .oe(1'b0), .d(c_bus), .q(control));
a_reg reg_a(.clk(rd_clk), .oe(1'b0), .d(a_bus), .q(adrs0));
r_reg reg_r(.clk(rd_clk), .oe(oe_r), .d(r_bus), .q(a_bus));
d_reg reg_d(.clk(d_clk),  .oe(oe_d), .d(d_bus), .q(d_bus));
d_reg reg_h(.clk(h_clk),  .oe(1'b0), .d(d_bus), .q(adrs1[17:12]));
d_reg reg_m(.clk(m_clk),  .oe(1'b0), .d(d_bus), .q(adrs1[11: 6]));
d_reg reg_l(.clk(l_clk),  .oe(1'b0), .d(d_bus), .q(adrs1[ 5: 0]));

// セレクタ
adrs_sel select(.sel(pointer), .g(reset), .in0(adrs0), .in1(adrs1), .out(adrs_bus));

endmodule


// Cフィールド
module c_field(we, oe, cs, addr, data);
 parameter DWIDTH=8,AWIDTH=18,WORDS=262144;
 input we,oe,cs;
 input [AWIDTH-1:0] addr;
 inout [DWIDTH-1:0] data;

 reg [DWIDTH-1:0] mem [WORDS-1:0];
 assign data = (~oe & ~cs)? mem[addr] : 8'bZ ;

 always @(~we)
   begin
     if(~cs) mem[addr] <= data;
   end

endmodule


// Aフィールド
module a_field(we, oe, cs, addr, data);
 parameter DWIDTH=18,AWIDTH=18,WORDS=262144;
 input we,oe,cs;
 input [AWIDTH-1:0] addr;
 inout [DWIDTH-1:0] data;

 reg [DWIDTH-1:0] mem [WORDS-1:0];
 assign data = (~oe & ~cs)? mem[addr] : 18'bZ ;

 always @(~we)
   begin
     if(~cs) mem[addr] <= data;
   end

endmodule


// Rフィールド
module r_field(we, oe, cs, addr, data);
 parameter DWIDTH=18,AWIDTH=18,WORDS=262144;
 input we,oe,cs;
 input [AWIDTH-1:0] addr;
 inout [DWIDTH-1:0] data;

 reg [DWIDTH-1:0] mem [WORDS-1:0];
 assign data = (~oe & ~cs)? mem[addr] : 18'bZ ;

 always @(~we)
   begin
     if(~cs) mem[addr] <= data;
   end

endmodule


// Dフィールド
module d_field(we, oe, cs, addr, data);
 parameter DWIDTH=6,AWIDTH=18,WORDS=262144;
 input we,oe,cs;
 input [AWIDTH-1:0] addr;
 inout [DWIDTH-1:0] data;

 reg [DWIDTH-1:0] mem [WORDS-1:0];
 assign data = (!oe && !cs)? mem[addr] : 6'bZ ;

 always @(~we)
   begin
     if(~cs) mem[addr] <= data;
   end

endmodule


// Cレジスタ
module c_reg(clk, oe, d, q);
 parameter DWIDTH=8,AWIDTH=18,WORDS=262144;
 input  clk,oe;
 input  [DWIDTH-1:0] d;
 output [DWIDTH-1:0] q;

 reg [DWIDTH-1:0] r;
 assign q = (~oe)? r : 8'bZ ;

 always @(posedge clk)
   begin
     r <= d;
   end

endmodule


// Aレジスタ
module a_reg(clk, oe, d, q);
 parameter DWIDTH=18,AWIDTH=18,WORDS=262144;
 input  clk,oe;
 input  [DWIDTH-1:0] d;
 output [DWIDTH-1:0] q;

 reg [DWIDTH-1:0] r;
 assign q = (~oe)? r : 18'bZ ;

 always @(posedge clk)
   begin
     r <= d;
   end

endmodule

// Rレジスタ
module r_reg(clk, oe, d, q);
 parameter DWIDTH=18,AWIDTH=18,WORDS=262144;
 input  clk,oe;
 input  [DWIDTH-1:0] d;
 output [DWIDTH-1:0] q;

 reg [DWIDTH-1:0] r;
 assign q = (~oe)? r : 18'b0 ;

 always @(posedge clk)
   begin
     r <= d;
   end

endmodule


// Dレジスタ
module d_reg(clk, oe, d, q);
 parameter DWIDTH=6,AWIDTH=18,WORDS=262144;
 input  clk,oe;
 input  [DWIDTH-1:0] d;
 output [DWIDTH-1:0] q;

 reg [DWIDTH-1:0] r;
 assign q = (~oe)? r : 6'bZ ;

 always @(posedge clk)
   begin
     r <= d;
   end

endmodule


// アドレスセレクタ
module adrs_sel(sel, g, in0, in1, out);
 parameter AWIDTH=18,WORDS=262144;
 input  sel, g;
 input  [AWIDTH-1:0] in0;
 input  [AWIDTH-1:0] in1;
 output [AWIDTH-1:0] out;

 assign out = g? (sel? in1 : in0) : 18'bZ;

 endmodule
