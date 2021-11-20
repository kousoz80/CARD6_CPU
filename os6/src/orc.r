// oregengo-Rコンパイラ for os6
// セルフホスト ver 0.1

 const SINGLE_QUOT 7
 const MAX_PASS 3
 count i#,j#,k#
 char  asmfile$(128),cmd$(128)
 char  rfp$(FILSIZ),wfp$(FILSIZ),sfp$(FILSIZ)
 long   infile#,outfile#,strfile#,varfile#,t#

main:
 if argc#<2 goto abort
 "COMPILE:", prints nl
 "ASM.S",  asmfile, strcpy
 "--TMP1", infile#=
 "--TMP2", outfile#=
 "--STR",  strfile#=
 "--VAR",  varfile#=

 // 入力ファイルの結合
 infile#, wfp, wopen
 argc#, 1, - k#=
 for i#=1 to k#
   argv#(i#),  cat_file j#=
   if j#=ERROR then wfp, wclose infile#, rm gotoabort
 next i#
 wfp, wclose

 // コンパイル処理
 str_procsr   // 文字列の処理

 infile#, outfile#, infile#=  swap outfile#=
 compile_s    // struct / enum構文の処理
 infile#, k#= outfile#, infile#= varfile#, outfile#= k#, varfile#=
 0, compile   // 宣言文の処理
 outfile#, varfile#, outfile#= swap varfile#=
 for i#=1 to MAX_PASS
  i#, compile // 実行文の処理
  infile#, outfile#, infile#=  swap outfile#=
 next i#

 // 出力ファイルを結合する
 asmfile, wfp, wopen
 infile#,   cat_file
 strfile#,  cat_file
 varfile#,  cat_file
 wfp, wclose

// tempファイルを消去
 infile#,   rm
 outfile#, rm
 strfile#,  rm
 varfile#, rm
 end

// 異常終了
abort:
 " COMMAND INPUT ERROR", prints nl
 end


//　ファイル結合サブルーチン
cat_file:
 rfp, ropen t#=
 if t#=ERROR then ERROR, end
 lop1:
  rfp, getc t$=
  if t$=CNULL goto ext1
  t$, wfp, putc
  goto lop1
 ext1:
 rfp, rclose
 NULL, end


// 文字列処理
str_procsr:
 const DBL_QUOT 2
 infile#,   rfp, ropen
 outfile#,  wfp, wopen
 strfile#,  sfp, wopen
 1, j#=
 loop4:
  rfp, getc k$=
  if k$=CNULL goto exit4
  if k$=SINGLE_QUOT goto case_single_quot
  if k$<>DBL_QUOT then k$, wfp, putc gotoloop4

  // 文字列があるときの処理
  case_dbl_quot:
    'S', wfp, putc
    '@', wfp, putc
     j#,  wfp, fprintd
    'S', sfp, putc
    '@', sfp, putc
     j#,  sfp, fprintd
    ':', sfp, putc sfp, fnl
    loop5:
      rfp, getc k$=
      if k$=CNULL goto exit4
      if k$=DBL_QUOT goto exit5
      " BYTE ", sfp, fprints k$, sfp, fprintd sfp, fnl
      goto loop5
    exit5:
    " BYTE CNULL", sfp, fprints sfp, fnl
    j#++
  goto loop4
  
  // 文字定数があるときの処理
  case_single_quot:
    rfp, getc k$=
    k$, wfp, fprintd
    loop6:
      rfp, getc k$=
      if k$=CNULL goto exit4
    if k$<>SINGLE_QUOT goto loop6
  goto loop4
     
 exit4:
 rfp, rclose
 wfp, wclose
 sfp, wclose
 end


