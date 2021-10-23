
/*


  "card8vm_orc.c" 

    oregengo_R
    独自言語コンパイラ ver 0.1 for CARD8 CPU

  ・CARD8 CPU用式のアセンブラソースファイルを生成
  ・ソースファイル名は "asm.s"となる
  ・オリジナルとは若干言語仕様が異なる

    コンパイル: gcc -o card8vm_orc card8vm_orc.c 

*/

#include <stdio.h>
#include <string.h>

// パス１定義データ （宣言文の定義）
char*  pass1[] = {
  " long \\#(\\),\\#(\\),\\#(\\),\\#(\\)", "\\1: memory \\2*3\n\\3: memory \\4*3\n\\5: memory \\6*3\n\\7: memory \\8*3\n",
  " long \\#(\\),\\#(\\),\\#(\\)",         "\\1: memory \\2*3\n\\3: memory \\4*3\n\\5: memory \\6*3\n",
  " long \\#(\\),\\#(\\)",                 "\\1: memory \\2*3\n\\3: memory \\4*3\n",
  " long \\#(\\)",                         "\\1: memory \\2*3\n",

  " long \\#,\\#,\\#,\\#,\\#,\\#,\\#,\\#", "\\1: memory 3\n\\2: memory 3\n\\3: memory 3\n\\4: memory 3\n\\5: memory 3\n\\6: memory 3\n\\7: memory 3\n\\8: memory 3\n",
  " long \\#,\\#,\\#,\\#,\\#,\\#,\\#",     "\\1: memory 3\n\\2: memory 3\n\\3: memory 3\n\\4: memory 3\n\\5: memory 3\n\\6: memory 3\n\\7: memory 3\n",
  " long \\#,\\#,\\#,\\#,\\#,\\#",         "\\1: memory 3\n\\2: memory 3\n\\3: memory 3\n\\4: memory 3\n\\5: memory 3\n\\6: memory 3\n",
  " long \\#,\\#,\\#,\\#,\\#",             "\\1: memory 3\n\\2: memory 3\n\\3: memory 3\n\\4: memory 3\n\\5: memory 3\n",
  " long \\#,\\#,\\#,\\#",                 "\\1: memory 3\n\\2: memory 3\n\\3: memory 3\n\\4: memory 3\n",
  " long \\#,\\#,\\#",                     "\\1: memory 3\n\\2: memory 3\n\\3: memory 3\n",
  " long \\#,\\#",                         "\\1: memory 3\n\\2: memory 3\n",
  " long \\#",                             "\\1: memory 3\n",

  " char \\$(\\),\\$(\\),\\$(\\),\\$(\\)", "\\1: memory \\2\n\\3: memory \\4\n\\5: memory \\6\n\\7: memory \\8\n",
  " char \\$(\\),\\$(\\),\\$(\\)",         "\\1: memory \\2\n\\3: memory \\4\n\\5: memory \\6\n",
  " char \\$(\\),\\$(\\)",                 "\\1: memory \\2\n\\3: memory \\4\n",
  " char \\$(\\)",                         "\\1: memory \\2\n",

  " char \\$,\\$,\\$,\\$,\\$,\\$,\\$,\\$", "\\1: memory 1\n\\2: memory 1\n\\3: memory 1\n\\4: memory 1\n\\5: memory 1\n\\6: memory 1\n\\7: memory 1\n\\8: memory 1\n",
  " char \\$,\\$,\\$,\\$,\\$,\\$,\\$",     "\\1: memory 1\n\\2: memory 1\n\\3: memory 1\n\\4: memory 1\n\\5: memory 1\n\\6: memory 1\n\\7: memory 1\n",
  " char \\$,\\$,\\$,\\$,\\$,\\$",         "\\1: memory 1\n\\2: memory 1\n\\3: memory 1\n\\4: memory 1\n\\5: memory 1\n\\6: memory 1\n",
  " char \\$,\\$,\\$,\\$,\\$",             "\\1: memory 1\n\\2: memory 1\n\\3: memory 1\n\\4: memory 1\n\\5: memory 1\n",
  " char \\$,\\$,\\$,\\$",                 "\\1: memory 1\n\\2: memory 1\n\\3: memory 1\n\\4: memory 1\n",
  " char \\$,\\$,\\$",                     "\\1: memory 1\n\\2: memory 1\n\\3: memory 1\n",
  " char \\$,\\$",                         "\\1: memory 1\n\\2: memory 1\n",
  " char \\$",                             "\\1: memory 1\n",

  " count \\#,\\#,\\#,\\#,\\#,\\#,\\#,\\#", "\\1: memory 12\n\\2: memory 12\n\\3: memory 12\n\\4: memory 12\n\\5: memory 12\n\\6: memory 12\n\\7: memory 12\n\\8: memory 12\n",
  " count \\#,\\#,\\#,\\#,\\#,\\#,\\#",     "\\1: memory 12\n\\2: memory 12\n\\3: memory 12\n\\4: memory 12\n\\5: memory 12\n\\6: memory 12\n\\7: memory 12\n",
  " count \\#,\\#,\\#,\\#,\\#,\\#",         "\\1: memory 12\n\\2: memory 12\n\\3: memory 12\n\\4: memory 12\n\\5: memory 12\n\\6: memory 12\n",
  " count \\#,\\#,\\#,\\#,\\#",             "\\1: memory 12\n\\2: memory 12\n\\3: memory 12\n\\4: memory 12\n\\5: memory 12\n",
  " count \\#,\\#,\\#,\\#",                 "\\1: memory 12\n\\2: memory 12\n\\3: memory 12\n\\4: memory 12\n",
  " count \\#,\\#,\\#",                     "\\1: memory 12\n\\2: memory 12\n\\3: memory 12\n",
  " count \\#,\\#",                         "\\1: memory 12\n\\2: memory 12\n",
  " count \\#",                             "\\1: memory 12\n",

  NULL
};


