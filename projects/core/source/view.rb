require 'aeditor/backend/cellarea'
require 'aeditor/backend/view_horizontal'


# purpose:
# the view in the MVC pattern.
#
# functions:
# * do partial-repaint to a cellarea.
# * determines what the visible_part is of each line.
#
# issues:
# * 1st prio is to repaint that area where the cursor is located.
# * 2nd prio is to repaint the border zones.
# * much of the rendering code is similar, can it be simplified?
# * @dirty_scroll exists because 'refocus_x' must return, either
#   'true' if scroll occured, or 'false' if no scroll occured.
# * one View can attached to one Buffer, no multiplicity.
#
# todo: 
#
class View
	include HorizontalViewDecorated
	def initialize(buffer, cellarea)
		@buffer = buffer
		@cellarea = cellarea
		clear_dirty
		@cell_width = cellarea.getx
		init_render(@cell_width, 0)
		@caretaker = nil
	end
	attr_reader :cellarea
	attr_reader :x, :cell_width

	def set_caretaker(ct)
		@caretaker = ct
	end

	# purpose:
	# do partial-repaint accordingly to the dirty-flags.
	#
	# is invoked from Buffer.notify_observers
	def update(cursor=true, line=true, all=true)
		# do refocusing.. if so, then repaint everything
		clear_dirty
		all = true if refocus_x(@buffer.position_x)

		if all
			# repaint every cell in the cellarea
			render
		elsif line
			# repaint the line which contains the cursor
			render_line
		elsif cursor
			# repaint the cursor (eg. cursor movement)
			render_cursor
		end
	end
	def render

		if @buffer.blocking.enabled
			y1 = @buffer.blocking.y
			x1 = @buffer.blocking.x
			y2 = @buffer.position_visible_lines
			x2 = @buffer.position_x
			if (y1 > y2) or ((y1 == y2) and (x1 > x2))
				y1, y2 = y2, y1
				x1, x2 = x2, x1
			end
			ymin = y1 - @buffer.position_visible_lines_view
			ymax = y2 - @buffer.position_visible_lines_view
		else
			ymin = 1
			ymax = 0
		end

		y = 0
		@buffer.each_line do |cells|
			if cells
				vpart = visible_part(cells)
			else
				# empty lines
				vpart = Array.new(@width) { Cell.new(" "[0], Cell::MENU_SEP) }
			end
			if (y > ymin) and (y < ymax)
				vpart.each { |cell| cell.set_block }
			elsif (y == ymin) and (y == ymax)
				# oneliner
				x = @x
				vpart.each { |cell|
					if (x >= x1) and (x < x2)
						cell.set_block
					end
					x += 1
				}
			elsif (y == ymin) and (y < ymax)
				# right only
				x = @x
				vpart.each { |cell|
					cell.set_block if (x >= x1)
					x += 1
				}
			elsif (y > ymin) and (y == ymax)
				# left only
				x = @x
				vpart.each { |cell|
					cell.set_block if (x < x2)
					x += 1
				}
			end
			@cellarea.render_line(y, vpart)
			y += 1
		end
		cursor_x = @buffer.position_x
		cursor_y = @buffer.position_y
		@cellarea.cursor_position(cursor_x-@x, cursor_y)
		@cellarea.refresh
	end
	def render_line
		if @buffer.blocking.enabled
			y1 = @buffer.blocking.y
			x1 = @buffer.blocking.x
			y2 = @buffer.position_visible_lines
			x2 = @buffer.position_x
			if (y1 > y2) or ((y1 == y2) and (x1 > x2))
				y1, y2 = y2, y1
				x1, x2 = x2, x1
			end
			ymin = y1
			ymax = y2
			y = @buffer.position_visible_lines
		else
			ymin = 1
			ymax = 0
			y = -1
		end

		vpart = visible_part(@buffer.edit_to_cells)
		if (y > ymin) and (y < ymax)
			vpart.each { |cell| cell.set_block }
		elsif (y == ymin) and (y == ymax)
			# oneliner
			x = @x
			vpart.each { |cell|
				if (x >= x1) and (x < x2)
					cell.set_block
				end
				x += 1
			}
		elsif (y == ymin) and (y < ymax)
			# right only
			x = @x
			vpart.each { |cell|
				cell.set_block if (x >= x1)
				x += 1
			}
		elsif (y > ymin) and (y == ymax)
			# left only
			x = @x
			vpart.each { |cell|
				cell.set_block if (x < x2)
				x += 1
			}
		end
		cursor_y = @buffer.position_y
		cursor_x = @buffer.position_x
		@cellarea.render_line(cursor_y, vpart)
		@cellarea.cursor_position(cursor_x-@x, cursor_y)
		@cellarea.refresh
	end
	def render_cursor
		cursor_x = @buffer.position_x
		cursor_y = @buffer.position_y
		@cellarea.cursor_position(cursor_x-@x, cursor_y)
		@cellarea.refresh
	end
	def clear_dirty
		@dirty_scroll = false
	end
	def scroll_left
		@dirty_scroll = true
		super
	end
	def scroll_right
		@dirty_scroll = true
		super
	end
	# purpose:
	# scroll the view sideways so the cursor becomes visible.
	#
	# return 'true' if scrolling is going on. 
	# return 'false' if everything is unchanged.
	def refocus_x(x)
		super(x)
		@dirty_scroll
	end
end

