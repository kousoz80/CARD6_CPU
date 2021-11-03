// CARD8仮想マシンのシミュレータプログラム

// 入出力エリア
 org 0xfffffd
KEY_DATA: data 0
PRT_STB:  data 0
PRT_DATA: data 0


// プログラムエリア
 org 0x000000

// 各レジスタを初期化
_start:
      move.l @vm_start,reg_pc
      move.l _000,reg_sp
      move.l _000,reg_x
      move.l _000,reg_y
      move.b _000,reg_a
      move.b _000,reg_cf
      move.b _000,reg_zf
      jmp fetch_ins

@vm_start:    data.l vm_start      // 最初に命令を実行するアドレス

// 命令コードをフェッチ
@fetch_ins: data.l fetch_ins
fetch_ins:
      read@ reg_pc
      write ins
      move.l @fetch_ins1,inc_reg_pc_ret
      jmp inc_reg_pc
@fetch_ins1: data.l fetch_ins1
fetch_ins1:

    // 命令コードに応じた処理
      read @ins_table_l(h)
      set(h)
      read @ins_table_l(m)
      set(m)
      read ins
      set(l)
      read@
      write ins_adr(l)

      read @ins_table_m(h)
      set(h)
      read @ins_table_m(m)
      set(m)
      read ins
      set(l)
      read@
      write ins_adr(m)

      read @ins_table_h(h)
      set(h)
      read @ins_table_h(m)
      set(m)
      read ins
      set(l)
      read@
      write ins_adr(h)

      jmp@   ins_adr

@ins_table_h: data.l ins_table_h  // 命令実行用ジャンプテーブル上位アドレス
@ins_table_m: data.l ins_table_m  // 命令実行用ジャンプテーブル中位アドレス
@ins_table_l: data.l ins_table_l  // 命令実行用ジャンプテーブル下位アドレス



// hlt;	  停止する
hlt:
      jmp hlt 


// lxi xxxx; Xレジスタにxxxxの値をセットする
lxi:
        read@ reg_pc
        write reg_x(l)
        move.l @lxi1,inc_reg_pc_ret
        jmp inc_reg_pc
@lxi1:  data.l lxi1
lxi1:
        read@ reg_pc
        write reg_x(m)
        move.l @lxi2,inc_reg_pc_ret
        jmp inc_reg_pc
@lxi2:  data.l lxi2
lxi2:
        read@ reg_pc
        write reg_x(h)
        move.l @lxi3,inc_reg_pc_ret
        jmp inc_reg_pc
@lxi3:  data.l lxi3
lxi3:
        jmp fetch_ins
        

// ldx xxxx; Xレジスタにxxxx番地の内容を転送する
ldx:
        read@ reg_pc
        write adr(l)
        move.l @ldx1,inc_reg_pc_ret
        jmp inc_reg_pc
@ldx1:  data.l ldx1
ldx1:
        read@ reg_pc
        write adr(m)
        move.l @ldx2,inc_reg_pc_ret
        jmp inc_reg_pc
@ldx2:  data.l ldx2
ldx2:
        read@ reg_pc
        write adr(h)
        move.l @ldx3,inc_reg_pc_ret
        jmp inc_reg_pc
@ldx3:  data.l ldx3
ldx3:
        read@ adr
        write reg_x(l)
        move.l @ldx4,inc_adr_ret
        jmp inc_adr
@ldx4:  data.l ldx4
ldx4:
        read@ adr
        write reg_x(m)
        move.l @ldx5,inc_adr_ret
        jmp inc_adr
@ldx5:  data.l ldx5
ldx5:
        read@ adr
        write reg_x(h)
        jmp fetch_ins


// adx xxxx; Xレジスタにxxxx番地の内容を加算する
adx:
        read@ reg_pc
        write adr(l)
        move.l @adx1,inc_reg_pc_ret
        jmp inc_reg_pc
@adx1:  data.l adx1
adx1:
        read@ reg_pc
        write adr(m)
        move.l @adx2,inc_reg_pc_ret
        jmp inc_reg_pc
@adx2:  data.l adx2
adx2:
        read@ reg_pc
        write adr(h)
        move.l @adx3,inc_reg_pc_ret
        jmp inc_reg_pc
@adx3:  data.l adx3
adx3:
        read@ adr
        write tmp(l)
        move.l @adx4,inc_adr_ret
        jmp inc_adr
@adx4:  data.l adx4
adx4:
        read@ adr
        write tmp(m)
        move.l @adx5,inc_adr_ret
        jmp inc_adr
@adx5:  data.l adx5
adx5:
        read@ adr
        write tmp(h)
        move.l reg_x,add_long_in0
        move.l tmp,add_long_in1
        move.l @adx6,add_long_ret
        jmp add_long
@adx6:  data.l adx6
adx6:
        move.l add_long_out,reg_x
        move.b add_long_zf,reg_zf
        move.b add_long_cf,reg_cf
        jmp fetch_ins


// sbx xxxx; Xレジスタからxxxx番地の内容を減算する
sbx:
        read@ reg_pc
        write adr(l)
        move.l @sbx1,inc_reg_pc_ret
        jmp inc_reg_pc
@sbx1:  data.l sbx1
sbx1:
        read@ reg_pc
        write adr(m)
        move.l @sbx2,inc_reg_pc_ret
        jmp inc_reg_pc
@sbx2:  data.l sbx2
sbx2:
        read@ reg_pc
        write adr(h)
        move.l @sbx3,inc_reg_pc_ret
        jmp inc_reg_pc
@sbx3:  data.l sbx3
sbx3:
        read@ adr
        write tmp(l)
        move.l @sbx4,inc_adr_ret
        jmp inc_adr
@sbx4:  data.l sbx4
sbx4:
        read@ adr
        write tmp(m)
        move.l @sbx5,inc_adr_ret
        jmp inc_adr
@sbx5:  data.l sbx5
sbx5:
        read@ adr
        write tmp(h)
        move.l reg_x,sub_long_in0
        move.l tmp,sub_long_in1
        move.l @sbx6,sub_long_ret
        jmp sub_long
