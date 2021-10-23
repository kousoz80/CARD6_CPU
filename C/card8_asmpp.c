
/*


  "card8_asmpp.c" 
  CARD8アセンブラ用プリプロセッサ

  コンパイル: gcc -o card8_asmpp card8_asmpp.c 


*/

#include <stdio.h>
#include <string.h>

// マクロ命令定義データ
char*  macro[] = {
  "\\: move.b \\,\\",    "\\1:\n read \\2\n write \\3\n",
  "\\: move.l \\,\\",    "\\1:\n read \\2\n write \\3\n read \\2+1\n write \\3+1\n read \\2+2\n write \\3+2\n",
  "\\: set@ \\",         "\\1:\n read \\2\n set.l\n read \\2+1\n set.m\n read \\2+2\n set.h\n",
  "\\: read@ \\",        "\\1:\n read \\2\n set.l\n read \\2+1\n set.m\n read \\2+2\n set.h\n read@\n",
  "\\: read@",           "\\1:\n read@\n",
  "\\: jmp@ \\",         "\\1:\n read \\2\n set.l\n read \\2+1\n set.m\n read \\2+2\n set.h\n jmp@\n",
  "\\: jmp@",            "\\1:\n jmp@\n",
  "\\: data.b \\",       "\\1:\n data \\2\n",
  "\\: data.l \\",       "\\1:\n data \\2.l\n data \\2.m\n data \\2.h\n",
  " move.b \\,\\",       " read \\1\n write \\2\n",
  " move.l \\,\\",       " read \\1\n write \\2\n read \\1+1\n write \\2+1\n read \\1+2\n write \\2+2\n",
  " set@ \\",            " read \\1\n set.l\n read \\1+1\n set.m\n read \\1+2\n set.h\n",
  " read@ \\",           " read \\1\n set.l\n read \\1+1\n set.m\n read \\1+2\n set.h\n read@\n",
  " read@",              " read@\n",
  " jmp@ \\",            " read \\1\n set.l\n read \\1+1\n set.m\n read \\1+2\n set.h\n jmp@\n",
  " jmp@",               " jmp@\n",
  " data.b \\",          " data \\1\n",
  " data.l \\",          " data \\1.l\n data \\1.m\n data \\1.h\n",
  "\\:\\",               "\\1:\n \\2\n",
  "\\:",                 "\\1:\n",
  " \\:",                "\\1:\n",
  " \\",                 " \\1\n",
  "\\",                  "\\1\n",

NULL
};


// プロトタイプ宣言
void compile(char* in, char* out );

//変数宣言
#define LEN_ARG  128  // 引数の最大の長さ

// コンパイラ定義データ
char   *Comment1 = "/*", *Comment2 = "//";
FILE  *hInFile, *hOutFile;


//必要なデータの初期化部分
int main( int argc, char* argv[] ){

  if( argc != 3 ) return 0;

  // マクロ展開
  compile( argv[1], argv[2]);
}


// コンパイル処理サブルーチン
void compile( char* infile, char* outfile ){
  char buf[1024], outbuf[1024], arg[10][LEN_ARG];
  char *source, **pattern, *ref, *out, *p, *q, *s;
  int  line, arg_p, i;


  if( ( hInFile  = fopen( infile,  "r" ) ) == NULL ){
    printf("ファイルの読み込みでエラーが発生しました.\n");
    return;
  }
  if( ( hOutFile =  fopen( outfile, "w" ) ) == NULL ){
    fclose( hInFile );
    printf("ファイルの書き込みでエラーが発生しました.\n");
    return;
  }

  line = 1;
  while( fgets(buf, 1024, hInFile ) != NULL ){

//printf("%d: %s\n", line, buf );

    // コメントをすてる
    if( ( s = strstr( buf, Comment1 ) ) != NULL ) *s = '\0';
    if( ( s = strstr( buf, Comment2 ) ) != NULL ) *s = '\0';

    // 不要な空白文字をすてる
    for( i = strlen( buf ) - 1; i >= 0 && buf[ i ] <= ' '; i-- ) ;
    buf[ i + 1 ] = '\0';

    // 空文の場合はファイルからの読み込みに戻る
    if( buf[0]=='\0' ) continue;

    /* 文字列ポインタ arg[0] に現在の行を代入する */
    sprintf( arg[0], "%d", line );

    /* 参照パターンを設定する */
    pattern = macro;

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
