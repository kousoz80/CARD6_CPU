// "card8vm_sym.c" CARD8エミュレータのC言語による実装 ver 1.0
// コンパイル: gcc -ptherad -o card8vm_sym card8vm_sym.c 

#include <stdio.h>
#include <pthread.h>
#include <termios.h>
#include <errno.h>
#include <unistd.h>
#include <fcntl.h>


#define MEM_SIZE	0x1000000

// I/Oポート
#define KEY_CODE	0xfffffd
#define PRT_STROBE	0xfffffe
#define PRT_DATA	0xffffff


int is_break, KeyCode;

// 仮想マシンのレジスタセット
int reg_pc;	// PC: プログラムカウンタ
int reg_sp;	// SP: スタックポインタ
int reg_x;	// X:  インデックスレジスタX
int reg_y;	// Y:  インデックスレジスタY
int reg_a;	// A:  アキュムレータ
int reg_cf;	// CF: キャリーフラグ
int reg_zf;	// ZF: ゼロフラグ

// メモリ
static int mem[MEM_SIZE];

// 仮想マシンの命令セット
enum card8vm_ins {
HLT,	// hlt;	停止する
LXI,	// lxi xxxx;	Xレジスタにxxxxの値をセットする
LDX,	// ldx xxxx;	Xレジスタにxxxx番地の内容を転送する
ADX,	// adx xxxx;	Xレジスタにxxxx番地の内容を加算する
SBX,	// sbx xxxx;	Xレジスタからxxxx番地の内容を減算する
STX,	// stx xxxx;	Xレジスタの内容をxxxx番地に転送する
LAI,	// lai xx;	Aレジスタにxxの値をセットする
LD,		// ld;	AレジスタにXレジスタが示す番地の内容を転送する
ST,		// st;	Xレジスタが示す番地にAレジスタの内容を転送する
ADC,	// adc;	AレジスタにXレジスタが示す番地の内容をキャリー付き加算する
SBB,	// sbb;	AレジスタからXレジスタが示す番地の内容をボロー(キャリーの反転)付き減算する
AND,	// and;	AレジスタにXレジスタが示す番地の内容をAND演算する(CFは0にする)
OR,		// or;	AレジスタにXレジスタが示す番地の内容をOR演算する(CFは1にする)
RORX,	// rorx;	Xレジスタが示す番地の内容のビットをCFを含めて右回転させる
ROLX,	// rolx;	Xレジスタが示す番地の内容のビットをCFを含めて左回転させる
JMP,	// jmp xxxx;	xxxx番地にジャンプする
JZ,		// jz xxxx;	ZFが１のときxxxx番地にジャンプする
JNZ,	// jnz xxxx;	ZFが0のときxxxx番地にジャンプする
JC,		// jc xxxx;	CFが１のときxxxx番地にジャンプする
JNC,	// jnc xxxx;	CFが0のときxxxx番地にジャンプする
JMPX,	// jmpx;	Xレジスタが示す番地にジャンプする
JMPY,	// jmpy;	Yレジスタが示す番地にジャンプする
LYI,	// lyi xxxx;	Yレジスタにxxxxの値をセットする
LDY,	// ldy xxxx;	Yレジスタにxxxx番地の内容を転送する
ADY,	// ady xxxx;	Yレジスタにxxxx番地の内容を加算する
SBY,	// sby xxxx;	Yレジスタからxxxx番地の内容を減算する
STY,	// sty xxxx;	Yレジスタの内容をxxxx番地に転送する
LD_Y,	// ld_y;	AレジスタにYレジスタが示す番地の内容を転送する
ST_Y,	// st_y;	Yレジスタが示す番地にAレジスタの内容を転送する
ADC_Y,	// adc_y;	AレジスタにYレジスタが示す番地の内容をキャリー付き加算する
SBB_Y,	// sbc_y;	AレジスタからYレジスタが示す番地の内容をボロー(キャリーの反転)付き減算する
AND_Y,	// and_y;	AレジスタにYレジスタが示す番地の内容をAND演算する(CFは0にする)
OR_Y,	// or_y;	AレジスタにYレジスタが示す番地の内容をOR演算する(CFは1にする)
CALL,	// call xxxx;	PCレジスタの内容をスタックにプッシュしてxxxx番地にジャンプする
RET,	// ret;	スタックにプッシュされたアドレスPCレジスタに復帰する
PUSHA,	// push a;	Aレジスタの内容をスタックにプッシュする
PUSHX,	// push x;	Xレジスタの内容をスタックにプッシュする 
POPA,	// pop a;	スタックからAレジスタの内容を復帰する 
POPX,	// pop x;	スタックからXレジスタの内容を復帰する 
TXS,	// txs;	Xレジスタスの内容をスタックポインタに転送する 
TSX,	// tsx;	スタックポインタの内容をXレジスタスに転送する 
INCX,	// incx;	Xレジスタを+1する (ZFのみ変化する、CFは変化しない)
DECX,	// decx;	Xレジスタを-1する (ZFのみ変化する、CFは変化しない)
INCY,	// incy;	Yレジスタを+1する (ZFのみ変化する、CFは変化しない)
DECY,	// decy;	Yレジスタを-1する (ZFのみ変化する、CFは変化しない)
RORY,	// rory;	Yレジスタが示す番地の内容のビットをCFを含めて右回転させる
ROLY	// roly;	Yレジスタが示す番地の内容のビットをCFを含めて左回転させる

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

if( KeyCode != 0 ){
 mem[KEY_CODE] = KeyCode;
 KeyCode = 0;
}
if( mem[PRT_STROBE] != 0 ){
  int c;
  mem[PRT_STROBE] = 0;
  c = mem[PRT_DATA];
  putchar(c);
}

}

