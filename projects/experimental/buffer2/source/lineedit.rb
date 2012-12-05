class LineEdit
	def initialize
		@text_left = ''
		@text_right = ''
	end
	attr_reader :text_left, :text_right
	def text
		@text_left + @text_right
	end
	def insert(text)
		raise TypeError unless text.kind_of?(String)
		text.unpack('U*')  # ensure its valid UTF-8
		@text_left += text
	end
	def erase_left
		m = @text_left.match(/.\z/u)
		return nil unless m
		b1, b2 = m.begin(0), m.end(0)
		@text_left.slice!(b1, b2 - b1)
	end
	def move_left
		s = erase_left
		@text_right = s + @text_right if s
	end
	def move_home
		@text_right = @text_left + @text_right
		@text_left = ''
	end
	def move_end
		@text_left += @text_right
		@text_right = ''
	end
	def erase_right
		m = @text_right.match(/\A./u)
		return nil unless m
		b1, b2 = m.begin(0), m.end(0)
		@text_right.slice!(b1, b2 - b1)
	end
	def move_right
		s = erase_right
		@text_left += s if s
	end
end