// パス２定義データ （if-then 文の定義）
char*  pass2[] = {
  " if \\<>\\ then \\", " if \\1=\\2 goto L\\0\n \\3\nL\\0:\n",
  " if \\>=\\ then \\", " if \\1<\\2 goto L\\0\n \\3\nL\\0:\n",
  " if \\<=\\ then \\", " if \\1>\\2 goto L\\0\n \\3\nL\\0:\n",
  " if \\>\\ then \\",  " if \\1<=\\2 goto L\\0\n \\3\nL\\0:\n",
  " if \\<\\ then \\",  " if \\1>=\\2 goto L\\0\n \\3\nL\\0:\n",
  " if \\=\\ then \\",  " if \\1<>\\2 goto L\\0\n \\3\nL\\0:\n",

  "\\: \\",  "\\1:\n \\2\n",
  "\\",      "\\1\n",

  NULL
};


// パス３ 定義データ （if-goto,for-next文の定義）
char*  pass3[] = {
  "/\\/",  "/\\1/\n",
  "\\:",    "\\1:\n",

// 宣言文は無視する
  " long \\",      "",
  " char \\",     "",
  " count \\",    "",
  " const \\ \\", "/\\1: = \\2/\n",
  " const_plus \\ \\", "/\\1: += \\2/\n",
  " const0", "/ = 0/\n",

// if 〜 goto 文
  " if \\<>\\ goto \\",            " \\1,\n \\2,\n jnz \\3\n",
  " if \\>=\\ goto \\",            " \\1,\n \\2,\n jge \\3\n",
  " if \\<=\\ goto \\",            " \\2,\n \\1,\n jge \\3\n",
  " if \\>\\ goto \\",             " \\2,\n \\1,\n jlt \\3\n",
  " if \\<\\ goto \\",             " \\1,\n \\2,\n jlt \\3\n",
  " if \\=\\ goto \\",             " \\1,\n \\2,\n jz \\3\n",
  " goto \\",                      " jmp \\1\n",

// for-next (cpu依存する部分あり) ---> ジャンプアドレス($+xxx)
  " for \\#=\\ to \\ step \\",     " \\2,\n \\1#=\n \\3,\n \\1+3#=\n \\4,\n \\1+6#=\n $+16,\n \\1+9#=\n",
  " for \\#=\\ to \\",             " \\2,\n \\1#=\n \\3,\n \\1+3#=\n 1,\n \\1+6#=\n $+16,\n \\1+9#=\n",
  " next \\#",                     " \\1#,\n \\1+3#,\n jz $+125\n \\1#,\n \\1+6#,\n +\n \\1#=\n \\1+9#,\n jmp@\n",

// data文
  " data \\,\\,\\,\\,\\,\\,\\,\\", " data\\1\n data\\2\n data\\3\n data\\4\n data\\5\n data\\6\n data\\7\n data\\8\n",
  " data \\,\\,\\,\\,\\,\\,\\",    " data\\1\n data\\2\n data\\3\n data\\4\n data\\5\n data\\6\n data\\7\n",
  " data \\,\\,\\,\\,\\,\\",       " data\\1\n data\\2\n data\\3\n data\\4\n data\\5\n data\\6\n",
  " data \\,\\,\\,\\,\\",          " data\\1\n data\\2\n data\\3\n data\\4\n data\\5\n",
  " data \\,\\,\\,\\",             " data\\1\n data\\2\n data\\3\n data\\4\n",
  " data \\,\\,\\",                " data\\1\n data\\2\n data\\3\n",
  " data \\,\\",                   " data\\1\n data\\2\n",
  " data \\",                      " data\\1\n",

// 一般のステートメント
  " \\ \\ \\ \\ \\ \\ \\ \\",      " \\1\n \\2\n \\3\n \\4\n \\5\n \\6\n \\7\n \\8\n",
  " \\ \\ \\ \\ \\ \\ \\",         " \\1\n \\2\n \\3\n \\4\n \\5\n \\6\n \\7\n",
  " \\ \\ \\ \\ \\ \\",            " \\1\n \\2\n \\3\n \\4\n \\5\n \\6\n",
  " \\ \\ \\ \\ \\",               " \\1\n \\2\n \\3\n \\4\n \\5\n",
  " \\ \\ \\ \\",                  " \\1\n \\2\n \\3\n \\4\n",
  " \\ \\ \\",                     " \\1\n \\2\n \\3\n",
  " \\ \\",                        " \\1\n \\2\n",
  " \\",                           " \\1\n",

  NULL
};