// 1サイクル実行
void exec_one_cycle(){
  enum card8vm_ins ins;	// 命令コード
  int adr, tmp;

    // 命令コードをフェッチ
    ins = mem[ reg_pc++ ];

    // 命令コードに応じた処理
    switch( ins ){

	// hlt;			停止する
    case HLT:
      is_break = 1;
      break;

    // lxi xxxx;	Xレジスタにxxxxの値をセットする
    case LXI:
      reg_x = mem[ reg_pc++ ] | (mem[ reg_pc++ ] << 8) | (mem[ reg_pc++ ] << 16);
      break;

    // ldx xxxx;	Xレジスタにxxxx番地の内容を転送する
    case LDX:
      adr = mem[ reg_pc++ ] | (mem[ reg_pc++ ] << 8) | (mem[ reg_pc++ ] << 16);
      reg_x = mem[ adr++ ] | (mem[ adr++ ] << 8) | (mem[ adr ] << 16);
      break;

    // adx xxxx;	Xレジスタにxxxx番地の内容を加算する
    case ADX:
      adr = mem[ reg_pc++ ] | (mem[ reg_pc++ ] << 8) | (mem[ reg_pc++ ] << 16);
      tmp = mem[ adr++ ] | (mem[ adr++ ] << 8) | (mem[ adr ] << 16);
      reg_x = reg_x + tmp;
      reg_zf = (reg_x==0? 1 : 0);
      reg_cf = (reg_x>=0x1000000? 1 : 0);
      reg_x &= 0xffffff; 
      break;

    // sbx xxxx;	Xレジスタからxxxx番地の内容を減算する
    case SBX:
      adr = mem[ reg_pc++] | (mem[ reg_pc++ ] << 8) | (mem[reg_pc++] << 16);
      tmp = mem[ adr++ ] | (mem[ adr++ ] << 8) | (mem[ adr ] << 16);
      reg_x = reg_x - tmp;
      reg_zf = (reg_x==0? 1 : 0);
      reg_cf = (reg_x<0? 0 : 1);
      reg_x &= 0xffffff; 
      break;

    // stx xxxx;	Xレジスタの内容をxxxx番地に転送する
    case  STX:
      adr = mem[ reg_pc++] | (mem[ reg_pc++ ] << 8) | (mem[reg_pc++] << 16);
      mem[ adr++ ] = (reg_x>>0)  & 0xff;
      mem[ adr++ ] = (reg_x>>8)  & 0xff;
      mem[ adr ]   = (reg_x>>16) & 0xff;
      break;

    // lai xx;		Aレジスタにxxの値をセットする
    case  LAI:
      reg_a = mem[ reg_pc++ ];
      break;

    // ld;			AレジスタにXレジスタが示す番地の内容を転送する
    case  LD:
      reg_a = mem[ reg_x ];
      break;

    // st;			Xレジスタが示す番地にAレジスタの内容を転送する
    case  ST:
      mem[ reg_x ] = reg_a;
      break;

    // adc;			AレジスタにXレジスタが示す番地の内容をキャリー付き加算する
    case  ADC:
      reg_a = reg_a + mem[ reg_x ] + reg_cf;
      reg_cf = (reg_a>=0x100? 1 : 0);
      reg_a &= 0xff; 
      reg_zf = (reg_a==0? 1 : 0);
      break;

    // sbb;			AレジスタからXレジスタが示す番地の内容をボロー(キャリーの反転)付き減算する
    case  SBB:
      reg_a = reg_a - mem[ reg_x ] - 1 + reg_cf;
      reg_cf = (reg_a<0? 0 : 1);
      reg_a &= 0xff; 
      reg_zf = (reg_a==0? 1 : 0);
      break;

    // and;			AレジスタにXレジスタが示す番地の内容をAND演算する(CFは0にする)
    case  AND:
      reg_a = (reg_a & mem[ reg_x ]) & 0xff;
      reg_zf = (reg_a==0? 1 : 0);
      reg_cf = 0;
      break;

    // or;			AレジスタにXレジスタが示す番地の内容をOR演算する(CFは1にする)
    case  OR:
      reg_a = (reg_a | mem[ reg_x ]) & 0xff;
      reg_zf = (reg_a==0? 1 : 0);
      reg_cf = 1;
      break;

    // rorx;			Xレジスタが示す番地の内容のビットをCFを含めて右回転させる
    case  RORX:
      tmp = mem[ reg_x ];
      mem[ reg_x ] = tmp >> 1;
      if( reg_cf == 1 ) mem[ reg_x ] |= 0x80; 
      mem[ reg_x ] &= 0xff; 
      reg_zf = (mem[ reg_x ]==0? 1 : 0);
      reg_cf = ((tmp&0x01)!=0)? 1 : 0;
      break;

    // rolX;			Xレジスタが示す番地の内容のビットをCFを含めて左回転させる
    case  ROLX:
      tmp = mem[ reg_x ];
      mem[ reg_x ] = tmp << 1;
      if( reg_cf == 1 ) mem[ reg_x ] |= 0x01; 
      mem[ reg_x ] &= 0xff; 
      reg_zf = (mem[ reg_x ]==0? 1 : 0);
      reg_cf = (tmp & 0x80)!=0? 1 : 0;
      break;

    // jmp xxxx;	xxxx番地にジャンプする
    case  JMP:
      tmp = mem[ reg_pc++] | (mem[ reg_pc++ ] << 8) | (mem[reg_pc++] << 16);
      reg_pc = tmp;
      break;

    // jz xxxx;		ZFが１のときxxxx番地にジャンプする
    case  JZ:
      tmp = mem[ reg_pc++] | (mem[ reg_pc++ ] << 8) | (mem[reg_pc++] << 16);
      if( reg_zf == 1 ) reg_pc = tmp;
      break;

    // jnz xxxx;	ZFが0のときxxxx番地にジャンプする
    case  JNZ:
      tmp = mem[ reg_pc++] | (mem[ reg_pc++ ] << 8) | (mem[reg_pc++] << 16);
      if( reg_zf == 0 ) reg_pc = tmp;
      break;

    // jc xxxx;		CFが１のときxxxx番地にジャンプする
    case  JC:
      tmp = mem[ reg_pc++] | (mem[ reg_pc++ ] << 8) | (mem[reg_pc++] << 16);
      if( reg_cf == 1 ) reg_pc = tmp;
      break;

    // jnc xxxx;	CFが0のときxxxx番地にジャンプする
    case  JNC:
      tmp = mem[ reg_pc++] | (mem[ reg_pc++ ] << 8) | (mem[reg_pc++] << 16);
      if( reg_cf == 0 ) reg_pc = tmp;
      break;

    // jmpx;		Xレジスタが示す番地にジャンプする
    case  JMPX:
      reg_pc = reg_x;
      break;

    // ここから拡張命令

    // jmpy;		Yレジスタが示す番地にジャンプする
    case  JMPY:
      reg_pc = reg_y;
      break;

    // lyi xxxx;	Yレジスタにxxxxの値をセットする
    case LYI:
      reg_y = mem[ reg_pc++ ] | (mem[ reg_pc++ ] << 8) | (mem[ reg_pc++ ] << 16);
      break;

    // ldy xxxx;	Yレジスタにxxxx番地の内容を転送する
    case LDY:
      adr = mem[ reg_pc++ ] | (mem[ reg_pc++ ] << 8) | (mem[ reg_pc++ ] << 16);
      reg_y = mem[ adr++ ] | (mem[ adr++ ] << 8) | (mem[ adr ] << 16);
      break;

    // ady xxxx;	Yレジスタにxxxx番地の内容を加算する
    case ADY:
      adr = mem[ reg_pc++ ] | (mem[ reg_pc++ ] << 8) | (mem[ reg_pc++ ] << 16);
      tmp = mem[ adr++ ] | (mem[ adr++ ] << 8) | (mem[ adr ] << 16);
      reg_y = reg_y + tmp;
      reg_zf = (reg_y==0? 1 : 0);
      reg_cf = (reg_y>=0x1000000? 1 : 0);
      reg_y &= 0xffffff; 
      break;

    // sby xxxx;	Yレジスタからxxxx番地の内容を減算する
    case SBY:
      adr = mem[ reg_pc++] | (mem[ reg_pc++ ] << 8) | (mem[reg_pc++] << 16);
      tmp = mem[ adr++ ] | (mem[ adr++ ] << 8) | (mem[ adr ] << 16);
      reg_y = reg_y - tmp;
      reg_zf = (reg_y==0? 1 : 0);
      reg_cf = (reg_y<0? 0 : 1);
      reg_y &= 0xffffff; 
      break;

    // sty xxxx;	Yレジスタの内容をxxxx番地に転送する
    case STY:
      adr = mem[ reg_pc++] | (mem[ reg_pc++ ] << 8) | (mem[reg_pc++] << 16);
      mem[ adr++ ] = (reg_y>>0)  & 0xff;
      mem[ adr++ ] = (reg_y>>8)  & 0xff;
      mem[ adr ]   = (reg_y>>16) & 0xff;
      break;

    // ld_y;		AレジスタにYレジスタが示す番地の内容を転送する
    case LD_Y:
      reg_a = mem[ reg_y ];
      break;

    // st_y;		Yレジスタが示す番地にAレジスタの内容を転送する
    case ST_Y:
      mem[ reg_y ] = reg_a;
      break;

    // adc_y;		AレジスタにYレジスタが示す番地の内容をキャリー付き加算する
    case ADC_Y:
      reg_a = reg_a + mem[ reg_y ] + reg_cf;
      reg_cf = (reg_a >= 0x100)? 1 : 0;
      reg_a &= 0xff; 
      reg_zf = (reg_a==0)? 1 : 0;
      break;

    // sbb_y;			AレジスタからYレジスタが示す番地の内容をボロー(キャリーの反転)付き減算する
    case  SBB_Y:
      reg_a = reg_a - mem[ reg_y ] - 1 + reg_cf;
      reg_cf = (reg_a<0? 0 : 1);
      reg_a &= 0xff; 
      reg_zf = (reg_a==0? 1 : 0);
      break;

    // and_y;		AレジスタにYレジスタが示す番地の内容をAND演算する(CFは0にする)
    case AND_Y:
      reg_a = (reg_a & mem[ reg_y ]) & 0xff;
      reg_zf = (reg_a==0? 1 : 0);
      reg_cf = 0;
      break;

    // or_y;		AレジスタにYレジスタが示す番地の内容をOR演算する(CFは1にする)
    case OR_Y:
      reg_a = (reg_a | mem[ reg_y ]) & 0xff;
      reg_zf = (reg_a==0? 1 : 0);
      reg_cf = 1;
      break;

    // call xxxx;	PCレジスタの内容をスタックにプッシュしてxxxx番地にジャンプする
    case CALL:
      tmp = mem[ reg_pc++] | (mem[ reg_pc++ ] << 8) | (mem[reg_pc++] << 16);
      mem[ --reg_sp ] = (reg_pc>>16) & 0xff;
      mem[ --reg_sp ] = (reg_pc>>8)  & 0xff;
      mem[ --reg_sp ] = (reg_pc>>0)  & 0xff;
      reg_pc = tmp;
      break;

    // ret;	スタックにプッシュされたアドレスPCレジスタに復帰する
    case RET:
      reg_pc = mem[ reg_sp++ ] | (mem[ reg_sp++ ] << 8) | (mem[ reg_sp++ ] << 16);
      break;

    // push a;	Aレジスタの内容をスタックにプッシュする
    case PUSHA:
      mem[ --reg_sp ] = reg_a;
      break;

    // push x;	Xレジスタの内容をスタックにプッシュする 
    case PUSHX:
      mem[ --reg_sp ] = (reg_x>>16) & 0xff;
      mem[ --reg_sp ] = (reg_x>>8)  & 0xff;
      mem[ --reg_sp ] = (reg_x>>0)  & 0xff;
      break;

    // pop a;	スタックからAレジスタの内容を復帰する 
    case POPA:
      reg_a = mem[ reg_sp++ ];
      break;

    // pop x;	スタックからXレジスタの内容を復帰する 
    case POPX:
      reg_x = mem[ reg_sp++ ] | (mem[ reg_sp++ ] << 8) | (mem[ reg_sp++ ] << 16);
      break;

    // txs;	Xレジスタスの内容をスタックポインタに転送する 
    case TXS:
      reg_sp = reg_x;
      break;

    // tsx;	スタックポインタの内容をXレジスタスに転送する 
    case TSX:
      reg_x = reg_sp;
      break;

    // incx;	Xレジスタを+1する
    case INCX:
      reg_x = (reg_x+1) & 0xffffff;
      reg_zf = (reg_x==0? 1 : 0);
      break;

    // decx;	Xレジスタを-1する
    case DECX:
      reg_x = (reg_x-1) & 0xffffff;
      reg_zf = (reg_x==0? 1 : 0);
      break;

    // incy;	Yレジスタを+1する
    case INCY: 
      reg_y = (reg_y+1) & 0xffffff;
      reg_zf = (reg_y==0? 1 : 0);
      break;

    // decy;	Yレジスタを-1する
    case DECY: 
      reg_y = (reg_y-1) & 0xffffff;
      reg_zf = (reg_y==0? 1 : 0);
      break;

    // rory;			Yレジスタが示す番地の内容のビットをCFを含めて右回転させる
    case  RORY:
      tmp = mem[ reg_y ];
      mem[ reg_y ] = tmp >> 1;
      if( reg_cf == 1 ) mem[ reg_y ] |= 0x80; 
      mem[ reg_y ] &= 0xff; 
      reg_zf = (mem[ reg_y ]==0? 1 : 0);
      reg_cf = ((tmp&0x01)!=0)? 1 : 0;
      break;

    // roly;			Yレジスタが示す番地の内容のビットをCFを含めて左回転させる
    case  ROLY:
      tmp = mem[ reg_y ];
      mem[ reg_y ] = tmp << 1;
      if( reg_cf == 1 ) mem[ reg_y ] |= 0x01; 
      mem[ reg_y ] &= 0xff; 
      reg_zf = (mem[ reg_y ]==0? 1 : 0);
      reg_cf = (tmp & 0x80)!=0? 1 : 0;
      break;

    }

// I/O同期
io_sync();

}



// 実行スレッド
void* mainThread( void* pParam ){

printf("enter main thread\r\n");

  reg_pc = 0x070000;
  reg_x = 0;
  reg_y = 0;
  reg_a = 0;
  reg_cf = 0;
  reg_zf = 0;
  mem[0] = (int)HLT;

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

  is_break = 0;
  pthread_create( &ThreadMain,     NULL, mainThread,     NULL );
  while( !is_break ){
    int c = getch();
    if( c == (int)'\r' ) c =(int)'\n';
    if( c == '\\' ) is_break = 1;
    KeyCode = c;
  }
  pthread_join( ThreadMain,     NULL );

}
