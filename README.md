



# CARD6_CPU
  
自作CPUを電子部品で組み上げて、BASICや自作のOSを動かしてセルフホストのコンパイラでプログラム開発等が可能です。

## 特徴
  
・オリジナル6ビットCPU
  
・プログラムカウンタやALUを持たない極めて簡素な構造
  
・エミュレータやアセンブラ、コンパイラ等の開発ツールが付属
  
・BASICインタプリタやOS等も付属
  

## ・回路の構成
  
CARD6 CPUはプログラムカウンタやALUを持たない簡素な構造となっています。
  
そのため、初心者でも比較的簡単に組み立てることができます。  
  
### ・ブロック図
  
  
![enter image description here](image/card6_cpu1.jpg?raw=true)
  
  
### ・回路図
  
CARD6 CPUは極めて簡素な構成なのでCPUだけでなくコンピュータ全体が一枚の回路図に収まってしまいます。
  
  
![enter image description here](image/card6_cpu2.png?raw=true)
  
  
## ・仮想マシン
  
CARD6 CPUはその簡素な構造のため、基本的にデータ移動と無条件ジャンプ以外は何もできません。
  
そのため、演算処理や条件ジャンプを実装するため、かなり余分な手間が必要となります。
  
そこで、まず仮想マシンを実装して、その仮想マシンを利用することで普通のCPUと同じようなプログラミングを可能にしています。
  
後述のコンパイラやOS、BASIC等は全てその仮想マシンの命令コードで記述されています。
  

## ・ファイルの説明
  
 ###run(スクリプトファイル)
  
  エミュレータを起動します。
  
  CPUのアセンブル、コンパイル、ソースコードの作成/編集、デバッグ等がパソコン上で行えます。
  
![enter image description here](image/sym1.png?raw=true)
  
 ###run_vm(スクリプトファイル)
  
  仮想マシンのエミュレータを起動します。
  
![enter image description here](image/sym_vm1.png?raw=true)
  
  高速エミュレータを起動したとき
  
![enter image description here](image/fast_sym1.png?raw=true)
  
  直接仮想マシンのエミュレーションを行いますので高速に実行できます。
  
  複雑な処理のエミュレーションに向いています。
　　
![enter image description here](image/sym_vm1.png?raw=true)
  
  BASICを実行したとき
  
![enter image description here](image/card6basic.png?raw=true)  
  
  高速エミュレータを起動したとき
  
![enter image description here](image/fast_sym_vm1.png?raw=true)
  
  ###run_os6(スクリプトファイル)
  
  OSの動作をエミュレーションします。

![enter image description here](image/os6.png?raw=true)
  
  ###a.out
  仮想マシンのイメージファイルです、これがないとエミュレータは動作しません。
  
  ###r.out
  アプリケーションのイメージファイルです、コンパイルすると内容は更新されます。
  
  ##asm(ディレクトリ)
  仮想マシンのソースコードが格納されています。
  
  ##bin(ディレクトリ)
  アプリケーションの実行可能ファイルが格納されています。
  
  ##C(ディレクトリ)
  アプリケーションのソースコード(C言語)が格納されています。
  
  ##jar(ディレクトリ)
  アプリケーション(Java)の実行可能ファイル(jar)が格納されています。
  
  ##oregengo-R(ディレクトリ)
  エミュレータまたは実機で動作するアプリケーションのソースコード(自作言語)が格納されています。
  

  ##Project(ディレクトリ)
  アプリケーション等のObjectEditorプロジェクトファイルが格納されています。
  
  ObjectEditorの詳細
  
  https://github.com/kousoz80/ObjectEditor
  

## ・プログラミング
  
プログラミングツールとしてアセンブラ、コンパイラ、BASICインタプリタ等が用意されています。
  
  
### ・アセンブラ
  
