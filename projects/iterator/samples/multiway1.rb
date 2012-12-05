require 'iterator'

a = %w(a b c d e).create_iterator
b = (0..4).to_a.create_iterator
while a.has_next?
	p [a.current, b.current]
	a.next
	b.next
end
a.close
b.close
