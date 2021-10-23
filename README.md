



# CARD8_CPU
  
## ・シミュレータ
  
  
  実機のない環境でも開発/実行を体験できるようにシミュレータが用意されています。
  
  
  CPUのシミュレーション、アセンブル、ソースコードの編集、デバッグ等がパソコン上で行えます。
  

    
###  ・実行画面
  
![enter image description here](https://imgur.com/PyoqBlu.jpg)  
  

### ・アセンブラソースコードの編集画面
  
![enter image description here](https://imgur.com/xseChi5.jpg)  
  
  
  
### ・実行結果
  
  
![enter image description here](https://imgur.com/23sktb7.jpg)
  
  
## ・アセンブラの命令
  
  org xxx
  
   ・・・カレントアドレスを数値xxxにセットする

  align16
  
   ・・・カレントアドレスを16ワード境界に揃える

  align256
  
   ・・・カレントアドレスを256ワード境界に揃える

  read xxx
  
   ・・・アドレスxxxのデータを読み出してカレントアドレスのdフィールドにセットする

  read@
  
  ・・・H,M,Lレジスタで指定されたアドレスのデータを読み出してカレントアドレスのdフィールドにセットする

  write xxx
  
  ・・・カレントアドレスのdフィールドの内容を指定アドレスxxxのデータフィールドにセットする


  write@
  
  ・・・カレントアドレスのdフィールドの内容をのH,M,Lレジスタで指定されたアドレスのデータフィールドにセットする


  set.h
  
  ・・・カレントアドレスのdフィールドの内容をHレジスタにセットする


  set.m
  
  ・・・カレントアドレスのdフィールドの内容をMレジスタにセットする


  set.l
  
  ・・・カレントアドレスのdフィールドの内容をLレジスタにセットする


  jmp  xxx
  
  ・・・指定アドレスxxxにジャンプする

  jmp@
  
  ・・・H,M,Lレジスタで指定されたアドレスにジャンプする


  data xxx
  
  ・・・Dレジスタに数値xxxをセットする
  
  
  data.h xxx
  
  ・・・Hレジスタに数値xxxをセットする
  
  
  data.m xxx
  
  ・・・Mレジスタに数値xxxをセットする
  
  
  data.l xxx
  
  ・・・Lレジスタに数値xxxをセットする
  
  
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
    
  
  
