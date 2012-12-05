require 'aeditor/backend/cell'

class Cellarea
	def initialize
		@x = 0
		@y = 0
	end
	attr_reader :x, :y
	def getx
		0
	end
	def gety
		0
	end
	def close
	end
	def cursor_position(x, y)
	end
	def waitkey
	end
	def render_line(y, cells)
	end
	def refresh
	end
	def clear
	end
end
