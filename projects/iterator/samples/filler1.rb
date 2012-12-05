require 'iterator'

ary = (0..9).to_a
i1 = ary.create_iterator.next(3)
i2 = ary.create_iterator_end.prev(3)
Iterator::Algorithm.fill(i1, i2, 666)
p ary   #=>  [0, 1, 2, 666, 666, 666, 666, 7, 8, 9]
i1.close
i2.close
