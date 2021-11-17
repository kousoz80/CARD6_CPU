// ファイル表示プログラム

 int cc#
 char fp$(FILSIZ)

main:
 if argc#<>2 then "ILLEAGAN ARGUMENT", prints nl end
 argv#(1), fp, ropen
 if fp#=ERROR then "FILE NOT FOUND", prints nl end
loop:
 fp, getc cc$=
 if cc$=CNULL then fp, rclose end
 cc$, putchar
 goto loop