// パス4 定義データ （コード生成）
char* codegen[] = {
"/\\/", "\\1\n",
" \\:", "\\1:\n",
"\\:", "\\1:\n",
" jge \\", " x=(r1)\n x-=(r0)\n (__tmp)=x\n x=__tmp+2\n a=0x80\n a&=(x)\n jz \\1\n",
" jlt \\", " x=(r1)\n x-=(r0)\n (__tmp)=x\n x=__tmp+2\n a=0x80\n a&=(x)\n jnz \\1\n",
" jz \\", " x=(r1)\n x-=(r0)\n jz \\1\n",
" jnz \\", " x=(r1)\n x-=(r0)\n jnz \\1\n",
" jmp \\", " jmp \\1\n",
" goto\\", " jmp \\1\n",
" +", " x=(r1)\n x+=(r0)\n (r0)=x\n",
" -", " x=(r1)\n x-=(r0)\n (r0)=x\n",
" *", " call mul\n x=(__ans)\n (r0)=x\n",
" umul", " call umul\n x=(__ans)\n (r0)=x\n",
" /", " call div\n x=(__ans)\n (r0)=x\n",
" udiv", " call udiv\n x=(__ans)\n (r0)=x\n",
" neg", " x=0\n x-=(r0)\n (r0)=x\n",
" not", " x=0xffffff\n x-=(r0)\n (r0)=x\n",
" mod", " call udiv\n x=(r1)\n (r0)=x\n",
" swap", " x=(r0)\n (__tmp)=x\n x=(r1)\n (r0)=x\n x=(__tmp)\n (r1)=x\n",
" push", " x=(r2)\n (r3)=x\n x=(r1)\n (r2)=x\n x=(r0)\n (r1)=x\n",
" pop", " x=(r1)\n (r0)=x\n x=(r2)\n (r1)=x\n x=(r3)\n (r2)=x\n",
" PUSH", " x=(r0)\n push x\n",
" POP", " pop x\n (r0)=x\n",
" and", " x=r1\n a=(x)\n x=r0\n a&=(x)\n (x)=a\n x=r1+1\n a=(x)\n x=r0+1\n a&=(x)\n (x)=a\n x=r1+2\n a=(x)\n x=r0+2\n a&=(x)\n (x)=a\n",
" or", " x=r1\n a=(x)\n x=r0\n a|=(x)\n (x)=a\n x=r1+1\n a=(x)\n x=r0+1\n a|=(x)\n (x)=a\n x=r1+2\n a=(x)\n x=r0+2\n a|=(x)\n (x)=a\n",
" getchar$,", " call getchar\n",
" inkey$,", " call inkey\n",
" \\(pc),", " x=(r2)\n (r3)=x\n x=(r1)\n (r2)=x\n x=(r0)\n (r1)=x\n x=$-24+\\1\n (r0)=x\n",
" end", " ret\n",
" jmp@", " x=(r0)\n jmp (x)\n",
" call@", " x=$+10\n push x\n x=(r0)\n jmp (x)\n",
" ->@\\(\\)", " x=&\\2\n (arg0)=x\n x=\\1\n x+=(r0)\n y=r0\n a=(x)\n (y)=a\n x++\n y++\n a=(x)\n (y)=a\n x++\n y++\n a=(x)\n (y)=a\n x=$+10\n push x\n x=(r0)\n jmp (x)\n",
" ->@\\", " x=\\1\n x+=(r0)\n y=r0\n a=(x)\n (y)=a\n x++\n y++\n a=(x)\n (y)=a\n x++\n y++\n a=(x)\n (y)=a\n x=$+10\n push x\n x=(r0)\n jmp (x)\n",
" ->\\#=", " x=\\1\n x+=(r0)\n y=r1\n a=(y)\n (x)=a\n x++\n y++\n a=(y)\n (x)=a\n x++\n y++\n a=(y)\n (x)=a\n",
" ->\\$=", " x=\\1\n x+=(r0)\n y=r1\n a=(y)\n (x)=a\n",
" ->\\#", " x=\\1\n x+=(r0)\n y=r0\n a=(x)\n (y)=a\n x++\n y++\n a=(x)\n (y)=a\n x++\n y++\n a=(x)\n (y)=a\n",
" ->\\$", " x=\\1\n x+=(r0)\n y=r0\n a=(x)\n (y)=a\n",
" ->\\", " x=\\1\n x+=(r0)\n (r0)=x\n",
" (\\)#(\\#),", " x=(r2)\n (r3)=x\n x=(r1)\n (r2)=x\n x=(r0)\n (r1)=x\n x=(\\1)\n x+=(\\2)\n x+=(\\2)\n x+=(\\2)\n y=r0\n a=(x)\n (y)=a\n x++\n y++\n a=(x)\n (y)=a\n x++\n y++\n a=(x)\n (y)=a\n",
" \\#(\\#),", " x=(r2)\n (r3)=x\n x=(r1)\n (r2)=x\n x=(r0)\n (r1)=x\n x=\\1\n x+=(\\2)\n x+=(\\2)\n x+=(\\2)\n y=r0\n a=(x)\n (y)=a\n x++\n y++\n a=(x)\n (y)=a\n x++\n y++\n a=(x)\n (y)=a\n",
" (\\)$(\\#),", " x=(r2)\n (r3)=x\n x=(r1)\n (r2)=x\n x=(r0)\n (r1)=x\n x=(\\1)\n x+=(\\2)\n y=r0\n a=(x)\n (y)=a\n a=0\n y++\n (y)=a\n y++\n (y)=a\n",
" \\$(\\#),", " x=(r2)\n (r3)=x\n x=(r1)\n (r2)=x\n x=(r0)\n (r1)=x\n x=\\1\n x+=(\\2)\n y=r0\n a=(x)\n (y)=a\n a=0\n y++\n (y)=a\n y++\n (y)=a\n",
" (\\)#(\\#)=", " x=(\\1)\n x+=(\\2)\n x+=(\\2)\n x+=(\\2)\n y=r0\n a=(y)\n (x)=a\n x++\n y++\n a=(y)\n (x)=a\n x++\n y++\n a=(y)\n (x)=a\n",
" \\#(\\#)=", " x=\\1\n x+=(\\2)\n x+=(\\2)\n x+=(\\2)\n y=r0\n a=(y)\n (x)=a\n x++\n y++\n a=(y)\n (x)=a\n x++\n y++\n a=(y)\n (x)=a\n",
" (\\)$(\\#)=", " x=(\\1)\n x+=(\\2)\n y=r0\n a=(y)\n (x)=a\n",
" \\$(\\#)=", " x=\\1\n x+=(\\2)\n y=r0\n a=(y)\n (x)=a\n",
" (\\)#(\\),", " x=(r2)\n (r3)=x\n x=(r1)\n (r2)=x\n x=(r0)\n (r1)=x\n x=\\2+\\2+\\2\n x+=(\\1)\n y=r0\n a=(x)\n (y)=a\n x++\n y++\n a=(x)\n (y)=a\n x++\n y++\n a=(x)\n (y)=a\n",
" \\#(\\),", " x=(r2)\n (r3)=x\n x=(r1)\n (r2)=x\n x=(r0)\n (r1)=x\n x=\\1+\\2+\\2+\\2\n y=r0\n a=(x)\n (y)=a\n x++\n y++\n a=(x)\n (y)=a\n x++\n y++\n a=(x)\n (y)=a\n",
" (\\)$(\\),", " x=(r2)\n (r3)=x\n x=(r1)\n (r2)=x\n x=(r0)\n (r1)=x\n x=\\2\n x+=(\\1)\n y=r0\n a=(x)\n (y)=a\n y++\n a=0\n (y)=a\n y++\n (y)=a\n",
" \\$(\\),", " x=(r2)\n (r3)=x\n x=(r1)\n (r2)=x\n x=(r0)\n (r1)=x\n x=\\1+\\2\n y=r0\n a=(x)\n (y)=a\n y++\n a=0\n (y)=a\n y++\n (y)=a\n",
" (\\)#(\\)=", " x=\\2+\\2+\\2\n x+=(\\1)\n y=r0\n a=(y)\n (x)=a\n x++\n y++\n a=(y)\n (x)=a\n x++\n y++\n a=(y)\n (x)=a\n",
" \\#(\\)=", " x=\\1+\\2+\\2+\\2\n y=r0\n a=(y)\n (x)=a\n x++\n y++\n a=(y)\n (x)=a\n x++\n y++\n a=(y)\n (x)=a\n",
" (\\)$(\\)=", " x=\\2\n x+=(\\1)\n y=r0\n a=(y)\n (x)=a\n",
" \\$(\\)=", " x=\\1+\\2\n y=r0\n a=(y)\n (x)=a\n",
" \\#++", " x=(\\1)\n x++\n (\\1)=x\n",
" \\#--", " x=(\\1)\n x--\n (\\1)=x\n",
" \\$++", " x=\\1\n a&=(x)\n a=(x)\n y=__001\n a+=(y)+cf\n (x)=a\n",
" \\$--", " x=\\1\n a&=(x)\n a=(x)\n y=__001\n a-=(y)+bf\n (x)=a\n",
" (\\)#,", " x=(r2)\n (r3)=x\n x=(r1)\n (r2)=x\n x=(r0)\n (r1)=x\n x=(\\1)\n y=r0\n a=(x)\n (y)=a\n x++\n y++\n a=(x)\n (y)=a\n x++\n y++\n a=(x)\n (y)=a\n",
" \\#,", " x=(r2)\n (r3)=x\n x=(r1)\n (r2)=x\n x=(r0)\n (r1)=x\n x=(\\1)\n (r0)=x\n",
" (\\)$,", " x=(r2)\n (r3)=x\n x=(r1)\n (r2)=x\n x=(r0)\n (r1)=x\n x=(\\1)\n y=r0\n a=(x)\n (y)=a\n y++\n a=0\n (y)=a\n y++\n (y)=a\n",
" \\$,", " x=(r2)\n (r3)=x\n x=(r1)\n (r2)=x\n x=(r0)\n (r1)=x\n x=\\1\n y=r0\n a=(x)\n (y)=a\n y++\n a=0\n (y)=a\n y++\n (y)=a\n",
" \\,", " x=(r2)\n (r3)=x\n x=(r1)\n (r2)=x\n x=(r0)\n (r1)=x\n x=\\1\n (r0)=x\n",
" (\\)#=", " x=(\\1)\n y=r0\n a=(y)\n (x)=a\n x++\n y++\n a=(y)\n (x)=a\n x++\n y++\n a=(y)\n (x)=a\n",
" \\#=", " x=(r0)\n (\\1)=x\n",
" (\\)$=", " x=(\\1)\n y=r0\n a=(y)\n (x)=a\n",
" \\$=", " x=\\1\n y=r0\n a=(y)\n (x)=a\n",
" data\\", " int \\1\n",
" @\\(\\)", " x=$+18\n push x\n x=\\2\n (arg0)=x\n x=(\\1)\n jmp (x)\n",
" @\\", " x=$+10\n push x\n x=(\\1)\n jmp (x)\n",
" \\", " call \\1\n",

NULL
};


