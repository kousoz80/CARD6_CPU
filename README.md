



# CARD6_CPU
  
自作CPUを電子部品で組み立てて、BASICや自作のOSを動かしてセルフホストのコンパイラでプログラム開発などしています。

![enter image description here](image/card6_cpu3.jpg?raw=true)
  
<a name="mokuji"></a>
## 目次
[・特徴](#tokutyou)  
[・構成](#kousei)  
　　[メモリの構成](#memory_kousei)  
　　　　[cフィールド](#cfield)  
　　　　[aフィールド](#afield)  
　　　　[rフィールド](#rfield)  
　　　　[dフィールド](#dfield)  
　　[OPコード](#op_code)  
[・動作](#dousa)  
　　[分岐処理](#bunki)  
　　[逐次処理](#tikuji)  
　　[データ転送処理](#data)  
[・プログラミング](#programming)  
　　[アセンブラの命令](#meirei)  
　　[演算子](#enzanshi)  
　　[コーディング例](#coding)  
　　　　[データ転送](#tensou)  
　　　　[単項演算](#enzan1)  
　　　　[二項演算](#enzan2)  
　　　　[条件分岐](#jouken)  
[・デバッグツール](#debug)  
[・仮想マシン](#kasou)  
　　[コンパイラ](#compiler)  
　　[BASIC](#basic)  
　　[OS](#os)  
[・回路図](#kairozu)  
[・動画](#douga)  
[・各ファイルの説明](#setumei)  

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
CARD6 CPUはプログラムカウンタやALU、シーケンサ等が存在しない極めて特異かつ単純な構成となっています。
  
  
  
![enter image description here](image/card6_cpu1.jpg?raw=true)
  
###### [目次](#mokuji)  
<a name="memory_kousei"></a>
  
### メモリの構成
  CPUのアーキテクチャはおおまかに分けるとプログラムとデータの区別をしないノイマン型と  
  プログラムとデータを区別するハーバード型に分かれています。  
  CARD6アーキテクチャではハーバード型をさらに進めて、メモリをc,a,r,dの独立した４つのフィールドに分けて使用します。  
  
<a name="cfield"></a>
  
###  c(control)フィールド
  このフィールドにはCPUの各レジスタやメモリ、IOポートを制御する信号がをビット単位で格納されます、いわゆるOPコードです。  

<a name="afield"></a>
  
###  a(address)フィールド
  このフィールドには次に実行するアドレスが格納されます
  
<a name="rfield"></a>
  
###  r(return address)フィールド
  このフィールドにはOPコードのRETビット(※後述)が有効になったとき  
  次の次に実行するアドレスが格納されます。
  
  
<a name="dfield"></a>
  
###  d(data)フィールド
  このフィールドにはデータが格納されます。
  
  
  
  
  
###### [目次](#mokuji)  
<a name="op_code"></a>
  
### OPコード
  OPコードの各ビットはメモリのcフィールドあるいはCレジスタの出力端子から出力されて  
  各レジスタやアドレスセレクタやIOポートを制御します。  
  そのビット割り当ては次のようになっています。  
![enter image description here](image/opcode.png?raw=true)
  
  
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





  
###### [目次](#mokuji)  
<a name="dousa"></a>
## ・動作
  CARD6 CPUは全ての動作を1クロックで完了します。  
  前半の半サイクルでメモリからレジスタ、後半の半サイクルでレジスタからメモリにデータを移動して完了します。  


  
<a name="bunki"></a>
### 分岐処理
  メモリのaフィールドのアドレスに分岐します。  
  ただしOPコードのPOINTERビットが有効なときはHMLレジスタの示すアドレスに分岐します。  
  
<a name="tikuji"></a>
### 逐次処理
  CARD6 CPUはプログラムカウンタを持っていません。  
  基本的に逐次処理はメモリのaフィールドに次のアドレスをセットしておくことによりおこなわれます。  
  
<a name="data"></a>
### データ転送処理
  １.　レジスタにロード  
  メモリのaフィールドにロードする番地をセットして、rフィールドに次のアドレスをセットして  
  OPコードのRETビットを有効にするとレジスタに値がセットされて次のアドレスに戻ってきます。  
  
  ２．　dフィールドにストア  
  メモリのaフィールドにストアする番地をセットして、rフィールドに次のアドレスをセットして  
  OPコードのSTビットとRETビットを有効にするとDレジスタの値をストアして次のアドレスに戻ってきます。  
  
  
  ３．　間接アドレッシング  
  上記に加えてOPコードのPOINTERビットを有効にすると、メモリアクセスにHMLレジスタの示すアドレスが使われます。
  
  
  
###### [目次](#mokuji)  
<a name="programming"></a>
  
## ・プログラミング
CARD6 CPUは構造が簡単な反面、プログラミング作業は初心者にとって負担が大きくなります  
そこで、プログラミングツールとしてアセンブラが用意されています。  
  
  
<a name="meirei"></a>
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
  ・・・数値xxxをカレントアドレスに1バイト(6ビット)セットする
 
  
  data.b xxx  
  ・・・数値xxxをカレントアドレスに1バイト(6ビット)セットする
  
  
  data.l xxx(マクロ命令)  
  ・・・数値xxxをカレントアドレスに1ロングワード(18ビット)セットする
  
  
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
  

  
###### [目次](#mokuji)  
<a name="enzanshi"></a>
###  演算子
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
  
  
  
###### [目次](#mokuji)  
<a name="coding"></a>
### ・コーディング例

<a name="tensou"></a>
#### ・データ転送
  
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
  
  　
###### [目次](#mokuji)  
<a name="enzan1"></a>
#### 単項演算
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
  
    	// アドレス64バイト境界に設定する
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
  
  　
###### [目次](#mokuji)  
<a name="enzan2"></a>
#### 二項演算
二項演算はMレジスタとLレジスタを使って演算処理をおこないます。  
  
    	//　アドレスxxxとyyyの値を加算してxxxにストアする  
    	read 　add_table_h  
    	set(h)  
    	read 　xxx  
    	set(m)  
    	read 　yyy  
    	set(l)  
    	read@  
    	write 　xxx  
    	・  
    	・  
    	・  
    xxx:  
    	data 0  
  
    // 加算用テーブルのアドレス(H)  
    add_table_h:  
    	data   add_table.h  
  
    	// アドレス4Kバイト境界に設定する
    	section  
  
    // 加算用テーブル  
    add_table:  

    	// 0+yyyを計算するテーブル  
    	data 0  
    	data 1  
    	data 2  
    	・  
    	・  
    	・  
    	data 62  
    	data 63  

    	// 1+yyyを計算するテーブル  
    	data 1  
    	data 2  
    	data 3  
    	・  
    	・  
    	・  
    	data 63  
    	data 0  
    	・  
    	・  
    	・  
    	// 63+yyyを計算するテーブル  
    	data 63  
    	data 0  
    	data 1  
    	・  
    	・  
    	・  
    	data 61  
    	data 62  
  
  　
###### [目次](#mokuji)  
<a name="jouken"></a>
#### 条件分岐
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
  
  
  
###### [目次](#mokuji)  

<a name="debug"></a>

## デバッグツール
  カレントディレクトリに移動して"./run"と入力するとデバッガが起動します。  
  CPUのハードウェア制御やエミュレーション、デバッグ、コンパイル等がパソコン上で行えます。
  
###  ハードウェアデバッグモード
  CARD6 CPUボードと接続してハードウェアのデバッグやテストをおこないます。  
  また、BASICインタプリタを内蔵していて、テスト等を自動で実行することができます。  
![enter image description here](image/debug1.png?raw=true)
  
  
###### [目次](#mokuji)  

###  エミュレーションモード
  エミュレーションモードにするとエミュレータが起動して実機がなくてもプログラムを開発・実行することができます。  
![enter image description here](image/sym1.png?raw=true)
  
![enter image description here](image/sym2.png?raw=true)
  

###### [目次](#mokuji)  

###  仮想マシンのエミュレーションモード  
  仮想マシンのエミュレータを起動します、エミュレーションモードよりも高速に動作します。  
![enter image description here](image/vm_sym1.png?raw=true)

  
###### [目次](#mokuji)  

<a name="kasou"></a>
## ・仮想マシン
CARD6 CPUはその構造上、分岐処理とデータ移動処理以外のことはできません。  
またハーバードアーキテクチャのため命令とデータを同様に扱うことができません。  
そこで、まず仮想マシンを実装して、その仮想マシンを利用することで、ノイマン型のCPUと同様なプログラミングを可能としています。  
後述のコンパイラやOS、BASIC等は全てその仮想マシンの命令コードで実装されています。  
  

<a name="compiler"></a>
### コンパイラ
CARD6 CPUには自作言語のコンパイラが用意されています。  
詳細は以下を参照して下さい。
  
https://github.com/kousoz80/oregengo_R  
  
![enter image description here](image/compiler1.png?raw=true)
  
  
###### [目次](#mokuji)  

<a name="basic"></a>
### BASIC
  
BASIC言語の仕様は電大版Tiny BASICとほぼ同じです。
  
https://ja.wikipedia.org/wiki/Tiny_BASIC
  
![enter image description here](image/basic1.png?raw=true)



###### [目次](#mokuji)  

<a name="os"></a>
### OS
  OSの動作をエミュレーションします。

![enter image description here](image/os6.png?raw=true)
  
  
  
  
###### [目次](#mokuji)
  
<a name="kairozu"></a>
  
## ・回路図
CARD6 CPUは極めて簡単な構造なのでCPUだけでなくコンピュータ全体が一枚の回路図に収まってしまいます。
  
  
![enter image description here](image/card6_cpu2.png?raw=true)
  
  
  
###### [目次](#mokuji)
  
<a name="douga"></a>
## ・動画
動作の様子を動画で公開しています  
https://www.youtube.com/watch?v=zzh4TlBwuV4
  
![enter image description here](image/douga1.png?raw=true)  

###### [目次](#mokuji)
  
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
  
  ※ObjectEditorとは回路図を描くような感覚でプログラムを作成することができる統合開発ツールです。  
  https://github.com/kousoz80/ObjectEditor
  
![enter image description here](image/objedit1.png?raw=true)
  
  
###### [目次](#mokuji)  
