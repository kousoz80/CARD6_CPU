



# CARD6_CPU
  
自作CPUを電子部品で組み立てて、BASICや自作のOSを動かしてセルフホストのコンパイラでプログラム開発などしています。

![enter image description here](image/card6_cpu3.jpg?raw=true)
  
<span style="font-size: 200%;">

[・特徴](#tokutyou)
  
[・構成](#kousei)
  
[・動作](#dousa)
  
[・プログラミング](#programming)
  
[・デバッグツール](#debug)
  
[・回路図](#kairozu)
  
[・各ファイルの説明](#setumei)
  
</span>
  
<a name="tokutyou"></a>
  
## ・特徴
  
・オリジナル6ビットCPU
  
・データや命令、アドレス等が分離された変形ハーバードアーキテクチャ
  
・極限まで切り詰めた簡素な構造
  
・1命令をを１クロックサイクルで動作
  
・エミュレータやアセンブラ、コンパイラ等の開発ツールが付属
  
・BASICインタプリタやOS等も付属
  
<a name="kousei"></a>

## ・構成
  
CARD6 CPUはプログラムカウンタやALUを持たない極めて単純な構成となっています。
  
  
  
![enter image description here](image/card6_cpu1.jpg?raw=true)
  
  
### メモリの説明
  
  CPUのアーキテクチャはおおまかに分けるとプログラムとデータの区別をしないノイマン型と
  
  プログラムとデータを区別するハーバード型に分かれています。  
  
  CARD6アーキテクチャではハーバード型をさらに進めて、メモリをc,a,r,dの独立した４つのフィールドに分けて使用します。
  
  
  
####  c(control)フィールド
  
  このフィールドにはCPUの各レジスタやメモリ、IOポートを制御する信号がをビット単位で格納されます。
  
  いわゆるOPコードです。
  
####  a(address)フィールド
  
  このフィールドには次に実行するアドレスが格納されます
  
####  r(return address)フィールド
  
  このフィールドにはOPコードのRETビット(※後述)が有効になったとき

  次の次に実行するアドレスが格納されます。
  
  
####  d(data)フィールド
  
  このフィールドにはデータが格納されます。
  
  
  
  
  
### OPコードのビット割り当て
  
  
  OPコードの各ビットはメモリのcフィールドあるいはCレジスタの出力端子から出力されて
  
  各レジスタやアドレスセレクタやIOポートを制御します。
  
  そのビット割り当ては次のようになっています。
　
  
    MSB　　７　　　６　　　５　　　４　　　３　　　２　　　１　　　０　　LSB
  
             IO　POINTER 　RET 　 ST　　　LD　　LDH　　LDM　　LDL　　

  
### OPコードの説明
  
  
  IO:  
   このビットが有効なときはメモリではなくIOポートにアクセスします(dフィールドのみ)。
  
  
  POINTER:  
   このビットが有効なときはHMLレジスタの出力がメモリアドレスとなり  
   そうでない場合Aレジスタの出力がメモリアドレスとなります。
  
  
  RET:  
   このビットが有効なときは次に実行されるアドレスのaフィールドにRレジスタの値がセットされます。  
   結果として、このビットが有効になったときに次の命令を実行後、  
   rフィールドのアドレスにジャンプします。
  
  
  
  ST:  
   このビットが有効なときはメモリのdフィールドにDレジスタの値がセットされます。
  
  
  LD:  
   このビットが有効なときはDレジスタにメモリのdフィールドの値がセットされます。
  
  
  LDH:  
   このビットが有効なときはHレジスタにメモリのdフィールドの値がセットされます。
  
  
  LDM:  
   このビットが有効なときはMレジスタにメモリのdフィールドの値がセットされます。
  
  
  LDL:  
   このビットが有効なときはLレジスタにメモリのdフィールドの値がセットされます。





  
<a name="dousa"></a>
## ・動作
  
  CARD6 CPUは全ての動作を1クロックで完了します。  
  前半の半サイクルでメモリからレジスタ、後半の半サイクルでレジスタからメモリにデータを移動して完了します。  


  
### 分岐処理  
  
  メモリのaフィールドのアドレスに分岐します。
  
  ただしOPコードのPOINTERビットが有効なときはHMLレジスタの示すアドレスに分岐します。  
  
### 逐次処理  
  
  CARD6 CPUはプログラムカウンタを持っていません。
  
  基本的に逐次処理はメモリのaフィールドに次のアドレスをセットしておくことによりおこなわれます。
  
  
### データ転送  
  
  
  １.　レジスタにロード　
  
  メモリのaフィールドにロードする番地をセットして、rフィールドに次のアドレスをセットして
  
  OPコードのRETビットを有効にするとレジスタに値がセットされて次のアドレスに戻ってきます。

  
  ２．　dフィールドにストア　
  
  メモリのaフィールドにストアする番地をセットして、rフィールドに次のアドレスをセットして
  
  OPコードのSTビットとRETビットを有効にするとDレジスタの値をストアして次のアドレスに戻ってきます。
  
  
  ３．　間接アドレッシング  
  
  上記に加えてOPコードのPOINTERビットを有効にすると、メモリアクセスにHMLレジスタの示すアドレスが使われます。
  
  
  
<a name="programming"></a>
  
## ・プログラミング
  
CARD6 CPUは構造が簡単な反面、プログラミング作業は初心者にとって負担が大きくなります  
  
そこで、プログラミングツールとしてアセンブラが用意されています。
  
  
### アセンブラの命令
  
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
  

  
###  ・演算子
  
  基本的な演算子の他に以下のような演算子が用意されています。
  
  xxx.h  
  ・・・数値xxxの18ビット中の上位6ビットを与える
  
  xxx.m  
  ・・・数値xxxの18ビット中の中位6ビットを与える
  
  xxx.l  
  ・・・数値xxxの18ビット中の下位6ビットを与える
    
  ppp(h)  
  ・・・アドレスpppの上位6ビットの位置を与える(ppp+2と等価)
  
  ppp(m)  
  ・・・アドレスpppの中位6ビットの位置を与える(ppp+1と等価)
  
  ppp(l)  
  ・・・アドレスpppの下位6ビットの位置を与える(ppp+0と等価)
  
  
  
  
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
  
    	page  
  
    // インクリメント演算用テーブル  
    inc_table:  
    	data 1  
    	data 2  
    	data 3  
    	data 4  
    	・  
    	・  
    	・  
    	data 61  
    	data 62  
    	data 63  
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
  
  
  
<a name="debug"></a>

## デバッグツール
  
 ### run(スクリプトファイル)
  
  カレントディレクトリに移動して"./run"と入力するとデバッガが起動します。
  
  CPUのハードウェア制御やエミュレーション、デバッグ、コンパイル等がパソコン上で行えます。
  
![enter image description here](image/sym1.png?raw=true)
  
  高速エミュレータを起動したとき
  
![enter image description here](image/fast_sym1.png?raw=true)
  
 ### run_vm(スクリプトファイル)
  
  仮想マシンのエミュレータを起動します。
  
![enter image description here](image/sym_vm1.png?raw=true)
  
  直接仮想マシンのエミュレーションを行いますので高速に実行できます。
  
  複雑な処理のエミュレーションに向いています。
　　
![enter image description here](image/sym_vm1.png?raw=true)
  
  BASICを実行したとき
  
![enter image description here](image/card6basic.png?raw=true)  
  
  高速エミュレータを起動したとき
  
![enter image description here](image/fast_sym_vm1.png?raw=true)
  
## ・仮想マシン
  
CARD6 CPUはその簡素な構造のため、できることは分岐処理とデータ転送処理に限られています。
  
またハーバードアーキテクチャのため命令とデータを同様に扱うことができません。
  
そこで、まず仮想マシンを実装して、その仮想マシンを利用することで、ノイマン型のCPUと同様なプログラミングを可能としています。
  
後述のコンパイラやOS、BASIC等は全てその仮想マシンの命令コードで実装されています。
  

### ・コンパイラ
  
  
CARD6 CPUには自作言語のコンパイラが用意されています。
  
詳細は以下を参照して下さい。
  
https://github.com/kousoz80/oregengo_R  
  
  
### ・BASIC
  
BASIC言語の仕様は電大版Tiny BASICとほぼ同じです。
  
https://ja.wikipedia.org/wiki/Tiny_BASIC
  



### OS
  
  OSの動作をエミュレーションします。

![enter image description here](image/os6.png?raw=true)
  
  
  
  
<a name="kairozu"></a>
  
## ・回路図  
  
  
CARD6 CPUは極めて簡単な構成なのでCPUだけでなくコンピュータ全体が一枚の回路図に収まります。
  
  
![enter image description here](image/card6_cpu2.png?raw=true)
  
  
  
  
<a name="setumei"></a>
## ・各ファイルの説明
  
  
  
  ### a.out
  仮想マシンのイメージファイルです、これがないとエミュレータは動作しません。
  
  ### r.out
  アプリケーションのイメージファイルです、コンパイルすると内容は更新されます。
  
  ### asm(ディレクトリ)
  仮想マシンのソースコードが格納されています。
  
  ### bin(ディレクトリ)
  アプリケーションの実行可能ファイルが格納されています。
  
  ### C(ディレクトリ)
  アプリケーションのソースコード(C言語)が格納されています。
  
  ### jar(ディレクトリ)
  アプリケーション(Java)の実行可能ファイル(jar)が格納されています。
  
  ### oregengo-R(ディレクトリ)
  エミュレータまたは実機で動作するアプリケーションのソースコード(自作言語)が格納されています。
  

  ### Project(ディレクトリ)
  アプリケーション等のObjectEditorプロジェクトファイルが格納されています。
  
  ObjectEditorの詳細
  
  https://github.com/kousoz80/ObjectEditor
  