// struct / class / enum構文の処理
compile_s:
 char  sbuf$(1024),sname$(512),cname$(512)
 long  mode#,offset#,s#,p#

 infile#,  rfp, ropen
 outfile#, wfp, wopen
 cmp_loop:
  buf,  rfp, finputs k$=
  if k$=CNULL goto cmp_end

  // コメントを除去
  buf, "/*", strstr k#=
  if k#<>NULL then CNULL, (k)$=
  buf, "//", strstr k#=
  if k#<>NULL then CNULL, (k)$=

  // 不要なスペースを除去
  buf, strlen buf, + k#=
  del_space:
   if k#=buf goto cmp_loop
   k#--
  if (k)$=' ' goto del_space
  CNULL, (k)$(1)=

  // 空文の場合はファイルからの読み込みに戻る
  if buf$=CNULL goto cmp_loop
  
    // 通常文の場合
    mode0:
    if mode#<>0 goto mode1
      buf, s#=
      mode01:       // 空白を読み飛ばす
        if (s)$=' ' then s#++ gotomode01

      // struct文が検出された場合
      mode0_struct:
        s#, "STRUCT ", 7, strncmp k#=
        if k#<>0 goto mode0_class
        1, mode#=
        0, offset#=
        s#, 7, + s#=
        mode02:
        if (s)$=' ' then s#++ gotomode02
        s#, sname, strcpy
        " CONST0", wfp, fprints wfp, fnl
        goto cmp_loop

      // class文が検出された場合
      mode0_class:
        s#, "CLASS ", 6, strncmp k#=
        if k#<>0 goto mode0_enum
        1, mode#=
        0, offset#=
        s#, 6, + s#=
        mode03:
        if (s)$=' ' then s#++ gotomode03
        s#, sname, strcpy
        " CONST0", wfp, fprints wfp, fnl
        goto cmp_loop

      // enum文が検出された場合
      mode0_enum:
      s#, "ENUM", strcmp k#=
      if k#<>0 goto mode0_other
      2, mode#=
      0, offset#=
      goto cmp_loop

      // 上記以外の場合
      mode0_other:
         buf, wfp, fprints wfp, fnl
         goto cmp_loop

    // struct/class 文の場合
    mode1:
    if mode#<>1 goto mode2
      buf, s#=
      mode11:       // 空白を読み飛ばす
        if (s)$=' ' then s#++ gotomode11

        // field文が検出された場合
        mode1_field:
        s#, "FIELD ", 6, strncmp k#=
        if k#<>0 goto mode1_long 
        s#, 6, + s#=
        mode110:       // 空白を読み飛ばす
        if (s)$=' ' then s#++ gotomode110
        " CONST-PLUS ", wfp, fprints  sname, wfp, fprints
        ".",  wfp, fprints s#, wfp, fprints
        " 0", wfp, fprints wfp, fnl
        goto cmp_loop
        
        // long文が検出された場合
        mode1_long:
        s#, "LONG ", 5, strncmp k#=
        if k#<>0 goto mode1_int 
        s#, 5, + s#=
        mode12:       // 空白を読み飛ばす
        if (s)$=' ' then s#++ gotomode12
        s#, "#", strstr p#=
        if p#<>NULL then CNULL, (p)$=
        " CONST-PLUS ", wfp, fprints  sname, wfp, fprints
        ".",  wfp, fprints s#, wfp, fprints
        " SIZEOF[LONG", wfp, fprints wfp, fnl
        goto cmp_loop
        
        // int文が検出された場合
        mode1_int:
        s#, "INT ", 4, strncmp k#=
        if k#<>0 goto mode1_char 
        s#, 4, + s#=
        mode13:       // 空白を読み飛ばす
        if (s)$=' ' then s#++ gotomode13
        s#, "#", strstr p#=
        if p#<>NULL then CNULL, (p)$=
        " CONST-PLUS ", wfp, fprints  sname, wfp, fprints
        ".",  wfp, fprints s#, wfp, fprints
        " SIZEOF[INT", wfp, fprints wfp, fnl
        goto cmp_loop
        
        // char文が検出された場合
        mode1_char:
        s#, "CHAR ", 5, strncmp k#=
        if k#<>0 goto mode1_end 
        s#, 5, + s#=
        mode15:       // 空白を読み飛ばす
        if (s)$=' ' then s#++ gotomode15
        s#, "$", strstr p#=
        if p#<>NULL then CNULL, (p)$=
        " CONST-PLUS ", wfp, fprints  sname, wfp, fprints
        ".",  wfp, fprints s#, wfp, fprints
        " SIZEOF[CHAR", wfp, fprints wfp, fnl
        goto cmp_loop
        
        // end文が検出された場合
        mode1_end:
        s#, "END", strcmp k#=
        if k#<>0 goto mode1_class 
        " CONST-PLUS ", wfp, fprints  sname, wfp, fprints
        ".SIZE 0",  wfp, fprints  wfp, fnl
        0, mode#=
        goto cmp_loop
        
        // クラスが検出された場合
        mode1_class:
        cname, p#=
        mode16:  // クラス名を読み込む
        if (s)$<>' ' then (s)$, (p)$= s#++ p#++ gotomode16
        CNULL, (p)$=
        mode17:  // 空白を読み飛ばす
        if (s)$=' ' then s#++ gotomode17
        " CONST-PLUS ", wfp, fprints  sname, wfp, fprints
        ".", wfp, fprints s#, wfp, fprints
        " ", wfp, fprints cname, wfp, fprints
        ".SIZE",  wfp, fprints wfp, fnl
        goto cmp_loop

    // enum文の場合
    mode2:
    if mode#<>2 goto cmp_loop // 普通はないが、それ以外のモードならループの先頭にジャンプする
      buf, s#=
      mode21:       // 空白を読み飛ばす
        if (s)$=' ' then s#++ gotomode21

        // end文が検出された場合
        mode2_end:
        s#, "END", strcmp k#=
        if k#<>0 goto mode2_other 
        0, mode#=
        goto cmp_loop

        // 上記以外の場合
        mode2_other:
        if (s)$='['    goto def_enum
        if (s)$>='A' goto def_enum
        goto cmp_loop

        // 列挙子を定義する
        def_enum:
        " CONST ", wfp, fprints  s#, wfp, fprints
        " ",  wfp, fprints  offset#, wfp, fprintd
        wfp, fnl
        offset#++
        goto cmp_loop

 // コンパイル終了
 cmp_end:
 rfp, rclose
 wfp, wclose
 end


