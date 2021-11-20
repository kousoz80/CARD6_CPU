//  os6 CARD6 CPU用　オペレーティングシステム ver 0.1

/ org 0x9000/  // 開始アドレスは仮想マシンの実装に依存する

 const EOF         -1          // ファイルの終わりをあらわす文字コード 
 const ERROR       -1          // エラーが発生したことをあらわす 
 const NULL        0           // ヌルポインタ 
 const CNULL       63          // ヌルキャラクタ 
 const SPACE       0           // 空白文字 
 const CR          61          // キャリッジリターンコード 
 const LF          61          // ラインフィードコード 
 const PLUS        11          // プラス記号の文字コード 
 const MINUS       13          // マイナス記号の文字コード 
 const ESC         62          // ESCキーの文字コード 
 const NaN        0x20000     // ゼロ除算が発生したことをあらわす 
 const STACK_SIZE  2000
 const SIZEOF_CHAR 1
 const SIZEOF_INT  3
 const SIZEOF_LONG 3

// ファイルシステム定数の定義
 const RAMDISK     0x10000 // RAMディスク領域
 const SEC_SIZE    256     // セクタサイズ
 const TOPSEC      0       // 最初のセクタ 
 const ENDSEC      254     // 最後のセクタ 
 const NONSEC      -1      // セクタの存在しないことを示す定数 
 const FILSIZ      280     // １つのＦＣＢに割り当てられるメモリ(念のため少し多めにとっている)
 const CUR_SEC     0       // 現在読み書き中のセクタ  
 const FILTOP      1       // ファイルの先頭のセクタ 
 const BUFP        2       // バッファのポインタ  
 const BUFF        9       // FCBのセクタバッファ領域 
 const NEXT_SEC    3       // 次にアクセスするセクタ(同時にセクタヘッダでもあり、ここがゼロの場合は使用されていないことを示す) 
 const NEXT_FIL    4       // 次のファイルのあるセクタ 
 const FNAME       15      // FCBのファイルネーム領域 
 const FCONT0      35      // FCBのデータ領域（最初のセクタ） 
 const FCONT1      12      // FCBのデータ領域 (2番目以降のセクタ)
 const BUF_END     265     // FCBのデータ領域の終わり 

// コマンドパラメータ
 const cmd_buf     0x3ff90      // コマンド入力バッファ 
 const argc        0x3ffd0      // コマンドのパラメータの数 
 const argv        0x3ffd3      // パラメータが格納されている 
 const MAXCHAR     63           // コマンドの最大入力文字数 

// レジスタ領域
 const reg_pc      0x3ffec
 const reg_sp      0x3ffef
 const reg_r0      0x3fff2
 const reg_r1      0x3fff5
 const reg_r2      0x3fff8
 const reg_r3      0x3fffb

// 作業変数
 char  __sign$(1),__nbuf$(64)
 int   __p1#,__p2#,__p3#,__p4#,__p5#,__p6#,__p7#
 int   __t#,__u#,read_p# // data文へのポインタ
 int   __tmp#,__ans#,__sgn#,__tt#
 char  sbuf$(64)
 char  cc$
 int   exec#
 long  __stack#(STACK_SIZE),__stack_top#(1)


// プログラム開始位置 
_start:
 __stack_top, reg_sp#=
 disk_setup
 "CARD6 OS VERSION 0.1", prints nl

main:
  "# ", prints
  fault:
  sbuf, inputs cc$=
  if cc$<>LF then nl "? ", prints gotofault
  if sbuf$=CNULL goto main
  CNULL, sbuf$(19)=    // ファイル名は最大19文字まで
  sbuf, load __tt#=
  if __tt#=ERROR then "COMMAND NOT FOUND", prints nl gotomain
  APP_START  // エントリアドレスはAPP_START固定
  goto main


// コンソールからから一文字読み込む
getchar:
 in __tt#=
 if __tt#=63 goto getchar
 __tt#, end


// コンソールへ一文字出力する
putchar:
 __tmp#=
 __tmp#, out
 end


// 文字列を表示する
prints:
 __p6#=
 __prints1:
  if (__p6)$=CNULL then end
  (__p6)$, putchar
  __p6#++
 goto __prints1


// 数値を表示する
printd:
 dec prints
 end


// 改行する
nl:
 61, putchar
 end


// 画面消去
cls:
  62, putchar
//  1,  putchar
  end


// キー入力(実装されていない)
inkey:
 in
 end

// コンソールから文字列を入力する
inputs:
 __p6#=
 __inputs1:
  getchar __p5$= putchar
  if __p5$=ESC goto __inputs2
  if __p5$=LF  goto __inputs2
  __p5$, (__p6)$=
  __p6#++
 goto __inputs1
 __inputs2:
 CNULL,  (__p6)$=
 __p5$, end


