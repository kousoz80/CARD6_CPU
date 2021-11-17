// dump file
 count i#,j#,k#
 char  fp$(FILSIZ),buf$(16)
 char  cc$
 int   fname#
main:
 if argc#<>2 then end
 argv#(1), fname#=
 fname#, fp, ropen
loop:
 if fp#=ERROR then end
 fp+BUFF, fp#, _reads
 for i#=0 to 255
 i#, 16, mod j#=
 if j#<>0 goto skip2
   fp#, hex prints
   ":", prints
   if i#=j# then "0", prints
   i#, j#, - hex prints
   " ", prints
 skip2:
 SPACE, putchar
 fp+BUFF$(i#), cc$=
 hex j#= strlen k#=
 if k#=1 then '0', putchar
 j#, prints
 i#, 16, mod j#=
 if  cc$>'Z' then '.', cc$=
 cc$, buf$(j#)=
 if j#<>15 goto skip
 " ", prints
 for k#=0 to 15
 buf$(k#), putchar
 next k#
 nl
skip:
 next i#
 fp#(NEXT_SEC), fp#=
 goto loop
 