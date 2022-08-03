for y=-12 to 12
for x=-39 to 39
ca=x*0.0458
cb=y*0.08333
a=ca
b=cb

for i=0 to 15
t=a*a-b*b+ca
b=2*a*b+cb
a=t
if a*a+b*b>4 then @l200
next i

print " ";
goto @l210

@l200
if i>9 then i=i+7
print chr$(48+i);

@l210
next x
print
next y