@sbx6:  data.l sbx6
sbx6:
        move.l sub_long_out,reg_x
        move.b sub_long_zf,reg_zf
        move.b sub_long_cf,reg_cf
        jmp fetch_ins


// stx xxxx;	Xレジスタの内容をxxxx番地に転送する
stx:
        read@ reg_pc
        write adr(l)
        move.l @stx1,inc_reg_pc_ret
        jmp inc_reg_pc
@stx1:  data.l stx1
stx1:
        read@ reg_pc
        write adr(m)
        move.l @stx2,inc_reg_pc_ret
        jmp inc_reg_pc
@stx2:  data.l stx2
stx2:
        read@ reg_pc
        write adr(h)
        move.l @stx3,inc_reg_pc_ret
        jmp inc_reg_pc
@stx3:  data.l stx3
stx3:
        set@ adr
        read reg_x(l) 
        write@
        move.l @stx4,inc_adr_ret
        jmp inc_adr
@stx4:  data.l stx4
stx4:
        set@ adr
        read reg_x(m) 
        write@
        move.l @stx5,inc_adr_ret
        jmp inc_adr
@stx5:  data.l stx5
stx5:
        set@ adr
        read reg_x(h) 
        write@
        jmp fetch_ins


// lai xx; Aレジスタにxxの値をセットする
lai:
        read@ reg_pc
        write reg_a
        move.l @lai1,inc_reg_pc_ret
        jmp inc_reg_pc
@lai1:  data.l lai1
lai1:
        jmp fetch_ins


// ld_x;  AレジスタにXレジスタが示す番地の内容を転送する
ld_x:
        read@ reg_x
        write reg_a
        jmp fetch_ins


// sta_x;  Xレジスタが示す番地にAレジスタの内容を転送する
st_x:
        set@ reg_x
        read reg_a 
        write@
        jmp fetch_ins


// adc_x;   AレジスタにXレジスタが示す番地の内容をキャリー付き加算する
adc_x:
        move.b reg_cf,carry
        move.b reg_a,adc_in0
        read@ reg_x
        write adc_in1
        move.l @adc_x1,adc_ret
        jmp adc
@adc_x1: data.l adc_x1
adc_x1:
        move.b adc_out,reg_a
        move.b zero,reg_zf
        move.b carry,reg_cf
        jmp fetch_ins


// sbb_x;   AレジスタからXレジスタが示す番地の内容をボロー(キャリーの反転)付き減算する
sbb_x:
        move.b reg_cf,carry
        move.b reg_a,sbb_in0
        read@ reg_x
        write sbb_in1
        move.l @sbb_x1,sbb_ret
        jmp sbb
@sbb_x1: data.l sbb_x1
sbb_x1:
        move.b sbb_out,reg_a
        move.b zero,reg_zf
        move.b carry,reg_cf
        jmp fetch_ins


// and_x;  AレジスタにXレジスタが示す番地の内容をAND演算する(CFは0にする)
and_x:
        move.b reg_a,and_in0
        read@ reg_x
        write and_in1
        move.l @and_x1,and_ret
        jmp and
@and_x1: data.l and_x1
and_x1:
        move.b and_out,reg_a
        move.b zero,reg_zf
        move.b _000,reg_cf
        jmp fetch_ins


// or_x;   AレジスタにXレジスタが示す番地の内容をOR演算する(CFは1にする)
or_x:
        move.b reg_a,or_in0
        read@ reg_x
        write or_in1
        move.l @or_x1,or_ret
        jmp or
@or_x1: data.l or_x1
or_x1:
        move.b or_out,reg_a
        move.b zero,reg_zf
        move.b _001,reg_cf
        jmp fetch_ins


// ror_x;   Xレジスタが示す番地の内容のビットをCFを含めて右回転させる
ror_x:
        move.b reg_cf,carry
        read@ reg_x
        write  ror_in
        move.l @ror_x1,ror_ret
        jmp ror
@ror_x1: data.l ror_x1
ror_x1:
        move.b zero,reg_zf
        move.b carry,reg_cf
        set@ reg_x
        read ror_out
        write@
        jmp fetch_ins


// rolX;  Xレジスタが示す番地の内容のビットをCFを含めて左回転させる
rol_x:
        move.b reg_cf,carry
        read@ reg_x
        write  rol_in
        move.l @rol_x1,rol_ret
        jmp rol
@rol_x1: data.l rol_x1
rol_x1:
        move.b zero,reg_zf
        move.b carry,reg_cf
        set@ reg_x
        read rol_out
        write@
        jmp fetch_ins


// jmp xxxx;   xxxx番地にジャンプする
jmp:
        read@ reg_pc
        write adr(l)
        move.l @jmp1,inc_reg_pc_ret
        jmp inc_reg_pc
@jmp1:  data.l jmp1
jmp1:
        read@ reg_pc
        write adr(m)
        move.l @jmp2,inc_reg_pc_ret
        jmp inc_reg_pc
@jmp2:  data.l jmp2
jmp2:
        read@ reg_pc
        write adr(h)
        move.l @jmp3,inc_reg_pc_ret
        jmp inc_reg_pc
@jmp3:  data.l jmp3
jmp3:
        move.l adr,reg_pc
        jmp fetch_ins


// jz xxxx; ZFが１のときxxxx番地にジャンプする
jz:
        read@ reg_pc
        write adr(l)
        move.l @jz1,inc_reg_pc_ret
        jmp inc_reg_pc
@jz1:   data.l jz1
jz1:
        read@ reg_pc
        write adr(m)
        move.l @jz2,inc_reg_pc_ret
        jmp inc_reg_pc
@jz2:   data.l jz2
jz2:
        read@ reg_pc
        write adr(h)
        move.l @jz3,inc_reg_pc_ret
        jmp inc_reg_pc
@jz3:   data.l jz3
jz3:
        move.b reg_zf,if_cond
        move.l @jz4,if_then
        move.l @fetch_ins,if_else
        jmp if
@jz4:   data.l jz4
jz4:
        move.l adr,reg_pc
        jmp fetch_ins


// jnz xxxx; ZFが0のときxxxx番地にジャンプする
jnz:
        read@ reg_pc
        write adr(l)
        move.l @jnz1,inc_reg_pc_ret
        jmp inc_reg_pc
