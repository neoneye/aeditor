data = "hello world".split(//)

i1 = data.ibegin + 3
i2 = data.iend - 3

p (i1..i2).to_a   #=> "lo wo"
