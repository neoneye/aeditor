require 'iterator'

a = %w(a b c d e).create_iterator
b = (1..5).to_a.create_iterator
until a.is_done?
	p [a.current, b.current]
	a.next
	b.next
end
a.close
b.close