@jnz1:  data.l jnz1
jnz1:
        read@ reg_pc
        write adr(m)
        move.l @jnz2,inc_reg_pc_ret
        jmp inc_reg_pc
@jnz2:  data.l jnz2
jnz2:
        read@ reg_pc
        write adr(h)
        move.l @jnz3,inc_reg_pc_ret
        jmp inc_reg_pc
@jnz3:  data.l jnz3
jnz3:
       move.b reg_zf,if_cond
       move.l @fetch_ins,if_then
       move.l @jnz4,if_else
       jmp if
@jnz4: data.l jnz4
jnz4:
       move.l adr,reg_pc
       jmp fetch_ins


// jc xxxx;  CFが１のときxxxx番地にジャンプする
jc:
        read@ reg_pc
        write adr(l)
        move.l @jc1,inc_reg_pc_ret
        jmp inc_reg_pc
@jc1:   data.l jc1
jc1:
        read@ reg_pc
        write adr(m)
        move.l @jc2,inc_reg_pc_ret
        jmp inc_reg_pc
@jc2:   data.l jc2
jc2:
        read@ reg_pc
        write adr(h)
        move.l @jc3,inc_reg_pc_ret
        jmp inc_reg_pc
@jc3:   data.l jc3
jc3:
        move.b reg_cf,if_cond
        move.l @jc4,if_then
        move.l @fetch_ins,if_else
        jmp if
@jc4:   data.l jc4
jc4:
       move.l adr,reg_pc
       jmp fetch_ins


// jnc xxxx;	CFが0のときxxxx番地にジャンプする
jnc:
        read@ reg_pc
        write adr(l)
        move.l @jnc1,inc_reg_pc_ret
        jmp inc_reg_pc
@jnc1:  data.l jnc1
jnc1:
        read@ reg_pc
        write adr(m)
        move.l @jnc2,inc_reg_pc_ret
        jmp inc_reg_pc
@jnc2:  data.l jnc2
jnc2:
        read@ reg_pc
        write adr(h)
        move.l @jnc3,inc_reg_pc_ret
        jmp inc_reg_pc
@jnc3:  data.l jnc3
jnc3:
       move.b reg_cf,if_cond
       move.l @fetch_ins,if_then
       move.l @jnc4,if_else
       jmp if
@jnc4: data.l jnc4
jnc4:
       move.l adr,reg_pc
       jmp fetch_ins


// jmpx;  Xレジスタが示す番地にジャンプする
jmpx:
       move.l reg_x,reg_pc 
       jmp fetch_ins


// jmpy; Yレジスタが示す番地にジャンプする
jmpy:
       move.l reg_y,reg_pc 
       jmp fetch_ins


// lyi xxxx;  Yレジスタにxxxxの値をセットする
lyi:
        read@ reg_pc
        write reg_y(l)
        move.l @lyi1,inc_reg_pc_ret
        jmp inc_reg_pc
@lyi1:  data.l lyi1
lyi1:
        read@ reg_pc
        write reg_y(m)
        move.l @lyi2,inc_reg_pc_ret
        jmp inc_reg_pc
@lyi2:  data.l lyi2
lyi2:
        read@ reg_pc
        write reg_y(h)
        move.l @lyi3,inc_reg_pc_ret
        jmp inc_reg_pc
@lyi3:  data.l lyi3
lyi3:
        jmp fetch_ins
        

// ldy xxxx;	Yレジスタにxxxx番地の内容を転送する
ldy:
        read@ reg_pc
        write adr(l)
        move.l @ldy1,inc_reg_pc_ret
        jmp inc_reg_pc
@ldy1:  data.l ldy1
ldy1:
        read@ reg_pc
        write adr(m)
        move.l @ldy2,inc_reg_pc_ret
        jmp inc_reg_pc
@ldy2:  data.l ldy2
ldy2:
        read@ reg_pc
        write adr(h)
        move.l @ldy3,inc_reg_pc_ret
        jmp inc_reg_pc
@ldy3:  data.l ldy3
ldy3:
        read@ adr
        write reg_y(l)
        move.l @ldy4,inc_adr_ret
        jmp inc_adr
@ldy4:  data.l ldy4
ldy4:
        read@ adr
        write reg_y(m)
        move.l @ldy5,inc_adr_ret
        jmp inc_adr
@ldy5:  data.l ldy5
ldy5
        read@ adr
        write reg_y(h)
        jmp fetch_ins


// ady xxxx;  Yレジスタにxxxx番地の内容を加算する
ady:
        read@ reg_pc
        write adr(l)
        move.l @ady1,inc_reg_pc_ret
        jmp inc_reg_pc
@ady1:  data.l ady1
ady1:
        read@ reg_pc
        write adr(m)
        move.l @ady2,inc_reg_pc_ret
        jmp inc_reg_pc
@ady2:  data.l ady2
ady2:
        read@ reg_pc
        write adr(h)
        move.l @ady3,inc_reg_pc_ret
        jmp inc_reg_pc
@ady3:  data.l ady3
ady3:
        read@ adr
        write tmp(l)
        move.l @ady4,inc_adr_ret
        jmp inc_adr
@ady4:  data.l ady4
ady4:
        read@ adr
        write tmp(m)
        move.l @ady5,inc_adr_ret
        jmp inc_adr
@ady5:  data.l ady5
ady5:
        read@ adr
        write tmp(h)
        move.l reg_y,add_long_in0
        move.l tmp,add_long_in1
        move.l @ady6,add_long_ret
        jmp add_long
@ady6:  data.l ady6
ady6:
        move.l add_long_out,reg_y
        move.b add_long_zf,reg_zf
        move.b add_long_cf,reg_cf
        jmp fetch_ins


// sby xxxx; Yレジスタからxxxx番地の内容を減算する
sby:
        read@ reg_pc
        write adr(l)
        move.l @sby1,inc_reg_pc_ret
        jmp inc_reg_pc
@sby1:  data.l sby1
sby1:
        read@ reg_pc
        write adr(m)
        move.l @sby2,inc_reg_pc_ret
        jmp inc_reg_pc
@sby2:  data.l sby2
sby2:
        read@ reg_pc
        write adr(h)
        move.l @sby3,inc_reg_pc_ret
        jmp inc_reg_pc
