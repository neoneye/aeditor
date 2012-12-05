require 'iterator'

# concatenate following 3 strings together, so they
# appear to be _one_ string.
ary1 = "Hell".split(//).to_a
ary2 = "O wO".split(//).to_a
ary3 = "rld!".split(//).to_a
i1 = ary1.create_iterator
i2 = ary2.create_iterator
i3 = ary3.create_iterator
iterator = Iterator::Concat.new([i1, i2, i3])
ary2.map!{|i|i.swapcase}
puts iterator.to_a.join  #-> Hello World!