// 文字列を比較する
strcmp:
 __p2#= swap __p1#=
 __strcmp1:
  if (__p1)$<>(__p2)$ then 1, end
  if (__p1)$=CNULL then 0, end
  __p1#++
  __p2#++
 goto __strcmp1


// 文字数制限付きで文字列を比較する
strncmp:
 __p3#= pop __p2#= pop __p1#=
 __strncmp1:
  if __p3#<=0 then 0, end
  if (__p1)$<>(__p2)$ then 1, end
  if (__p1)$=CNULL then 0, end
  __p1#++
  __p2#++
  __p3#--
 goto __strncmp1


// 文字列をコピーする
strcpy:
 __p2#= swap __p1#=
 __strcpy1:
  (__p1)$, (__p2)$= __p3#=
  __p1#++
  __p2#++
 if __p3#<>CNULL goto __strcpy1
 end


// 文字数制限付きで文字列をコピーする
strncpy:
 __p3#= pop __p2#= pop __p1#=
 __strncpy1:
  if __p3#<=0 then CNULL, (__p2)$= end
  (__p1)$, (__p2)$= __p4#=
  __p1#++
  __p2#++
  __p3#--
 if __p4#<>CNULL goto __strncpy1
 end


// 文字列を連結する
strcat:
 __p2#= swap __p1#=
__strcat1:
 if (__p2)$<>CNULL then __p2#++ goto__strcat1
__strcat2:
 (__p1)$, (__p2)$= __p3#=
 __p1#++
 __p2#++
 if __p3#<>CNULL goto __strcat2
 end


// 文字数制限付きで文字列を連結する
strncat:
 __p3#= pop __p2#= pop __p1#=
__strncat1:
 if (__p2)$<>CNULL then __p2#++ goto__strncat1
__strncat2:
 if __p3#<=0 then CNULL, (__p2)$= end
 (__p1)$, (__p2)$= __p4#=
 __p1#++
 __p2#++
 __p3#--
 if __p4#<>CNULL goto __strncat2
 end


// 文字列を検索する
strstr:
 __p2#= swap __p1#=
__strstr1:
 if (__p1)$=CNULL then NULL, end
 __p1#, __p3#=
 __p2#, __p4#=
__strstr2:
 if (__p3)$<>(__p4)$ then __p1#++ goto__strstr1
 __p3#++
 __p4#++
 if (__p4)$<>CNULL goto __strstr2
 __p1#, end


// 文字列の長さを得る
strlen:
 __p1#=
 0, __p2#=
__strlen1:
 if (__p1)$=CNULL then __p2#, end
 __p1#++
 __p2#++
 goto __strlen1


// 文字列を数値に変換する(基数指定あり)
atoi:
 __p2#= swap __p1#=
 1, __p3#=   0, __p4#=
 if (__p1)$=PLUS  then __p1#++
 if (__p1)$=MINUS then __p1#++ -1, __p3#=
__atoi1:
 0, __p5#=