/* プロトタイプ宣言  */
void catFile( char* fname );
void strProcess();
void compile_s();
void compile( int pass );

//変数宣言
#define MAX_PASS 4    // コンパイラのパス回数 */
#define LEN_ARG  128  // 引数の最大の長さ

/* コンパイラ定義データ */
char** RefData[MAX_PASS] = { pass1, pass2, pass3, codegen };
char* InFile  =   "__tmp1";
char* OutFile = "__tmp2";
char* StrFile =  "__str";
char* VarFile =  "__var";
char* AsmFile = "asm.s";
char* Tmp;
char   *Comment1 = "/*", *Comment2 = "//";
int     StringID;
FILE  *hInFile, *hOutFile, *hStrFile;


//必要なデータの初期化部分
int main( int argc, char* argv[] ){
  int offset;
  unsigned int i;
  char buf[32];

  if( argc < 2 ) return 0;

//  printf("compile:\n");

  /* 文字列IDを初期化する */
  StringID = 1;

  /* 入力ファイルの結合 */
  if( ( hOutFile = fopen( OutFile, "w") ) == NULL ){
    printf("ファイルが開けません");
    return 0;
  }
  for( i = 1; i < argc; i++ ){
    catFile( argv[ i ] );
  }  
  fclose( hOutFile );
  Tmp     = OutFile;
  OutFile = InFile;
  InFile  = Tmp;

  /* コンパイル開始 */
  strProcess();  // 文字列の処理
  Tmp     = OutFile;
  OutFile = InFile;
  InFile  = Tmp;

  compile_s();   // struct/enum構文の処理
  Tmp     = InFile;
  InFile  = OutFile;
  OutFile = VarFile;
  VarFile = Tmp;

  compile( 0 );   /* 宣言文の処理 */
  Tmp     = OutFile;
  OutFile = VarFile;
  VarFile = Tmp;

  for( i = 1; i < MAX_PASS; i++ ){
    compile( i );  // 手続き文の処理
    Tmp     = OutFile;
    OutFile = InFile;
    InFile  = Tmp;
  }

  /* 出力ファイル（アセンブラソース）の生成 */
  if( ( hOutFile = fopen( AsmFile, "w") ) != NULL ){
    catFile( InFile );  // プログラム
//    fprintf( hOutFile, "  align 8\n" );
    catFile( StrFile );  // 文字列
//    fprintf( hOutFile, "  align 8\n" );
    catFile( VarFile );  // 変数
    fclose( hOutFile );
  }
}


