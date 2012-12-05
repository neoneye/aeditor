require 'iterator'
str = %w(a b c).join("\n")
iterator = Iterator::Continuation.new(str, :each_line)
result = iterator.map{|i|"<<#{i}>>"}
iterator.close
p result  # ["<<a\n>>", "<<b\n>>", "<<c>>"]
