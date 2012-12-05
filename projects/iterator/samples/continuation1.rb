require 'iterator'

data = "hello world"
i = Iterator::Continuation.new(data, :each_byte)
while i.has_next?
	p i.current
	i.next
end
i.close