/* ファイル結合サブルーチン */
void catFile( char* fname ){
  int c;

  if( ( hInFile = fopen( fname,  "r" ) ) != NULL ){
    while( ( c = getc( hInFile ) ) != EOF )  putc( c, hOutFile );
    fclose( hInFile );
  }
  else{
    printf( "ファイル結合: ファイル\"%s\"を開くことができません\n", fname ) ;
  }

}


/* 文字列処理サブルーチン(ダブルクォーテーションで囲まれた文字列をバイトコードに変換する) */
void strProcess(){
  int  c;

  if( ( hInFile = fopen( InFile,  "r" ) ) == NULL ){
    printf( "文字列処理:入力エラー" ) ;
    return;
  }
  if( ( hOutFile = fopen( OutFile, "w") ) == NULL ){
    printf( "文字列処理:出力エラー" ) ;
    fclose( hInFile );
    return;
  }
  if( ( hStrFile = fopen( StrFile, "w") ) == NULL ){
    printf( "文字列処理:文字列ファイル出力エラー" ) ;
    fclose( hInFile );
    fclose( hOutFile );
    return;
  }
  while( ( c = getc( hInFile ) ) != EOF ){
    if( c == (int)'\"' ){
      fprintf( hOutFile, "S%d", StringID );
      fprintf( hStrFile, "S%d:\n", StringID++ );
      while( ( c = getc( hInFile  ) ) != '\"' && c != EOF ){
        fprintf( hStrFile, "  byte %d\n", c );
      }
      fprintf( hStrFile, "  byte 0\n" );
      if( c == EOF ) break;
    }
    else if( c == (int)'\'' ){
      if( ( c = getc( hInFile  ) ) == EOF ) break;
      fprintf( hOutFile, "%d", c );
      while( ( c = getc( hInFile  ) ) != '\'' && c != EOF ) {}
      if( c == EOF ) break;
    }
    else  putc( c, hOutFile );
  }
  fclose( hInFile );
  fclose( hOutFile );
  fclose( hStrFile );
}