@sby3:  data.l sby3
sby3:
        read@ adr
        write tmp(l)
        move.l @sby4,inc_adr_ret
        jmp inc_adr
@sby4:  data.l sby4
sby4:
        read@ adr
        write tmp(m)
        move.l @sby5,inc_adr_ret
        jmp inc_adr
@sby5:  data.l sby5
sby5:
        read@ adr
        write tmp(h)
        move.l reg_y,sub_long_in0
        move.l tmp,sub_long_in1
        move.l @sby6,sub_long_ret
        jmp sub_long
@sby6:  data.l sby6
sby6:
        move.l sub_long_out,reg_y
        move.b sub_long_zf,reg_zf
        move.b sub_long_cf,reg_cf
        jmp fetch_ins


// sty xxxx;  Yレジスタの内容をxxxx番地に転送する
sty:
        read@ reg_pc
        write adr(l)
        move.l @sty1,inc_reg_pc_ret
        jmp inc_reg_pc
@sty1:  data.l sty1
sty1:
        read@ reg_pc
        write adr(m)
        move.l @sty2,inc_reg_pc_ret
        jmp inc_reg_pc
@sty2:  data.l sty2
sty2:
        read@ reg_pc
        write adr(h)
        move.l @sty3,inc_reg_pc_ret
        jmp inc_reg_pc
@sty3:  data.l sty3
sty3:
        set@ adr
        read reg_y(l) 
        write@
        move.l @sty4,inc_adr_ret
        jmp inc_adr
@sty4:  data.l sty4
sty4:
        set@ adr
        read reg_y(m) 
        write@
        move.l @sty5,inc_adr_ret
        jmp inc_adr
@sty5:  data.l sty5
sty5:
        set@ adr
        read reg_y(h) 
        write@
        jmp fetch_ins


// ld_y;  AレジスタにYレジスタが示す番地の内容を転送する
ld_y:
        read@ reg_y
        write reg_a
        jmp fetch_ins


// st_y;  Yレジスタが示す番地にAレジスタの内容を転送する
st_y:
        set@ reg_y
        read reg_a 
        write@
        jmp fetch_ins

// adc_y;  AレジスタにYレジスタが示す番地の内容をキャリー付き加算する
adc_y:
        move.b reg_cf,carry
        move.b reg_a,adc_in0
        read@ reg_y
        write adc_in1
        move.l @adc_y1,adc_ret
        jmp adc
@adc_y1: data.l adc_y1
adc_y1:
        move.b adc_out,reg_a
        move.b zero,reg_zf
        move.b carry,reg_cf
        jmp fetch_ins


// sbb_y;  AレジスタからYレジスタが示す番地の内容をボロー(キャリーの反転)付き減算する
sbb_y:
        move.b reg_cf,carry
        move.b reg_a,sbb_in0
        read@ reg_y
        write sbb_in1
        move.l @sbb_y1,sbb_ret
        jmp sbb
@sbb_y1: data.l sbb_y1
sbb_y1:
        move.b sbb_out,reg_a
        move.b zero,reg_zf
        move.b carry,reg_cf
        jmp fetch_ins


// and_y;  AレジスタにYレジスタが示す番地の内容をAND演算する(CFは0にする)
and_y:
        move.b reg_a,and_in0
        read@ reg_y
        write and_in1
        move.l @and_y1,and_ret
        jmp and
@and_y1: data.l and_y1
and_y1:
        move.b and_out,reg_a
        move.b zero,reg_zf
        move.b _000,reg_cf
        jmp fetch_ins


// or_y;  AレジスタにYレジスタが示す番地の内容をOR演算する(CFは1にする)
or_y:
        move.b reg_a,or_in0
        read@ reg_y
        write or_in1
        move.l @or_y1,or_ret
        jmp or
@or_y1: data.l or_y1
or_y1:
        move.b or_out,reg_a
        move.b zero,reg_zf
        move.b _001,reg_cf
        jmp fetch_ins


// call xxxx;  PCレジスタの内容をスタックにプッシュしてxxxx番地にジャンプする
call:
        read@ reg_pc
        write adr(l)
        move.l @call1,inc_reg_pc_ret
        jmp inc_reg_pc
@call1: data.l call1
call1:
        read@ reg_pc
        write adr(m)
        move.l @call2,inc_reg_pc_ret
        jmp inc_reg_pc
@call2: data.l call2
call2:
        read@ reg_pc
        write adr(h)
        move.l @call3,inc_reg_pc_ret
        jmp inc_reg_pc
@call3: data.l call3
call3:
        move.l @call4,dec_reg_sp_ret
        jmp dec_reg_sp
@call4: data.l call4
call4:
        set@ reg_sp
        read reg_pc(h)
        write@
        move.l @call5,dec_reg_sp_ret
        jmp dec_reg_sp
@call5: data.l call5
call5:
        set@ reg_sp
        read reg_pc(m)
        write@
        move.l @call6,dec_reg_sp_ret
        jmp dec_reg_sp
@call6: data.l call6
call6:
        set@ reg_sp
        read reg_pc(l)
        write@
        move.l adr,reg_pc
        jmp fetch_ins


// ret; スタックにプッシュされたアドレスPCレジスタに復帰する
ret:
        read@ reg_sp
        write reg_pc(l)
        move.l @ret1,inc_reg_sp_ret
        jmp inc_reg_sp
@ret1:  data.l ret1
ret1:
        read@ reg_sp
        write reg_pc(m)
        move.l @ret2,inc_reg_sp_ret
        jmp inc_reg_sp
@ret2:  data.l ret2
ret2:
        read@ reg_sp
        write reg_pc(h)
        move.l @ret3,inc_reg_sp_ret
        jmp inc_reg_sp
@ret3:  data.l ret3
ret3:
        jmp fetch_ins


// push a;  Aレジスタの内容をスタックにプッシュする
push_a:
        set@ reg_sp
        read reg_a
        write@
        move.l @push_a1,dec_reg_sp_ret
        jmp dec_reg_sp
@push_a1: data.l push_a1
push_a1:
        jmp fetch_ins


