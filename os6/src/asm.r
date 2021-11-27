// CARD6 アセンブラ for os6 ver 0.1

 // シンボルテーブルのサイズ(アドレス空間が狭いCPUは慎重に)
 const SYMBOL_TABLE_SIZE 8192

main:
 char    buf$(256),xbuf$(256),in_fname$(32),out_fname$(32)
 char    infile$(FILSIZ),outfile$(FILSIZ)
 long    start_adrs#,blist#,prev_loc#
 count  i#,j#,nn#
 long    cmnt1#,cmnt2#,pc#,ofset#
 long    image_size#

 // ファイル名・オプション設定
 CNULL,  in_fname$= out_fname$=
 0, start_adrs#=
 0, blist#=
 if argc#<2 then " COMMAND INPUT ERROR", prints nl end
 argc#, 1, - nn#=
 for i#=1 to nn#
   argv#(i#), buf, strcpy

   // リストオプションの設定
   buf, "-LIST", strcmp j#=
   if j#=0 then  1, blist#= gotoset_fname1

   // スタートアドレスの設定
   buf, "-P0X", 4, strncmp j#=
   if j#=0 then  buf+4, 16, atoi start_adrs#= gotoset_fname1

   // ファイルネームの設定
   if in_fname$=CNULL then buf, in_fname, strcpy gotoset_fname1
   buf, out_fname, strcpy 

   set_fname1:
 next i#

 if in_fname$=CNULL then " COMMAND INPUT ERROR", prints nl end
 if out_fname$=CNULL then "A.OUT", out_fname, strcpy

 // 各パラメータを読み込む
 paramater, restore
 read cmnt1#= read cmnt2#= read pc#= read ofset#=


 // pass1: ラベルの定義
 0, symbl_p#= // ラベルテーブルを初期化
 1, pass#= 0, line#=
 start_adrs#, location#=
 in_fname, infile,  ropen j#=
 if j#=ERROR then "FILE NOT FOUND", prints nl end
 loop_pass1:
  buf, infile, finputs j$=
  if j$=CNULL goto exit_pass1
  buf, xbuf, strcpy
  asm_1line
  if (lbl)$=CNULL goto loop_pass1
   lbl#, lbl_serch
   if ex$=0  then LABEL, symbl_type$= lbl#, address#, def_symbl gotoloop_pass1
   line#, printd " MULSYMBOL: ", prints xbuf, prints nl
   goto loop_pass1
 exit_pass1:
 infile, rclose

 // pass2: コードの生成
 2, pass#= 0, line#=
 start_adrs#, location#=
 in_fname,   infile,   ropen
 out_fname, outfile, wopen

 loop_pass2:
  buf, infile, finputs j$=
  if j$=CNULL goto exit_pass2
  buf, xbuf, strcpy
  asm_1line j#=
  if j#<>ERROR goto no_error
    line#, printd " ERROR: ", prints xbuf, prints nl
  no_error:

  // 命令タイプごとの処理
  case_NORMAL:
     if ins_type#<>NORMAL goto case_MEMORY
     if wordlen#<1 goto case_MEMORY
     for i#=1 to wordlen#
       ins-1$(i#),  outfile, putc
     next i#

     // リスト出力モード
     if blist#=0 goto case_MEMORY
     address#, hex prints ":", prints
     for i#=1 to wordlen#
       if ins-1$(i#)<16 then "0", prints
       ins-1$(i#),  hex prints " ", prints
     next i#
     for i#=wordlen# to MAX_WORD
       "   ", prints
     next i#
     xbuf, prints nl

  case_MEMORY:
     if ins_type#<>MEMORY goto case_ALIGN
     location#, prev_loc#, - j#=
     if j#<1 goto memory1
       for i#=1 to j#
         0,  outfile, putc
       next i#

     // リスト出力モード
     memory1:
     if blist#=0 goto case_ALIGN
     address#, hex prints ": ALLOC ", prints
     j#, printd " BYTES.            ", prints 
     xbuf, prints nl

  case_ALIGN:
     if ins_type#<>ALIGN goto default
     location#, prev_loc#, - j#=
     if j#<1 goto align1
       for i#=1 to j#
         0,  outfile, putc
       next i#

     // リスト出力モード
     align1:
     if blist#=0 goto default
     address#, hex prints ": SKIP ", prints
     j#, printd " BYTES.", prints nl 

  default:
  goto loop_pass2
 exit_pass2:
 infile,  rclose
 outfile, wclose
 end


// 1行アセンブル
asm_1line:
 const NORMAL  0
 const ORG         1
 const EQU         2
 const MEMORY  3
 const ALIGN      4
 const EQU_PP   5
 const LABEL      0
 const MAX_WORD 8
 const END      -1

 count k#
 char  ins$(MAX_WORD),field$(MAX_WORD),arg$(256)
 long  location#,ins_type#,wordlen#,address#,line#,pass#
 long  lbl#,stt#,ref#,sou#,start_adr#,end_adr#,last_equ#

 buf, lbl#= stt#=
 line#++
 location#, address#=
  0, wordlen#=  
 -1, ins_type#=

// コメントを除去する 
 buf, cmnt1#, strstr k#=
 if k#<>NULL then CNULL, (k)$=
 buf, cmnt2#, strstr k#=
 if k#<>NULL then CNULL, (k)$=

// 不要なスペースを除去する
 buf, strlen buf, + k#=

 del_space:
  if k#=buf goto normal_end
  k#--
 if (k)$=SPACE goto del_space
 CNULL, (k)$(1)=

// ラベルを分離する
ext_label:
 loop1:
  if  (stt)$=':'   goto exit1
  if  (stt)$=SPACE goto exit1
  if  (stt)$=CNULL  goto normal_end
  stt#, 1, + stt#=
  goto loop1
 exit1:
 CNULL, (stt)$=


// ステートメントを分離する
ext_statement:
 stt#++
 if  (stt)$=SPACE goto ext_statement
 if  (stt)$=CNULL  goto normal_end

// 命令定義データを読み込む
 def_ins, restore
 read_ref:
  read ref#=  // 命令パターンを読み込む
  if  ref#=NULL goto error_end  // 読み込むデータが無ければエラー
  read ins_type#= read wordlen#=
  stt#, sou#=

 // 命令コードを読み込む
  0, k#=
  read_ins:
   if k#>=wordlen# goto clear_field
   read ins$(k#)= k#++
  goto read_ins

 // ビットフィールドのクリア
  clear_field:
   for k#=0 to MAX_WORD
    0, field$(k#)=
   next k#
   0, d_bit_adr#=

  // パターンの比較
  cmp_a_char: // 1文字ごとに比較する
   if (ref)$<>CNULL goto case_SPACE
   if (sou)$<>CNULL goto fault_cmp
   goto success_cmp

   // スペース
   case_SPACE:
    if (ref)$<>SPACE goto case_YEN
    if (sou)$<>SPACE goto fault_cmp
    loop2:
     sou#++
     if (sou)$=SPACE goto loop2
     if (sou)$=CNULL  goto fault_cmp
     ref#++
     goto cmp_a_char

   // %xxyy : 引数が存在する xx:タイプﾟ yy:ビットフィールドの幅
   case_YEN:
    long arg_type#

    if (ref)$<>'%' goto otherwise 
    (ref)$(1),     '0', - 10, *
    (ref)$(2), + '0', - arg_type#= // 引数のタイプ
    (ref)$(3),     '0', - 10, *
    (ref)$(4), + '0', - field_size#= // ビットフィールドの幅
    ref#, 5, + ref#=
    arg, k#=

    // 引数を分離する
    ext_arg:
     if (sou)$=CNULL then if (ref)$<>CNULL goto fault_cmp
     if (sou)$=(ref)$ then CNULL, (k)$= gotoeval_arg
     (sou)$, (k)$=
     sou#++
     k#++
     goto ext_arg

    // 引数を評価する
    eval_arg:
     long value#

     if arg$=CNULL   goto fault_cmp
     if arg_type#<8 goto normal_form

     // アセンブラ固有のシンボル(レジスタ等)として評価する
     implied_symbol:
      arg, arg_type#, symbl_serch value#=
      if ex$=0 goto fault_cmp
      goto set_field

      // 通常の数式として評価する
     normal_form:
      const A_QUOT 39
      char  op1$,op2$
      long  num#,p#,v#

      '+', op1$=
      arg, num#= p#=
      0, value#=
      if arg_type#<4 then 0, value#= gotoserch_op
      if arg_type#<6 then ofset#, location#, - wordlen#, - value#=

      // 演算子を探す
      serch_op:
       (p)$, op2$= p#++
       if op2$='+'    goto number2
       if op2$='-'     goto number2
       if op2$='*'     goto number2
       if op2$='/'      goto number2
       if op2$=CNULL goto number1
       goto serch_op

      number1:
       if (num)$=CNULL goto fault_cmp

      number2:
       CNULL, (p)$(-1)=  0, v#=
       if (num)$=CNULL goto serch_next

       // 先頭が "%'"
       if (num)$=A_QUOT then (num)$(1), v#= gotoserch_next

       // 先頭が"0"
       if (num)$<>'0' goto decimal
       if (num)$(1)='B' then num#, 2, + 2,   atoi v#= gotoserch_next // 2進数
       if (num)$(1)='X' then num#, 2, + 16, atoi v#= gotoserch_next // 16進数
       num#, 1, +  8,  atoi v#= gotoserch_next // 8進数

       // 10進数
       decimal:
        if (num)$<'0' goto label
        if (num)$>'9' goto label
        num#, 10, atoi v#=
        goto serch_next
       
       // ラベル
       label:
        num#, pc#, strcmp k#=
        if k#=0 then location#, v#= gotoserch_next
        num#, lbl_serch v#=
         if ex$=0 then if pass#=2 goto fault_cmp

      serch_next:
       if op1$='+' then value#, v#, + value#=
       if op1$='-'  then value#, v#,  - value#=
       if op1$='*'  then value#, v#,  * value#=
       if op1$='/'   then value#, v#,  / value#=
       if op2$<>CNULL then op2$, op1$= p#, num#= gotoserch_op

    // 引数の値をビット列に変換する
    set_field:
     0, s_bit_adr#=
     value, field, bit_copy  k#=
     if k#=ERROR   then if pass#=2 goto fault_cmp
     goto cmp_a_char

   // その他の文字
   otherwise:
    if (ref)$<>(sou)$ goto fault_cmp
    ref#++
    sou#++
    goto cmp_a_char

  // パターン比較が失敗したときの処理
  fault_cmp:
   read k#=
   if k#<>END goto fault_cmp
   goto read_ref

  // パターン比較が成功したときの処理
  success_cmp:
   0, s_bit_adr#=
   create_ins:  // 命令コードを展開
    read field_size#=
    if field_size#=END goto normal_end
    read d_bit_adr#=
    field, ins, bit_copy
    goto create_ins

 // エラー発生
 error_end:
  ERROR,
  goto exit_asm

 // 正常終了
 normal_end:
  NULL,

 exit_asm:
  k#=

  if ins_type#=EQU       then value#, address#= last_equ#=
  if ins_type#=EQU_PP then last_equ#, address#= value#, last_equ#, + last_equ#=
  if ins_type#=ORG       then value#, location#= address#=

  if  ins_type#<>NORMAL goto not_NORMAL
    location#, prev_loc#= address#=
    location#, wordlen#, + location#=
  not_NORMAL:

  if  ins_type#<>MEMORY goto not_MEMORY
    location#, prev_loc#= address#=
    location#, value#, + location#=
  not_MEMORY:

  if  ins_type#<>ALIGN goto not_ALIGN
    location#, prev_loc#=
    location#, value#, / value#, * location#=
    if location#<prev_loc# then location#, value#, + location#=
    location#, address#=
  not_ALIGN:

  k#, end


// ビット列をコピーする(6ビットCPU用)
bit_copy:
 count x#,y#,z#
 long field_size#,s_bit_adr#,d_bit_adr#,s#,d#

 d#= swap s#=
 if field_size#<=0 then NULL, end
  for x#=1 to field_size#
   s_bit_adr#, 6, / y#= // 6ビットCPU用
   s_bit_adr#, 6, mod power2 (s)$(y#), and z#=
   d_bit_adr#, 6, / y#=
   if z#<>0 then d_bit_adr#, 6, mod power2 (d)$(y#), or (d)$(y#)=
   s_bit_adr#++
   d_bit_adr#++
  next x#
  field_size#, 1, -   power2 y#=
  arg_type#,  1, and z#=
  if z#=0 then 0, y#, - x#=       y#,   1, - y#=
  if z#=1 then 0,       x#=    2, y#, * 1, - y#=
  if (s)#<x# then ERROR, end
  if (s)#>y# then ERROR, end
  NULL, end


// 2のべき乗を求める
power2:
  int uuu#,vvv#
  uuu#=
  1, vvv#=
power21:
  if uuu#<=0 then vvv#, end
  uuu#--
  vvv#, vvv#, + vvv#=
  goto power21


// シンボルを定義する
 const LEN_SYMBOL 16
 const TYPE       0
 const VALUE      1
 const NAME       4
 const LIMIT      15

 char symbl_type$,ex$
 long  symbl_name#,symbl_p#
 char symbol$(SYMBOL_TABLE_SIZE)

def_symbl:
 z#= swap x#=
 symbl_p#,    symbol+NAME, + x#, swap strcpy
 symbl_type$, symbol+TYPE$(symbl_p#)=
 z#,          symbol+VALUE#(symbl_p#)=
 CNULL,        symbol+LIMIT$(symbl_p#)=
 symbl_p#,    LEN_SYMBOL, + symbl_p#=
 end

// ラベルの検索
lbl_serch:
 LABEL,

// シンボルの検索
symbl_serch:
 symbl_type$= swap symbl_name#=
 if symbl_p#<=0 goto symbl_serch1
 symbl_p#, LEN_SYMBOL, - y#=
 for x#=0 to y# step LEN_SYMBOL
  if symbol+TYPE$(x#)<>symbl_type$  goto not_match
   symbol+NAME,  x#, + symbl_name#, strcmp z#=
   if z#=0 then 1, ex$= symbol+VALUE#(x#), end
  not_match:
 next x#
symbl_serch1:
 0, ex$=
 end

 
// アセンブラデータ
paramater:
  data "/*","//","$",0


// 命令定義データ
def_ins:
 data "ORG %0618",ORG,0
 data END
 data "EQU %0618",EQU,0
 data END
 data "= %0618",EQU,0
 data END
 data "+= %0618",EQU_PP,0
 data END
 data "MEMORY %0218",MEMORY,0
 data END
 data "BYTE %0618",NORMAL,1
 data 0
 data 6,0
 data END
 data "INT %0618",NORMAL,3
 data 0,0,0,0
 data 18,0
 data END
 data "LONG %0618",NORMAL,3
 data 0,0,0,0
 data 18,0
 data END

 data "JMP %0618",NORMAL,4
 data 1,0,0,0
 data 18,6
 data END
 data "JGE %0618",NORMAL,4
 data 3,0,0,0
 data 18,6
 data END
 data "JLT %0618",NORMAL,4
 data 4,0,0,0
 data 18,6
 data END
 data "JZ %0618",NORMAL,4
 data 5,0,0,0
 data 18,6
 data END
 data "JNZ %0618",NORMAL,4
 data 6,0,0,0
 data 18,6
 data END
 data "CALL %0618",NORMAL,4
 data 7,0,0,0
 data 18,6
 data END
 data "CALL@ %0618",NORMAL,4
 data 8,0,0,0
 data 18,6
 data END

 data "@JMP",NORMAL,1
 data 2
 data END
 data "@CALL",NORMAL,1
 data 9
 data END
 data "RET",NORMAL,1
 data 10
 data END
 data "ADD",NORMAL,1
 data 11
 data END
 data "SUB",NORMAL,1
 data 12
 data END
 data "MUL",NORMAL,1
 data 13
 data END
 data "DIV",NORMAL,1
 data 14
 data END
 data "UMUL",NORMAL,1
 data 15
 data END
 data "UDIV",NORMAL,1
 data 16
 data END
 data "MOD",NORMAL,1
 data 17
 data END
 data "AND",NORMAL,1
 data 18
 data END
 data "OR",NORMAL,1
 data 19
 data END
 data "NEG",NORMAL,1
 data 20
 data END
 data "NOT",NORMAL,1
 data 21
 data END
 data "IN",NORMAL,1
 data 22
 data END
 data "OUT",NORMAL,1
 data 23
 data END
 data "SWAP",NORMAL,1
 data 24
 data END
 data "PUSHR",NORMAL,1
 data 25
 data END
 data "POPR",NORMAL,1
 data 26
 data END
 data "PUSHS",NORMAL,1
 data 27
 data END
 data "POPS",NORMAL,1
 data 28
 data END

 data "INC.L %0618",NORMAL,4
 data 29,0,0,0
 data 18,6
 data END
 data "DEC.L %0618",NORMAL,4
 data 30,0,0,0
 data 18,6
 data END
 data "INC.B %0618",NORMAL,4
 data 31,0,0,0
 data 18,6
 data END
 data "DEC.B %0618",NORMAL,4
 data 32,0,0,0
 data 18,6
 data END
 data "CALL@MBR %0618",NORMAL,4
 data 33,0,0,0
 data 18,6
 data END
 data "ST-MBR.L %0618",NORMAL,4
 data 34,0,0,0
 data 18,6
 data END
 data "ST-MBR.B %0618",NORMAL,4
 data 35,0,0,0
 data 18,6
 data END
 data "LD-MBR.L %0618",NORMAL,4
 data 36,0,0,0
 data 18,6
 data END
 data "LD-MBR.B %0618",NORMAL,4
 data 37,0,0,0
 data 18,6
 data END
 data "LEA-MBR %0618",NORMAL,4
 data 38,0,0,0
 data 18,6
 data END

 data "LD@A-V.L %0618,%0618",NORMAL,7
 data 39,0,0,0,0,0,0
 data 18,6,18,24
 data END
 data "LD-A-V.L %0618,%0618",NORMAL,7
 data 40,0,0,0,0,0,0
 data 18,6,18,24
 data END
 data "LD@A-V.B %0618,%0618",NORMAL,7
 data 41,0,0,0,0,0,0
 data 18,6,18,24
 data END
 data "LD-A-V.B %0618,%0618",NORMAL,7
 data 42,0,0,0,0,0,0
 data 18,6,18,24
 data END
 data "ST@A-V.L %0618,%0618",NORMAL,7
 data 43,0,0,0,0,0,0
 data 18,6,18,24
 data END
 data "ST-A-V.L %0618,%0618",NORMAL,7
 data 44,0,0,0,0,0,0
 data 18,6,18,24
 data END
 data "ST@A-V.B %0618,%0618",NORMAL,7
 data 45,0,0,0,0,0,0
 data 18,6,18,24
 data END
 data "ST-A-V.B %0618,%0618",NORMAL,7
 data 46,0,0,0,0,0,0
 data 18,6,18,24
 data END
 data "LD@A-K.L %0618,%0618",NORMAL,7
 data 47,0,0,0,0,0,0
 data 18,6,18,24
 data END
 data "LD-A-K.L %0618,%0618",NORMAL,7
 data 48,0,0,0,0,0,0
 data 18,6,18,24
 data END
 data "LD@A-K.B %0618,%0618",NORMAL,7
 data 49,0,0,0,0,0,0
 data 18,6,18,24
 data END
 data "LD-A-K.B %0618,%0618",NORMAL,7
 data 50,0,0,0,0,0,0
 data 18,6,18,24
 data END
 data "ST@A-K.L %0618,%0618",NORMAL,7
 data 51,0,0,0,0,0,0
 data 18,6,18,24
 data END
 data "ST-A-K.L %0618,%0618",NORMAL,7
 data 52,0,0,0,0,0,0
 data 18,6,18,24
 data END
 data "ST@A-K.B %0618,%0618",NORMAL,7
 data 53,0,0,0,0,0,0
 data 18,6,18,24
 data END
 data "ST-A-K.B %0618,%0618",NORMAL,7
 data 54,0,0,0,0,0,0
 data 18,6,18,24
 data END

 data "LD@V.L %0618",NORMAL,4
 data 55,0,0,0
 data 18,6
 data END
 data "LD-V.L %0618",NORMAL,4
 data 56,0,0,0
 data 18,6
 data END
 data "LD@V.B %0618",NORMAL,4
 data 57,0,0,0
 data 18,6
 data END
 data "LD-V.B %0618",NORMAL,4
 data 58,0,0,0
 data 18,6
 data END
 data "ST@V.L %0618",NORMAL,4
 data 60,0,0,0
 data 18,6
 data END
 data "ST-V.L %0618",NORMAL,4
 data 61,0,0,0
 data 18,6
 data END
 data "ST@V.B %0618",NORMAL,4
 data 62,0,0,0
 data 18,6
 data END
 data "ST-V.B %0618",NORMAL,4
 data 63,0,0,0
 data 18,6
 data END
 data "LD-K %0618",NORMAL,4
 data 59,0,0,0
 data 18,6
 data END

 data "HLT",NORMAL,1
 data 0
 data END

 data NULL
