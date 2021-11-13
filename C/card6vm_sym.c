// "card6vm_sym.c" CARD6エミュレータのC言語による実装 ver 1.0
// コンパイル: gcc -ptherad -o card6vm_sym card6vm_sym.c 

#include <stdio.h>
#include <pthread.h>
#include <termios.h>
#include <errno.h>
#include <unistd.h>
#include <fcntl.h>

// I/Oポート
int KeyCode, KeyCode0;
int PrtData;
int is_break;


// アドレス設定
#define MEM_SIZE	0x40000
#define VM_START    0x9000
#define REG_PC 	 	0x3ffec
#define REG_SP 		0x3ffef
#define REG_R0 		0x3fff2
#define REG_R1 		0x3fff5
#define REG_R2 		0x3fff8
#define REG_R3 		0x3fffb

// 仮想マシンのレジスタセット(メモリアクセスで読み書き可能)
int reg_pc;	// PC: プログラムカウンタ
int reg_sp;	// SP: スタックポインタ
int reg_r0;	// R0: レジスタ0
int reg_r1;	// R1: レジスタ1
int reg_r2;	// R2: レジスタ2
int reg_r3;	// R3: レジスタ3

// メモリ
static int mem[MEM_SIZE];

// 仮想マシンの命令セット
enum card6vm_ins {
 hlt,		// 停止する
 jmp,		// ジャンプする(アドレスは直接指定)
 xxjmp,		// r0に格納されているアドレスにジャンプする
 jge,		// r1>=r0ならジャンプする
 jlt,		// r1>r0ならジャンプする
 jz,		// r1==r0ならジャンプする
 jnz,		// r1!=r0ならジャンプする
 call,		// サブルーチンを呼び出す(アドレスは直接指定)
 callxx,	// サブルーチンを呼び出す(アドレスは間接指定)
 xxcall,	// r0に格納されているアドレスを呼び出す
 ret,		// サブルーチンから復帰する
 add,		// r0=r1+r0
 sub,		// r0=r1-r0
 mul,		// r0=r1*r0
 div,		// r0=r1/r0
 umul,		// r0=r1*r0(符号なし)
 udiv,		// r0=r1/r0(符号なし)
 mod,		// r0=r1%r0
 and,		// r0=r1&r0
 or,		// r0=r1|r0
 neg,		// r0=-r0
 not,		// r0=~r0
 in,		// ポートから入力した値をr0にセット
 out,		// r0の値をポートに出力
 swap,		// r0とr1の値を入れ替える
 pushr,		// レジスタファイル(r1-r3)にr0の値をプッシュ
 popr,		// レジスタファイル(r1-r3)からr0に値をポップ
 pushs,		// スタックにr0の値をプッシュ
 pops,		// スタックからr0に値をポップ
 inc_l,		// オペランド(ロング型)をインクリメント
 dec_l,		// オペランド(ロング型)をデクリメント
 inc_b,		// オペランド(バイト型)をインクリメント
 dec_b,		// オペランド(バイト型)をデクリメント
 callxx_mbr,// 構造体のメンバに格納されているアドレスを呼び出す
 st_mbr_l,	// 構造体のメンバ(ロング型)にr0の値を格納する
 st_mbr_b,	// 構造体のメンバ(バイト型)にr0の値を格納する
 ld_mbr_l,	// 構造体のメンバ(ロング型)の値をr0にロードする
 ld_mbr_b,	// 構造体のメンバ(バイト型)の値をr0にロードする
 lea_mbr,	// 構造体のメンバのアドレスをr0にロードする
 ldxx_a_v_l,// 配列の要素(ロング型)の値をr0にロードする(配列のアドレスは間接指定,インデックスは変数)
 ld_a_v_l,	// 配列の要素(ロング型)の値をr0にロードする(配列のアドレスは直接指定,インデックスは変数)
 ldxx_a_v_b,// 配列の要素(バイト型)の値をr0にロードする(配列のアドレスは間接指定,インデックスは変数)
 ld_a_v_b,	// 配列の要素(バイト型)の値をr0にロードする(配列のアドレスは直接指定,インデックスは変数)
 stxx_a_v_l,// r0の値を配列の要素(ロング型)に格納する(配列のアドレスは間接指定,インデックスは変数)
 st_a_v_l,	// r0の値を配列の要素(ロング型)に格納する(配列のアドレスは直接指定,インデックスは変数)
 stxx_a_v_b,// r0の値を配列の要素(バイト型)に格納する(配列のアドレスは間接指定,インデックスは変数)
 st_a_v_b,	// r0の値を配列の要素(バイト型)に格納する(配列のアドレスは直接指定,インデックスは変数)
 ldxx_a_k_l,// 配列の要素(ロング型)の値をr0にロードする(配列のアドレスは間接指定,インデックスは定数)
 ld_a_k_l,	// 配列の要素(ロング型)の値をr0にロードする(配列のアドレスは直接指定,インデックスは定数)
 ldxx_a_k_b,// 配列の要素(バイト型)の値をr0にロードする(配列のアドレスは間接指定,インデックスは定数)
 ld_a_k_b,	// 配列の要素(バイト型)の値をr0にロードする(配列のアドレスは直接指定,インデックスは定数)
 stxx_a_k_l,// r0の値を配列の要素(ロング型)に格納する(配列のアドレスは間接指定,インデックスは定数)
 st_a_k_l,	// r0の値を配列の要素(ロング型)に格納する(配列のアドレスは直接指定,インデックスは定数)
 stxx_a_k_b,// r0の値を配列の要素(バイト型)に格納する(配列のアドレスは間接指定,インデックスは定数)
 st_a_k_b,	// r0の値を配列の要素(バイト型)に格納する(配列のアドレスは直接指定,インデックスは定数)
 ldxx_v_l,	// 変数(ロング型)の値をr0にロードする(アドレスは間接指定)
 ld_v_l,	// 変数(ロング型)の値をr0にロードする(アドレスは直接指定)
 ldxx_v_b,	// 変数(バイト型)の値をr0にロードする(アドレスは間接指定)
 ld_v_b,	// 変数(バイト型)の値をr0にロードする(アドレスは直接指定)
 ld_k,		// 定数をr0にセットする
 stxx_v_l,	// r0の値を変数(ロング型)に格納する(アドレスは間接指定)
 st_v_l,	// r0の値を変数(ロング型)に格納する(アドレスは直接指定)
 stxx_v_b,	// r0の値を変数(バイト型)に格納する(アドレスは間接指定)
 st_v_b		// r0の値を変数(バイト型)に格納する(アドレスは直接指定)
};