// マクロ処理
compile:
 const LEN_ARG 32
 char  buf$(1024),arg$(1024)
 long   pass#,line#,sou#,obj#,ref#,arg_p#

 pass#=
 infile#,  rfp, ropen
 outfile#, wfp, wopen
 1, line#=
 cmple_loop:
  buf,  rfp, finputs k$=
  if k$=CNULL goto cmple_end

  // 文字列arg(0)に現在の行を代入
  line#, dec arg+0, strcpy

  // パターンの比較
  ref_data#(pass#), restore
  read_ref: fault_cmp:
   read ref#=
   if ref#=NULL goto cmple_err
   buf, sou#=
   read obj#=
   arg+LEN_ARG, arg_p#=

   // 1文字ごとに比較する
   cmp_a_char:
    if (ref)$<>CNULL goto case_SPACE
    if (sou)$<>CNULL goto fault_cmp
    goto success_cmp

    // スペース
    case_SPACE:
     if (ref)$<>SPACE goto case_YEN
     if (sou)$<>SPACE goto fault_cmp
     loop1:
      sou#++
     if (sou)$=SPACE goto loop1
     if (sou)$=CNULL  goto fault_cmp
     ref#++
     goto cmp_a_char

    // 引数
    case_YEN:
     if (ref)$<>'%'   goto otherwise 
     ref#++
     arg_p#, k#=

     // 引数を分離する
     ext_arg:
      if (sou)$=CNULL then if (ref)$<>CNULL goto fault_cmp
      if (sou)$=(ref)$ then  CNULL, (k)$=  gotostore_arg
      (sou)$, (k)$=
      sou#++
      k#++
      goto ext_arg

    // 分離した引数を格納する
    store_arg:
     if (arg_p)$=CNULL goto fault_cmp
     arg_p#, LEN_ARG, + arg_p#=
     goto cmp_a_char

    // その他の文字
    otherwise:
     if (sou)$<>(ref)$ goto fault_cmp
     sou#++
     ref#++
     goto cmp_a_char

    // パターンの比較が成功したとき
    success_cmp: // オブジェクトを展開する
     buf, j#=
     loop2:
      if (obj)$<>'%' goto skip2
       (obj)$(1), '0', - LEN_ARG, * arg, + k#=
       obj#, 2, + obj#=
       loop3:
        if (k)$=CNULL goto loop2
        (k)$, (j)$=
        k#++
        j#++
       goto loop3
      skip2:
      if (obj)$=CNULL then  CNULL, (j)$=  buf, wfp, fprints gotocmple_next
      (obj)$, (j)$=
      obj#, 1, + obj#=
      j#++
     goto loop2

  // error処理
  cmple_err:

  // 次の行に移る
  cmple_next:
  line#++
  goto cmple_loop

 // コンパイル終了
 cmple_end:
 rfp, rclose
 wfp, wclose
 end