// struct/class, enum構文の処理関数
void compile_s(){
  int mode=0; // 0:通常, 1:struct文 2:enum文
  char *s, *t, buf[1024], sname[512],cname[512];
  int i, count;
  
  if( ( hInFile  = fopen( InFile,  "r" ) ) == NULL ){
    printf("struct/enum文の処理中にエラーが発生しました\n" );
    return;
  }
  if( ( hOutFile =  fopen( OutFile, "w" ) ) == NULL ){
    fclose( hInFile );
    printf("struct/enum文の処理中にエラーが発生しました\n" );
    return;
  }

  while( fgets(buf, 1024, hInFile ) != NULL ){

    // コメントをすてる
    if( ( s = strstr( buf, Comment1 ) ) != NULL ) *s = '\0';
    if( ( s = strstr( buf, Comment2 ) ) != NULL ) *s = '\0';

    // 不要な空白文字をすてる
    for( i = strlen( buf ) - 1; i >= 0 && buf[ i ] <= ' '; i-- ) ;
    buf[ i + 1 ] = '\0';

    // 空文の場合はファイルからの読み込みに戻る
    if( buf[0]=='\0' ) continue;

    // 通常文の場合
    if( mode == 0 ){
      for( s = buf; *s == ' ' || *s == '\t'; s++ ) {}      // 空白を読み飛ばす
      if( strncmp( s, "struct ", 7 ) == 0 ){
        mode = 1;
        count = 0;
        for( s += 7; *s == ' ' || *s == '\t'; s++ ) {}    // 空白を読み飛ばす
        strcpy( sname, s );
        fprintf( hOutFile, " const0\n" );
      }
      else if( strncmp( s, "class ", 6 ) == 0 ){
        mode = 1;
        count = 0;
        for( s += 6; *s == ' ' || *s == '\t'; s++ ) {}    // 空白を読み飛ばす
        strcpy( sname, s );
        fprintf( hOutFile, " const0\n" );
      }
      else  if( strcmp( s, "enum" ) == 0 ){
          mode = 2;
          count = 0;
      }
      else{
          fprintf( hOutFile, "%s\n", buf );
      }
    }

    // class/struct構文の場合
    else if( mode == 1 ){
      for( s = buf; *s == ' ' || *s == '\t'; s++ ) {}      // 空白を読み飛ばす

      // field文
      if( strncmp( s, "field ", 6 ) == 0 ){
        for( s += 6; *s == ' ' || *s == '\t'; s++ ) {}    // 空白を読み飛ばす
        fprintf( hOutFile, " const_plus %s.%s 0\n", sname, s );
      }

      // long型
      else if( strncmp( s, "long ", 5 ) == 0 ){
        for( s += 5; *s == ' ' || *s == '\t'; s++ ) {}    // 空白を読み飛ばす
        if( ( t = strstr( s, "#" ) ) != NULL ) *t = '\0';
        fprintf( hOutFile, " const_plus %s.%s SIZEOF_LONG\n", sname, s );
      }

      // int型
      else  if( strncmp( s, "int ", 4 ) == 0 ){
        for( s += 4; *s == ' ' || *s == '\t'; s++ ) {}    // 空白を読み飛ばす
        if( ( t = strstr( s, "!" ) ) != NULL ) *t = '\0';
        fprintf( hOutFile, " const_plus %s.%s SIZEOF_INT\n", sname, s );
      }

      // short型
      else   if( strncmp( s, "short ", 6 ) == 0 ){
        for( s += 6; *s == ' ' || *s == '\t'; s++ ) {}    // 空白を読み飛ばす
        if( ( t = strstr( s, "%" ) ) != NULL ) *t = '\0';
        fprintf( hOutFile, " const_plus %s.%s SIZEOF_SHORT\n", sname, s );
      }

      // char型
      else  if( strncmp( s, "char ", 5 ) == 0 ){
        for( s += 5; *s == ' ' || *s == '\t'; s++ ) {}    // 空白を読み飛ばす
        if( ( t = strstr( s, "$" ) ) != NULL ) *t = '\0';
        fprintf( hOutFile, " const_plus %s.%s SIZEOF_CHAR\n", sname, s );
      }

      // 終了
      else if( strcmp( s, "end" ) == 0 ){
        fprintf( hOutFile, " const_plus %s.SIZE 0\n", sname );
        mode = 0;
      }

      // クラス型
      else{
        for( t = cname; *s != ' '; s++ ) { *t++ = *s; }    // クラス名を読み込む
        *t = '\0';
        while( *s == ' ' || *s == '\t') { s++;}    // 空白を読み飛ばす
        fprintf( hOutFile, " const_plus %s.%s %s.SIZE\n", sname, s, cname );
      }

    }

    // enum文の場合
    else if( mode == 2 ){
      for( s = buf; *s == ' ' || *s == '\t'; s++ ) {}      // 空白を読み飛ばす
      if( strcmp( s, "end" ) == 0 ){
        mode = 0;
      }
      else if( *s == '_' || *s >= 'A' ){
        fprintf( hOutFile, " const %s %d\n", s, count );
        count++;
      }
    }

  }

  // コンパイル終了
  fclose( hInFile );
  fclose( hOutFile );
}


