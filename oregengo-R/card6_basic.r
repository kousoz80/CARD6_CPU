//
//    CARD6 BASIC VER 0.1
//    CARD6 コンピュータで動作するBASICインタプリタ
//
// 定数・構造体定義

// トークンタイプ
  const VARIABLE              1     // 変数名
  const COMMAND               2     // コマンド名
  const FUNCTION              3     // 関数名
  const NUMBER                4     // 数字表現文字
  const DELIMIT               5     // 区切り文字
  const STRING                6     // 文字列
  const LABEL                 7     // ラベル
  const EOL                   8     // 行末
  const COUNT                 9     // カウンタ型
  const ARRAY                 10    // 配列型
  

// 終了コード
  const DONE              1     // 正常終了
  const TERMINATE         2     // TEXT実行を終了
  const QUIT              3     // BASICを終了

  const MAX_TEXT_LENGTH   255   // テキスト行の長さの限界
  const MAX_STR_LENGTH    64   // 文字列の長さの限界

  const ARRAY_SIZE 4096
  const PROG_SIZE 16384
  const NUM_VAR_SIZE SIZEOF_LONG
  const STR_VAR_SIZE    MAX_STR_LENGTH
  const VALUE_SIZE  MAX_STR_LENGTH+SIZEOF_LONG
  const FOR_STACK_SIZE   1024
  const GOSUB_STACK_SIZE 1024
  const CALC_STACK_SIZE  8192

 const A_QUOT   7
 const DBL_QUOT 2

// プログラム構造体
 struct Program
   long length#      // 長さ
   long lineno#      // 行番号
   long text#        // テキスト先頭文字
 end


// FOR文用データ
  long ForStackP#
  struct  _ForStack
    long var#     // ループ変数へのポインタ
    long limit#   // ループ変数上限値
    long step#    // STEP値
    long program# // リピートTEXT行記憶用
    long token_p# // リピート有効文字先頭
  end


// GOSUB文用データ
  long GosubStackP#
  struct  _GosubStack
    long program#  // リターンする行記憶用
    long token_p#  // リターンする文字先頭
  end


// BASICのコマンド
  struct _Command
    long keyword#
    long func#
  end

// BASICの関数
  struct _Function
    long keyword#
    long func#
  end

// 値データ
  struct Value
    long type#
    long data#
  end

Command:
  data "RUN",cmd_run
  data "IF",cmd_if
  data "FOR",cmd_for
  data "NEXT",cmd_next
  data "GOTO",cmd_goto
  data "GOSUB",cmd_gosub
  data "RETURN",cmd_return
  data "PRINT",cmd_print
  data "INPUT",cmd_input
  data "CLEAR",cmd_clear
  data "NEW",cmd_new
  data "END",cmd_end
  data "LIST",cmd_list
  data "RUN",cmd_run
  data "STOP",cmd_stop
  data "CONT",cmd_cont
  data "THEN",cmd_then
  data "ELSE",cmd_else
  data NULL,NULL

Function:
  data "ABS",func_abs
  data "SGN",func_sgn
  data "CHR$",func_chrs
  data "ASC",func_asc
  data "MID$",func_mids
  data "LEFT$",func_lefts
  data "RIGHT$",func_rights
  data "INPUT$",func_inputs
  data "INKEY$",func_inkeys
  data "STR$",func_strs
  data "HEX$",func_hexs
  data "BIN$",func_bins
  data "OCT$",func_octs
  data "VAL",func_val
  data "LEN",func_len
  data "INSTR",func_instr
  data NULL,NULL

// プログラムを消去する
clear_program:

  CNULL, ProgArea, EndProg#= ->Program.text$=
  end

// 指定された行番号の位置を返す
// 見つからないときはNULLを返す
serch_line:

  long xlineno#,xmode#
  xmode#= pop xlineno#=

//  "SERCH LINE:", prints nl

  -1, jj#=
  ProgArea, pp#=
  serch_line1:
    if pp#>=EndProg# goto serch_line4
    pp#, ->Program.lineno# ii#=

// "LINENO=", prints ii#, printd nl

    if xmode#=1 then if ii#=xlineno# goto serch_line3
    if xmode#=1 goto serch_line2
      if ii#>=xlineno# then if xlineno#>jj# goto serch_line3 
    serch_line2:
    ii#, jj#=
    pp#, ->Program.length# xx#=
    
//    "SKIP:", prints xx#, printd "bytes", prints nl
    
    xx#, pp#, + pp#=
    goto serch_line1
  serch_line3:

//  "SERCH LINE END:", prints nl

  ii#, xlineno#, - pp#, end

  serch_line4:

//  "SERCH LINE NULL END:", prints nl

  0, NULL, end
  

// BASICのプログラムを最初から実行する
exec_basic:

  CurrentProg#=

//  "EXEC BASIC", prints nl

  clear_value
  CurrentProg#, ->Program.text TokenP#= 
  getToken // 最初のトークン切り出し
  CurrentProg#, TokenP#,  exec_basic2
  end

// BASICプログラムを現在のロケーションから継続して実行する
exec_basic2:

 long no#
  TokenP#= pop CurrentProg#=
  
//  "EXEC BASIC2:", prints nl
  
  0, status#=
  if CurrentProg#=NULL then "CAN'T CONTINUE", assertError

  // ループ
  exec_basic2_1:

    if BreakFlg#=0 goto exec_basic2_2
      0, BreakFlg#=
      CurrentProg#, BreakProg#=
      TokenP#, BreakToken#=
      "BREAK", assertError

    // トークンがCOMMANDなら次のトークンをとりだしてDISPATCH
    exec_basic2_2:
    if TokenType#<>COMMAND goto exec_basic2_3

//  "EXEC BASIC2 COMMAND:", prints nl

     TokenCode#, _Command.SIZE, * no#=
      getToken

//  "EXEC BASIC COMMAND", prints nl

      Command, no#, + ->@_Command.func status#=
      if status#<>DONE then status#, end
      goto exec_basic2_1

    // トークンが変数なら代入
    exec_basic2_3:
    if TokenType#=VARIABLE then cmd_let gotoexec_basic2_1


    // トークンがEOLなら次の行へ
    if TokenType#<>EOL goto exec_basic2_4

//  "EXEC BASIC2 EOL:", prints nl

      // 次の行に移る
      CurrentProg#, ->Program.length# CurrentProg#, + CurrentProg#=

      // 最終行(中身無し)に到達すると終了
      if CurrentProg#>=EndProg# then TERMINATE, end
      CurrentProg#, ->Program.length# tt#=
      if tt#<=0 then  TERMINATE, end

      // テキストポインタを設定
      CurrentProg#, ->Program.text TokenP#=
      getToken
      goto exec_basic2_1

    // マルチステートメントの処理
    exec_basic2_4:
    if TokenType#<>DELIMIT goto exec_basic2_5