/* データの先頭アドレス */
ref_data:
 data pass1,pass2,pass3,codegen

/* パス１定義データ （宣言文の定義）*/
pass1:
  data " LONG %#(%),%#(%),%#(%),%#(%)"
  data "%1: MEMORY %2*3
%3: MEMORY %4*3
%5: MEMORY %6*3
%7: MEMORY %8*3
"
 data " LONG %#(%),%#(%),%#(%)"
 data "%1: MEMORY %2*3
%3: MEMORY %4*3
%5: MEMORY %6*3
"
  data  " LONG %#(%),%#(%)"
  data  "%1: MEMORY %2*3
%3: MEMORY %4*3
"
  data  " LONG %#(%)"
  data  "%1: MEMORY %2*3
"
 data " LONG %#,%#,%#,%#,%#,%#,%#,%#"
 data "%1: MEMORY 3
%2: MEMORY 3
%3: MEMORY 3
%4: MEMORY 3
%5: MEMORY 3
%6: MEMORY 3
%7: MEMORY 3
%8: MEMORY 3
"
 data " LONG %#,%#,%#,%#,%#,%#,%#"
 data "%1: MEMORY 3
%2: MEMORY 3
%3: MEMORY 3
%4: MEMORY 3
%5: MEMORY 3
%6: MEMORY 3
%7: MEMORY 3
"
 data " LONG %#,%#,%#,%#,%#,%#"
 data "%1: MEMORY 3
%2: MEMORY 3
%3: MEMORY 3
%4: MEMORY 3
%5: MEMORY 3
%6: MEMORY 3
"
  data " LONG %#,%#,%#,%#,%#"
  data "%1: MEMORY 3
%2: MEMORY 3
%3: MEMORY 3
%4: MEMORY 3
%5: MEMORY 3
"
 data " LONG %#,%#,%#,%#"
 data "%1: MEMORY 3
%2: MEMORY 3
%3: MEMORY 3
%4: MEMORY 3
"
 data " LONG %#,%#,%#"
 data "%1: MEMORY 3
%2: MEMORY 3
%3: MEMORY 3
  "
 data " LONG %#,%#"
 data "%1: MEMORY 3
%2: MEMORY 3
"
 data " LONG %#"
 data "%1: MEMORY 3
"
 data " INT %#(%),%#(%),%#(%),%#(%)"
 data "%1: MEMORY %2*3
%3: MEMORY %4*3
%5: MEMORY %6*3
%7: MEMORY %8*3
"
 data " INT %#(%),%#(%),%#(%)"
 data "%1: MEMORY %2*3
%3: MEMORY %4*3
%5: MEMORY %6*3
"
 data " INT %#(%),%#(%)"
 data "%1: MEMORY %2*3
%3: MEMORY %4*3
"
 data " INT %#(%)"
 data "%1: MEMORY %2*3
"
 data " INT %#,%#,%#,%#,%#,%#,%#,%#"
 data "%1: MEMORY 3
%2: MEMORY 3
%3: MEMORY 3
%4: MEMORY 3
%5: MEMORY 3
%6: MEMORY 3
%7: MEMORY 3
%8: MEMORY 3
"
 data " INT %#,%#,%#,%#,%#,%#,%#"
 data "%1: MEMORY 3
%2: MEMORY 3
%3: MEMORY 3
%4: MEMORY 3
%5: MEMORY 3
%6: MEMORY 3
%7: MEMORY 3
"
 data " INT %#,%#,%#,%#,%#,%#"
 data "%1: MEMORY 3