// push x; Xレジスタの内容をスタックにプッシュする 
push_x:
        move.l @push_x1,dec_reg_sp_ret
        jmp dec_reg_sp
@push_x1: data.l push_x1
push_x1:
        set@ reg_sp
        read reg_x(h)
        write@
        move.l @push_x2,dec_reg_sp_ret
        jmp dec_reg_sp
@push_x2: data.l push_x2
push_x2:
        set@ reg_sp
        read reg_x(m)
        write@
        move.l @push_x3,dec_reg_sp_ret
        jmp dec_reg_sp
@push_x3: data.l push_x3
push_x3:
        set@ reg_sp
        read reg_x(l)
        write@
        jmp fetch_ins


// pop a; スタックからAレジスタの内容を復帰する 
pop_a:
        read@ reg_sp
        write reg_a
        move.l @pop_a1,inc_reg_sp_ret
        jmp inc_reg_sp
@pop_a1: data.l pop_a1
pop_a1:
        jmp fetch_ins

// pop x;  スタックからXレジスタの内容を復帰する 
pop_x:
        read@ reg_sp
        write reg_x(l)
        move.l @pop_x1,inc_reg_sp_ret
        jmp inc_reg_sp
@pop_x1: data.l pop_x1
pop_x1:
        read@ reg_sp
        write reg_x(m)
        move.l @pop_x2,inc_reg_sp_ret
        jmp inc_reg_sp
@pop_x2: data.l pop_x2
pop_x2:
        read@ reg_sp
        write reg_x(h)
        move.l @pop_x3,inc_reg_sp_ret
        jmp inc_reg_sp
@pop_x3: data.l pop_x3
pop_x3:
        jmp fetch_ins


// txs; Xレジスタスの内容をスタックポインタに転送する 
txs:
        move.l reg_x,reg_sp
        jmp fetch_ins


// tsx; スタックポインタの内容をXレジスタスに転送する 
tsx:
        move.l reg_sp,reg_x
        jmp fetch_ins


// incx; Xレジスタを+1する
incx:
        move.l reg_x,inc_long_in
        move.l @incx1,inc_long_ret
        jmp inc_long
@incx1: data.l incx1
incx1:
        move.l inc_long_out,reg_x
        jmp fetch_ins


// decx;  Xレジスタを-1する
decx:
        move.l reg_x,dec_long_in
        move.l @decx1,dec_long_ret
        jmp dec_long
@decx1: data.l decx1
decx1:
        move.l dec_long_out,reg_x
        jmp fetch_ins


// incy;  Yレジスタを+1する
incy:
        move.l reg_y,inc_long_in
        move.l @incy1,inc_long_ret
        jmp inc_long
@incy1: data.l incy1
incy1:
        move.l inc_long_out,reg_y
        jmp fetch_ins


// decy;  Yレジスタを-1する
decy:
        move.l reg_y,dec_long_in
        move.l @decy1,dec_long_ret
        jmp dec_long
@decy1: data.l decy1
decy1:
        move.l dec_long_out,reg_y
        jmp fetch_ins


// ror_y;  Yレジスタが示す番地の内容のビットをCFを含めて右回転させる
ror_y:
        move.b reg_cf,carry
        read@ reg_y
        write  ror_in
        move.l @ror_y1,ror_ret
        jmp ror
@ror_y1: data.l ror_y1
ror_y1:
        move.b zero,reg_zf
        move.b carry,reg_cf
        set@ reg_y
        read ror_out
        write@
        jmp fetch_ins


// rol_y;  Yレジスタが示す番地の内容のビットをCFを含めて左回転させる
rol_y:
        move.b reg_cf,carry
        read@  reg_y
        write  rol_in
        move.l @rol_y1,rol_ret
        jmp rol
@rol_y1: data.l rol_y1
rol_y1:
        move.b zero,reg_zf
        move.b carry,reg_cf
        set@ reg_y
        read rol_out
        write@
        jmp fetch_ins


// サブルーチン

// pcレジスタを+1する
inc_reg_pc_ret: data.l 0
inc_reg_pc:
        move.l reg_pc,inc_long_in
        move.l @inc_reg_pc1,inc_long_ret
        jmp inc_long
@inc_reg_pc1: data.l inc_reg_pc1
inc_reg_pc1:
        move.l inc_long_out,reg_pc
        jmp@ inc_reg_pc_ret


// spレジスタを+1する
inc_reg_sp_ret: data.l 0
inc_reg_sp:
        move.l reg_sp,inc_long_in
        move.l @inc_reg_sp1,inc_long_ret
        jmp inc_long
@inc_reg_sp1: data.l inc_reg_sp1
inc_reg_sp1:
        move.l inc_long_out,reg_sp
        jmp@ inc_reg_sp_ret


// spレジスタを-1する
dec_reg_sp_ret: data.l 0
dec_reg_sp:
        move.l reg_sp,dec_long_in
        move.l @dec_reg_sp1,dec_long_ret
        jmp dec_long
@dec_reg_sp1: data.l dec_reg_sp1
dec_reg_sp1:
        move.l dec_long_out,reg_sp
        jmp@ dec_reg_sp_ret


// adrを+1する
inc_adr_ret: data.l 0
inc_adr:
        move.l adr,inc_long_in
        move.l @inc_adr1,inc_long_ret
        jmp inc_long
@inc_adr1: data.l inc_adr1
inc_adr1:
        move.l inc_long_out,adr
        jmp@ inc_adr_ret


// ロングデータを+1する
inc_long_in:  data.l 0
inc_long_out: data.l 0
inc_long_ret: data.l 0
inc_long_zf:  data.b 0
inc_long:
  move.b inc_long_in(l),inc_in
  move.l @inc_long1,inc_ret
  jmp inc
@inc_long1: data.l inc_long1
inc_long1:
  move.b zero,zero1
  move.b inc_out,inc_long_out(l)
  move.b inc_long_in(m),add_carry_in
  move.l @inc_long2,add_carry_ret
  jmp add_carry
@inc_long2: data.l inc_long2
inc_long2:
  move.b zero,zero2
  move.b add_carry_out,inc_long_out(m)
  move.b inc_long_in(h),add_carry_in
  move.l @inc_long3,add_carry_ret
  jmp add_carry
