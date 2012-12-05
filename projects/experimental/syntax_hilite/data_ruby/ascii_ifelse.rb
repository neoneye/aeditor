# ambiguity between ?x  and cond ? ifval : elseval

# ascii
x = ?x
b = ?a + 1
az = ?a..?z
p(?a)


# ifelse
p((0==0)?b:b)
p((x == 0) ? 'zero' : 'non-zero')
p((x == 0) ? 'zero' : 'non-zero')
val = (true)?x:b