//  "EXEC BASIC2 DELIMIT:", prints nl

      if TokenText$=':' then getToken gotoexec_basic2_1
      "SYNTAX ERROR", assertError

    // ラベルの場合は無視(1つの行に2個以上ラベルがある場合は、最初のラベル以外は無視されるので注意)
    exec_basic2_5:

    // 上記以外の場合は文法エラー  

//  "EXEC BASIC2 OTHER:", prints nl

    "SYNTAX ERROR", assertError
    end

// エラーを発生させる
assertError:

 long mesg#
 mesg#=
 
// "ASSERT ERROR:", prints nl
// "CURRENT PROG=", prints CurrentProg#, hex prints nl
 
  // コンパイル出力ファイルが開いていたら閉じておく
  // xxxclose
  
// CARD6用コード
  StackSave#, reg_sp#=

// CARD8用コード
// x=(StackSave)/
// sp=x/

// x86_64用コード
// rax=StackSave/
// rsp=(rax)/

  CurrentProg#, ->Program.lineno# tt#=
  if tt#<=0 then  mesg#, prints nl gotobasic_entry
  "LINE ", prints tt#, printd  " : ", prints
  mesg#, prints nl
  if SysError#=1 then end
  goto basic_entry

// トークンを切り出してバッファに格納する
getToken:

// "GETTOKEN:", prints  (TokenP)$, printd nl
// 2, putchar TokenP#, prints 2, putchar nl

  CNULL, TokenText$=
  0, ii#=

  // 空白をスキップする
getToken1:
   if (TokenP)$>' ' then if (TokenP)$<63 goto getToken2
     if (TokenP)$=CNULL then EOL, TokenType#= end
     TokenP#++
     goto getToken1

  // "'"が現れたときは行の終わり
getToken2:
  if (TokenP)$=A_QUOT then EOL, TokenType#= end

  // 先頭が"であれば次の"までは文字列
  if (TokenP)$<>DBL_QUOT goto getToken4
    STRING, TokenType#=
    TokenP#++