@inc_long3: data.l inc_long3
inc_long3:
  move.b add_carry_out,inc_long_out(h)
  move.b zero,and_in0
  move.b zero1,and_in1
  move.l @inc_long4,and_ret
  jmp and
@inc_long4: data.l inc_long4
inc_long4:
  move.b and_out,and_in0
  move.b zero2,and_in1
  move.l @inc_long5,and_ret
  jmp and
@inc_long5: data.l inc_long5
inc_long5:
  move.b and_out,inc_long_zf
  jmp@ inc_long_ret


// ロングデータを-1する
dec_long_in:  data.l 0
dec_long_out: data.l 0
dec_long_ret: data.l 0
dec_long_zf:  data.b 0
dec_long:
  move.b dec_long_in(l),dec_in
  move.l @dec_long1,dec_ret
  jmp dec
@dec_long1: data.l dec_long1
dec_long1:
  move.b zero,zero1
  move.b dec_out,dec_long_out(l)
  move.b dec_long_in(m),sub_carry_in
  move.l @dec_long2,sub_carry_ret
  jmp sub_carry
@dec_long2: data.l dec_long2
dec_long2:
  move.b zero,zero2
  move.b sub_carry_out,dec_long_out(m)
  move.b dec_long_in(h),sub_carry_in
  move.l @dec_long3,sub_carry_ret
  jmp sub_carry
@dec_long3: data.l dec_long3
dec_long3:
  move.b sub_carry_out,dec_long_out(h)
  move.b zero,and_in0
  move.b zero1,and_in1
  move.l @dec_long4,and_ret
  jmp and
@dec_long4: data.l dec_long4
dec_long4:
  move.b and_out,and_in0
  move.b zero2,and_in1
  move.l @dec_long5,and_ret
  jmp and
@dec_long5: data.l dec_long5
dec_long5:
  move.b and_out,dec_long_zf
  jmp@ dec_long_ret


// ロングデータの加算
add_long_in0: data.l 0
add_long_in1: data.l 0
add_long_out: data.l 0
add_long_ret: data.l 0
add_long_cf:  data.b 0
add_long_zf:  data.b 0
add_long:
  move.b _000,carry
  move.b add_long_in0(l),adc_in0
  move.b add_long_in1(l),adc_in1
  move.l @add_long1,adc_ret
  jmp adc
@add_long1: data.l add_long1
add_long1:
  move.b zero,zero1
  move.b adc_out,add_long_out(l)
  move.b add_long_in0(m),adc_in0
  move.b add_long_in1(m),adc_in1
  move.l @add_long2,adc_ret
  jmp adc
@add_long2: data.l add_long2
add_long2:
  move.b zero,zero2
  move.b adc_out,add_long_out(m)
  move.b add_long_in0(h),adc_in0
  move.b add_long_in1(h),adc_in1
  move.l @add_long3,adc_ret
  jmp adc
@add_long3: data.l add_long3
add_long3:
  move.b adc_out,add_long_out(h)
  move.b carry,add_long_cf
  move.b zero,and_in0
  move.b zero1,and_in1
  move.l @add_long4,and_ret
  jmp and
@add_long4: data.l add_long4
add_long4:
  move.b and_out,and_in0
  move.b zero2,and_in1
  move.l @add_long5,and_ret
  jmp and
@add_long5: data.l add_long5
add_long5:
  move.b and_out,add_long_zf
  jmp@ add_long_ret


// ロングデータの減算
sub_long_in0: data.l 0
sub_long_in1: data.l 0
sub_long_out: data.l 0
sub_long_ret: data.l 0
sub_long_cf:  data.b 0
sub_long_zf:  data.b 0
sub_long:
  move.b _001,carry
  move.b sub_long_in0(l),sbb_in0
  move.b sub_long_in1(l),sbb_in1
  move.l @sub_long1,sbb_ret
  jmp sbb
@sub_long1: data.l sub_long1
sub_long1:
  move.b zero,zero1
  move.b sbb_out,sub_long_out(l)
  move.b sub_long_in0(m),sbb_in0
  move.b sub_long_in1(m),sbb_in1
  move.l @sub_long2,sbb_ret
  jmp sbb
@sub_long2: data.l sub_long2
sub_long2:
  move.b zero,zero2
  move.b sbb_out,sub_long_out(m)
  move.b sub_long_in0(h),sbb_in0
  move.b sub_long_in1(h),sbb_in1
  move.l @sub_long3,sbb_ret
  jmp sbb
@sub_long3: data.l sub_long3
sub_long3:
  move.b sbb_out,sub_long_out(h)
  move.b carry,sub_long_cf
  move.b zero,and_in0
  move.b zero1,and_in1
  move.l @sub_long4,and_ret
  jmp and
@sub_long4: data.l sub_long4
sub_long4:
  move.b and_out,and_in0
  move.b zero2,and_in1
  move.l @sub_long5,and_ret
  jmp and
@sub_long5: data.l sub_long5
sub_long5:
  move.b and_out,sub_long_zf
  jmp@ sub_long_ret


// キャリー付き加算
adc_in0:          data.b 0
adc_in1:          data.b 0
adc_out:          data.b 0
adc_ret:          data.l 0
@add_table:       data.l add_table
@add_table_carry: data.l add_table_carry
adc:
  move.b adc_in0,add_carry_in
  move.l @adc1,add_carry_ret
  jmp add_carry
@adc1: data.l adc1
adc1:
  read @add_table(h)
  set(h)
  read add_carry_out
  set(m)
  read adc_in1
  set(l)
  read@
  write adc_out  
  read @add_table_carry(h)
  set(h)
  read add_carry_out
  set(m)
  read adc_in1
  set(l)
  read@
  write or_in0
  move.b carry,or_in1
  move.l @adc2,or_ret
  jmp or
@adc2: data.l adc2
adc2:
  move.b or_out,carry
  move.b adc_out,check_zero_in
  move.l @adc3,check_zero_ret
  jmp check_zero
@adc3: data.l adc3
adc3:
  jmp@ adc_ret