#### アセンブラの命令
  
  page
  
   ・・・カレントアドレスをページ(６４バイト)区切りにセットする

  
  section
  
   ・・・カレントアドレスをセクション(4096バイト)区切りにセットする


  org xxx
  
   ・・・カレントアドレスを数値xxxにセットする

  equ xxx
  
   ・・・ラベルに数値xxxを割り付ける

  = xxx
  
   ・・・ラベルに数値xxxを割り付ける(equ命令と同等)

  read xxx
  
   ・・・アドレスxxxのデータを読み出してカレントアドレスのdフィールドにセットする

  read@
  
  ・・・HMLレジスタで指定されたアドレスのデータを読み出してカレントアドレスのdフィールドにセットする

  write xxx
  
  ・・・カレントアドレスのdフィールドの内容を指定アドレスxxxのデータフィールドにセットする


  write@
  
  ・・・カレントアドレスのdフィールドの内容をのHMLレジスタで指定されたアドレスのデータフィールドにセットする


  set(h)
  
  ・・・カレントアドレスのdフィールドの内容をHレジスタにセットする


  set(m)
  
  ・・・カレントアドレスのdフィールドの内容をMレジスタにセットする


  set(l)
  
  ・・・カレントアドレスのdフィールドの内容をLレジスタにセットする


  jmp  xxx
  
  ・・・指定アドレスxxxにジャンプする

  jmp@
  
  ・・・HMLレジスタで指定されたアドレスにジャンプする


  data xxx
  
  ・・・数値xxxを該当番地に1バイト(6ビット)セットする
 
  
  data.b xxx
  
  ・・・数値xxxを該当番地に1バイト(6ビット)セットする
  
  
  data.l xxx(マクロ命令)
  
  ・・・数値xxxを該当番地に1ロングワード(18ビット)セットする
  
  
  move.b xxx,yyy(マクロ命令)
   
  ・・・1バイト(6ビット)単位でxxx番地のデータをyyy番地に移動する
  
  
  
  move.l xxx,yyy(マクロ命令)
  
  ・・・1ロングワード(18ビット)単位でxxx番地のデータをyyy番地に移動する
  
  
  read @xxx(マクロ命令)
  
  ・・・xxx番地に格納されているアドレスのデータを読み込む(マクロ命令)
  
  
  jmp @xxx(マクロ命令)
  
  ・・・xxx番地に格納されているアドレスにジャンプする
  
  
  set @xxx(マクロ命令)
  
  ・・・xxx番地に格納されているアドレスをHMLレジスタにセットする
  

## ・コーディング例

### ・データ移動
  
    //　アドレスxxxの内容をアドレスyyyにコピーする
  
    read xxx
  
    write yyy
  
    move.b xxx,yyy
  
    move.l xxx,yyy
  ・
  
  ・
  
  ・
    
xxx:
  
  　  data 0
  
yyy:
  
  　data 1
  
  　
  
  　
  
  　
### ・演算
  
  
CARD6 CPUはALUを持っていないので定数テーブル参照を利用することで演算をおこないます。
  
  
 　 //　アドレスxxxの値を+1する
  
   read 　inc_table_h
  
   set(h) 
  
   read 　inc_table_m
  
   set(m)
  
   read 　xxx
  
   set(l)
  
   read@
  
   write 　xxx
  
  
  ・
  
  ・
  
  ・
    

  
xxx:
  
　 data 0

  
// インクリメント演算用テーブルのアドレス(H)
  
inc_table_h:
  
　 data   inc_table.h
  

// インクリメント演算用テーブルのアドレス(M)
  
inc_table_m:
  
　 data  　 inc_table.m
  
// インクリメント演算用テーブル
  
  page
   
inc_table:
  
 　data 1
  
 　data 2
  
 　data 3
  
 　data 4
  
 　data 5
  
 　data 6
  
 　data 7
  
 　data 8
  
 　data 9
  
 　data 10
  
 　data 11
  
 　data 12
  
 　data 13
  
 　data 14
  
 　data 15
  
 　data 0
  
  　
  
  　
  
  　
### ・条件分岐
  
  
条件分岐も演算同様に分岐先アドレスを格納したテーブルを参照することで条件分岐をおこないます。
  
  
// アドレスxxxの内容が0ならyyyにジャンプして1ならzzzにジャンプする
  
  
  
  ・
  
  ・
  
  ・
    

  
     read 　jump_table_h
  
     set(h)
  
     read 　jump_table_m
  
     set(m)
  
     read 　xxx
  
     set(l)
  
     jump@
  
  
  ・
  
  ・
  
  ・
    

  
  
xxx:
  
  　data 0
  
  
jump_table_h:
  
  　data　 jump_table.h
  
jump_table_m:
  
  　data　 jump_table.m
  

  page  
jump_table:
  
  　 jmp yyy
  
  　 jmp zzz
  
  　
  
###  ・演算子について
  
  基本的な演算の他に以下のような演算子が用意されています。
  
  xxx.h
  
  ・・・数値xxxの18ビット中の上位6ビットを与える
  
  xxx,m
  
  ・・・数値xxxの18ビット中の中位6ビットを与える
  
  xxx.l
  
  ・・・数値xxxの18ビット中の下位6ビットを与える
    
  
  
### ・コンパイラ
  
  
CARD6 CPUには自作言語のコンパイラが用意されています。
  
詳細は以下を参照して下さい。
  
https://github.com/kousoz80/oregengo_R  
  
  
### ・BASIC
  
BASIC言語の仕様は電大版Tiny BASICとほぼ同じです。
  
