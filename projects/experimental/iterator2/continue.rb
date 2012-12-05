require 'iterator'

data = "hello world"
i = Iterator::Continuation.new(data, :each_byte)
until i.is_done?
	p i.current
	i.next
end
i.close
