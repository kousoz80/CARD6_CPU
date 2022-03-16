cls
t=1
serial_disable 0
for i=0 to 70
serial_data t
serial_clk 0
wait 100
serial_clk 1
wait 100
t=1-t
next
wait 1000
serial_disable 1
serial_data 0
