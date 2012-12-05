require 'aeditor/backend/exceptions'
require 'aeditor/backend/render'

# purpose:
# determine which cells should visible.
# 
# functions:
# * horizontal scrolling
# * is there text outside the view (data_left? data_right?)
#
# issues:
# * makes heavy use of the 'flyweight' design pattent.
module HorizontalView
	def init_render(width=80, x=0)
		@x = x
		@width = width
	end
	def scroll_left
		#raise "already at the left-most position" if @x == 0
		raise BufferLeft if @x == 0
		@x -= 1
	end
	def scroll_right
		@x += 1
	end
	# cursor is locked, must move view instead
	def refocus_x(cursor_x)
		begin
			scroll_left  until cursor_x >= @x
		rescue CommandHarmless
		end
		begin
			scroll_right until cursor_x < @x+@width
		rescue CommandHarmless
		end
	end

	# purpose:
	# return that data which is visible
	#
	# flyweight
	def visible_part(line)
		res = line.slice(@x, @width)
		return [] unless res
		res
	end

	# purpose:
	# tells if there is more data outside the right-border
	#
	# flyweight
	def data_right?(line)
		(line.size > @x+@width)
	end

	# purpose:
	# tells if there is more data outside the left-border
	#
	# flyweight
	def data_left?(line)
		return false if @x == 0
		(line.size > 0)
	end
end

# purpose:
# determine which cells should visible and how they should appear.
#
# inherited-functions:
# * horizontal scrolling.
# * resize width of cellarea.
# * is there data outside the view: data_left? data_right?
#
# functions:
# * data_left? scans the string for leading-space.
# * attach decorations to the text:
#   * decoration-EOL indication (End Of Line).
#   * decoration-left, if data outside the left border.
#   * decoration-right, if data outside the right border.
#
# constraints:
# * logic is placed in the Render module.
# * BufferRender is decoration only.. logic not allowed!
#
module HorizontalViewDecorated
	include HorizontalView

	# blanks does not count as data outside left
	def data_left?(line)
		return false if @x == 0
		return false if @x >= line.size 
		0.upto(@x-1) do |i|
			return true if line[i].glyph != " "[0]
		end
		return false
	end

	def visible_part(cells_in)
		cells = super(cells_in)

		# left-decorator
		if data_left?(cells_in)
			cells[0] = Cell.new("<"[0], Cell::ERROR)
		end

		# right-decorator
		if data_right?(cells_in)
			cells[@width-1] = Cell.new(">"[0], Cell::ERROR)
		end

		# EOL-decorator
		if cells.size < @width 
			# x!=0 | size==0 || insert-eol
			#  0   |    0    || no
			#  0   |    1    || no
			#  1   |    0    || no
			#  1   |    1    || yes
			if not ((@x != 0) and (cells.size == 0))
				cells += '.'.to_cells(Cell::END_OF_LINE)
			end
		end
		cells
	end
end
