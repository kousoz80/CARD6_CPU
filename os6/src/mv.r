// ファイル名変更プログラム
main:
 int f#

 if argc#<>3 then "ILLEAGAL ARGUMENT", prints nl end
 argv#(1), argv#(2), mv f#=
 if f#=ERROR then "FILE NOT FOUND OR EXIST SAME FILE NAME", prints nl
 end