// プログラムをロード
int load_prog( char* fname ){
  FILE* fp;
  int adrs, data;

printf("load prog file\r\n");

  // ファイルがない場合はエラー
if( ( fp = fopen( fname, "r" ) ) == NULL ){
    printf("file not found.\n");
    return -1;
  }

  while(1){
    if( fscanf( fp, "%d\n",  &adrs ) < 1 ) break;
    if( fscanf( fp, "%d\n",  &data ) < 1 ) break;
    mem[ adrs ] = data;
  }
  fclose( fp );

printf("load prog file end\r\n");

  return 0;
}


// 1文字取得
int getch(){
  struct termios oldt, newt;
  int ch;
  int oldf;

  tcgetattr(STDIN_FILENO, &oldt);
  newt = oldt;
  newt.c_lflag &= ~(ICANON | ECHO);
  tcsetattr(STDIN_FILENO, TCSANOW, &newt);
  oldf = fcntl(STDIN_FILENO, F_GETFL, 0);
  fcntl(STDIN_FILENO, F_SETFL, oldf | O_NONBLOCK);
  ch = getchar();
  tcsetattr(STDIN_FILENO, TCSANOW, &oldt);
  fcntl(STDIN_FILENO, F_SETFL, oldf);
  return ch == EOF? 0 : ch;
}


// I/O同期処理
void io_sync(){

if( PrtData != 0xff ){
  int c = PrtData;
  if(c == 61 ) c = '\n';// 改行コード
  else if(c == 62 ) c = '\r';// エスケープコード
  else if(c == 63 ) c = '\0';// ヌル文字
  else c+= 32;
  putchar(c);
  PrtData = 0xff;
}

}


