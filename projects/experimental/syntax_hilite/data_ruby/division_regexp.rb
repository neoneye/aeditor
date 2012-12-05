# ambiguity between regexp and division operator

# division
res = 4 / 5
res = 3.3 / 4.4
res = x / y
res = x/y
res = values[3] / 5
res = meth(999) / val
res = 3.xx / 99
# /

# regexp
re = /abc/
str.match(/abc/)
p(/abc/)
p(/abc/, /abx/)

val = scan(/reg
exp/x)