__atoi2:
 if __p5#>=__p2# then __p3#, __p4#, * end
 if "0123456789ABCDEF"$(__p5#)<>(__p1)$ then __p5#++ goto__atoi2
 __p4#, __p2#, umul __p5#, + __p4#=
 __p1#++
 goto __atoi1


// 数値を文字列に変換する(基数指定あり)
itoa:
  __p2#= swap __p1#=
  if __p1#=0 then "0", __nbuf, strcpy __nbuf, end
  __nbuf, __p3#=
  1,      __p4#=
  __p1#,  __p5#=
__itoa1:
 if __p5#<__p2# goto __itoa2
  __p5#, __p2#, udiv __p5#=
  __p4#, __p2#, umul __p4#=
  goto __itoa1
__itoa2:
  __p1#, __p4#, udiv __p5#=
  __p4#, __p5#, umul __p1#, swap - __p1#=
  "0123456789ABCDEF"$(__p5#),  (__p3)$=
  __p3#++
  __p4#, __p2#, udiv __p4#=
  if __p4#<>0 goto __itoa2
  CNULL, (__p3)$=
 __nbuf, end


// 数値を2進文字列に変換する
bin:
 2, itoa end


// 数値を8進文字列に変換する
oct:
 8, itoa end


// 数値を10進文字列に変換する
dec:
 __p1#=
 if __p1#>=0 then __p1#, 10, itoa end
 __p1#,  neg 10, itoa
 MINUS,  __sign$=
 __sign, end


// 数値を16進文字列に変換する
hex:
 16, itoa end


// read文の読み込み位置を設定する
restore:
 read_p#=
 end


// data文で与えられたデータを読み込む
read:
 read_p#, 3, + read_p#=
 (read_p)#(-1), end


// 数値の絶対値を求める
abs:
  __p1#=
  if __p1#>=0 then __p1#, end
  0, __p1#, - end


// 定数エリア
__000: data 0
__001: data 1
__0x800000: data 0x800000
__NaN:  data NaN

// ファイルシステム 
  int   _void# // 空きセクタをしめす 
  int   _x#,_y#
  char  _buf$(FILSIZ)


// ディスクパラメータの初期化 
 disk_setup:
  TOPSEC, _void#=
  end

// 1セクタ割り当て
falloc:
  _buf, _void#, _reads
  if _buf#=TOPSEC then _void#, end // 使用していないセクタを見つけたらそれを返す
  _void#++
  if _void#<ENDSEC goto falloc
  NONSEC, end


// １セクタ開放
ffree:
  _x#= BLANK_SECTOR, swap _writes // 該当セクタに使用していない印をつける 
  if  _x#<_void# then _x#, _void#=
  end


// FCBをセーブする 
save_fcb:
  _wfp#=
  if (_wfp)#<>(_wfp)#(FILTOP) goto _save_fcb1
     _buf, (_wfp)#, _reads                    // マルチタスクの場合、他のタスクに
     _buf-BUFF#(NEXT_FIL), (_wfp)#(NEXT_FIL)= // よってNEXT_FIL部分が
  _save_fcb1:                                 // 書き換えられてしまうことがあるのでこの部分を追加する
  _wfp#,  BUFF, + (_wfp)#, _writes
  FCONT1, _wbufp#=
  end


// ファイルから１文字入力
getc:
  int   _rfp#,_rbufp#
  _rfp#=
  (_rfp)#(BUFP), _rbufp#=
  if (_rfp)#=NONSEC then EOF,     end
  _getc1:
    if _rbufp#<BUF_END then _rbufp#, 1, + (_rfp)#(BUFP)= (_rfp)$(_rbufp#), end
    (_rfp)#(NEXT_SEC), (_rfp)#=
    if (_rfp)#=NONSEC  then EOF, end
    _rfp#,  BUFF, + (_rfp)#, _reads
    FCONT1, _rbufp#=
  goto _getc1


// ファイルに１文字出力する
putc:
  int  _wfp#,_wbufp#
  char _c1$

  _wfp#= swap _c1$=
  if (_wfp)#=NONSEC then ERROR,   end
  (_wfp)#(BUFP), _wbufp#=
  _putc1:
    if _wbufp#>=BUF_END goto _putc2
       _wbufp#, 1, + (_wfp)#(BUFP)=
       _c1$, (_wfp)$(_wbufp#)=
       end
    _putc2:
    falloc _x#= (_wfp)#(NEXT_SEC)=
    _wfp#, save_fcb
    _x#,   (_wfp)#=
  if _x#<>NONSEC then NEW_SECTOR, _x#, _writes goto_putc1
  ERROR, end


// 使用していないセクタのヘッダ(先頭がTOPSEC)
BLANK_SECTOR:
  data TOPSEC

// これから使用するセクタのヘッダ(先頭がNONSEC)
NEW_SECTOR:
  data NONSEC


// 読み出しモードでファイルをオープンする
ropen:
  int _fp#,_fname#,_z#
  _fp#= swap _fname#=
  TOPSEC, _x#=
  _ropen1:
    _fp#, BUFF,  + _x#, _reads
    _fp#, FNAME, + _fname#,  strcmp _z#=
    if _z#=0 then FCONT0, (_fp)#(BUFP)= _x#, (_fp)#= (_fp)#(FILTOP)= end
    _x#, _y#=
    (_fp)#(NEXT_FIL), _x#=
  if _x#<>NONSEC goto _ropen1
  NONSEC, (_fp)#= end


//  書き込みモードでファイルをオープンする 
wopen:
  ropen
  if (_fp)#=NONSEC goto fcreate

fkilcon:// ファイルの内容を消去する 
  (_fp)#(NEXT_SEC), _x#=
  _fkilcon1:
    if _x#=NONSEC then end
    _buf,  _x#, _reads
    _x#, ffree
    _buf-BUFF#(NEXT_SEC), _x#=
  goto _fkilcon1

fcreate:// 新しくファイルを作成する 
  falloc  (_fp)#= (_fp)#(FILTOP)= (_fp)#(NEXT_FIL)=
  _fp#, BUFF,  + _y#,     _writes
  if (_fp)#=NONSEC then end
  NONSEC, (_fp)#(NEXT_FIL)=
  _fp#, FNAME, + _fname#, swap strcpy
  _fp#, BUFF,  + (_fp)#,  _writes
  FCONT0, (_fp)#(BUFP)=
  end


// 読み出しモードでオープンしたファイルをクローズする 
rclose:
  end


// 書き込みモードでオープンしたファイルをクローズする 
wclose:
  _fp#=
  if (_fp)#=NONSEC then end
  (_fp)#(BUFP), _x#=
  if _x#<BUF_END then CNULL, (_fp)$(_x#)=
  NONSEC, (_fp)#(NEXT_SEC)=
  _fp#, save_fcb
  end


// ファイルを消去する 
rm:
  char _fil$(FILSIZ)
  _fil, ropen
  if _fil#<=NONSEC then ERROR, end // ディスクにファイルがなければエラー 
  if _fil#=TOPSEC  then ERROR, end // １番目のファイルは削除できない 
  fkilcon
  _buf, _y#, _reads
  _fil#(NEXT_FIL), _buf-BUFF#(NEXT_FIL)=
  _buf, _y#, _writes
  _fil#, ffree
  _fil#, end


// ファイル名を変更する 
mv:
  int _fnam1#,_fnam2#
  _fnam2#= swap _fnam1#=
  _fnam2#, _fil, ropen
  if _fil#<>ERROR  then ERROR, end   // 既に同じファイルがあればエラー 
  _fnam1#, _fil, ropen
  if _fil#=ERROR  then ERROR, end   // ディスクにファイルがないとエラー 
  _fnam2#, _fil+FNAME, strcpy
  _fil+BUFF, _fil#, _writes
  _fil#, end


// ファイルから文字列を１行入力する 
finputs:
  count _p0#
  int   _p1#,_p2#,_p3#
  _p2#= swap _p1#=
_finputs1:
  _p2#, getc _p3#=
  if _p3#=LF    goto _finputs2 // LFのとき入力終わり 
  if _p3#=EOF   goto _finputs2 // EOFのときも入力終わり 
  if _p3#=CNULL goto _finputs2 // ヌル文字のときも入力終わり 
  if _p3#=ESC   goto _finputs2 // ESCのときも入力終わり 
  _p3#, (_p1)$=
  _p1#++
  goto _finputs1
_finputs2:
  CNULL,  (_p1)$=
  _p3#, end


// ファイルに文字列を出力する 
fprints:
  _p2#= swap _p1#=
_fprints1:
  if (_p1)$=CNULL then end
  (_p1)$, _p2#, putc
  _p1#++
  goto _fprints1


// ファイルに数値を出力する 
fprintd:
  _p1#= swap dec _p1#, fprints
  end


// ファイルに改行コードを出力する 
fnl:
  _p0#=
  LF, _p0#, putc
  end


// バイナリファイルをロードする (ファイルフォーマットはMS-DOSのCOM形式に類似)
load:
  int _pp0#
  cmd_buf, strcpy
  if cmd_buf$=CNULL then ERROR, end
  0,  argc#=   cmd_buf+MAXCHAR$=
  SPACE, _c1$=
  for _p0#=cmd_buf to cmd_buf+MAXCHAR
    if _c1$<>SPACE goto endif1
      if (_p0)$<>SPACE then _p0#, argv#(argc#)= argc#++
    endif1:
    if _c1$=SPACE  then (_p0)$, _c1$= gotoendif2
      (_p0)$, _c1$=
      if (_p0)$=SPACE  then CNULL, (_p0)$=
    endif2:
  if (_p0)$(1)<>CNULL then next _p0#
  if argc#=0 then ERROR, end
  argv#(0), _fil, ropen
  if  _fil#=NONSEC then ERROR, end
  FCONT0,    _p1#=  // 転送元アドレス
  APP_START, _p2#=  // アプリケーション開始アドレス(固定値)
  loop_load:
    _fil$(_p1#), (_p2)$=
    _p1#++
    if _p1#<BUF_END goto endif3
      if _fil#(NEXT_SEC)=NONSEC then 0, end
      _fil+BUFF, _fil#(NEXT_SEC), _reads
      FCONT1, _p1#=
    endif3:
    _p2#++
  goto loop_load


// １セクタ読み出し
_reads:
  int _xsec#,_xbuf#
  _xsec#= swap _xbuf#=
  _xsec#, SEC_SIZE, * RAMDISK, + _xsec#=
  for _p0#=0 to 255
  (_xsec)$(_p0#), (_xbuf)$(_p0#)=
  next _p0#
  end


// １セクタ書き込み
_writes:
  _xsec#= swap _xbuf#=
  _xsec#, SEC_SIZE, * RAMDISK, + _xsec#=
  for _p0#=0 to 255
  (_xbuf)$(_p0#), (_xsec)$(_p0#)=
  next _p0#
  end


 // アプリケーション開始アドレス
 char APP_START$(1)
