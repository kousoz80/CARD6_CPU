// CARD6実機のデバッグテストコード


 org 0x000000
_start:
      read  xxx
      write yyy
loop:
      jmp loop

xxx:    data 0x12
yyy:    data 0