// キャリー付き減算
sbb_in0:          data.b 0
sbb_in1:          data.b 0
sbb_out:          data.b 0
sbb_ret:          data.l 0
@sub_table:       data.l sub_table
@sub_table_carry: data.l sub_table_carry
sbb:
  move.b sbb_in0,sub_carry_in
  move.l @sbb1,sub_carry_ret
  jmp sub_carry
@sbb1: data.l sbb1
sbb1:
  read @sub_table(h)
  set(h)
  read sub_carry_out
  set(m)
  read sbb_in1
  set(l)
  read@
  write sbb_out  
  read @sub_table_carry(h)
  set(h)
  read sub_carry_out
  set(m)
  read sbb_in1
  set(l)
  read@
  write and_in0
  move.b carry,and_in1
  move.l @sbb2,and_ret
  jmp and
@sbb2: data.l sbb2
sbb2:
  move.b and_out,carry
  move.b sbb_out,check_zero_in
  move.l @sbb3,check_zero_ret
  jmp check_zero
@sbb3: data.l sbb3
sbb3:
  jmp@ sbb_ret


// AND演算
and_in0:          data.b 0
and_in1:          data.b 0
and_out:          data.b 0
and_ret:          data.l 0
@and_table:       data.l and_table
and:
  read @and_table(h)
  set(h)
  read and_in0
  set(m)
  read and_in1
  set(l)
  read@
  write and_out  
  move.b and_out,check_zero_in
  move.l @and1,check_zero_ret
  jmp check_zero
@and1: data.l and1
and1:
  jmp@ and_ret


// OR演算
or_in0:          data.b 0
or_in1:          data.b 0
or_out:          data.b 0
or_ret:          data.l 0
@or_table:       data.l or_table
or:
  read @or_table(h)
  set(h)
  read or_in0
  set(m)
  read or_in1
  set(l)
  read@
  write or_out  
  move.b or_out,check_zero_in
  move.l @or1,check_zero_ret
  jmp check_zero
@or1: data.l or1
or1:
  jmp@ or_ret


// 右まわり
ror_in:           data.b 0
ror_out:          data.b 0
ror_ret:          data.l 0
@ror_table:       data.l ror_table
@ror_table_carry: data.l ror_table_carry
ror:
  read @ror_table(h)
  set(h)
  read @ror_table(m)
  set(m)
  read ror_in
  set(l)
  read@
  write ror_out
  move.b carry,if_cond // carryがあるときは0x80を足す
  move.l @ror1,if_then
  move.l @ror3,if_else
  jmp if
@ror1: data.l ror1
@ror3: data.l ror3
ror1:
  move.b _000,carry
  move.b ror_out,adc_in0
  move.b _0x80,adc_in1
  move.l @ror2,adc_ret
  jmp adc
@ror2: data.l ror2
ror2:
  move.b adc_out,ror_out
ror3:
  read @ror_table_carry(h)
  set(h)
  read @ror_table_carry(m)
  set(m)
  read ror_in
  set(l)
  read@
  write carry
  move.b ror_out,check_zero_in
  move.l @ror4,check_zero_ret
  jmp check_zero
@ror4: data.l ror4
ror4:
  jmp@ ror_ret
  

// 左まわり
rol_in:           data.b 0
rol_out:          data.b 0
rol_ret:          data.l 0
@rol_table:       data.l rol_table
@rol_table_carry: data.l rol_table_carry
rol:
  read @rol_table(h)
  set(h)
  read @rol_table(m)
  set(m)
  read rol_in
  set(l)
  read@
  write add_carry_in  // carryがあるときは1を足す
  move.l @rol1,add_carry_ret
  jmp add_carry
@rol1: data.l rol1
rol1:
  move.b add_carry_out,rol_out
  read @rol_table_carry(h)
  set(h)
  read @rol_table_carry(m)
  set(m)
  read rol_in
  set(l)
  read@
  write carry
  move.b rol_out,check_zero_in
  move.l @rol2,check_zero_ret
  jmp check_zero
@rol2: data.l rol2
rol2:
  jmp@ rol_ret


// carryが１なら+1する 
add_carry_in:  data.b 0
add_carry_out: data.b 0
add_carry_ret: data.l 0
add_carry:
  move.b add_carry_in,add_carry_out
  move.b carry,if_cond
  move.l @add_carry1,if_then
  move.l @add_carry3,if_else
  jmp if
@add_carry1: data.l add_carry1
@add_carry3: data.l add_carry3
add_carry1:
  move.b add_carry_in,inc_in
  move.l @add_carry2,inc_ret
  jmp inc
@add_carry2: data.l add_carry2
add_carry2:
  move.b inc_out,add_carry_out
add_carry3:
  move.b add_carry_out,check_zero_in
  move.l @add_carry4,check_zero_ret
  jmp check_zero
@add_carry4: data.l add_carry4
add_carry4:
  jmp@ add_carry_ret


// carryが0なら-1する 
sub_carry_in:  data.b 0
sub_carry_out: data.b 0
sub_carry_ret: data.l 0
sub_carry:
  move.b sub_carry_in,sub_carry_out
  move.b carry,if_cond
  move.l @sub_carry3,if_then
  move.l @sub_carry1,if_else
  jmp if
@sub_carry1: data.l sub_carry1
@sub_carry3: data.l sub_carry3
sub_carry1:
  move.b sub_carry_in,dec_in
  move.l @sub_carry2,dec_ret
  jmp dec
@sub_carry2: data.l sub_carry2
sub_carry2:
  move.b dec_out,sub_carry_out
sub_carry3:
  move.b sub_carry_out,check_zero_in
  move.l @sub_carry4,check_zero_ret
  jmp check_zero
@sub_carry4: data.l sub_carry4
sub_carry4:
  jmp@ sub_carry_ret


// バイトデータを+1する
inc_in:           data.b 0
inc_out:          data.b 0
inc_ret:          data.l 0
@inc_table:       data.l inc_table
@inc_table_carry: data.l inc_table_carry
inc:
  read @inc_table(h)
  set(h)
  read @inc_table(m)
  set(m)
  read inc_in
  set(l)
  read@
  write inc_out  
  read @inc_table_carry(h)
  set(h)
  read @inc_table_carry(m)
  set(m)
  read inc_in
  set(l)
  read@
  write carry
  move.b inc_out,check_zero_in
  move.l @inc1,check_zero_ret
  jmp check_zero
