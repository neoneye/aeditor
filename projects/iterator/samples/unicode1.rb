require 'iterator'
str = [1000, 50000, 40, 999, 30000].pack('U*')
byte_iterator = str.create_iterator
res = Iterator::DecodeUTF8.new(byte_iterator).to_a
p res  # [1000, 50000, 40, 999, 30000]