// 1サイクル実行
void exec_one_cycle(){
  enum card6vm_ins ins;	// 命令コード
  int adr, tmp, opr1, opr2, t0, t1;
  int access0=-1, access1=-1;

    // 命令コードをフェッチ
    ins = mem[ reg_pc++ ];

    // 命令コードに応じた処理
    switch( ins ){

case hlt:		// 停止する
is_break = 1;
break;

case jmp:		// ジャンプする(アドレスは直接指定)
opr1 = mem[reg_pc++] | (mem[reg_pc++] << 6) | (mem[reg_pc++] << 12);
reg_pc = opr1;
break;

case xxjmp:		// r0に格納されているアドレスにジャンプする
reg_pc = reg_r0;
break;

case jge:		// 演算結果が>=0ならジャンプする
opr1 = mem[reg_pc++] | (mem[reg_pc++] << 6) | (mem[reg_pc++] << 12);
t0 = reg_r0>=0x20000? reg_r0-0x40000 : reg_r0;
t1 = reg_r1>=0x20000? reg_r1-0x40000 : reg_r1;
if( t1 >= t0 ) reg_pc = opr1;
break;

case jlt:		// 演算結果が>0ならジャンプする
opr1 = mem[reg_pc++] | (mem[reg_pc++] << 6) | (mem[reg_pc++] << 12);
t0 = reg_r0>=0x20000? reg_r0-0x40000 : reg_r0;
t1 = reg_r1>=0x20000? reg_r1-0x40000 : reg_r1;
if( t1 < t0 ) reg_pc = opr1;
break;

case jz:		// 演算結果が==0ならジャンプする
opr1 = mem[reg_pc++] | (mem[reg_pc++] << 6) | (mem[reg_pc++] << 12);
if( reg_r1 == reg_r0 ) reg_pc = opr1;
break;

case jnz:		// 演算結果が!=0ならジャンプする
opr1 = mem[reg_pc++] | (mem[reg_pc++] << 6) | (mem[reg_pc++] << 12);
if( reg_r1 != reg_r0 ) reg_pc = opr1;
break;

case call:		// サブルーチンを呼び出す(アドレスは直接指定)
opr1 = mem[reg_pc++] | (mem[reg_pc++] << 6) | (mem[reg_pc++] << 12);
mem[ --reg_sp ] = (reg_pc>>12) & 0x3f;
mem[ --reg_sp ] = (reg_pc>>6)  & 0x3f;
mem[ --reg_sp ] = (reg_pc>>0)  & 0x3f;
reg_pc = opr1;
break;

case callxx:	// サブルーチンを呼び出す(アドレスは間接指定)
opr1 = mem[reg_pc++] | (mem[reg_pc++] << 6) | (mem[reg_pc++] << 12);
mem[ --reg_sp ] = (reg_pc>>12) & 0x3f;
mem[ --reg_sp ] = (reg_pc>>6)  & 0x3f;
mem[ --reg_sp ] = (reg_pc>>0)  & 0x3f;
reg_pc = mem[opr1++] | (mem[opr1++] << 6) | (mem[opr1] << 12);
break;

case xxcall:	// reg_r0に格納されているアドレスを呼び出す
mem[ --reg_sp ] = (reg_pc>>12) & 0x3f;
mem[ --reg_sp ] = (reg_pc>>6)  & 0x3f;
mem[ --reg_sp ] = (reg_pc>>0)  & 0x3f;
reg_pc = reg_r0;
break;

case ret:		// サブルーチンから復帰する
reg_pc = mem[ reg_sp++ ] | (mem[ reg_sp++ ] << 6) | (mem[ reg_sp++ ] << 12);
break;

case add:		// r0=r1+r0
reg_r0=(reg_r1+reg_r0)&0x3ffff;
break;

case sub:		// r0=r1-r0
reg_r0=(reg_r1-reg_r0)&0x3ffff;
break;

case mul:		// r0=r1*r0
reg_r0=(reg_r1*reg_r0)&0x3ffff;
break;

case div:		// r0=r1/r0
reg_r0=reg_r1/reg_r0;
break;

case umul:		// r0=r1*r0(符号なし)
reg_r0=(reg_r1&0x3ffff)*(reg_r0&0x3ffff);
break;

case udiv:		// r0=r1/r0(符号なし)
reg_r0=(reg_r1&0x3ffff)/(reg_r0&0x3ffff);
break;

case mod:		// r0=r1%r0
reg_r0=reg_r1%reg_r0;
break;

case and:		// r0=r1&r0
reg_r0=reg_r1&reg_r0;
break;

case or:		// r0=r1|r0
reg_r0=reg_r1|reg_r0;
break;

case neg:		// r0=-r0
reg_r0=(-reg_r0)&0x3ffff;
break;

case not:		// r0=~r0
reg_r0=(~reg_r0)&0x3ffff;
break;

case in:		// ポートから入力した値をr0にセット
reg_r0= KeyCode0 & 0x3f;
KeyCode0 = 0x3f;
break;

case out:		// r0の値をポートに出力
PrtData= reg_r0 & 0x3f;
break;

case swap:		// r0とr1の値を入れ替える
tmp=reg_r0;
reg_r0=reg_r1;
reg_r1=tmp;
break;

case pushr:		// レジスタファイル(r1-r3)にr0の値をプッシュ
reg_r3 = reg_r2;
reg_r2 = reg_r1;
reg_r1 = reg_r0;
break;

case popr:		// レジスタファイル(r1-r3)からr0に値をポップ
reg_r0 = reg_r1;
reg_r1 = reg_r2;
reg_r2 = reg_r3;
break;

case pushs:		// スタックにr0の値をプッシュ
mem[ --reg_sp ] = (reg_r0>>12) & 0x3f;
mem[ --reg_sp ] = (reg_r0>>6)  & 0x3f;
mem[ --reg_sp ] = (reg_r0>>0)  & 0x3f;
access1 = (access0 = reg_sp)+2;
break;

case pops:		// スタックからr0に値をポップ
reg_r0 = mem[ reg_sp++ ] | (mem[ reg_sp++ ] << 6) | (mem[ reg_sp++ ] << 12);
break;

case inc_l:		// オペランド(ロング型)をインクリメント
opr1 = mem[reg_pc++] | (mem[reg_pc++] << 6) | (mem[reg_pc++] << 12);
tmp = mem[opr1++] | (mem[opr1++] << 6) | (mem[opr1] << 12);
tmp++;
mem[ opr1-- ] = (tmp>>12) & 0x3f;
mem[ opr1-- ] = (tmp>>6)  & 0x3f;
mem[ opr1   ] = (tmp>>0)  & 0x3f;
access1 = (access0 = opr1)+2;
break;

case dec_l:		// オペランド(ロング型)をデクリメント
opr1 = mem[reg_pc++] | (mem[reg_pc++] << 6) | (mem[reg_pc++] << 12);
tmp = mem[opr1++] | (mem[opr1++] << 6) | (mem[opr1] << 12);
tmp--;
mem[ opr1-- ] = (tmp>>12) & 0x3f;
mem[ opr1-- ] = (tmp>>6)  & 0x3f;
mem[ opr1   ] = (tmp>>0)  & 0x3f;
access1 = (access0 = opr1)+2;
break;

case inc_b:		// オペランド(バイト型)をインクリメント
opr1 = mem[reg_pc++] | (mem[reg_pc++] << 6) | (mem[reg_pc++] << 12);
tmp = mem[opr1];
tmp++;
mem[ opr1 ] = tmp & 0x3f;
access1 = (access0 = opr1)+0;
break;

case dec_b:		// オペランド(バイト型)をデクリメント
opr1 = mem[reg_pc++] | (mem[reg_pc++] << 6) | (mem[reg_pc++] << 12);
tmp = mem[opr1];
tmp--;
mem[ opr1 ] = tmp & 0x3f;
access1 = (access0 = opr1)+0;
break;

case callxx_mbr:// 構造体のメンバに格納されているアドレスを呼び出す
opr1 = mem[reg_pc++] | (mem[reg_pc++] << 6) | (mem[reg_pc++] << 12);
opr1 += reg_r0;
opr1&=0x3ffff;
adr = mem[opr1++] | (mem[opr1++] << 6) | (mem[opr1] << 12);
mem[ --reg_sp ] = (reg_pc>>12) & 0x3f;
mem[ --reg_sp ] = (reg_pc>>6)  & 0x3f;
mem[ --reg_sp ] = (reg_pc>>0)  & 0x3f;
reg_pc = adr;
break;

case st_mbr_l:	// 構造体のメンバ(ロング型)にr1の値を格納する
opr1 = mem[reg_pc++] | (mem[reg_pc++] << 6) | (mem[reg_pc++] << 12);
opr1 += reg_r0;
opr1&=0x3ffff;
mem[ opr1++ ] = (reg_r1>>0)  & 0x3f;
mem[ opr1++ ] = (reg_r1>>6)  & 0x3f;
mem[ opr1   ] = (reg_r1>>12) & 0x3f;
access0 = (access1 = opr1)-2;
break;

case st_mbr_b:	// 構造体のメンバ(バイト型)にr1の値を格納する
opr1 = mem[reg_pc++] | (mem[reg_pc++] << 6) | (mem[reg_pc++] << 12);
opr1 += reg_r0;
opr1&=0x3ffff;
mem[ opr1 ] = reg_r1 & 0x3f;
access1 = (access0 = opr1)+0;
break;

case ld_mbr_l:	// 構造体のメンバ(ロング型)の値をr0にロードする
opr1 = mem[reg_pc++] | (mem[reg_pc++] << 6) | (mem[reg_pc++] << 12);
opr1 += reg_r0;
opr1&=0x3ffff;
reg_r0 = mem[opr1++] | (mem[opr1++] << 6) | (mem[opr1] << 12);
break;

case ld_mbr_b:	// 構造体のメンバ(バイト型)の値をr0にロードする
opr1 = mem[reg_pc++] | (mem[reg_pc++] << 6) | (mem[reg_pc++] << 12);
opr1 += reg_r0;
opr1&=0x3ffff;
reg_r0 = mem[opr1];
break;

case lea_mbr:	// 構造体のメンバのアドレスをr0にロードする
opr1 = mem[reg_pc++] | (mem[reg_pc++] << 6) | (mem[reg_pc++] << 12);
reg_r0 += opr1;
reg_r0&=0x3ffff;
break;

case ldxx_a_v_l:// 配列の要素(ロング型)の値をr0にロードする(配列のアドレスは間接指定,インデックスは変数)
opr1 = mem[reg_pc++] | (mem[reg_pc++] << 6) | (mem[reg_pc++] << 12);
opr2 = mem[reg_pc++] | (mem[reg_pc++] << 6) | (mem[reg_pc++] << 12);
adr = mem[opr1++] | (mem[opr1++] << 6) | (mem[opr1] << 12);
tmp = mem[opr2++] | (mem[opr2++] << 6) | (mem[opr2] << 12);
adr+=tmp;
adr+=tmp;
adr+=tmp;
adr&=0x3ffff;
reg_r3 = reg_r2;
reg_r2 = reg_r1;
reg_r1 = reg_r0;
reg_r0 = mem[adr++] | (mem[adr++] << 6) | (mem[adr] << 12);
break;

case ld_a_v_l:	// 配列の要素(ロング型)の値をr0にロードする(配列のアドレスは直接指定,インデックスは変数)
opr1 = mem[reg_pc++] | (mem[reg_pc++] << 6) | (mem[reg_pc++] << 12);
opr2 = mem[reg_pc++] | (mem[reg_pc++] << 6) | (mem[reg_pc++] << 12);
tmp = mem[opr2++] | (mem[opr2++] << 6) | (mem[opr2] << 12);
opr1+=tmp;
opr1+=tmp;
opr1+=tmp;
opr1&=0x3ffff;
reg_r3 = reg_r2;
reg_r2 = reg_r1;
reg_r1 = reg_r0;
reg_r0 = mem[opr1++] | (mem[opr1++] << 6) | (mem[opr1] << 12);
break;

case ldxx_a_v_b:// 配列の要素(バイト型)の値をr0にロードする(配列のアドレスは間接指定,インデックスは変数)
opr1 = mem[reg_pc++] | (mem[reg_pc++] << 6) | (mem[reg_pc++] << 12);
opr2 = mem[reg_pc++] | (mem[reg_pc++] << 6) | (mem[reg_pc++] << 12);
adr = mem[opr1++] | (mem[opr1++] << 6) | (mem[opr1] << 12);
tmp = mem[opr2++] | (mem[opr2++] << 6) | (mem[opr2] << 12);
adr+=tmp;
adr&=0x3ffff;
reg_r3 = reg_r2;
reg_r2 = reg_r1;
reg_r1 = reg_r0;
reg_r0 = mem[adr];
break;

case ld_a_v_b:	// 配列の要素(バイト型)の値をr0にロードする(配列のアドレスは直接指定,インデックスは変数)
opr1 = mem[reg_pc++] | (mem[reg_pc++] << 6) | (mem[reg_pc++] << 12);
opr2 = mem[reg_pc++] | (mem[reg_pc++] << 6) | (mem[reg_pc++] << 12);
tmp = mem[opr2++] | (mem[opr2++] << 6) | (mem[opr2] << 12);
opr1+=tmp;
opr1&=0x3ffff;
reg_r3 = reg_r2;
reg_r2 = reg_r1;
reg_r1 = reg_r0;
reg_r0 = mem[opr1];
break;

case stxx_a_v_l:// r0の値を配列の要素(ロング型)に格納する(配列のアドレスは間接指定,インデックスは変数)
opr1 = mem[reg_pc++] | (mem[reg_pc++] << 6) | (mem[reg_pc++] << 12);
opr2 = mem[reg_pc++] | (mem[reg_pc++] << 6) | (mem[reg_pc++] << 12);
adr = mem[opr1++] | (mem[opr1++] << 6) | (mem[opr1] << 12);
tmp = mem[opr2++] | (mem[opr2++] << 6) | (mem[opr2] << 12);
adr+=tmp;
adr+=tmp;
adr+=tmp;
adr&=0x3ffff;
mem[ adr++ ] = (reg_r0>>0)  & 0x3f;
mem[ adr++ ] = (reg_r0>>6)  & 0x3f;
mem[ adr   ] = (reg_r0>>12) & 0x3f;
access0 = (access1 = adr)-2;
break;

case st_a_v_l:	// r0の値を配列の要素(ロング型)に格納する(配列のアドレスは直接指定,インデックスは変数)
opr1 = mem[reg_pc++] | (mem[reg_pc++] << 6) | (mem[reg_pc++] << 12);
opr2 = mem[reg_pc++] | (mem[reg_pc++] << 6) | (mem[reg_pc++] << 12);
tmp = mem[opr2++] | (mem[opr2++] << 6) | (mem[opr2] << 12);
opr1+=tmp;
opr1+=tmp;
opr1+=tmp;
opr1&=0x3ffff;
mem[ opr1++ ] = (reg_r0>>0)  & 0x3f;
mem[ opr1++ ] = (reg_r0>>6)  & 0x3f;
mem[ opr1   ] = (reg_r0>>12) & 0x3f;
access0 = (access1 = opr1)-2;
break;

case stxx_a_v_b:// r0の値を配列の要素(バイト型)に格納する(配列のアドレスは間接指定,インデックスは変数)
opr1 = mem[reg_pc++] | (mem[reg_pc++] << 6) | (mem[reg_pc++] << 12);
opr2 = mem[reg_pc++] | (mem[reg_pc++] << 6) | (mem[reg_pc++] << 12);
adr = mem[opr1++] | (mem[opr1++] << 6) | (mem[opr1] << 12);
tmp = mem[opr2++] | (mem[opr2++] << 6) | (mem[opr2] << 12);
adr+=tmp;
adr&=0x3ffff;
mem[ adr ] = reg_r0 & 0x3f;
access1 = (access0 = adr)+0;
break;

case st_a_v_b:	// r0の値を配列の要素(バイト型)に格納する(配列のアドレスは直接指定,インデックスは変数)
opr1 = mem[reg_pc++] | (mem[reg_pc++] << 6) | (mem[reg_pc++] << 12);
opr2 = mem[reg_pc++] | (mem[reg_pc++] << 6) | (mem[reg_pc++] << 12);
tmp = mem[opr2++] | (mem[opr2++] << 6) | (mem[opr2] << 12);
opr1+=tmp;
opr1&=0x3ffff;
mem[ opr1 ] = reg_r0 & 0x3f;
access1 = (access0 = opr1)+0;
break;

case ldxx_a_k_l:// 配列の要素(ロング型)の値をr0にロードする(配列のアドレスは間接指定,インデックスは定数)
opr1 = mem[reg_pc++] | (mem[reg_pc++] << 6) | (mem[reg_pc++] << 12);
opr2 = mem[reg_pc++] | (mem[reg_pc++] << 6) | (mem[reg_pc++] << 12);
adr = mem[opr1++] | (mem[opr1++] << 6) | (mem[opr1] << 12);
adr+=opr2;
adr+=opr2;
adr+=opr2;
adr&=0x3ffff;
reg_r3 = reg_r2;
reg_r2 = reg_r1;
reg_r1 = reg_r0;
reg_r0 = mem[adr++] | (mem[adr++] << 6) | (mem[adr] << 12);
break;

case ld_a_k_l:	// 配列の要素(ロング型)の値をr0にロードする(配列のアドレスは直接指定,インデックスは定数)
opr1 = mem[reg_pc++] | (mem[reg_pc++] << 6) | (mem[reg_pc++] << 12);
opr2 = mem[reg_pc++] | (mem[reg_pc++] << 6) | (mem[reg_pc++] << 12);
opr1+=opr2;
opr1+=opr2;
opr1+=opr2;
opr1&=0x3ffff;
reg_r3 = reg_r2;
reg_r2 = reg_r1;
reg_r1 = reg_r0;
reg_r0 = mem[opr1++] | (mem[opr1++] << 6) | (mem[opr1] << 12);
break;

case ldxx_a_k_b:// 配列の要素(バイト型)の値をr0にロードする(配列のアドレスは間接指定,インデックスは定数)
opr1 = mem[reg_pc++] | (mem[reg_pc++] << 6) | (mem[reg_pc++] << 12);
opr2 = mem[reg_pc++] | (mem[reg_pc++] << 6) | (mem[reg_pc++] << 12);
adr = mem[opr1++] | (mem[opr1++] << 6) | (mem[opr1] << 12);
adr+=opr2;
adr&=0x3ffff;
reg_r3 = reg_r2;
reg_r2 = reg_r1;
reg_r1 = reg_r0;
reg_r0 = mem[adr];
break;

case ld_a_k_b:	// 配列の要素(バイト型)の値をr0にロードする(配列のアドレスは直接指定,インデックスは定数)
opr1 = mem[reg_pc++] | (mem[reg_pc++] << 6) | (mem[reg_pc++] << 12);
opr2 = mem[reg_pc++] | (mem[reg_pc++] << 6) | (mem[reg_pc++] << 12);
opr1+=opr2;
opr1&=0x3ffff;
reg_r3 = reg_r2;
reg_r2 = reg_r1;
reg_r1 = reg_r0;
reg_r0 = mem[opr1];
break;

case stxx_a_k_l:// r0の値を配列の要素(ロング型)に格納する(配列のアドレスは間接指定,インデックスは定数)
opr1 = mem[reg_pc++] | (mem[reg_pc++] << 6) | (mem[reg_pc++] << 12);
opr2 = mem[reg_pc++] | (mem[reg_pc++] << 6) | (mem[reg_pc++] << 12);
adr = mem[opr1++] | (mem[opr1++] << 6) | (mem[opr1] << 12);
adr+=opr2;
adr+=opr2;
adr+=opr2;
adr&=0x3ffff;
mem[ adr++ ] = (reg_r0>>0)  & 0x3f;
mem[ adr++ ] = (reg_r0>>6)  & 0x3f;
mem[ adr   ] = (reg_r0>>12) & 0x3f;
access0 = (access1 = adr)-2;
break;

case st_a_k_l:	// r0の値を配列の要素(ロング型)に格納する(配列のアドレスは直接指定,インデックスは定数)
opr1 = mem[reg_pc++] | (mem[reg_pc++] << 6) | (mem[reg_pc++] << 12);
opr2 = mem[reg_pc++] | (mem[reg_pc++] << 6) | (mem[reg_pc++] << 12);
opr1+=opr2;
opr1+=opr2;
opr1+=opr2;
opr1&=0x3ffff;
mem[ opr1++ ] = (reg_r0>>0)  & 0x3f;
mem[ opr1++ ] = (reg_r0>>6)  & 0x3f;
mem[ opr1   ] = (reg_r0>>12) & 0x3f;
access0 = (access1 = opr1)-2;
break;

case stxx_a_k_b:// r0の値を配列の要素(バイト型)に格納する(配列のアドレスは間接指定,インデックスは定数)
opr1 = mem[reg_pc++] | (mem[reg_pc++] << 6) | (mem[reg_pc++] << 12);
opr2 = mem[reg_pc++] | (mem[reg_pc++] << 6) | (mem[reg_pc++] << 12);
adr = mem[opr1++] | (mem[opr1++] << 6) | (mem[opr1] << 12);
adr+=opr2;
adr&=0x3ffff;
mem[ adr ] = reg_r0 & 0x3f;
access1 = (access0 = adr)+0;
break;

case st_a_k_b:	// r0の値を配列の要素(バイト型)に格納する(配列のアドレスは直接指定,インデックスは定数)
opr1 = mem[reg_pc++] | (mem[reg_pc++] << 6) | (mem[reg_pc++] << 12);
opr2 = mem[reg_pc++] | (mem[reg_pc++] << 6) | (mem[reg_pc++] << 12);
opr1+=opr2;
opr1&=0x3ffff;
mem[ opr1 ] = reg_r0 & 0x3f;
access1 = (access0 = opr1)+0;
break;

case ldxx_v_l:	// 変数(ロング型)の値をr0にロードする(アドレスは間接指定)
opr1 = mem[reg_pc++] | (mem[reg_pc++] << 6) | (mem[reg_pc++] << 12);
adr = mem[opr1++] | (mem[opr1++] << 6) | (mem[opr1] << 12);
reg_r3 = reg_r2;
reg_r2 = reg_r1;
reg_r1 = reg_r0;
reg_r0 = mem[adr++] | (mem[adr++] << 6) | (mem[adr] << 12);
break;

case ld_v_l:	// 変数(ロング型)の値をr0にロードする(アドレスは直接指定)
opr1 = mem[reg_pc++] | (mem[reg_pc++] << 6) | (mem[reg_pc++] << 12);
reg_r3 = reg_r2;
reg_r2 = reg_r1;
reg_r1 = reg_r0;
reg_r0 = mem[opr1++] | (mem[opr1++] << 6) | (mem[opr1] << 12);
break;

case ldxx_v_b:	// 変数(バイト型)の値をr0にロードする(アドレスは間接指定)
opr1 = mem[reg_pc++] | (mem[reg_pc++] << 6) | (mem[reg_pc++] << 12);
adr = mem[opr1++] | (mem[opr1++] << 6) | (mem[opr1] << 12);
reg_r3 = reg_r2;
reg_r2 = reg_r1;
reg_r1 = reg_r0;
reg_r0 = mem[adr];
break;

case ld_v_b:	// 変数(バイト型)の値をr0にロードする(アドレスは直接指定)
opr1 = mem[reg_pc++] | (mem[reg_pc++] << 6) | (mem[reg_pc++] << 12);
reg_r3 = reg_r2;
reg_r2 = reg_r1;
reg_r1 = reg_r0;
reg_r0 = mem[opr1];
break;

case ld_k:		// 定数をr0にセットする
reg_r3 = reg_r2;
reg_r2 = reg_r1;
reg_r1 = reg_r0;
reg_r0 = mem[reg_pc++] | (mem[reg_pc++] << 6) | (mem[reg_pc++] << 12);
break;

case stxx_v_l:	// r0の値を変数(ロング型)に格納する(アドレスは間接指定)
opr1 = mem[reg_pc++] | (mem[reg_pc++] << 6) | (mem[reg_pc++] << 12);
adr = mem[opr1++] | (mem[opr1++] << 6) | (mem[opr1] << 12);
mem[ adr++ ] = (reg_r0>>0)  & 0x3f;
mem[ adr++ ] = (reg_r0>>6)  & 0x3f;
mem[ adr   ] = (reg_r0>>12) & 0x3f;
access0 = (access1 = adr)-2;
break;

case st_v_l:	// r0の値を変数(ロング型)に格納する(アドレスは直接指定)
opr1 = mem[reg_pc++] | (mem[reg_pc++] << 6) | (mem[reg_pc++] << 12);
mem[ opr1++ ] = (reg_r0>>0)  & 0x3f;
mem[ opr1++ ] = (reg_r0>>6)  & 0x3f;
mem[ opr1   ] = (reg_r0>>12) & 0x3f;
access0 = (access1 = opr1)-2;
break;

case stxx_v_b:	// r0の値を変数(バイト型)に格納する(アドレスは間接指定)
opr1 = mem[reg_pc++] | (mem[reg_pc++] << 6) | (mem[reg_pc++] << 12);
adr = mem[opr1++] | (mem[opr1++] << 6) | (mem[opr1] << 12);
mem[ adr ] = reg_r0 & 0x3f;
access1 = (access0 = adr)+0;
break;

case st_v_b	:	// r0の値を変数(バイト型)に格納する(アドレスは直接指定)
opr1 = mem[reg_pc++] | (mem[reg_pc++] << 6) | (mem[reg_pc++] << 12);
mem[ opr1 ] = reg_r0 & 0x3f;
access1 = (access0 = opr1)+0;
break;

    }

//System.out.println("access:"+hex6(access0)+"-"+hex6(access1));

// レジスタ領域にアクセスがあったときはレジスタを更新する
if( access0 <= REG_PC && REG_PC <= access1 ) {reg_pc = mem[REG_PC]+mem[REG_PC+1]*64+mem[REG_PC+2]*4096;}
if( access0 <= REG_SP && REG_SP <= access1 ) {reg_sp = mem[REG_SP]+mem[REG_SP+1]*64+mem[REG_SP+2]*4096;}
if( access0 <= REG_R0 && REG_R0 <= access1 ) {reg_r0 = mem[REG_R0]+mem[REG_R0+1]*64+mem[REG_R0+2]*4096;}
if( access0 <= REG_R1 && REG_R1 <= access1 ) {reg_r1 = mem[REG_R1]+mem[REG_R1+1]*64+mem[REG_R1+2]*4096;}
if( access0 <= REG_R2 && REG_R2 <= access1 ) {reg_r2 = mem[REG_R2]+mem[REG_R2+1]*64+mem[REG_R2+2]*4096;}
if( access0 <= REG_R3 && REG_R3 <= access1 ) {reg_r3 = mem[REG_R3]+mem[REG_R3+1]*64+mem[REG_R3+2]*4096;}

// I/O同期
io_sync();

}