// コンパイル処理サブルーチン
void compile( int pass ){
  char buf[1024], outbuf[1024], arg[10][LEN_ARG];
  char *source, **pattern, *ref, *out, *p, *q, *s;
  int  line, arg_p, i;

  if( ( hInFile  = fopen( InFile,  "r" ) ) == NULL ){
    printf("中間ファイルの読み込みでエラーが発生しました,pass=%d\n", pass);
    return;
  }
  if( ( hOutFile =  fopen( OutFile, "w" ) ) == NULL ){
    fclose( hInFile );
    printf("中間ファイルの書き込みでエラーが発生しました, pass=%d\n", pass);
    return;
  }

  line = 1;
  while( fgets(buf, 1024, hInFile ) != NULL ){

//printf("%d: %s\n", line, buf );

    /* 不要な空白文字をすてる */
    for( i = strlen( buf ) - 1; i >= 0 && buf[ i ] <= ' '; i-- ) ;
    buf[ i + 1 ] = '\0';

    /* 文字列ポインタ arg[0] に現在の行を代入する */
    sprintf( arg[0], "%d", line );

    /* 参照パターンを設定する */
    pattern = RefData[ pass ];

    /* パターンの比較 */
    next_pattern:  
    while( *pattern != NULL ){
      source = buf;
      ref = *pattern++;
      out = *pattern++;
      arg_p  = 1;

      /* １文字ごとに比較する */
      while( *ref != '\0' ){
        char* xarg;
        switch( *ref ){

        /* スペースの場合 */
        case ' ':
          if( *source > ' ' ) goto next_pattern;
          while( *source <= ' ' && *source > '\0' ) source++;
          if( *source == '\0' ) goto next_pattern;
          ref++;
          break;

        /* '\' 引数がある場合  */
        case '\\':
          xarg = arg[ arg_p ];
          ref++;

          /* 引数を分離する */
          while( *source != *ref ){
            *xarg++ = *source++;
            if( *source == '\0' && *ref != '\0' ) goto next_pattern; // 引数が途中で終了したらミスマッチと判定
          }
          *xarg = '\0';
          if( *arg[ arg_p ] == '\0' ) goto next_pattern; // 引数が空の場合はミスマッチと判定
          arg_p++;
          break;

        /* 上記以外の文字のとき */
        default:
          if( *source++ != *ref++ ) goto next_pattern; // 文字が違っていたらミスマッチと判定
        }
      }
      if( *source != '\0' ) goto next_pattern; // 余分な文字列が残っていたらミスマッチと判定

      /* パターンの比較が成功したら引数を展開して出力 */
      p = outbuf;
      while( *out != '\0' ){
        if( *out == '\\' ){
          q = arg[ (int)out[1] - '0' ];
          out += 2;
          while( *q != '\0' ) *p++ = *q++;
        }
        else *p++ = *out++;
      }
      *p = '\0';
      fprintf( hOutFile, "%s", outbuf );
      break;
    }

//    /* マッチするパターンが無ければメッセージを表示する */
//    if( *pattern == NULL ){
//      printf( "マッチするパターンがありませんでした\n" );
//    }

    line++;
  }

  // コンパイル終了
  fclose( hInFile );
  fclose( hOutFile );
}