%2: MEMORY 3
%3: MEMORY 3
%4: MEMORY 3
%5: MEMORY 3
%6: MEMORY 3
"
 data " INT %#,%#,%#,%#,%#"
 data "%1: MEMORY 3
%2: MEMORY 3
%3: MEMORY 3
%4: MEMORY 3
%5: MEMORY 3
"
 data " INT %#,%#,%#,%#"
 data "%1: MEMORY 3
%2: MEMORY 3
%3: MEMORY 3
%4: MEMORY 3
"
 data " INT %#,%#,%#"
 data "%1: MEMORY 3
%2: MEMORY 3
%3: MEMORY 3
"
 data " INT %#,%#"
 data "%1: MEMORY 3
%2: MEMORY 3
"
 data " INT %#"
 data "%1: MEMORY 3
"
 data " CHAR %$(%),%$(%),%$(%),%$(%)"
 data "%1: MEMORY %2
%3: MEMORY %4
%5: MEMORY %6
%7: MEMORY %8
"
 data " CHAR %$(%),%$(%),%$(%)"
 data "%1: MEMORY %2
%3: MEMORY %4
%5: MEMORY %6
"
 data " CHAR %$(%),%$(%)"
 data "%1: MEMORY %2
%3: MEMORY %4
"
 data " CHAR %$(%)"
 data "%1: MEMORY %2
"
 data " CHAR %$,%$,%$,%$,%$,%$,%$,%$"
 data "%1: MEMORY 1
%2: MEMORY 1
%3: MEMORY 1
%4: MEMORY 1
%5: MEMORY 1
%6: MEMORY 1
%7: MEMORY 1
%8: MEMORY 1
"
 data " CHAR %$,%$,%$,%$,%$,%$,%$"
 data "%1: MEMORY 1
%2: MEMORY 1
%3: MEMORY 1
%4: MEMORY 1
%5: MEMORY 1
%6: MEMORY 1
%7: MEMORY 1
"
 data " CHAR %$,%$,%$,%$,%$,%$"
 data "%1: MEMORY 1
%2: MEMORY 1
%3: MEMORY 1
%4: MEMORY 1
%5: MEMORY 1
%6: MEMORY 1
"
 data " CHAR %$,%$,%$,%$,%$"
 data "%1: MEMORY 1
%2: MEMORY 1
%3: MEMORY 1
%4: MEMORY 1
%5: MEMORY 1
"
 data " CHAR %$,%$,%$,%$"
 data "%1: MEMORY 1
%2: MEMORY 1
%3: MEMORY 1
%4: MEMORY 1
"
 data " CHAR %$,%$,%$"
 data "%1: MEMORY 1
%2: MEMORY 1
%3: MEMORY 1
"
 data " CHAR %$,%$"
 data "%1: MEMORY 1
%2: MEMORY 1
"
 data " CHAR %$"
 data "%1: MEMORY 1
"
 data " COUNT %#,%#,%#,%#,%#,%#,%#,%#"
 data "%1: MEMORY 12
%2: MEMORY 12
%3: MEMORY 12
%4: MEMORY 12
%5: MEMORY 12
%6: MEMORY 12
%7: MEMORY 12
%8: MEMORY 12
"
 data " COUNT %#,%#,%#,%#,%#,%#,%#"
 data "%1: MEMORY 12
%2: MEMORY 12
%3: MEMORY 12
%4: MEMORY 12
%5: MEMORY 12
%6: MEMORY 12
%7: MEMORY 12
"
 data " COUNT %#,%#,%#,%#,%#,%#"
 data "%1: MEMORY 12
%2: MEMORY 12
%3: MEMORY 12
%4: MEMORY 12
%5: MEMORY 12
%6: MEMORY 12
"
 data " COUNT %#,%#,%#,%#,%#"
 data "%1: MEMORY 12
%2: MEMORY 12
%3: MEMORY 12
%4: MEMORY 12
%5: MEMORY 12
"
 data " COUNT %#,%#,%#,%#"
 data "%1: MEMORY 12
%2: MEMORY 12
%3: MEMORY 12
%4: MEMORY 12
"
 data " COUNT %#,%#,%#"
 data "%1: MEMORY 12
