// ファイルコピープログラム
 count i#
 char  infile$(FILSIZ),outfile$(FILSIZ)
 int  c#

main:
 if argc#<3 then "ILLEAGAL ARGUMENT", prints nl end
 argv#(1), infile, ropen
 if infile#=ERROR then "FILE NOT FOUND", prints nl end
 argv#(2), outfile, wopen
loop:
 infile, getc c#=
 if c#=EOF goto ext
 c#, outfile, putc
 goto loop
ext:
 infile,  rclose
 outfile, wclose
 end
