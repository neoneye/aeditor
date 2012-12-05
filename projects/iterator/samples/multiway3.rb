require 'iterator'
data_a = %w(a b c d)
data_b = (0..3)
ia = Iterator::Continuation.new(data_a, :each)
ib = Iterator::Continuation.new(data_b, :each)
result = []
while ia.has_next? and ib.has_next?
	result << ia.current
	result << ib.current
	ia.next
	ib.next
end
ia.close
ib.close
p result   # ["a", 0, "b", 1, "c", 2, "d", 3]