%2: MEMORY 12
%3: MEMORY 12
"
 data " COUNT %#,%#"
 data "%1: MEMORY 12
%2: MEMORY 12
"
 data " COUNT %#"
 data "%1: MEMORY 12
"
 data NULL

/* パス2定義データ （if-then文の定義）*/
pass2:

 data " IF %<>% THEN %"
 data " IF %1=%2 GOTO L@%0
   %3
L@%0:
"
 data " IF %>=% THEN %"
 data " IF %1<%2 GOTO L@%0
   %3
L@%0:
"
 data " IF %<=% THEN %"
 data " IF %1>%2 GOTO L@%0
   %3
L@%0:
"
 data " IF %>% THEN %"
 data " IF %1<=%2 GOTO L@%0
 %3
L@%0:
"
 data " IF %<% THEN %"
 data " IF %1>=%2 GOTO L@%0
 %3
L@%0:
"
 data " IF %=% THEN %"
 data " IF %1<>%2 GOTO L@%0
 %3
L@%0:
"


 data "%: %"
 data "%1:
 %2
"
 data "%"
 data "%1
"
 data NULL

/* パス3定義データ （実行文の定義）*/
pass3:
 data "/%/"
 data "/%1/
"
 data "%:"
 data "%1:
"

 data " LONG %"
 data ""
 data " INT %"
 data ""
 data " CHAR %"
 data ""
 data " COUNT %"
 data ""
 data " CONST % %"
 data "/%1: = %2/
"
 data " CONST-PLUS % %"
 data "/%1: += %2/
"
 data " CONST0"
 data "/ = 0/
"

// 整数比較
 data " IF %<>% GOTO %"
 data " %1,
 %2,
 JNZ %3
"
 data " IF %>=% GOTO %"
 data " %1,
 %2,
 JGE %3
"
 data " IF %<=% GOTO %"
 data " %2,
 %1,
 JGE %3
"
 data " IF %>% GOTO %"
 data " %2,
  %1,
  JLT %3
"
 data " IF %<% GOTO %"
 data " %1,
 %2,
 JLT %3
"
 data " IF %=% GOTO %"
 data " %1,
 %2,
 JZ %3
"



 data " GOTO %"
 data " JMP %1
"
// for-next (cpu依存する部分あり) ---> ジャンプアドレス($+xxx)
 data " FOR %#=% TO % STEP %"
 data " %2,
 %1#=
 %3,
 %1+3#=
 %4,
 %1+6#=
 $+8,
 %1+9#=
"
 data " FOR %#=% TO %"
 data " %2,
 %1#=
 %3,
 %1+3#=
 1,
 %1+6#=
 $+8,
 %1+9#=
"
 data " NEXT %#"
 data " %1#,
 %1+3#,
 JZ $+22
 %1#,
 %1+6#,
 +
 %1#=
 %1+9#,
 JMP@
"
 data " DATA %,%,%,%,%,%,%,%"
 data " DATA%1
 DATA%2
 DATA%3
 DATA%4
 DATA%5
 DATA%6
 DATA%7
 DATA%8
"
 data " DATA %,%,%,%,%,%,%"
 data " DATA%1
 DATA%2
 DATA%3
 DATA%4
 DATA%5
 DATA%6
 DATA%7
"
 data " DATA %,%,%,%,%,%"
 data " DATA%1
 DATA%2
 DATA%3
 DATA%4
 DATA%5
 DATA%6
"
 data " DATA %,%,%,%,%"
 data " DATA%1
 DATA%2
 DATA%3
 DATA%4
 DATA%5
"
 data " DATA %,%,%,%"
 data " DATA%1
 DATA%2
 DATA%3
 DATA%4
"
 data " DATA %,%,%"
 data " DATA%1
 DATA%2
 DATA%3
"
 data " DATA %,%"
 data " DATA%1
 DATA%2
"
 data " DATA %"
 data " DATA%1
"
 data " % % % % % % % %"
 data " %1
 %2
 %3
 %4
 %5
 %6
 %7
 %8
"
 data " % % % % % % %"
 data " %1
  %2
  %3
  %4
  %5
  %6
  %7
"
 data " % % % % % %"
 data " %1
 %2
 %3
 %4
 %5
 %6
