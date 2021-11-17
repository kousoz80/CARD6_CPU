// ディレクトリ表示プログラム
main:
  int   i#
  char  fp$(FILSIZ)

  TOPSEC, i#=
loop:
  fp+BUFF,  i#, _reads
  fp+FNAME, prints nl
  fp#(NEXT_FIL), i#=
  if i#<>NONSEC goto loop
  end
