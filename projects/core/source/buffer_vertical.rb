require 'aeditor/backend/log'
require 'aeditor/backend/exceptions'

# purpose:
# logic for vertical movement
#
# The operations you see here is only 80% symmetical,
# this is because of 'empty line', lines which is nil
# can only occur in the bottom part of the view.
#
# in order to use it you must overload these methods:
#
# #export_top
#    transfer top-most-line from view to buffer.
#
# #export_bottom
#    transfer bottom-most-line from view to buffer.
#    if line == nil then discard it.
#
# #import_top 
#    transfer top-most-line from buffer to view.
#
# #import_bottom(allow_empty_lines)
#    transfer bottom-most-line from buffer to view.
#    if empty_lines is allowed and we are at the bottom
#    of the buffer, then 'nil' should be imported.
#
# #replace_current_line 
#    no comments.
#
# #top_empty?,
# #bottom_empty?
#    false if there is data for import.
#
# #is_last_line?
#    only true if cursor is on the last physical line in buffer
module BufferVertical
	class CannotExport < StandardError; end
	# important: it requires at least 2 lines in the view
	# in order to work. 
	def change_focus_to_line_above
		new = @line_top.pop
		old = replace_current_line(new)
		@line_bottom.unshift(old)
	end
	# important: it requires at least 2 lines in the view
	# in order to work. 
	def change_focus_to_line_below
		raise BufferBottom if @line_bottom.first == nil
		new = @line_bottom.shift
		old = replace_current_line(new)
		@line_top.push(old)
	end
	# purpose:
	# scroll the view up by one line.
	# you can tell if the cursor should follow the view
	def scroll_up(cursor_follow=false)
		import_top
		cond = (@line_bottom.empty? or cursor_follow)
		change_focus_to_line_above if cond
		export_bottom
		cond
	end
	# purpose:
	# scroll the view down by one line.
	# you can tell if the cursor should follow the view
	def scroll_down(cursor_follow=false)
		if bottom_empty?
			if cursor_follow
				if (@line_bottom.first == nil)
					raise BufferBottom
				end
			else
				if (@line_bottom.first == nil) and (@line_top.empty?) 
					raise BufferBottom
				end
			end
		end
		import_bottom  # allow empty lines
		cond = (@line_top.empty? or cursor_follow)
		change_focus_to_line_below if cond
		export_top
		cond
	end
	def move_up
		if @line_top.empty?
			scroll_up(true)  # let cursor follow
		else
			change_focus_to_line_above
		end
	end
	def move_down
		if @line_bottom.empty?
			scroll_down(true)  # let cursor follow
		else
			change_focus_to_line_below
		end
	end
	def scroll_page_up
		(visible_lines-1).times do
			scroll_up
		end
	end
	def scroll_page_down
		(visible_lines-1).times do
			scroll_down
		end
	end
	# purpose:
	# pageup the same way as BorlandPascal7.0 for msdos
	# or as VIM's half-page scrolls (Ctrl-U).
	#
	# height is used by redo
	def move_page_up(height=nil)
		height ||= visible_lines
		# oneliner behavier
		return scroll_up(true) if height == 1 
		# buffer-bottom behavier
		if top_empty?  # @data_top.empty?
			y = @line_top.size
			raise BufferTop if y == 0
			begin
				(height - 1).times { move_up }
			rescue BufferTop
			end
			return
		end
		# normal behavier
		begin
			(height - 1).times { scroll_up(true) }
		rescue BufferTop
		end
	end
	# purpose:
	# pagedown the same way as BorlandPascal7.0 for msdos
	# almost the same behavier as VIM's (Ctrl-D).
	#
	# height is used by redo
	def move_page_down(height=nil)
		height ||= visible_lines
		# oneliner behavier
		return scroll_down(true) if height == 1 
		# buffer-bottom behavier
		if bottom_empty? 
			raise BufferBottom if is_last_line? 
			begin
				(height - 1).times { move_down }
			rescue BufferBottom
			end
			return
		end
		# normal behavier
		begin
			(height - 1).times { scroll_down(true) }
		rescue BufferBottom
		end
	end
	def visible_lines
		@line_top.size + @line_bottom.size + 1
	end

	# purpose:
	# import lines.. in case of failure, then import empty lines
	def safe_import(n_top, n_bottom)
		begin
			n = n_top
			while n > 0
				import_top
				n -= 1
			end
		rescue
			n_bottom += n
		end

		n = n_bottom
		while n > 0
			import_bottom  # allow empty lines
			n -= 1
		end
	end

	def resize_topbottom(n_top, n_bottom)
		export_bottom while (@line_bottom.size > n_bottom)
		export_top while (@line_top.size > n_top)
		safe_import(
			n_top - @line_top.size,
			n_bottom - @line_bottom.size)
	end

	# purpose:
	# if you resize the top of the window, then
	# this strategy will let cursor-y be preserved.
	def resize_top(n_lines)
		return if n_lines == visible_lines
		if n_lines > visible_lines
			# insert some lines
			safe_import(n_lines - visible_lines, 0)
			return
		end
		# remove some lines
		n = visible_lines - n_lines
		if n > @line_top.size
			(n - @line_top.size).times do
				change_focus_to_line_below
			end
		end
		n.times { export_top }
	end

	# purpose:
	# if you resize the bottom of the window, then
	# this strategy will let cursor-y be preserved.
	def resize_bottom(n_lines)
		return if n_lines == visible_lines
		if n_lines > visible_lines
			# insert some lines
			safe_import(0, n_lines - visible_lines)
			return
		end
		# remove some lines
		n = visible_lines - n_lines
		if n > @line_bottom.size
			(n - @line_bottom.size).times do
				change_focus_to_line_above
			end
		end
		n.times { export_bottom }
	end

	# purpose:
	# if you resize the window (restore, maximize), then
	# this strategy will let cursor-y be centered.
	# important: no preservation of cursor-y!
	#
	# issues:
	# * perhaps cutting in half should be assymetric,
	#   at the moment its symmetric. 
	#   does it have any consequences ?
	def resize_center(n_lines)
		return if n_lines == visible_lines
		if n_lines > visible_lines
			# insert some lines
			remaining = n_lines - visible_lines
			diff = @line_top.size - @line_bottom.size
			n_top = 0
			n_bottom = 0

			# give to the poor (robin hood)
			add = [remaining, diff.abs].min
			remaining -= add
			if diff > 0
				n_bottom += add
			else
				n_top += add
			end

			# share equaly the remaining lines
			half = remaining / 2
			n_bottom += half
			n_top += remaining - half

			safe_import(n_top, n_bottom)
		else
			# remove some lines
			remaining = visible_lines - n_lines
			diff = @line_top.size - @line_bottom.size
			n_top = 0
			n_bottom = 0

			# take from the rich (robin hood)
			add = [remaining, diff.abs].min
			remaining -= add
			if diff > 0
				n_top += add
			else
				n_bottom += add
			end

			# remove equaly the remaining lines
			half = remaining / 2
			n_bottom += half
			n_top += remaining - half

			# export lines
			n_top.times { export_top }
			n_bottom.times { export_bottom }
		end
	end
end
