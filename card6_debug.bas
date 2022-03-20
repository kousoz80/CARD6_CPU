
' メインコントロールプログラム
' ダウンロードやステップ実行をおこなう

' メニューを表示
@start_menu:
cls
gosub @reset_cpu
print "Menu"
print "0:Download"
print "1:Single Step Run"
print "input No";:input c
if c=0 then @download
if c=1 then @single_step_run
goto @start_menu
end


' ダウンロード
@download:
  input "Start Address",sad
  input "End Address",ead
  if ead<sad then @start_menu
  for adrs=sad to ead
  print "address:";hex$(adrs)
  gosub @write_memory
  next
  goto @stat_menu


' シングルステップ実行
@single_step_run:
  print "s(ingle step), r(eset), q(uit) ";:c$=input$(1):print
  if c$="s" then print "single step":gosub @exec_single_step:goto @single_step_run
  if c$="r" then print "reset":gosub @reset_cpu:goto @single_step_run
  if c$="q" then @start_menu
  goto @single_step_run


' 1ワードメモリに書き込む
@write_memory:

  ' シフトレジスタに値をセットする
  val=adrs:       digit=&h20000:gosub @push_shift_register
  val=mem_c(adrs):digit=&h80:   gosub @push_shift_register
  val=mem_a(adrs):digit=&h20000:gosub @push_shift_register
  val=mem_r(adrs):digit=&h20000:gosub @push_shift_register
  val=mem_d(adrs):digit=&h80:   gosub @push_shift_register

  ' メモリに書き込む
  serial_disable 0
  wait wt
  serial_write 0
  wait wt
  serial_write 1
  wait wt
  serial_disable 1
  return


' プログラムロード用シフトレジスタに値をセットする
@push_shift_register:
    serial_data (val and digit)<>0
    serial_clk 0
    wait wt
    serial_clk 1
    wait wt
    digit=digit/2
  if digit>=1 goto @push_shift_register
  return


' CPUをリセットして停止状態にする
@reset_cpu:
  read_port 1
  write_port 1
  cpu_reset 1
  cpu_halt 1
  cpu_clk 1
  osc_enable 0
  serial_disable 1
  serial_clk 1
  serial_data 0
  serial_write 1
  wait rs
  cpu_halt 1
  wait wt
  cpu_clk 0
  wait wt
  cpu_clk 1
  cpu_reset 0
  return


' シングルステップ実行
@exec_single_step:
  cpu_halt 1
  osc_enable 0
  wait wt
  cpu_halt 0

  ' 原クロックを４分周して読み出し/書き込み信号を作っているので
  ' ４回パルスを出す
  wait();
  cpu_clk 0
  wait wt
  cpu_clk 1
  wait wt
  cpu_clk 0
  wait wt
  cpu_clk 1
  wait wt
  cpu_clk 0
  wait wt
  cpu_clk 1
  wait wt
  cpu_clk 0
  wait wt
  cpu_clk 1
  wait wt

  return