// 実行スレッド
void* mainThread( void* pParam ){

printf("enter main thread\r\n");

  reg_pc = VM_START;
  reg_sp = 0;
  reg_r0 = reg_r1 = reg_r2 = reg_r3 = 0;
  mem[0] = (int)hlt;

  // メインループ
  while( !is_break ){
    exec_one_cycle();
  }
}


// メイン
void main( int argc, char** argv ){
  pthread_t ThreadMain;

printf("Card8vm Emulator ver 0.1\n");
printf("If you want to break, please type \'\\\' key.\n");

  // パラメータがあるときはプログラムファイル名とみなしてロードする
  if( argc > 1 ) load_prog( argv[1] );

  PrtData = 0xff;
  KeyCode = 0x3f;
  is_break = 0;
  pthread_create( &ThreadMain,     NULL, mainThread,     NULL );
  while( !is_break ){

    KeyCode = getch();
    if( KeyCode == '\\' ) is_break = 1;
    if( KeyCode != 0 ){
      if( KeyCode == '\n' ) KeyCode0 = 61;
      else if( KeyCode == '\r' ) KeyCode0 = 61;
      else if( KeyCode < 32 )  KeyCode0 = 62;
      else if( KeyCode >= 0x20 && KeyCode <= 0x5f ) KeyCode0 = KeyCode - 0x20;
      else if( KeyCode >= 'a' && KeyCode <= 'z' )   KeyCode0 = KeyCode - 'a' + 'A' - ' ';
      KeyCode = 0;
    }

  }
  pthread_join( ThreadMain,     NULL );

}
