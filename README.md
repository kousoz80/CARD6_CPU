



# CARD6_CPU
  
## ・シミュレータ
  
  
  実機のない環境でも開発/実行を体験できるようにシミュレータが用意されています。
  
  
  CPUのシミュレーション、アセンブル、ソースコードの編集、デバッグ等がパソコン上で行えます。
  

    
###  ・os6実行画面(高速エミュレータ上)
  
![enter image description here](image/os6.png?raw=true)  
  

### ・BASIC実行画面(エミュレータ上)
  
![enter image description here](image/card6basic.png?raw=true)  
  
  
  
### ・ブロック図
  
  
![enter image description here](image/card6_cpu1.jpg?raw=true)
  
  
### ・回路図
  
  
![enter image description here](image/card6_cpu2.png?raw=true)
  
  
## ・アセンブラの命令
  
  org xxx
  
   ・・・カレントアドレスを数値xxxにセットする

  equ xxx
  
   ・・・ラベルに数値xxxを割り付ける

  read xxx
  
   ・・・アドレスxxxのデータを読み出してカレントアドレスのdフィールドにセットする

  read@
  
  ・・・H,M,Lレジスタで指定されたアドレスのデータを読み出してカレントアドレスのdフィールドにセットする

  write xxx
  
  ・・・カレントアドレスのdフィールドの内容を指定アドレスxxxのデータフィールドにセットする


  write@
  
  ・・・カレントアドレスのdフィールドの内容をのH,M,Lレジスタで指定されたアドレスのデータフィールドにセットする


  set(h)
  
  ・・・カレントアドレスのdフィールドの内容をHレジスタにセットする


  set(m)
  
  ・・・カレントアドレスのdフィールドの内容をMレジスタにセットする


  set(l)
  
  ・・・カレントアドレスのdフィールドの内容をLレジスタにセットする


  jmp  xxx
  
  ・・・指定アドレスxxxにジャンプする

  jmp@
  
  ・・・H,M,Lレジスタで指定されたアドレスにジャンプする


  data xxx
  
  ・・・数値xxxを該当番地に1バイト(6ビット)セットする
 
  
  data.b xxx
  
  ・・・数値xxxを該当番地に1バイト(6ビット)セットする
  
  
  data.l xxx(マクロ命令)
  
  ・・・数値xxxを該当番地に1ロングワード(3バイト)セットする
  
  
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
  
  ・
  
  ・
  
  ・
    
xxx:
  
  　  data 0
  
yyy:
  
  　data 1
  
  　
  
  　
  
  　
### ・演算

  
  
 　 //　アドレスxxxの値を+1する
  
　 read 　inc_table_h
  
　 read 　inc_table_m
  
　 read 　xxx
  
　 set.l
  
　 read@
  
　 write 　xxx
  
  
  ・
  
  ・
  
  ・
    

  
xxx:
  
　 data 0

  
// インクリメント演算用テーブルのアドレス(H)
  
inc_table_h:
  
　 data.h　 inc_table.h
  

// インクリメント演算用テーブルのアドレス(M)
  
inc_table_m:
  
　 data.m　 inc_table.m
  
// インクリメント演算用テーブル
  
　 align16
   
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
  
// アドレスxxxの内容が0ならyyyにジャンプして1ならzzzにジャンプする
  
  
  
  ・
  
  ・
  
  ・
    

  
  　 read 　jump_table_h
  
  　 read 　jump_table_m
  
  　 read 　xxx
  
  　 set.l
  
  　 jump@
  
  
  ・
  
  ・
  
  ・
    

  
  
xxx:
  
  　data 0
  
  
jump_table_h:
  
  　data.h　 jump_table.h
  
jump_table_m:
  
  　data.m　 jump_table.m
  
  　align16
  
jump_table:
  
  　 jmp yyy
  
  　 jmp zzz
  
  　
  
###  ・演算子について
  
  基本的な演算の他に以下のような演算子が用意されています。
  
  xxx.h
  
  ・・・数値xxxの24ビット中の上位8ビットを与える
  
  xxx,m
  
  ・・・数値xxxの24ビット中の中位8ビットを与える
  
  xxx.l
  
  ・・・数値xxxの24ビット中の下位8ビットを与える
    
  
  