"
 data " % % % % %"
 data " %1
  %2
  %3
  %4
  %5
"
 data " % % % %"
 data " %1
  %2
  %3
  %4
"
 data " % % %"
 data " %1
  %2
  %3
 "
 data " % %"
 data " %1
  %2
"
 data " %"
 data " %1
"
 data NULL

codegen:
 data "/%/"
 data "%1
"
 data " %:"
 data "%1:
"
 data "%:"
 data "%1:
"
 data " JGE %"
 data " JGE %1
"
 data " GOTO%"
 data " JMP %1
"
 data " JLT %"
 data " JLT %1
"
 data " JZ %"
 data " JZ %1
"
 data " JNZ %"
 data " JNZ %1
"
 data " JMP %"
 data " JMP %1
"
 data " JMP@"
 data " @JMP
"
 data " CALL@"
 data " @CALL
"
 data " RET"
 data " RET
"
 data " END"
 data " RET
"
 data " +"
 data " ADD
"
 data " -"
 data " SUB
"
 data " *"
 data " MUL
"
 data " /"
 data " DIV
"
 data " UMUL"
 data " UMUL
"
 data " UDIV"
 data " UDIV
"
 data " MOD"
 data " MOD
"
 data " AND"
 data " AND
"
 data " OR"
 data " OR
"
 data " NEG"
 data " NEG
"
 data " NOT"
 data " NOT
"
 data " IN"
 data " IN
"
 data " OUT"
 data " OUT
"
 data " SWAP"
 data " SWAP
"
 data " PUSHR"
 data " PUSHR
"
 data " POPR"
 data " POPR
"
 data " PUSHS"
 data " PUSHS
"
 data " POPS"
 data " POPS
"
 data " %#++"
 data " INC.L %1
"
 data " %#--"
 data " DEC.L %1
"
 data " %$++"
 data " INC.B %1
"
 data " %$--"
 data " DEC.B %1
"
 data " ->@%"
 data " CALL@MBR %1
"
 data " ->%#="
 data " ST-MBR.L %1
"
 data " ->%$="
 data " ST-MBR.B %1
"
 data " ->%#"
 data " LD-MBR.L %1
"
 data " ->%$"
 data " LD-MBR.B %1
"
 data " ->%"
 data " LEA-MBR %1
"
 data " (%)#(%#),"
 data " LD@A-V.L %1,%2
"
 data " %#(%#),"
 data " LD-A-V.L %1,%2
"
 data " (%)$(%#),"
 data " LD@A-V.B %1,%2
"
 data " %$(%#),"
 data " LD-A-V.B %1,%2
"
 data " (%)#(%#)="
 data " ST@A-V.L %1,%2
"
 data " %#(%#)="
 data " STA-V.L %1,%2
"
 data " (%)$(%#)="
 data " ST@A-V.B %1,%2
"
 data " %$(%#)="
 data " ST-A-V.B %1,%2
"
 data " (%)#(%),"
 data " LD@A-K.L %1,%2
"
 data " %#(%),"
 data " LD-A-K.L %1,%2
"
 data " (%)$(%),"
 data " LD@A-K.B %1,%2
"
 data " %$(%),"
 data " LD-A-K.B %1,%2
"
 data " (%)#(%)="
 data " ST@A-K.L %1,%2
"
 data " %#(%)="
 data " ST-A-K.L %1,%2
"
 data " (%)$(%)="
 data " ST@A-K.B %1,%2
"
 data " %$(%)="
 data " ST-A-K.B %1,%2
"
 data " (%)#,"
 data " LD@V.L %1
"
 data " %#,"
 data " LD-V.L %1
"
 data " (%)$,"
 data " LD@V.B %1
"
 data " %$,"
 data " LD-V.B %1
"
 data " (%)#="
 data " ST@V.L %1
"
 data " %#="
 data " ST-V.L %1
"
 data " (%)$="
 data " ST@V.B %1
"
 data " %$="
 data " ST-V.B %1
"
 data " %,"
 data " LD-K %1
"
 data " DATA%"
 data " INT %1
"
 data " @%"
 data " CALL@ %1
"
 data " %"
 data " CALL %1