@inc1: data.l inc1
inc1:
  jmp@ inc_ret
  

// バイトデータを-1する
dec_in:           data.b 0
dec_out:          data.b 0
dec_ret:          data.l 0
@dec_table:       data.l dec_table
@dec_table_carry: data.l dec_table_carry
dec:
  read @dec_table(h)
  set(h)
  read @dec_table(m)
  set(m)
  read dec_in
  set(l)
  read@
  write dec_out  
  read @dec_table_carry(h)
  set(h)
  read @dec_table_carry(m)
  set(m)
  read dec_in
  set(l)
  read@
  write carry
  move.b dec_out,check_zero_in
  move.l @dec1,check_zero_ret
  jmp check_zero
@dec1: data.l dec1
dec1:
  jmp@ dec_ret


// 0かどうか調べる
check_zero_in:  data.b 0
check_zero_ret: data.l 0
@check_zero_table: data.l check_zero_table
check_zero:
  read @check_zero_table(h)
  set(h)
  read @check_zero_table(m)
  set(m)
  read check_zero_in
  set(l)
  read@
  write zero  
  jmp@ check_zero_ret


// レジスタ変数
ins:     data.b 0
ins_adr: data.l 0
reg_pc:  data.l 0
reg_sp:  data.l 0
reg_x:   data.l 0
reg_y:   data.l 0
reg_a:   data.b 0
reg_zf:  data.b 0
reg_cf:  data.b 0
adr:     data.l 0
tmp:     data.l 0
carry:   data.b 0
carry1:  data.b 0
zero:    data.b 0
zero1:   data.b 0
zero2:   data.b 0

// 定数テーブル
_000:  data.l 0
_001:  data.l 1
_0x80: data.b 0x80


// 条件分岐
 .page  // 256バイト境界
if_table:
 data.b if0.l
 data.b if1.l

if_cond:   data.b 0
if_then:   data.l 0
if_else:   data.l 0
@if_table: data.l if_table
if:
  read @if_table(h)
  set(h)
  read @if_table(m)  
  set(m)
  read if_cond
  set(l)
  read@
  set(l)
  jmp@
if0:
  jmp@ if_else
if1:
  jmp@ if_then


// 命令実行用ジャンプテーブル下位アドレス
 .page  // 256バイト境界
ins_table_l:
  data.b hlt.l
  data.b lxi.l
  data.b ldx.l
  data.b adx.l
  data.b sbx.l
  data.b stx.l
  data.b lai.l
  data.b ld_x.l
  data.b st_x.l
  data.b adc_x.l
  data.b sbb_x.l
  data.b and_x.l
  data.b or_x.l
  data.b ror_x.l
  data.b rol_x.l
  data.b jmp.l
  data.b jz.l
  data.b jnz.l
  data.b jc.l
  data.b jnc.l
  data.b jmpx.l
  data.b jmpy.l
  data.b lyi.l
  data.b ldy.l
  data.b ady.l
  data.b sby.l
  data.b sty.l
  data.b ld_y.l
  data.b st_y.l
  data.b adc_y.l
  data.b sbb_y.l
  data.b and_y.l
  data.b or_y.l
  data.b call.l
  data.b ret.l
  data.b push_a.l
  data.b push_x.l
  data.b pop_a.l
  data.b pop_x.l
  data.b txs.l
  data.b tsx.l
  data.b incx.l
  data.b decx.l
  data.b incy.l
  data.b decy.l
  data.b ror_y.l
  data.b rol_y.l


// 命令実行用ジャンプテーブル中位アドレス
 .page  // 256バイト境界
ins_table_m:
  data.b hlt.m
  data.b lxi.m
  data.b ldx.m
  data.b adx.m
  data.b sbx.m
  data.b stx.m
  data.b lai.m
  data.b ld_x.m
  data.b st_x.m
  data.b adc_x.m
  data.b sbb_x.m
  data.b and_x.m
  data.b or_x.m
  data.b ror_x.m
  data.b rol_x.m
  data.b jmp.m
  data.b jz.m
  data.b jnz.m
  data.b jc.m
  data.b jnc.m
  data.b jmpx.m
  data.b jmpy.m
  data.b lyi.m
  data.b ldy.m
  data.b ady.m
  data.b sby.m
  data.b sty.m
  data.b ld_y.m
  data.b st_y.m
  data.b adc_y.m
  data.b sbb_y.m
  data.b and_y.m
  data.b or_y.m
  data.b call.m
  data.b ret.m
  data.b push_a.m
  data.b push_x.m
  data.b pop_a.m
  data.b pop_x.m
  data.b txs.m
  data.b tsx.m
  data.b incx.m
  data.b decx.m
  data.b incy.m
  data.b decy.m
  data.b ror_y.m
  data.b rol_y.m


// 命令実行用ジャンプテーブル上位アドレス
 .page  // 256バイト境界
ins_table_h:
  data.b hlt.h
  data.b lxi.h
  data.b ldx.h
  data.b adx.h
  data.b sbx.h
  data.b stx.h
  data.b lai.h
  data.b ld_x.h
  data.b st_x.h
  data.b adc_x.h
  data.b sbb_x.h
  data.b and_x.h
  data.b or_x.h
  data.b ror_x.h
  data.b rol_x.h
  data.b jmp.h
  data.b jz.h
  data.b jnz.h
  data.b jc.h
  data.b jnc.h
  data.b jmpx.h
  data.b jmpy.h
  data.b lyi.h
  data.b ldy.h
  data.b ady.h
  data.b sby.h
  data.b sty.h
  data.b ld_y.h
  data.b st_y.h
  data.b adc_y.h
  data.b sbb_y.h
  data.b and_y.h
  data.b or_y.h
  data.b call.h
  data.b ret.h
  data.b push_a.h
  data.b push_x.h
  data.b pop_a.h
  data.b pop_x.h
  data.b txs.h
  data.b tsx.h
  data.b incx.h
  data.b decx.h
  data.b incy.h
  data.b decy.h
  data.b ror_y.h
  data.b rol_y.h


// 演算テーブル

// 仮想マシンの実行開始アドレス
vm_start:
