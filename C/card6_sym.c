// "card6_sym.c" CARD6エミュレータのC言語による実装 ver 1.1
// コンパイル: gcc -ptherad -o card6_sym card6_sym.c 
// 修正点
// ver 1.1 OPコードを負論理に変更



#include <stdio.h>
#include <pthread.h>
#include <termios.h>
#include <errno.h>
#include <unistd.h>
#include <fcntl.h>

#define MEM_SIZE	0x40000
#define DATA_INS 231

// I/Oポート
int KeyCode, KeyCode0;
int PrtData;
int is_break;

// 命令コードのビット割り当て
#define IO  0x80
#define PTR 0x40
#define RET 0x20
#define ST  0x10
#define LD  0x08
#define LDH 0x04
#define LDM 0x02
#define LDL 0x01


// レジスタセット
int reg_c;
int reg_a;
int reg_r;
int reg_d;
int reg_h;
int reg_m;
int reg_l;


// メモリ
static int mem_c[MEM_SIZE];
static int mem_a[MEM_SIZE];
static int mem_r[MEM_SIZE];
static int mem_d[MEM_SIZE];

// プログラムをロード
int load_prog( char* fname ){
  FILE* fp;
  int adrs, data;

printf("load prog file\r\n");

// ファイルがない場合はエラー
if( ( fp = fopen( fname, "r" ) ) == NULL ){
    printf("prog file not found.\n");
    return -1;
  }

  while(1){
    if( fscanf( fp, "%d\n",  &adrs ) < 1 ) break;
    if( fscanf( fp, "%d\n",  &data ) < 1 ) break;
    mem_c[ adrs ] = data;
    if( fscanf( fp, "%d\n",  &data ) < 1 ) break;
    mem_a[ adrs ] = data;
    if( fscanf( fp, "%d\n",  &data ) < 1 ) break;
    mem_r[ adrs ] = data;
    if( fscanf( fp, "%d\n",  &data ) < 1 ) break;
    mem_d[ adrs ] = data;
  }
  fclose( fp );

printf("load prog file end\r\n");

  return 0;
}


// データをロード
int load_data( char* fname ){
  FILE* fp;
  int adrs, data;

printf("load data file\r\n");

// ファイルがない場合はエラー
if( ( fp = fopen( fname, "r" ) ) == NULL ){
    printf("data file not found.\n");
    return -1;
  }

  while(1){
    if( fscanf( fp, "%d\n",  &adrs ) < 1 ) break;
    if( fscanf( fp, "%d\n",  &data ) < 1 ) break;
    mem_c[ adrs ] = DATA_INS; // data命令をセットして読み書きできるようにしておく
    mem_a[ adrs ] = 0;
    mem_r[ adrs ] = 0;
    mem_d[ adrs ] = data;
  }
  fclose( fp );

printf("load data file end\r\n");

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
int address;

//レジスター＞メモリ(I/O) サイクル
if( (reg_c & PTR) == 0 ) address = reg_h * 4096 + reg_m * 64 + reg_l; else address = reg_a;
if( (reg_c & RET) == 0 ) mem_a[address] = reg_r;
if( (reg_c & IO)  == 0 && (reg_c & ST)  == 0 ) PrtData = reg_d;			// I/Oアクセス
if( (reg_c & IO)  != 0 && (reg_c & ST)  == 0 ) mem_d[address] = reg_d;	// メモリアクセス

// メモリ(I/O)ー＞レジスタ サイクル
reg_c = mem_c[address];
reg_a = mem_a[address];
reg_r = mem_r[address];
if( (reg_c & IO)  == 0 && (reg_c & LD)  == 0 ){ // I/Oアクセス
  reg_d= KeyCode0;
  KeyCode0 = 0x3f;
}
if( (reg_c & IO)  != 0 && (reg_c & LD)  == 0 ){	// メモリアクセス
	 reg_d = mem_d[address];
}
if( (reg_c & LDH) == 0 ) reg_h = mem_d[address];
if( (reg_c & LDM) == 0 ) reg_m = mem_d[address];
if( (reg_c & LDL) == 0 ) reg_l = mem_d[address];

// I/O同期
io_sync();

}


// 実行スレッド
void* mainThread( void* pParam ){

printf("enter main thread\r\n");

  reg_c = 255;
  reg_a = 0;
  reg_r = 0;
  reg_d = 0;
  reg_h = 0;
  reg_m = 0;
  reg_l = 0;

  // メインループ
  while( !is_break ){
    exec_one_cycle();
  }
}


// メイン
void main( int argc, char** argv ){
  pthread_t ThreadMain;
  int adrs;

printf("CARD8 Emulator ver 0.1\n");
printf("If you want to break, please type \'\\\' key.\n");

  // すべてのメモリにdata命令をセットして読み書きできるようにしておく
  for( adrs = 0; adrs < MEM_SIZE; adrs++ ){
    mem_c[ adrs ] = DATA_INS;
    mem_a[ adrs ] = 0;
    mem_r[ adrs ] = 0;
    mem_d[ adrs ] = 0;
  }

  // パラメータがあるときはプログラムファイル名とみなしてロードする
  if( argc > 1 ) load_prog( argv[1] );
  if( argc > 2 ) load_data( argv[2] );

  is_break = 0;
  KeyCode0 = 0x3f;
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
