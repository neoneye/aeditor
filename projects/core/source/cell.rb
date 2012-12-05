class Cell
	BACKGROUND = 0
	TEXT = 1
	KEYWORD = 2
	ERROR = 3
	MENU = 4
	MENU_SEP = 5
	END_OF_LINE = 6
	TAB = 7
	MENU_BLINK = 8
	BLOCK = 9
	def initialize(glyph, color=TEXT)
		raise if not glyph.kind_of?(Fixnum)
		@glyph = glyph
		@color = color
	end
	def to_s
		String.new << @glyph
	end
	def set_block
		@color = BLOCK
	end
	attr_reader :color, :glyph
end
