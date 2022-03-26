
' メインコントロールプログラム
' ダウンロードやステップ実行をおこなう
wt=100
rs=100

' メニューを表示
@start_menu:
cls
gosub @reset_cpu
print "Menu"
print "0:Download"
print "1:Single Step Run"
print "2:exit"
print "input No";:input c
if c=0 then  @download
if c=1 then  @single_step_run
if c<>2 then @start_menu
end


' ダウンロード
@download:
  input "Start Address",sad
  input "End Address",ead
  if ead<sad then @start_menu
  for adrs=sad to ead
  gosub @write_memory
  next
  goto @start_menu


' シングルステップ実行
@single_step_run:
  print "s(ingle step), r(eset), q(uit) ";:c$=input$(1):print
  if c$="s" then print "single step":gosub @exec_single_step:goto @single_step_run
  if c$="r" then print "reset":gosub @reset_cpu:goto @single_step_run
  if c$="q" then @start_menu
  goto @single_step_run


' 1ワードメモリに書き込む
@write_memory:

  sdisable 0

  ' シフトレジスタに値をセットする
  vv=mem_c(adrs):digit=&h80:   gosub @push_shift_register
  vv=mem_a(adrs):digit=&h20000:gosub @push_shift_register
  vv=mem_r(adrs):digit=&h20000:gosub @push_shift_register
  vv=mem_d(adrs):digit=&h20:   gosub @push_shift_register
  vv=adrs:       digit=&h20000:gosub @push_shift_register

  ' 最後に1回シフトパルスを入れる
  sdata 0
  sclk 0
  wait wt
  sclk 1
  wait wt

  print "ad:";adrs;", c:";mem_c(adrs);", a:";mem_a(adrs);", r:";mem_r(adrs);", d:";mem_d(adrs);:input t$

  ' メモリに書き込む
  swrite 0
  wait wt
  swrite 1

  sdisable 1
  return


' プログラムロード用シフトレジスタに値をセットする
@push_shift_register:
    sdata (vv and digit)<>0
    sclk 0
    wait wt
    sclk 1
    wait wt
    digit=digit/2
  if inkey$="s" then c$=input$(1)
  if digit>=1 then @push_shift_register
  return


' CPUをリセットして停止状態にする
@reset_cpu:
  rd_port 1
  wr_port 1
  cpu_reset 1
  cpu_halt 1
  osc 1
  osc_enable 0
  sdisable 1
  sclk 1
  sdata 0
  swrite 1
  wait rs
  cpu_reset 0
  cpu_halt 0
  wait wt
  osc 0
  wait wt
  osc 1
  cpu_halt 1
  wait wt
  return


' シングルステップ実行
@exec_single_step:

  ' 原クロックを４分周して読み出し/書き込み信号を作っているので
  ' ４回パルスを出す
  wait();
  osc 0
  wait wt
  osc 1
  wait wt
  osc 0
  wait wt
  osc 1
  wait wt
  osc 0
  wait wt
  osc 1
  wait wt
  osc 0
  wait wt
  osc 1
  wait wt

  return
