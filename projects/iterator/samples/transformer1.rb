require 'iterator'

input = "heLLo woRLD".split(//)
i1 = input.create_iterator
i2 = input.create_iterator_end
dest = []
result = dest.create_iterator_end
Iterator::Algorithm.transform(i1, i2, result) {|val| val.upcase}
p dest.join   #=>  "HELLO WORLD"