getToken3:
   if (TokenP)$=CNULL then "SYNTAX ERROR", assertError
   if (TokenP)$<>DBL_QUOT then (TokenP)$, TokenText$(ii#)= TokenP#++ ii#++ gotogetToken3
   TokenP#++
    CNULL, TokenText$(ii#)=

//    "STRING:", prints nl 

    end

  // 先頭がアルファベット
getToken4:
  (TokenP)$, is_symbol_char0 tt#=
  if tt#=0 goto getToken20
  
//  "SYMBOL CHAR:", prints nl
  
getToken5:
  (TokenP)$, is_symbol_char tt#=
  if tt#=1 then  (TokenP)$, TokenText$(ii#)= TokenP#++ ii#++ gotogetToken5
  CNULL, TokenText$(ii#)=

//  "TOKENTEXT=", prints TokenText, prints nl

    // "ELSE"キーワードが出てきたら行の終わりと判断する
getToken6:
    TokenText, "ELSE", strcmp tt#=
    if tt#=0 then EOL, TokenType#= end

    // Basicのコマンドの場合
    Command, pp#= 0, ii#=
getToken7:
    pp#, ->_Command.keyword# qq#=
    if qq#=NULL goto  getToken8
    TokenText, qq#, strcmp tt#=
    if tt#=0 then  COMMAND, TokenType#= ii#, TokenCode#= end
    pp#, _Command.SIZE, + pp#=
    ii#++
    goto getToken7

    // 関数の場合
getToken8:
    Function, pp#= 0, ii#=
getToken8x:
    pp#, ->_Function.keyword# qq#=
    if qq#=NULL goto  getToken9
    TokenText, qq#, strcmp tt#=
    if tt#=0 then  FUNCTION, TokenType#= ii#, TokenCode#= end
    pp#, _Function.SIZE, + pp#=
    ii#++
    goto getToken8x

    // コマンドでも関数でもないときは変数とみなす
getToken9:
  
//  "VARIABLE:", prints nl
  
    VARIABLE, TokenType#= end


// 先頭が'0'~'9'で始まっている場合が数値
getToken20:
  (TokenP)$, cc#=
  if cc#<'0'  goto getToken30
  if cc#>'9'  goto getToken30

getToken21:
      NUMBER, TokenType#=
      0, ii#= TokenValue#=
getToken22:
      TokenValue#, 10, * (TokenP)$, + '0', - TokenValue#=
      (TokenP)$, TokenText$(ii#)=
      TokenP#++
      ii#++
      if (TokenP)$>='0' then if (TokenP)$<='9' goto getToken22
      CNULL, TokenText$(ii#)=
      end

// 上記以外は区切り文字
getToken30:
    DELIMIT, TokenType#=
    cc#, TokenText$(ii#)=
    ii#++
    TokenP#++
    (TokenP)$, bb#=
    
    if cc#<>'=' goto getToken31
    if bb#='<' then bb#, TokenText$(ii#)= ii#++ TokenP#++ gotogetToken33 
    if bb#='>' then bb#, TokenText$(ii#)= ii#++ TokenP#++ gotogetToken33 

getToken31:
    if cc#<>'<' goto getToken32
    if bb#='=' then bb#, TokenText$(ii#)= ii#++ TokenP#++ gotogetToken33 
    if bb#='>' then bb#, TokenText$(ii#)= ii#++ TokenP#++ gotogetToken33 

getToken32:
    if cc#<>'>' goto getToken33
    if bb#='=' then bb#, TokenText$(ii#)= ii#++ TokenP#++

getToken33:
    CNULL, TokenText$(ii#)=
  
//  "DELIMITTER:", prints cc#, printd nl
//  "TOKENTEXT=", prints TokenText, prints nl

 end

// トークンが正しければ次のトークンを読み込み
// トークンが間違っていたらエラーを発生させる
checkToken:

  long token#
  token#=
  
//  "CHECK TOKEN:", prints nl
//  "TOKENTEXT=", prints TokenText, prints nl
  
  TokenText, token#, strcmp tt#=
  if tt#<>0 then "SYNTAX ERROR", assertError
  getToken
  end

// 文字判別関数

// 空白文字
is_space:
  long cc1#
  cc1#=
  if cc1#=' ' then 1, end
  0, end

// シンボル文字(最初の1文字)
is_symbol_char0:
  cc1#=
  if cc1#='@' goto is_symbol_char0_1
  if cc1#>='A' then if cc1#<='Z' goto is_symbol_char0_1
  0, end
is_symbol_char0_1:
  1, end

// シンボル文字
is_symbol_char:
  cc1#=
  if cc1#='@' goto is_symbol_char1
  if cc1#>='A' then if cc1#<='Z' goto is_symbol_char1
  if cc1#>='0' then if cc1#<='9' goto is_symbol_char1
  if cc1#='$' goto is_symbol_char1
  0, end
is_symbol_char1:
  1, end

// 数字かどうかを判別
is_digit:
  cc1#=
  if cc1#<'0' then 0, end
  if cc1#>'9' then 0, end
  1, end

  // 変数宣言
 char DirectArea$(1024)
 char ProgArea$(PROG_SIZE)
 long NumVarArea#(NUM_VAR_SIZE)
 char StrVarArea$(STR_VAR_SIZE)
 long ArrayArea#(ARRAY_SIZE)
 char ForStackArea$(FOR_STACK_SIZE)
 char GosubStackArea$(GOSUB_STACK_SIZE)
 char CalcStackArea$(CALC_STACK_SIZE)

  long   JmpEntry#			       // エラー処理用のエントリポイント
  long   StackSave# 
  long   EndProg#          // BASICプログラム最初の行と最後の行
  long   CurrentProg#      // 現在実行中への行へのポインタ
  long  BreakProg#         // 現在実行中への行へのポインタ
  char  TextBuffer$(MAX_TEXT_LENGTH+1) // プログラムテキストのバッファ
  char  TokenText$(MAX_TEXT_LENGTH+1)  // トークンバッファ
  char   VarName$(MAX_TEXT_LENGTH+1)    // 変数名格納エリア
  long   TokenP#           // トークン解析用の文字位置ポインタ
  long   BreakToken# 
  long   TokenType#,TokenCode#  // トークンタイプとコード
  long   TokenValue#    // トークンの値
  long   CalcStackP#      // 演算スタックポインタ
  long   SysError#       // この変数がセットされたらシステムエラー
  long   TopVar#          // 変数リスト開始値
  long   EndVar#         // 変数リスト終値
  long   ErrorMessage#
  long   BreakFlg#
  long   RunFlg# 
  long   CurrentLineNo#
  long   BasicBusy# 
  long   var_type#

  count ii#,jj#,kk#,ll#
  count mm#,nn#
  long aa#,bb#,cc#,lbl#,str#
  long pp#,qq#,rr#,ss#,tt#,uu#,vv#,ww#
  long xx#,yy#,zz#
 
 

// 行番号number、文字列strのTEXTを挿入、または修正する
edit_line:
  long prog#,plen#,ofset#,ee#
  ptext, strlen SIZEOF_LONG*2+1, + plen#=


  // x86_64のアライメント(8バイト)に考慮したコード、CARD8の場合はコメントアウトする
  //  plen#, 8, mod tt#=
  //  if tt#<>0 then 8, tt#, - plen#, + plen#=


//  "EDIT LINE:", prints "length=", prints plen#, printd nl

  // プログラムが空の場合
  if EndProg#>ProgArea goto edit_line1

//  "NO PROGRAM", prints nl

    plen#, ProgArea, ->Program.length#=
    pline#, ProgArea, ->Program.lineno#=
    ptext, ProgArea, ->Program.text strcpy
    ProgArea, plen#, + EndProg#=
    -1, EndProg#, ->Program.length#=
    end

  // 行番号からプログラムをサーチする
  edit_line1:
  pline#, 0, serch_line prog#= pop tt#=

// "ADDR=0X", prints prog#, hex prints nl
// "MODE=", prints tt#, printd nl

  if prog#=NULL goto edit_line4 // 挿入位置がプログラムの末尾の場合
  if tt#<>0     goto edit_line5 // 挿入位置がプログラムの行間の場合

  // 修正テキストが挿入位置のテキストより短い場合
  edit_line2:

//  "REDUCE PROGRAM", prints nl

  prog#, ->Program.length# plen#, - ofset#=
  plen#, prog#, ->Program.length#=
  prog#, plen#, + tt#=
  EndProg#, ofset#, - EndProg#=
  if ofset#<0 goto edit_line3
  for ii#=tt# to EndProg#
    (ii)$(ofset#), (ii)$=
  next ii#
  ptext, prog#, ->Program.text strcpy
  -1, EndProg#, ->Program.length#=
  end

  // 修正テキストが挿入位置のテキストより長い場合
  edit_line3:

//  "EXPAND PROGRAM", prints nl

  for ii#=EndProg# to tt# step -1
    (ii)$(ofset#), (ii)$=
  next ii#
  ptext, prog#, ->Program.text strcpy
  -1, EndProg#, ->Program.length#=
  end

  // 挿入位置がプログラムの末尾の場合
  edit_line4:

//  "APPEND PROGRAM", prints nl
//  "LENGTH=", prints plen#, printd nl
 
  plen#,  EndProg#, ->Program.length#=
  pline#, EndProg#, ->Program.lineno#=
  ptext,  EndProg#, ->Program.text strcpy
  plen#,  EndProg#, + EndProg#=
  -1, EndProg#, ->Program.length#=
  end

  // 挿入位置がプログラムの行間の場合
  edit_line5:

//  "INSERT PROGRAM", prints nl
//  "LENGTH=", prints plen#, printd nl

  for ii#=EndProg# to prog# step -1
    (ii)$, (ii)$(plen#)=
  next ii#
  plen#,  prog#, ->Program.length#= 
  pline#, prog#, ->Program.lineno#=
  ptext,  prog#, ->Program.text strcpy
  plen#,  EndProg#, + EndProg#=
  -1, EndProg#, ->Program.length#=
  end

// 行番号numberのTEXTを削除する
del_line:
 pline#= 1, serch_line prog#=
 if prog#=NULL then end
 prog#, ->Program.length# plen#=
 EndProg#, plen#, - EndProg#=
 for ii#=prog# to EndProg#
 (ii)$(plen#), (ii)$=
 next ii# 
 -1, EndProg#, ->Program.length#=
 end

// 画面１行入力strを行番号xとテキストに分割する
divide_line:

  long txt#,lx#
  txt#= pop xx#= pop pp#=
  0, lx#=

// "DIVIDE LINE:", prints nl

  // 空白文字を除去する
  divide_line1:
  (pp)$, is_space tt#=
  if tt#=1 then pp#++ gotodivide_line1

  // 行番号がない場合
  (pp)$, is_digit tt#=
  if tt#=1 goto divide_line2
  -1, (xx)#=
  pp#, txt#, strcpy
  end

  // 行番号を得る
  divide_line2:
  (pp)$, is_digit tt#=
  if tt#=0 goto divide_line3
  lx#, 10, *  (pp)$, + '0', - lx#=
  pp#++
  goto divide_line2

  // テキストがない場合
  divide_line3:
  (pp)$, is_space tt#=
  if tt#=1 then pp#++ gotodivide_line3
  if (pp)$=CNULL then lx#, (xx)#= CNULL, (txt)$= end

  // テキストを格納する
  pp#, txt#, strcpy
  lx#, (xx)#=
  end

// 変数の全クリア
clear_variable:

//  "CLAER VARIABLE:", prints nl

  for ii#=0 to 25
    0, NumVarArea#(ii#)=
  next ii#
  for ii#=0 to 25*STR_VAR_SIZE step STR_VAR_SIZE
    CNULL, StrVarArea$(ii#)=
  next ii#
  for ii#=0 to ARRAY_SIZE
    0, ArrayArea#(ii#)=
  next ii#
  end

// 変数の値を格納してあるアドレスを得る
// 同時に変数var_typeに変数の型をセットする
get_var_adr:
  long xvname#,index#
  xvname#= strlen tt#=

// "GET VAR ADR:", prints xvname#, prints
// ", LENGTH=", prints tt#, printd nl

 if tt#=0 then NULL, end
 if tt#>2 then NULL, end

 if (xvname)$='@' goto get_var_adr2

 if tt#=1 goto get_var_adr1

// 文字列変数の場合
 if (xvname)$(1)<>'$' then "SYNTAX ERROR", assertError
  (xvname)$, index#=
  
//  "STRING VAR:", prints  index#, putchar nl

  STRING, var_type#=
  index#, 'a', - STR_VAR_SIZE, * StrVarArea, +
  end

// 数値変数の場合
get_var_adr1:
  (xvname)$, index#=

// "NUM VAR:", prints index#, putchar nl

  NUMBER, var_type#=
  index#, 'a', - SIZEOF_LONG, * NumVarArea, +
  end 

// 配列変数の場合
get_var_adr2:

// "ARRAY VAR", prints nl

  getToken
  ARRAY, var_type#=
  "(", checkToken
  sign#, PUSH eval_expression POP sign#=
  get_number index#=
  if index#<0 then "ARRAY RANGE IS OVER", assertError
  if index#>ARRAY_SIZE then  "ARRAY RANGE IS OVER", assertError
  ")",  checkToken

//  "GET VARIABLE VALUE END:", prints nl


  index#, SIZEOF_LONG, * ArrayArea, +  tt#=
  
// "ARRAY VAR: ADDR=0X", prints tt#, hex prints nl

  tt#,  end

// clearコマンド
cmd_clear:

// "CMD CLEAR:", prints nl

  clear_value
  clear_variable
  ForStackArea, ForStackP#= 
  DONE, end

// ifコマンド
cmd_if:

// "CMD IF:", prints nl

  // 論理式が真ならば"THENをチェックしてその次から始める"
  eval_expression
  get_number tt#=
  if tt#=0 goto cmd_if1
    "THEN", checkToken
    if TokenType#<>NUMBER then DONE, end
    TokenValue#, 1, serch_line pp#=
    if pp#=NULL then "LINE NO. NOT FOUND", assertError
    pp#, CurrentProg#=
    CurrentProg#, ->Program.text TokenP#= 
    getToken
    DONE, end

  // 行のトークンを逐次検索する
cmd_if1:
    getToken

    // "ELSE"があったらそこから始める
    TokenText, "ELSE", strcmp tt#=
    if tt#<>0 goto cmd_if2
    getToken
    if TokenType#<>NUMBER then DONE, end
    TokenValue#, 1, serch_line pp#=
     if pp#=NULL then "LINE NO. NOT FOUND", assertError
     pp#, CurrentProg#=
     CurrentProg#, ->Program.text TokenP#= 
     getToken
     DONE, end

cmd_if2:
   if TokenType#<>EOL goto cmd_if1
   DONE, end


// returnコマンド
cmd_return:

// "CMD RETURN:", prints nl

  if GosubStackP#<GosubStackArea then "RETURN WITHOUT GOSUB", assertError
  GosubStackP#, _GosubStack.SIZE, - GosubStackP#=
  GosubStackP#, ->_GosubStack.token_p# TokenP#=
  GosubStackP#, ->_GosubStack.program# CurrentProg#=
  getToken
  DONE, end


// gosubコマンド
cmd_gosub:
  long pp1#
  
//  "CMD GOSUB:", prints nl
  
  GosubStackArea, GOSUB_STACK_SIZE, + tt#=
  if GosubStackP#>=tt# then  "STACK OVERFLOW (GOSUB)", assertError

  if TokenType#<>NUMBER then "SYNTAX ERROR", assertError
  TokenValue#, 1, serch_line pp1#=
  if pp1#=NULL then "LINE NO.NOT FOUND", assertError
  getToken

  CurrentProg#, GosubStackP#, ->_GosubStack.program#=
  TokenP#, GosubStackP#, ->_GosubStack.token_p#= 
  GosubStackP#,  _GosubStack.SIZE, + GosubStackP#=
  pp1#, CurrentProg#=
  CurrentProg#, ->Program.text TokenP#=
  getToken
  DONE, end

// nextコマンド
cmd_next:

 // "CMD NEXT:", prints nl

  long for_var#
  if ForStackP#<=ForStackArea then  "NEXT WITHOUT FOR", assertError
  ForStackP#, _ForStack.SIZE, - ForStackP#=

  // nextの後に変数名がある場合
  if TokenType#<>VARIABLE goto cmd_next1
    TokenText, get_var_adr ForStackP#, ->_ForStack.var# - tt#=
    if tt#<>0 then "NEXT WITHOUT FOR", assertError
    getToken

  // STEP値をループ変数へ加える
cmd_next1:
  ForStackP#, ->_ForStack.var# for_var#=
  ForStackP#, ->_ForStack.step# (for_var)#, + (for_var)#=

  // 終了条件を満たさなければループエントリーに戻る
  (for_var)#, ForStackP#, ->_ForStack.limit# - ForStackP#, ->_ForStack.step# *  tt#=
  if tt#>0 goto cmd_next2
    ForStackP#, ->_ForStack.token_p# TokenP#=
    ForStackP#, ->_ForStack.program# CurrentProg#= 
    ForStackP#, _ForStack.SIZE, + ForStackP#=
    getToken
cmd_next2:
    DONE, end    

// forコマンド
cmd_for:

// "CMD FOR:", prints nl

  ForStackArea, FOR_STACK_SIZE, + tt#=
  if ForStackP#>=tt# then "STACK OVER FLOW (FOR-NEXT)", assertError
  if TokenType#<>VARIABLE then "SYNTAX ERROR", assertError

//  "GET LOOP VARIABLE", prints nl

  // ループ変数を確保
  TokenText, get_var_adr for_var#= 
  for_var#, ForStackP#, ->_ForStack.var#=

//  "LET LOOP VARIABLE, TOKEN TYPE=", prints TokenType#, printd nl


  // ループ変数に初期値代入
  cmd_let

//  "TO CHECK TOPKEN:", prints TokenText, prints nl
  
  "TO", checkToken

  // ループ変数上限を得る

//  "LIMIT EXPRESSION", prints nl

  clear_value
  eval_expression
  get_number ForStackP#, ->_ForStack.limit#=

  // STEP値がある場合
  TokenText, "STEP", strcmp tt#=
  if tt#<>0 goto cmd_for1

//  "STEP EXPRESSION", prints nl


    getToken
    clear_value
    eval_expression
    get_number ForStackP#, ->_ForStack.step#=
    goto cmd_for2 

  // STEP値が省略された場合
cmd_for1:
  1,  ForStackP#, ->_ForStack.step#=

  // 現在の実行位置をスタックへ保存
cmd_for2:

//  "SAVE CURRENT POSITION TO STACK", prints nl 

  CurrentProg#, ForStackP#, ->_ForStack.program#=
  TokenP#, ForStackP#, ->_ForStack.token_p#=
  ForStackP#,  _ForStack.SIZE, + ForStackP#=
  DONE, end

// gotoコマンド
cmd_goto:

// "CMD GOTO:", prints nl

  1, RunFlg#=
  if TokenType#<>NUMBER then "SYNTAX ERROR", assertError
  TokenValue#, 1, serch_line pp#=
  if pp#=NULL then "LINE NO. NOT FOUND", assertError
  pp#, CurrentProg#=
  CurrentProg#, ->Program.text TokenP#=
  getToken
  DONE, end

// inputコマンド
cmd_input:
 long input_var#

//  "CMD INPUT:", prints nl

  // コンソールから入力
cmd_input3:
    long is_question#
    1, is_question#=

cmd_input4:

      // 文字列のときはプロンプト文字列を表示する
      if TokenType#=STRING then TokenText, prints getToken gotocmd_input4

      // 変数の場合は入力する
      if TokenType#<>VARIABLE goto cmd_input5
      TokenText, get_var_adr input_var#=
      if var_type<>ARRAY then getToken


//  "VAR ADR=0X", prints input_var#, hex prints nl
  

      if is_question#=1 then "? ", prints
      sss, inputs tt#=
      if tt#=3 then 1, BreakFlg#= // CTRL+Cで中断
      sss, strlen 1, + tt#=
      if var_type#=STRING then sss, input_var#, MAX_STR_LENGTH, strncpy
      if var_type#=NUMBER then sss, 10, atoi (input_var)#=
      if var_type#=ARRAY  then sss, 10, atoi (input_var)#=
      1, is_question#=
      goto cmd_input4

      // セパレータ ',' or ';'
cmd_input5:
      if TokenType#<>DELIMIT then DONE, end
      if TokenText$=',' then 1, is_question#= getToken gotocmd_input4
      if TokenText$=';' then 0, is_question#= getToken gotocmd_input4
      DONE, end

// printコマンド
cmd_print:
  long last_char#
  CNULL, last_char#=

// "CMD PRINT:", prints nl

  // print文
cmd_print4:

// "PRINT:", prints nl

    if TokenType#=EOL goto cmd_print6
    if TokenType#=DELIMIT then if TokenText$=':' goto cmd_print6

      // データの表示
      TokenText$, last_char#=
      clear_value
      eval_expression

      // 文字列型データの表示
      value_type typ#=
      if typ#=STRING then get_string ss#= prints

      // 数値型データの表示
      if typ#=NUMBER then get_number printd

      check_value

      // セパレータが','の場合
      if TokenType#<>DELIMIT  goto cmd_print5
      if TokenText$<>',' goto cmd_print5
        TokenText$, last_char#=
        ',', putchar  // カンマを出力
        getToken
        goto cmd_print4

      // セパレータが';'の場合
cmd_print5:
      if TokenType#<>DELIMIT  goto cmd_print51
      if TokenText$<>';' goto cmd_print51
        TokenText$, last_char#=
        getToken
        goto cmd_print4

// 終端処理
cmd_print51:
      if TokenType#=EOL  goto cmd_print6
      if TokenType#=DELIMIT then if TokenText$=':' goto cmd_print6
      "SYNTAX ERROR", assertError

cmd_print6:
    if last_char#<>';' then  nl
    DONE, end

// stopコマンド
cmd_stop:

// "CMD STOP:", prints nl

  1, BreakFlg#=
  DONE, end

// contコマンド
cmd_cont:

// "CMD CONT:", prints nl

  BreakProg#, BreakToken#, exec_basic2
  DONE, end

// runコマンド
cmd_run:

// "CMD RUN:", prints nl

  cmd_clear                      // 変数をクリア
  ForStackArea,   ForStackP#=    // FOR-NEXT用スタックをクリア
  GosubStackArea, GosubStackP#=  // GOSUB-RETURN用スタックをクリア
  ProgArea, CurrentProg#=
  if CurrentProg#=NULL then TERMINATE, end
  CurrentProg#, ->Program.text TokenP#=
  getToken
  DONE, end

// 代入文
cmd_let:
 long lvar#

// "CMD LET:", prints nl

  if TokenType#<>VARIABLE then DONE, end
  
//   "VAR NAME=", prints TokenText, prints nl
  
    TokenText, get_var_adr lvar#=
    if var_type#<>ARRAY then getToken
    "=", checkToken
    var_type#, PUSH eval_expression POP var_type#=
    value_type tt#=

//   "VARIABLE TYPE=", prints var_type#, printd nl
//   "VALUE TYPE=",    prints tt#, printd nl

    if tt#=STRING then if var_type#<>STRING goto cmd_let2
    if tt#=NUMBER then if var_type#=STRING  goto cmd_let2

    if tt#=NUMBER then get_number (lvar)#=
    if tt#=STRING then get_string lvar#, strcpy

// "VAR ADR=0X", prints lvar#, hex prints nl
// "CMD LET END:", prints nl

    DONE, end

// 型違いエラー
cmd_let2:
 "TYPE MISMATCH ERROR", assertError
 end

// listコマンド
cmd_list:

// "CMD LIST:", prints nl

  long list_st#,list_ed#
  0, list_st#= 65535, list_ed#=
  
  if TokenType#=NUMBER then get_number list_st#= getToken
  if TokenText$=',' then  getToken
  if TokenText$='-' then  getToken
  if TokenType#=NUMBER then get_number list_ed#= getToken
  ProgArea, pp#=
cmd_list1:
  if pp#>=EndProg# goto cmd_list3
     pp#, ->Program.length# tt#=
     if tt#<=0 goto cmd_list3
     pp#, ->Program.lineno# tt#=
     if tt#<list_st# goto cmd_list2
     if tt#>list_ed# goto cmd_list2
       tt#, printd " ", prints  pp#, ->Program.text prints nl
cmd_list2:
     pp#, ->Program.length# pp#, + pp#=
     goto cmd_list1
cmd_list3:
    TERMINATE, end


// endコマンド
cmd_end:

// "CMD END:", prints nl

  TERMINATE, end

// newコマンド
cmd_new:

// "CMD NEW:", prints nl

  clear_program 
  cmd_clear
  TERMINATE, end

// elseコマンド
cmd_else:
  "ELSE WITHOUT IF", assertError
  DONE, end

// thenコマンド
cmd_then:
  "THEN WITHOUT IF", assertError
  DONE, end

// len関数
func_len:

// "FUNC LEN:", prints nl

  getToken
  "(", checkToken
  eval_expression
  ")", checkToken
  get_string ss#= strlen put_number
  0, end

// val関数
func_val:

// "FUNC VAL:", prints nl

  getToken
  "(", checkToken
  eval_expression
  ")", checkToken
  get_string 10, atoi put_number
  0, end

// str$関数
func_strs:

// "FUNC STRS:", prints nl

  getToken
  "(", checkToken
  eval_expression
  ")", checkToken
  get_number 10, itoa put_string
  0, end

// left$関数
func_lefts:

// "FUNC LEFTS:", prints nl

  getToken
  "(", checkToken
  eval_expression
  ",", checkToken
  eval_expression
  ")", checkToken
  get_number kk#=
  get_string ss0#= strlen ll#=
  0, ii#=
func_lefts1:
  if ii#>=kk# goto func_lefts2
  if ii#>=ll#   goto func_lefts2
  (ss0)$(ii#), sss$(ii#)=
  ii#++
  goto func_lefts1
func_lefts2:
  CNULL, sss$(ii#)=
  sss, put_string
  0, end


// mid$関数
func_mids:
  long ss0#
  
// "FUNC MIDS:", prints nl 

  getToken
  "(", checkToken
  eval_expression
  ",", checkToken
  eval_expression
  if TokenText$=','   then  getToken eval_expression gotofunc_midsx
  MAX_STR_LENGTH, put_number
func_midsx:
  ")", checkToken
  get_number jj#=
  get_number 1, - ii#=
  get_string ss0#= strlen ll#=
  jj#, ii#, + jj#=
  0, kk#=
  
// "STRING=", prints ss0#, prints nl  
  
func_mids1:
  if ii#>=jj# goto func_mids2
  if ii#>=ll# goto func_mids2
  (ss0)$(ii#), sss$(kk#)=
  ii#++
  kk#++
  goto   func_mids1
func_mids2:
  CNULL, sss$(kk#)=
  sss, put_string
  0, end

// asc関数
func_asc:

// "FUNC ASC:", prints nl

  getToken
  "(", checkToken
  eval_expression
  ")", checkToken
  get_string ss#=
  (ss)$, put_number
  0, end

// right$関数/
func_rights:

// "FUNC RIGHTS:", prints nl

  getToken
  "(", checkToken
  eval_expression
  ",", checkToken
  eval_expression
  ")", checkToken
  get_number ii#=
 get_string ss0#= strlen ll#=
  ll#, ii#, - ii#=
  if ii#<0 then 0, ii#=
  0, kk#=
func_rights1:
  if ii#>=ll# goto func_rights2
  (ss0)$(ii#), sss$(kk#)=
  ii#++
  kk#++
  goto func_rights1
func_rights2:
  CNULL, sss$(kk#)=
  sss, put_string
  0, end

// chr$関数
func_chrs:
 char ccc$(2)

// "FUNC CHRS:", prints nl

  getToken
  "(", checkToken
  eval_expression
  ")", checkToken
  get_number ccc$(0)=
  CNULL, ccc$(1)=
  ccc, put_string
  0, end

// abs関数
func_abs:
 long vabs#
 
// "FUNC ABS:", prints nl

  getToken
  "(", checkToken
  eval_expression
  ")", checkToken
  get_number vabs#=
  
//  "IN=", prints vabs#, printd nl
  
  if vabs#<0 then vabs#, neg vabs#=
  
//  "OUT=", prints vabs#, printd nl
  
  vabs#, put_number

// "FUNC ABS END:", prints nl

  0, end

// input$関数
func_inputs:

// "FUNC INPUTS:", prints nl 

  getToken
  "(", checkToken
  eval_expression
    ")", checkToken
    get_number nn#=
    0, ii#=
    func_inputs2:
      if ii#>=nn# goto func_inputs3
      getchar sss$(ii#)= tt#=
      if tt#>=' ' then ii#++
      goto func_inputs2
    func_inputs3:
    CNULL, sss$(ii#)=
    sss, put_string
    0, end

// inkey＄関数
func_inkeys:

// "FUNC INKEY:", prints nl

  char inkey_str$(8)
  getToken
  inkey inkey_str$=
  CNULL, inkey_str+1$=
  inkey_str, put_string
  0, end


// instr関数
func_instr:
  long ss1#

// "FUNC INSTR:", prints nl 

  getToken
  "(", checkToken
  eval_expression
  ",", checkToken
  eval_expression
  if TokenText$=','   then  getToken eval_expression gotofunc_instr1
  1, put_number
func_instr1:
  ")", checkToken
  get_number xx#= xx#--
  get_string ss1#=
  get_string ss0#= strlen ll#=
  if xx#<0    then 0, put_number gotofunc_instr2
  if xx#>=ll# then 0, put_number gotofunc_instr2
  ss0#, xx#, + ss1#, strstr xx#=
  if xx#=NULL then 0, put_number gotofunc_instr2
  xx#, ss0#, - 1, + put_number
func_instr2:
  0, end

// sgn関数
func_sgn:
 long vsgn0#,vsgn#
 
// "FUNC SGN:", prints nl

  getToken
  "(", checkToken
  eval_expression
  ")", checkToken
  get_number vsgn0#=
  
//  "IN=", prints vsgn0#, printd nl

  0, vsgn#=
  if vsgn0#<0 then -1, vsgn#=
  if vsgn0#>0 then  1, vsgn#=
  
//  "OUT=", prints vsgn#, printd nl
  
  vsgn#, put_number

// "FUNC SGN END:", prints nl

  0, end

// hex$関数
func_hexs:

// "FUNC HEXS:", prints nl

  getToken
  "(", checkToken
  eval_expression
  ")", checkToken
  get_number hex put_string
  0, end

// bin$関数
func_bins:

// "FUNC BINS:", prints nl

  getToken
  "(", checkToken
  eval_expression
  ")", checkToken
  get_number bin put_string
  0, end

// oct$関数
func_octs:

// "FUNC OCTS:", prints nl

  getToken
  "(", checkToken
  eval_expression
  ")", checkToken
  get_number oct put_string
  0, end

// =  の確認
eval_eq:

//  "EVAL EQ:", prints nl

  get_number tt#=
  if tt#=0 then 1, put_number 0, end
  0, put_number 0, end

// <> の確認
eval_neq:

//  "EVAL NEQ:", prints nl

  get_number tt#=
  if tt#<>0 then 1, put_number 0, end
  0, put_number 0, end

// <  の確認
eval_lt:

// "EVAL LT:", prints nl

  get_number tt#=
  if tt#<0 then 1, put_number 0, end
  0, put_number 0, end

// <= の確認
eval_le:

//  "EVAL LE:", prints nl

  get_number tt#=
  if tt#<=0 then 1, put_number 0, end
  0, put_number 0, end

// >  の確認
eval_gt:

//  "EVAL GT:", prints nl

  get_number tt#=
  if tt#>0 then 1, put_number 0, end
  0, put_number 0, end

.// >= の確認
eval_ge:

//  "EVAL GE:", prints nl

  get_number tt#=
  if tt#>=0 then 1, put_number 0, end
  0, put_number 0, end

// 比較演算
eval_cmp:

//  "EVAL CMP:", prints nl


  // 文字列の場合
  value_type tt#=
  if  tt#<>STRING goto eval_cmp1
    get_string s1, strcpy
    get_string s2, strcpy
    s1, s2, strcmp put_number
    0, end

  // 数値の場合
  eval_cmp1:
    get_number d1#=
    get_number d2#=
    d2#, d1#, - put_number
    0, end

// 論理式 AND演算
eval_and:

//  "EVAL AND:", prints nl

  get_number ss#=
  get_number tt#=
  tt#, ss#, and put_number
  0, end

// 論理式 OR 演算
eval_or:

//  "EVAL OR:", prints nl

  get_number ss#=
  get_number tt#=
  tt#, ss#, or put_number
  0, end

// 除算の余り
eval_mod:

//  "EVAL MOD:", prints nl

  get_number ss#=
  get_number tt#=
  if ss#=0 then "DIVISION BY ZERO", assertError
  tt#, ss#, mod put_number
  0, end

// 除算演算
eval_div:

//  "EVAL DIV:", prints nl

  get_number ss#=
  get_number tt#=
  if ss#=0 then "DIVISION BY ZERO", assertError
  tt#, ss#, /
  put_number
  0, end

// 乗算演算
eval_mul:

//  "EVAL MUL:", prints nl

  get_number ss#=
  get_number tt#=
  tt#, ss#, *
  put_number
  0, end


// 減算演算
eval_sub:

// "EVAL SUB:", prints nl

  get_number ss#=
  get_number tt#=
  tt#, ss#, - put_number
  0, end



// 加算演算
eval_add:

// "EVAL ADD:", prints nl

  get_number ss#=
  get_number tt#=
  tt#, ss#, +
  put_number
  0, end


// 文字列連結演算
eval_concat:
  char sss0$(MAX_STR_LENGTH)
//  "EVAL CONCAT:", prints nl

  get_string sss, strcpy
  get_string sss0, strcpy
  sss, sss0, strcat
  sss0, put_string
  0, end

// 原子の処理
eval_atom:
  long sign#,typ#,val#
  0, sign#=

// "EVAL ATOM:", prints nl
// "TEXT=", prints TokenText, prints nl

  // 原子の前に＋がついている場合
  if TokenText$='+' then getToken  1, sign#=

  // 原子の前に-がついている場合
  if TokenText$='-' then getToken  -1, sign#=

  // (式)は原子である
  if TokenText$<>'('  goto eval_atom2
    getToken
    sign#, PUSH
    eval_expression
    POP sign#=
    ")", checkToken
    value_type tt#=
    if tt#<>STRING goto eval_atom1
    if sign#<>0 then "TYPE MISMATCH", assertError
    
//    "EVAL ATOM(STRING PERMANENT) END:", prints nl
    
    0, end
    eval_atom1:
    if sign#=-1 then  get_number tt#= 0, tt#, - put_number
    
//    "EVAL ATOM(NUMERIC PERMANENT) END:", prints nl
    
    0, end

  // 数値は原子である
  eval_atom2:
  if TokenType#<>NUMBER goto eval_atom3
    TokenValue#, put_number
    getToken
    if sign#=-1 then  get_number tt#= 0, tt#, - put_number
    
//    "EVAL ATOM(NUMBER) END:", prints nl
    
    0, end

  // 文字列は原子である
  eval_atom3:
  if TokenType#<>STRING goto eval_atom4

//    "EVAL ATOM(STRING) :", prints nl

    TokenText, put_string
    getToken
    if sign#<>0 then "SYNTAX ERROR", assertError
    
//    "EVAL ATOM(STRING) END:", prints nl
    
    0, end

  // 関数は原子である
  eval_atom4:
  if TokenType#<>FUNCTION goto eval_atom5
    sign#, PUSH
    TokenCode#, _Function.SIZE, * Function, + ->@_Function.func
    POP sign#=
    value_type tt#=
    if tt#<>STRING goto eval_atom4_1
    if sign#<>0 then "TYPE MISMATCH", assertError
    
//    "EVAL ATOM(STRING FUNCTION) END:", prints nl
    
    0, end
    eval_atom4_1:
    if sign#=-1 then  get_number neg put_number
    
//    "EVAL ATOM(NUMERIC FUNCTION) END:", prints nl
    
    0, end

  // 変数は原子である
  eval_atom5:
  if TokenType#<>VARIABLE goto eval_atom6

//    "VARIABLE:", prints nl
  
    sign#, PUSH
    TokenText, get_var_adr val#=
    POP sign#=
    if var_type#<>ARRAY then getToken

    // 文字列型変数
    if var_type#<>STRING goto eval_atom5_1
    val#, put_string
    if sign#<>0 then "SYNTAX ERROR",  assertError
    
//    "EVAL ATOM(STRING VARIABLE) END:", prints nl
    
    0, end
    
    // 数値型変数
    eval_atom5_1:
    (val)#, put_number
    if sign#=-1 then  get_number neg put_number
    
//    "EVAL ATOM(NUMERIC VARIABLE) END:", prints nl
    
    0, end

  // その他の場合(エラー)
  eval_atom6:

      "ILLEGAL EXPRESSION", assertError
    
//    "EVAL ATOM(OTHER) END:", prints nl
    
    0, end

// 項の処理
eval_term:

// "EVAL TERM:", prints nl

  // 原子を解析
  eval_atom

  // 乗除算は数値型にのみ適用される
  value_type tt#=
  if tt#<>NUMBER  then  0, end

eval_term1:

      // 項は原子*原子
      if TokenText$='*' then getToken eval_atom eval_mul gotoeval_term1

      // 項は原子/原子
      if TokenText$='/' then getToken eval_atom eval_div gotoeval_term1

      // 項は原子 mod 原子
      TokenText, "MOD", strcmp tt#=
      if tt#=0 then getToken eval_atom eval_mod gotoeval_term1

// "EVAL TERM END:", prints nl
      0, end

// 算術式の処理
eval_aexpression:

// "EVAL AEXPRESSION:", prints nl

  // 項を解析
  eval_term
  value_type tt#=
  if tt#<>STRING goto eval_aexpression2

  // 文字列型の場合
  eval_aexpression1:

      // 式は項+項
      if TokenText$='+' then getToken eval_term eval_concat gotoeval_aexpression1

// "EVAL AEXPRESSION END(STRING):", prints nl
      0, end

  // 数値型の場合
  eval_aexpression2:
  
// "EVAL AEXPRESSION2:", prints nl
// "TOKENTEXT=", prints TokenText, prints nl 
  
      // 式は項+項
      if TokenText$='+' then getToken eval_term eval_add gotoeval_aexpression2

      // 式は項-項
      if TokenText$='-' then getToken eval_term eval_sub gotoeval_aexpression2

// "EVAL AEXPRESSION END(NUMBER):", prints nl
      0, end

// 関係式の処理
eval_relation:

//  "EVAL RELATION:", prints nl

  // 式を解析
  eval_aexpression
  
eval_relation1:

    // 論理因子は 式>=式
    TokenText, ">=", strcmp tt#=
    if tt#<>0 goto eval_relation2
      getToken
      eval_aexpression
      eval_cmp
      eval_ge
      goto eval_relation1

    // 論理因子は 式>式
eval_relation2:
    TokenText, ">", strcmp tt#=
    if tt#<>0 goto eval_relation3
      getToken
      eval_aexpression
      eval_cmp
      eval_gt
      goto eval_relation1

    // 論理因子は 式<=式
eval_relation3:
    TokenText, "<=", strcmp tt#=
    if tt#<>0 goto eval_relation4
      getToken
      eval_aexpression
      eval_cmp
      eval_le
      goto eval_relation1

    // 論理因子は 式<式
eval_relation4:
    TokenText, "<", strcmp tt#=
    if tt#<>0 goto eval_relation5
      getToken
      eval_aexpression
      eval_cmp
      eval_lt
      goto eval_relation1

    // 論理因子は 式<>式
eval_relation5:
    TokenText, "<>", strcmp tt#=
    if tt#<>0 goto eval_relation6
      getToken
      eval_aexpression
      eval_cmp
      eval_neq
      goto eval_relation1

    // 論理因子は 式=式
eval_relation6:
    TokenText, "=", strcmp tt#=
    if tt#<>0 goto eval_relation7
      getToken
      eval_aexpression
      eval_cmp
      eval_eq
      goto eval_relation1

    // 上記以外ならば終了
eval_relation7:

//  "EVAL RELATION END:", prints nl

    0, end



// 論理項の処理
eval_lterm:

// "EVAL LTERM:", prints nl

  // 論理因子を解析
  eval_relation
eval_lterm1:

  // and以外ならば終了
  TokenText, "AND", strcmp tt#=
  if tt#<>0 then  0, end

  // 論理項は論理因子AND論理因子AND...
  getToken
  eval_relation
  eval_and
  goto eval_lterm1

// 式の処理
eval_expression:
  long s0#,s1#,s2#,d1#,d2#
  char sss$(MAX_STR_LENGTH+1)

// "EVAL EXPRESSION:", prints nl

  // 論理項を解析
  eval_lterm
eval_expression1:

  // OR以外ならば終了
  TokenText, "OR", strcmp tt#=
  if tt#<>0 then  0, end 

  // 論理式は論理項OR論理項OR...
  getToken
  eval_lterm
  eval_or
  goto eval_expression1


// 文字列をスタックから取りこむ
get_string:
  value_type tt#=
  
//  "GET STRING:", prints nl
  
  if tt#<>STRING then "TYPE MISMATCH", assertError
  CalcStackP#, VALUE_SIZE, - CalcStackP#=
  CalcStackP#, ->Value.data tt#=
  
//  "GET STRING:", prints tt#, prints nl
  
  tt#, end

// 数値をスタックから取りこむ
get_number:
  long vgetn#
  value_type vgetn#=
  
//  "GET NUMBER:", prints nl
  
  if vgetn#<>NUMBER then "TYPE MISMATCH", assertError
  CalcStackP#, VALUE_SIZE, - CalcStackP#=
  CalcStackP#, ->Value.data# vgetn#=
  
//  "VALUE=", prints vgetn#, printd nl
  
  vgetn#, end

// 文字列をスタックに置く
put_string:
  str#=

//  "PUT STRING:", prints str#, prints nl
  
  STRING, CalcStackP#, ->Value.type#=
  CalcStackP#, ->Value.data ss#=
  str#, ss#, MAX_STR_LENGTH-1, strncpy
  CalcStackP#, VALUE_SIZE, + CalcStackP#=

//  "PUT STRING END:", prints str#, prints nl

  end
 

// 数値をスタックに置く
put_number:
  long num#
  num#=
  
//  "PUT NUMBER:", prints num#, printd nl 
  
  NUMBER, CalcStackP#, ->Value.type#=
  num#, CalcStackP#, ->Value.data#=
  CalcStackP#, VALUE_SIZE, + CalcStackP#=
 end
 

// 現在の計算スタックの値の型を返す、スタックに値が入っていない場合は0を返す
value_type:
  long valx#
 
  if CalcStackP#=CalcStackArea then 0, end
  CalcStackP#, VALUE_SIZE, - valx#=
  valx#, ->Value.type# end

// 現在の計算スタックをチェックして整合がとれていなかったらエラーを発生させる
check_value:
  if CalcStackP#<>CalcStackArea then "ILLEGAL EXPRESSION", assertError
  end

// 計算用スタックを初期化する
clear_value:


// "CLEAR VALUE:", prints nl

  CalcStackArea, CalcStackP#=
  end


_INIT_STATES:

 end
main:
  _INIT_STATES
  goto _PSTART
_PSTART:
 _1539967402_in

 end
_1539967402_in:
// BASICを起動する
start_basic:


  char text$(MAX_TEXT_LENGTH+1),ptext$(MAX_TEXT_LENGTH+1)
  long status#,pline#

// card6用コード
 reg_sp#, StackSave#=

// card8用コード
// x=sp/
// (StackSave)=x/

// x86_64用コード
// rax=StackSave/
// (rax)=rsp/

  1, RunFlg#=
  0, BreakProg#=


  // コマンドモード(パラメータ無しで起動した場合)
    cls
    "CARD6 BASIC VER 0.1", prints nl
    cmd_new

      // 通常処理
      basic_entry:
      nl "READY", prints nl

        // コマンド入力ループ
        start_basic1:

          // 計算スタック初期化
          clear_value

          // 1行入力
          start_basic2:
          "> ", prints
          text, inputs tt#=
          if tt#<>LF then nl "? ", prints gotostart_basic2 
          if text$=CNULL goto start_basic2


          // 入力を行番号、TEXTに分割
          text,  pline, ptext, divide_line

//  "LINE=", prints pline#, printd nl
//  "TEXT=", prints ptext,  prints nl

          // 行番号も有効なテキストもないときはやり直し
          if pline#<0 then if ptext$=CNULL goto start_basic2

          start_basic3:
          if pline#>=0 then if ptext$=CNULL  goto start_basic4  // 行番号のみ
          if pline#<0  then if ptext$<>CNULL goto start_basic5  // テキストのみ
          
          // 行番号、テキストがあるときは該当行を挿入または修正
          pline#, ptext, edit_line
          goto start_basic2
          
          // 行番号だけのときは該当行を削除
          start_basic4:
          if pline#=-1 goto start_basic5
          if ptext$<>CNULL goto start_basic5
          pline#, del_line
          goto start_basic2

          // テキストだけのときはダイレクトエリアに格納して、インタープリタに解析実行させる
          start_basic5:
          0, BreakFlg#=

// "DIRECT COMMAND:", prints nl
 
              -1, DirectArea, ->Program.lineno#=
              ptext, DirectArea, ->Program.text strcpy
              ptext, strlen SIZEOF_LONG*2+1, + plen#=
              plen#, DirectArea, ->Program.length#=
              DirectArea, plen#, + tt#=
              -1, tt#, ->Program.length#=

//  "TEXT=", prints DirectArea, ->Program.text prints nl
//  "LENGTH=", prints DirectArea, ->Program.length# printd nl

              DirectArea, exec_basic status#=
              if status#=QUIT goto start_basic6
              if status#<>TERMINATE then  "DIRECT COMMAND ONLY", assertError
              goto basic_entry

        start_basic6:
        cmd_new
        "<<<BYE>>>", prints nl
        end

 end
