require 'iterator'
require 'aeditor/lexer'
require 'aeditor/string'

module Buffer

module Model

class ModelIterator < Iterator::Base
	def initialize(model, x, y)
		super()
		@model = model
		@x = x
		@y = y
	end
	attr_reader :model, :x, :y
	def set_y(y)
		@y = y
	end
	def clone
		self.class.new(@model, @x, @y)
	end
	def has_next?
		(@y < @model.lines.size) and (@x < @model.lines[@y].content.size)
	end
	def next1
		@x += 1
	end
	def current
		@model.lines[@y].content[@x, 1]
	end
	def has_prev?
		(@y < @model.lines.size) and (@x > 0)
	end
	def prev1
		@x -= 1
	end
	def insert_before(text)
		data = @model.lines[@y].content
		data[@x, 0] = text
		@x += 1
	end
	def insert_after(text)
		data = @model.lines[@y].content
		data[@x, 0] = text
	end
	def erase_before
		@x -= 1
		data = @model.lines[@y].content
		data.slice!(@x, 1)
	end
	def erase_after
		data = @model.lines[@y].content
		data.slice!(@x, 1)
	end
end

class Line
	def initialize(text = nil)  # make me nicer
		m = /\A(.*)(\n|)\z/.match(text || "")
		raise 'cannot initialize' unless m
		@content = m[1]
		@newline = m[2]
	end
	attr_reader :content, :newline
	def clone
		self.class.new(text)
	end
	def set_content(content)
		@content = content
	end
	def set_newline(newline)
		@newline = newline
	end
	def text
		@content + @newline
	end
	def split(position, newline)
		content = @content.slice!(position..-1)
		line = Line.new(content + @newline)
		@newline = newline
		# caller should insert this extra line
		line
	end
	def join(line)
		@content += line.content
		@newline = line.newline
	end
	def ==(other)
		(other.class == self.class) and
		(other.content == @content) and
		(other.newline == @newline)
	end
end

class Caretaker
	def initialize
		@lines = [Line.new]
	end
	attr_reader :lines
	def number_of_lines
		@lines.size
	end
	def append_text(string)
		raise TypeError, "expected String" unless string.kind_of?(String)
		last = @lines.pop
		ary = (last.text + string).scan(/.*?(?:\n|\z)/)
		ary.delete('')
		ary.push('') if ary.empty?
		ary.push('') if /\n\z/.match(ary.last)
		@lines += ary.map{|text| Line.new(text) }
	end
	def self.open(string)
		model = self.new
		model.append_text(string)
		model
	end
	def with_iterator_begin(skip=0, &block)
		i = @lines.create_iterator.next(skip)
		begin
			return block.call(i)
		ensure
			i.close
		end
	end
	def to_a
		with_iterator_begin do |modelline_iterator|
			return modelline_iterator.map{|modelline| modelline.text}
		end
	end
	def insert_text(position, text)
		extra_lines = @lines[position.y].insert_text(position.x, text)
		if extra_lines.size >= 1
			@lines[position.y+1, 0] = extra_lines
		end
	end
	def erase_text(position1, position2)
		if position1.y != position2.y
			raise "implement me"
		end
		x = position1.x
		width = position2.x - x
		join_with_next_line = @lines[position1.y].erase_text(x, width)
		if join_with_next_line and @lines[position1.y]
			next_line = @lines.delete_at(position1.y+1)
			insert_text(position1, next_line.text)
		end
	end
	def mk_iterator(x, y)
		ModelIterator.new(self, x, y)
	end
	def ==(other)
		(other.class == self.class) and
		(other.lines == @lines)
	end
end # class Caretaker

end # module Model

module View


module Line

class Base
	def text
		""
	end
end

class Normal < Base
	def initialize(model_iterator)
		@model_iterator = model_iterator
	end
	attr_reader :model_iterator
	def text
		@model_iterator.current.text
	end
end

class Empty < Base
end

end # module Line

module Memento

class Base
end

class All < Base
	def initialize
		@model = nil
		@cursor_x = nil
		@cursor_y = nil
		@selection_x = nil
		@selection_y = nil
		@selection_mode = nil
	end
	attr_accessor :model, :cursor_x, :cursor_y
	attr_accessor :selection_x, :selection_y, :selection_mode
end

class Position < Base
	def initialize
		@cursor_x = nil
		@cursor_y = nil
	end
	attr_accessor :cursor_x, :cursor_y
end

class Range < Base
	def initialize
		@cursor_x = nil
		@cursor_y = nil
		@model_lines = nil
		@y_top = nil
		@y_bottom = nil
		@selection_x = nil
		@selection_y = nil
		@selection_mode = nil
	end
	attr_accessor :cursor_x, :cursor_y, :model_lines, :y_top, :y_bottom
	attr_accessor :selection_x, :selection_y, :selection_mode
end

end # module Memento

require 'aeditor/editor'
require 'aeditor/history'

class Caretaker
	DIRTY_CURSOR = 0b0001
	DIRTY_ALL    = 0b1111

	def initialize(model, cellsx, cellsy)
		@tabsize = 8
		@bookmarks = {}
		@model = model
		@model_iterator = @model.mk_iterator(0, 0)
		@editor = Editor.new(@model_iterator)
		@editor.use_virtual_space_strategy(true)
		@editor.set_tabsize(@tabsize)
		@editor.use_cursor_through_tabs_strategy(false) 
		@use_autoindent = false
		@selection_mode = false
		@selection_y = 0
		@selection_x = 0
		@scroll_x = 0
		@scroll_y = 0
		@cursor_y = 0
		@number_of_cells_x = cellsx
		@number_of_cells_y = cellsy
		@extra_top = 0
		@extra_bottom = 0
		@lines = nil
		@lexer = LexerText::Lexer.new
		@lexer_states = [[]]
		@render_callback = lambda {}
		@render_dirty_flag = DIRTY_ALL
		@render_dirty_locked = false
		@vscroll_callback = nil
		@search_pattern_last = nil
		@replacement_string = ''
		@memento_caretaker = History::Caretaker.new(self)
		reset_lcache 
		reload_lines
	end
	attr_reader :scroll_x, :scroll_y, :cursor_y, :editor
	attr_reader :tabsize, :model_iterator, :model
	attr_reader :number_of_cells_x, :number_of_cells_y
	attr_reader :selection_mode, :selection_y, :selection_x
	attr_reader :extra_top, :extra_bottom, :lines
	attr_reader :lexer_states, :search_last_pattern
	attr_reader :lexer_cache_lines, :lexer_cache_valid, :lexer_cache_states
	attr_reader :bookmarks, :render_valid, :memento_caretaker
	attr_reader :search_pattern_last, :replacement_string
	def create_memento  # per default make snapshot of everything
		m = Memento::All.new
		m.model = @model
		m.cursor_x = @editor.cursor_x
		m.cursor_y = @cursor_y
		m.selection_x = @selection_x
		m.selection_y = @selection_y
		m.selection_mode = @selection_mode
=begin
TODO: we must store everything
bookmarks
model iterator  (maybe?)
editor          (maybe?)

TODO: In order to improve user experience of undo where scrolling occurs
Then we must store these things as well
tabsize
scroll x, y
number of cells x, y
=end
		Marshal.dump(m)
	end
	def create_memento_position
		m = Memento::Position.new
		m.cursor_x = @editor.cursor_x
		m.cursor_y = @cursor_y
		Marshal.dump(m)
	end
	def create_memento_range(y_top, y_bottom)
		raise IndexError if y_top < 0
		raise IndexError if y_bottom < 0
		m = Memento::Range.new
		m.cursor_x = @editor.cursor_x
		m.cursor_y = @cursor_y
		count = @model.lines.size-(y_top+y_bottom)
		raise IndexError if count <= 0
		$logger.debug(2) {"create memento range ytop=#{y_top} ybot=#{y_bottom} lines=#{count}"}
		m.model_lines = @model.lines[y_top, count]
		m.y_top = y_top
		m.y_bottom = y_bottom
		m.selection_x = @selection_x
		m.selection_y = @selection_y
		m.selection_mode = @selection_mode
		Marshal.dump(m)
	end
	def set_memento(memento)
		m = Marshal.load(memento)
		case m
		when Memento::All
			goto_absolute(0, 0)
			@model = m.model
			@model_iterator = @model.mk_iterator(0, 0)
			@editor.set_model_iterator(@model_iterator) 
			@selection_x = m.selection_x
			@selection_y = m.selection_y
			@selection_mode = m.selection_mode
			scroll_to_cursor
			reset_lcache 
			reload_lines
			reload_current_line
			goto_absolute(m.cursor_x, m.cursor_y)
			dirty_all
		when Memento::Range
			#if m.selection_mode != @selection_mode or @selection_mode
			#	# TODO: optimize me
			#	render_dirty_all
			#end
			@selection_x = m.selection_x
			@selection_y = m.selection_y
			@selection_mode = m.selection_mode
			goto_absolute(nil, m.y_top)
			count = @model.lines.size-(m.y_top+m.y_bottom)
			$logger.debug(2) {"set_memento range  replace #{count} with #{m.model_lines.size} lines"}
			@model.lines[m.y_top, count] = m.model_lines
			m.model_lines.size.times do |i|
				lcache_clear(m.y_top + i)
			end
			reload_lines
			reload_current_line
			goto_absolute(m.cursor_x, m.cursor_y)
			render_dirty_all
			dirty_all
		when Memento::Position
			goto_absolute(m.cursor_x, m.cursor_y)
		else
			raise TypeError
		end
	end
	def execute(command)
		raise TypeError unless command.kind_of?(History::Command::Base)
		lock_dirty_flag {
			@memento_caretaker.execute(command)
		}
	end
	def execute_undo
		lock_dirty_flag {
			@memento_caretaker.execute_undo
		}
	rescue History::Caretaker::Nothing2Undo
	end
	def execute_redo
		lock_dirty_flag {
			@memento_caretaker.execute_redo
		}
	rescue History::Caretaker::Nothing2Redo
	end
	def model_x
		@model_iterator.x
	end
	def cursor_x
		@editor.cursor_x
	end
	def cursor_cell_x
		@editor.cursor_x - @scroll_x
	end
	def cursor_cell_y
		@cursor_y - @scroll_y
	end
	def set_render_callback(&block)
		@render_callback = block
	end
	def set_vscroll_callback(&block)
		@vscroll_callback = block
	end
	def set_tabsize(tabsize)
		@tabsize = tabsize
		@editor.set_tabsize(@tabsize)
		@editor.do_move_begin
	end 
	def set_lexer(lexer)
		@lexer = lexer
	end
	def set_mode_cursor_through_tabs(on_off)  
		@editor.use_cursor_through_tabs_strategy(on_off) 
	end
	def set_mode_autoindent(on_off)  
		@use_autoindent = on_off
	end
	def set_extra_lines(top, bottom)
		@extra_top = top
		@extra_bottom = bottom
		reload_lines
	end
	def set_dirty_flag(flag)
		@render_dirty_flag |= flag
		if @render_dirty_locked 
			#puts "locked"
			return 
		end
		return if @render_dirty_flag == 0
		@render_callback.call(@render_dirty_flag)
		@render_dirty_flag = 0
	end
	def lock_dirty_flag(&block)
		old, @render_dirty_locked = @render_dirty_locked, true
		$logger.debug(2) {
			"buffer.obtain lock  old=#{old}  " +
			"current=#{@render_dirty_locked}"
		}
		retval = nil
		begin
			retval = block.call
		ensure
			@render_dirty_locked = old
		end
		$logger.debug(2) {
			"buffer.restore lock  current=#{@render_dirty_locked}"
		}
		set_dirty_flag(0)
		retval
	end
	def dirty_all
		set_dirty_flag(DIRTY_ALL)
	end
	def dirty_cursor
		set_dirty_flag(DIRTY_CURSOR)
	end
	def scroll_to_cursor
		if @scroll_y > @cursor_y  
			set_scroll_y(@cursor_y, false)
		elsif @scroll_y+@number_of_cells_y <= @cursor_y  
			set_scroll_y(@cursor_y - @number_of_cells_y + 1, false)
		end
		if @scroll_x > @editor.cursor_x
			set_scroll_x(@editor.cursor_x)
		elsif @scroll_x+@number_of_cells_x <= @editor.cursor_x
			set_scroll_x(@editor.cursor_x - @number_of_cells_x + 1)
		end
	end
	def set_scroll_x(x)
		return if x == @scroll_x
		@scroll_x = x
		render_dirty_all
		dirty_all
	end
	def scroll_to_center
		nocy2 = @number_of_cells_y / 2
		ny = @cursor_y - nocy2
		ny = 0 if ny < 0
		ny = @model.lines.size-1 if ny >= @model.lines.size
		sy = (@scroll_y * 2 + ny * 3) / 5

		nocx2 = @number_of_cells_x / 2
		nx = @editor.cursor_x - nocx2
		nx = 0 if nx < 0
		sx = (@scroll_x * 2 + nx * 3) / 5

		set_scroll_x(sx)
		set_scroll_y(sy, false)
	end
	def resize(cellsx, cellsy)
		@number_of_cells_x = cellsx
		@number_of_cells_y = cellsy
		reload_lines
	end
	def reload_lines(do_reset_lcache=true)
		reset_lcache if do_reset_lcache
		@lines = [nil] * (@extra_top + @number_of_cells_y + @extra_bottom)
		y = @scroll_y - @extra_top
		empty_padding = (y < 0) ? -y : 0
		@model.with_iterator_begin(y + empty_padding) do |model_iterator|
			self.with_iterator_begin do |view_iterator|
				empty_padding.times do 
					raise unless view_iterator.has_next?
					view_iterator.current = Line::Empty.new
					view_iterator.next
				end
				while view_iterator.has_next? and model_iterator.has_next?
					view_iterator.current = Line::Normal.new(model_iterator.clone)
					model_iterator.next
					view_iterator.next
				end
				while view_iterator.has_next?
					view_iterator.current = Line::Empty.new
					view_iterator.next
				end
			end
		end
	end
	def reload_current_line(newx=nil)
		x = newx || @editor.cursor_x
		@editor.do_move_begin
		loop do
			break if x <= @editor.cursor_x
			ok = @editor.do_move_right
			break unless ok
		end
		# TODO: why doesn't the following lines work ?
		#render_dirty(@cursor_y - @scroll_y)
		#dirty_all
	end
	def goto_cell(x, y)
		change_cursor_y(y - cursor_cell_y)
		reload_current_line(@scroll_x + x)
		render_dirty(cursor_cell_y)
		dirty_all
	end
	def goto_absolute(x, y)
		set_cursor_y(y)
		reload_current_line(x)
		render_dirty(@cursor_y-@scroll_y)
		dirty_all
	end
	def reload_current_line_modelx(newx)
		x = newx || @model_iterator.x
		@editor.do_move_begin
		loop do
			break if x <= @model_iterator.x
			ok = @editor.do_move_right
			break unless ok
		end
	end
	def with_iterator_begin(skip=0, &block)
		iterator = @lines.create_iterator
		begin
			iterator.next(skip)
			return block.call(iterator)
		ensure
			iterator.close
		end
	end
	def reset_lcache 
		n = @number_of_cells_y + @extra_bottom
		# TODO: not sure if these 2 arrays can be merged
		@lexer_cache_valid = [false] * n
		@lexer_cache_states = [nil] * n
		@lexer_cache_lines = [nil] * n
		@render_valid = [false] * n
	end
	def lexer_sync
		sy = @lexer_states.size - 1
		count = @scroll_y - sy
		$logger.debug(2) {"lexer sync: @scrolly=#{@scroll_y}, states=#{sy}, count=#{count}"}
		return if count == 0
		if count > 0
			@lexer.set_states(@lexer_states.last.map{|i| i.clone})
			count.times do |i|
				$logger.debug(2) { "index=#{sy+i} size=#{@model.lines.size}" }
				line = @model.lines[sy+i].text
				@lexer.lex_line(line)
				@lexer_states << @lexer.states.clone
			end
		else
			(-count).times do
				@lexer_states.pop
			end
		end
	end
	def set_scroll_y(scroll_y, cursor_follow=true)
		if scroll_y == @scroll_y
			return true
		end
		if scroll_y < 0 or scroll_y >= @model.lines.size
			return false
		end
		count = scroll_y - @scroll_y
		if (@cursor_y + count) >= @model.lines.size and cursor_follow
			return false
		end
		# TODO: don't use scroll with pageup/pagedown.. 
		# TODO: pageup/pagedown doesn't render selection correct
		use_scroll = @vscroll_callback ? true : false
		delta = scroll_y - @scroll_y
		$logger.debug(2) { "delta scroll=#{delta}" }
		if delta > 0
			delta.times { lcache_remove_line(0, !use_scroll) }
		else
			(-delta).times { lcache_insert_line(0, !use_scroll) }
		end
		if use_scroll
			if delta > 0
				n = delta
				n_copy = @render_valid.size - n
				@vscroll_callback.call(n, 0, n_copy) if n_copy > 0
				(n+@extra_bottom).times do |i| 
					render_dirty(@render_valid.size - 1 - i)
				end
				$logger.debug(2) { 
					val = @cursor_y - @scroll_y - n  # old cursor position
					"cy=#{@cursor_y} sy=#{@scroll_y} val=#{val}"
				}
				render_dirty(@cursor_y - @scroll_y - n)  # old cursor position
				if @selection_mode
					y1 = [@cursor_y - @scroll_y - n, 0].max
					y2 = @cursor_y - @scroll_y
					$logger.debug(2) { "selection = #{y1}..#{y2}" }
					y1.upto(y2) {|y| render_dirty(y) }
				end
			else
				n = -delta 
				n_copy = @render_valid.size - n
				@vscroll_callback.call(0, n, n_copy) if n_copy > 0
				n.times{|i| render_dirty(i) }
				render_dirty(@render_valid.size - 1)
				render_dirty(@cursor_y - @scroll_y + n)  # old cursor position
				@extra_bottom.times do |i| 
					render_dirty(@render_valid.size - 1 - i)
				end
				if @selection_mode
					y1 = @cursor_y - @scroll_y
					y2 = [@cursor_y - @scroll_y + n, @render_valid.size-1].min
					$logger.debug(2) { "selection = #{y1}..#{y2}" }
					y1.upto(y2) {|y| render_dirty(y) }
				end
			end
		end
		@scroll_y = scroll_y
		reload_lines(false)
		if cursor_follow
			@cursor_y += count
			@model_iterator.set_y(@cursor_y)
			reload_current_line
		end
		lexer_sync unless use_scroll
		dirty_all
		true
	end
	def set_cursor_y(cursor_y)
		if cursor_y < 0
			return false
		end
		if cursor_y >= @model.lines.size
			return false
		end
		if @selection_mode
			y1, y2 = [@cursor_y, cursor_y].sort
			y1.upto(y2) {|y| render_dirty(y) }
		end
		render_dirty(@cursor_y - @scroll_y)
		@cursor_y = cursor_y
		@model_iterator.set_y(@cursor_y)
		scroll_to_cursor
		dirty_cursor
		reload_current_line
		true
	end
	def change_cursor_y(count)
		if count == 0
			return true
		end
		if count < 0 and (@cursor_y + count) < @scroll_y
			return false
		end
		if count > 0 and (@cursor_y + count) >= (@scroll_y + @number_of_cells_y)
			return false
		end
		if (@cursor_y + count) >= @model.lines.size
			return false
		end
		set_cursor_y(@cursor_y + count)
	end
	def move_up
		if change_cursor_y(-1)
			return true
		end
		set_scroll_y(@scroll_y-1)
	end
	def move_down
		if change_cursor_y(+1)
			return true
		end
		set_scroll_y(@scroll_y+1)
	end
	def move_page_up
		return if set_scroll_y(@scroll_y+1-@number_of_cells_y)
		if @scroll_y == 0
			change_cursor_y(-@cursor_y)
		else
			set_scroll_y(0)
		end
	end
	def move_page_down
		return if set_scroll_y(@scroll_y+@number_of_cells_y-1)
		lines = @model.lines.size
		cells = @number_of_cells_y
		if @scroll_y >= lines - cells
			change_cursor_y(lines - @cursor_y - 1)
		else
			set_scroll_y(lines - cells)
		end
	end
	def move_right
		@editor.do_move_right
		dirty_cursor
		true
	end
	def move_left
		@editor.do_move_left
		dirty_cursor
		true
	end
	def moveto_line_begin
		@editor.do_move_begin
		dirty_cursor
	end
	def moveto_line_end
		@editor.do_move_end
		dirty_cursor
	end
	def move_home
		cy = @cursor_y
		m = /\A\s*/.match(@model.lines[cy].content)
		length = m.to_s.expand_tabs(@tabsize).length
		while cy >= 0
			txt = @model.lines[cy].content
			m = /\A\s*/.match(txt)
			if m.end(0) < txt.size
				length = m.to_s.expand_tabs(@tabsize).length
				break
			end
			cy -= 1
		end
		cx = @editor.cursor_x
		moveto_line_begin
		return if cx == length
		reload_current_line(length)
		dirty_cursor
	end
	def to_a
		with_iterator_begin do |view_iterator|
			return view_iterator.map{|viewline| viewline.text}
		end
	end
	def insert_text(text)
		text.split(//).each do |char|
			if char == "\n"
				breakline_internal
			else
				@editor.do_insert(char)
				lcache_clear(@cursor_y - @scroll_y)
			end
		end
		dirty_all
	end
	def breakline
		indent_str = nil
		if @use_autoindent
			txt = @model.lines[@cursor_y].content
			$logger.debug(2) { "content = #{txt.inspect}" }
			m = /\A\s*/.match(txt)
			if @model_iterator.x <= m.end(0)  
				insert_emptyline
				return
			end
			indent_str = m.to_s
			$logger.debug(2) { "auto indent=#{indent_str.inspect}" }
		end
		breakline_internal
		if indent_str
			indent_str.split(//).each do |letter|
				insert_text(letter)
			end
		end
	end
	def insert_emptyline
		$logger.debug(2) { "insert empty line" }
		use_scroll = @vscroll_callback ? true : false
		@model.lines[@cursor_y, 0] = Model::Line.new("\n")
		adjust_bookmarks(@cursor_y, 1)
		lcache_insert_line(@cursor_y-@scroll_y, !use_scroll)
		@cursor_y += 1
		lcache_clear(@cursor_y-@scroll_y)
		@model_iterator.set_y(@cursor_y)
		if use_scroll
			y1 = @cursor_y-@scroll_y
			n = @lexer_cache_valid.size - y1 - 1
			@vscroll_callback.call(y1, y1+1, n) if n > 0
			render_dirty(y1)
			render_dirty(y1-1)
			@extra_bottom.times do |i|
				render_dirty(@render_valid.size-1-i)
			end
		end
		reload_lines(false)
		reload_current_line
		@editor.do_split
		while @model_iterator.has_next?  # wipe spaces
			char = @model_iterator.current
			if char == "\t" or char == " "
				@model_iterator.erase_after
			else
				break
			end
		end
		reload_current_line
		dirty_all
	end
	def breakline_internal
		use_scroll = @vscroll_callback ? true : false
		@editor.do_split
		x = @model_iterator.x
		@editor.do_move_begin
		line = @model.lines[@cursor_y].split(x, "\n")
		adjust_bookmarks(@cursor_y, 1)
		lcache_insert_line(@cursor_y-@scroll_y, !use_scroll)
		@cursor_y += 1
		lcache_clear(@cursor_y-@scroll_y)
		@model.lines[@cursor_y, 0] = line
		@model_iterator.set_y(@cursor_y)
		if use_scroll
			y1 = @cursor_y-@scroll_y
			n = @lexer_cache_valid.size - y1 - 1
			@vscroll_callback.call(y1, y1+1, n) if n > 0
			render_dirty(y1)
			render_dirty(y1-1)
			@extra_bottom.times do |i|
				render_dirty(@render_valid.size-1-i)
			end
		end
		reload_lines(false)
		reload_current_line
		dirty_all
	end
	def joinline
		use_scroll = @vscroll_callback ? true : false
		@editor.do_move_end
		line = @model.lines.delete_at(@cursor_y + 1)
		adjust_bookmarks(@cursor_y, -1)
		lcache_remove_line(@cursor_y-@scroll_y, !use_scroll)
		lcache_clear(@cursor_y-@scroll_y)
		@model.lines[@cursor_y].join(line)
		if use_scroll
			y1 = @cursor_y-@scroll_y+2
			y2 = @cursor_y-@scroll_y+1
			n = @render_valid.size-y1
			@vscroll_callback.call(y1, y2, n) if n > 0
			render_dirty(@cursor_y-@scroll_y)
			(@extra_bottom+1).times do |i|
				render_dirty(@render_valid.size-1-i)
			end
		else
			reload_lines(false)
		end
		reload_current_line
		dirty_all
	end
	def backspace
		unless @editor.do_backspace
			return false
		end
		lcache_clear(@cursor_y - @scroll_y)
		dirty_all
		true
	end
	def real_backspace
		return backspace if cursor_x > 0
		if move_up
			joinline
			return true
		end
		false # we have reached top of file
	end
	def selection_init
		@selection_mode = true
		@selection_y = @cursor_y
		@selection_x = @editor.cursor_x
		dirty_all
	end
	def selection_reset
		@selection_mode = false
		y1, y2 = [@selection_y - @scroll_y, @cursor_y - @scroll_y].sort
		y1 = 0 if y1 < 0 
		lines = @number_of_cells_y + @extra_top + @extra_bottom
		y2 = lines-1 if y2 >= lines
		$logger.debug(2) { "removing selection from lines #{y1}..#{y2}" }
		y1.upto(y2) do |y|
			render_dirty(y)
		end
		dirty_all
	end
	def selection_erase
		return false unless @selection_mode
		xy1 = [@editor.cursor_x, @cursor_y]
		xy2 = [@selection_x, @selection_y]
		selection_reset
		moveto_line_begin
		erase(xy1, xy2)
		y1, x1, y2, x2 = sort_by_yx(xy1, xy2)
		@cursor_y = y1
		@model_iterator.set_y(@cursor_y)
		adjust_bookmarks(y1, y1-y2)
		scroll_to_cursor
		reload_lines
		reload_current_line(x1)
		dirty_all
		true
	end
	def get_text_selection_array
		return [] unless @selection_mode
		copy_text(
			[@selection_x, @selection_y],
			[@editor.cursor_x, @cursor_y]
		)
	end
	def sort_by_yx(xy1, xy2)
		[xy1.reverse, xy2.reverse].sort.flatten
	end
	def copy_text(xy1, xy2)
		y1, x1, y2, x2 = sort_by_yx(xy1, xy2)
		$logger.debug(2) { "x1=#{x1} y1=#{y1} x2=#{x2} y2=#{y2}" }

		line1_old = @model.lines[y1]
		line2_old = @model.lines[y2]
		line1_clone = @model.lines[y1].clone
		line2_clone = @model.lines[y2].clone
		@model.lines[y1] = line1_clone
		@model.lines[y2] = line2_clone

		# expand TAB to space at position (x1, y1)
		i1 = @model.mk_iterator(0, y1)
		editor = Editor.new(i1)
		editor.use_virtual_space_strategy(true)
		editor.set_tabsize(@tabsize)
		editor.use_cursor_through_tabs_strategy(true)
		editor.do_move_begin
		editor.do_move_right while editor.cursor_x < x1
		editor.do_split
		mx1 = i1.x
		i1.close

		# expand TAB to space at position (x2, y2)
		i2 = @model.mk_iterator(0, y2)
		editor = Editor.new(i2)
		editor.use_virtual_space_strategy(true)
		editor.set_tabsize(@tabsize)
		editor.use_cursor_through_tabs_strategy(true)
		editor.do_move_right until editor.cursor_x >= x2
		editor.do_split
		mx2 = i2.x
		i2.close
		$logger.debug(2) { "x1(#{x1})->mx1(#{mx1}), x2(#{x2})->mx2(#{mx2})" }

		ary = []
		if y1 == y2
			ary << [@model.lines[y1].text.slice(mx1, mx2-mx1)]
		else
			cy = y1
			ary << @model.lines[cy].text.slice(mx1..-1)
			cy += 1
			while cy < y2
				ary << @model.lines[cy].text
				cy += 1
			end
			ary << @model.lines[cy].text.slice(0, mx2)
		end

		@model.lines[y2] = line2_old
		@model.lines[y1] = line1_old

		ary
	end
	def erase(xy1, xy2)
		y1, x1, y2, x2 = sort_by_yx(xy1, xy2)

		# expand TAB to space at position (x1, y1)
		i1 = @model.mk_iterator(0, y1)
		editor = Editor.new(i1)
		editor.use_virtual_space_strategy(true)
		editor.set_tabsize(@tabsize)
		editor.use_cursor_through_tabs_strategy(true)
		editor.do_move_begin
		editor.do_move_right while editor.cursor_x < x1
		editor.do_split
		mx1 = i1.x
		i1.close

		# expand TAB to space at position (x2, y2)
		i2 = @model.mk_iterator(0, y2)
		editor = Editor.new(i2)
		editor.use_virtual_space_strategy(true)
		editor.set_tabsize(@tabsize)
		editor.use_cursor_through_tabs_strategy(true)
		editor.do_move_right until editor.cursor_x >= x2
		editor.do_split
		mx2 = i2.x
		i2.close
		$logger.debug(2) { "x1(#{x1})->mx1(#{mx1}), x2(#{x2})->mx2(#{mx2})" }

		line1 = @model.lines[y1]
		n = mx2 + line1.content.size - mx1
		line1.join(@model.lines[y2])
		line1.content.slice!(mx1, n)
		lines = y2-y1
		if lines > 0
			@model.lines.slice!(y1+1, lines)
		end
	end
	def move_word_right
		text = @model.lines[@cursor_y].content
		mx = @model_iterator.x
		rest = text.slice(mx, text.size-mx)
		m = /\A(?: \s+ | \w+ | . )/x.match(rest)
		return false unless m
		resx = m.end(0) + mx
		move_right while @model_iterator.x < resx
		true
	end
	def move_word_next
		unless move_word_right
			return false unless move_down
			moveto_line_begin
		end
		true
	end
	def move_word_left
		text = @model.lines[@cursor_y].content
		mx = @model_iterator.x
		rest = text.slice(0, mx)
		m = /(?: \s+ | \w+ | . )\z/x.match(rest)
		return false unless m
		resx = m.begin(0)
		moveto_line_begin
		move_right while @model_iterator.x < resx
		true
	end
	def move_word_prev
		unless move_word_left
			return false unless move_up
			moveto_line_end
		end
		true
	end
	def swap_lower
		return false if @cursor_y+1 >= @model.lines.size
		content = @model.lines[@cursor_y].content
		@model.lines[@cursor_y].set_content(
			@model.lines[@cursor_y+1].content 
		)
		@model.lines[@cursor_y+1].set_content(content)
		swap_bookmarks(@cursor_y, @cursor_y+1)
		@cursor_y += 1
		@model_iterator.set_y(@cursor_y)
		if @cursor_y >= @scroll_y + (@number_of_cells_y / 2)
			@scroll_y += 1
		end
		@scroll_y = @model.lines.size-1 if @scroll_y >= @model.lines.size
		reload_lines
		reload_current_line
		lexer_sync
		dirty_all
		true
	end
	def swap_lower_selection
		return false unless @selection_mode
		xy1 = [@editor.cursor_x, @cursor_y]
		xy2 = [@selection_x, @selection_y]
		y1, x1, y2, x2 = sort_by_yx(xy1, xy2)
		y2 += 1 if x2 > 0
		return false if y2 >= @model.lines.size
		y2_content = @model.lines[y2].content
		y = y2
		while y > y1
			@model.lines[y].set_content(
				@model.lines[y - 1].content 
			)
			swap_bookmarks(y, y-1)
			y -= 1
		end
		@model.lines[y1].set_content(y2_content)
		@selection_y += 1
		@cursor_y += 1
		@model_iterator.set_y(@cursor_y)
		if @cursor_y >= @scroll_y + (@number_of_cells_y / 2)
			@scroll_y += 1
		end
		@scroll_y = @model.lines.size-1 if @scroll_y >= @model.lines.size
		reload_lines
		reload_current_line
		lexer_sync
		dirty_all
		true
	end
	def swap_upper
		return false if @cursor_y <= 0
		content = @model.lines[@cursor_y].content
		@model.lines[@cursor_y].set_content(
			@model.lines[@cursor_y-1].content 
		)
		@model.lines[@cursor_y-1].set_content(content)
		swap_bookmarks(@cursor_y, @cursor_y-1)
		@cursor_y -= 1
		@model_iterator.set_y(@cursor_y)
		if @cursor_y <= @scroll_y + (@number_of_cells_y / 2)
			@scroll_y -= 1
		end
		@scroll_y = 0 if @scroll_y < 0
		reload_lines
		reload_current_line
		lexer_sync
		dirty_all
		true
	end
	def swap_upper_selection
		return false unless @selection_mode
		xy1 = [@editor.cursor_x, @cursor_y]
		xy2 = [@selection_x, @selection_y]
		y1, x1, y2, x2 = sort_by_yx(xy1, xy2)
		y1 -= 1
		y2 -= 1
		y2 += 1 if x2 > 0
		#return false if y2 >= @model.lines.size
		y1_content = @model.lines[y1].content
		y = y1
		while y < y2
			@model.lines[y].set_content(
				@model.lines[y + 1].content 
			)
			swap_bookmarks(y, y+1)
			y += 1
		end
		@model.lines[y2].set_content(y1_content)
		@selection_y -= 1
		@cursor_y -= 1
		@model_iterator.set_y(@cursor_y)
		if @cursor_y <= @scroll_y + (@number_of_cells_y / 2)
			@scroll_y -= 1
		end
		@scroll_y = 0 if @scroll_y < 0
		reload_lines
		reload_current_line
		lexer_sync
		dirty_all
		true
	end
	def indent(text)
		x = @editor.cursor_x
		moveto_line_begin
		insert_text(text)
		reload_current_line(x)
	end
	def indent_selection(text)
		return false unless @selection_mode
		x = @editor.cursor_x
		xy1 = [@editor.cursor_x, @cursor_y]
		xy2 = [@selection_x, @selection_y]
		y1, x1, y2, x2 = sort_by_yx(xy1, xy2)
		$logger.debug(2) { "x1=#{x1} y1=#{y1} x2=#{x2} y2=#{y2}" }
		y2 -= 1 if x2 == 0
		y = y1
		while y <= y2
			@model.lines[y].content[0, 0] = text
			lcache_clear(y-scroll_y)
			y += 1
		end
		reload_current_line(x)
		dirty_all
	end
	def unindent
		text = @model.lines[@cursor_y].content
		m = /\A\s+/.match(text)
		return false unless m
		x = @editor.cursor_x
		moveto_line_begin  
		through_tabs = @editor.cursor_through_tabs
		@editor.use_cursor_through_tabs_strategy(false)
		while @editor.cursor_x < @tabsize
			if @model_iterator.has_next? 
				char = @model_iterator.current
				if char != ' ' and char != "\t"
					break
				end
			end
			move_right
		end
		while @editor.cursor_x > 0
			backspace
		end
		@editor.use_cursor_through_tabs_strategy(through_tabs)
		reload_current_line(x)
		true
	end
	def unindent_selection
		return false unless @selection_mode
		x = @editor.cursor_x
		cy = @cursor_y
		xy1 = [@editor.cursor_x, @cursor_y]
		xy2 = [@selection_x, @selection_y]
		y1, x1, y2, x2 = sort_by_yx(xy1, xy2)
		$logger.debug(2) { "x1=#{x1} y1=#{y1} x2=#{x2} y2=#{y2}" }
		y2 -= 1 if x2 == 0
		y = y1
		moveto_line_begin
		while y <= y2
			@model_iterator.prev while @model_iterator.has_prev?
			@model_iterator.set_y(y)  
			@cursor_y = y
			unindent
			y += 1
		end
		@model_iterator.prev while @model_iterator.has_prev?
		@model_iterator.set_y(cy)
		@cursor_y = cy
		reload_current_line(x)
		dirty_all
		true
	end
	def search(pattern)
		return unless pattern
		@search_pattern_last = pattern
		re = Regexp.new(Regexp.escape(pattern))
		cy = @cursor_y
		mx = @model_iterator.x+1
		@cursor_y.upto(@model.lines.size-1) do |y|
			text = @model.lines[y].text
			if y == cy
				linetext = @model.lines[y].text 
				text = linetext[mx, text.size-mx] 
			else
				mx = 0
			end
			match = re.match(text) 
			next unless match
			@cursor_y = y
			@model_iterator.set_y(y)
			reload_current_line_modelx(mx + match.end(0))
			selection_init
			reload_current_line_modelx(mx + match.begin(0))  
			scroll_to_cursor
			reload_lines
			dirty_all
			return true
		end
		false
	end
	def search_again  
		return false unless @search_pattern_last
		search(@search_pattern_last)
	end
	def enter_replace_mode(search_pattern, replacement_string)
		search(search_pattern)
		@replacement_string = replacement_string
	end
	def mode_accept
		selection_erase
		insert_text(@replacement_string)
		search_again
	end
	def mode_skip
		search_again
	end
	def bookmark(name)
		@bookmarks[name] = @cursor_y
	end
	# if delta is positive then lines are inserted
	# if delta is negative then lines are removed
	def adjust_bookmarks(y, delta)
		return if delta == 0
		if delta < 0
			@bookmarks.each do |key, yval|
				if (yval > y) and (yval <= y-delta)
					@bookmarks[key] = y
				end
			end
		end
		@bookmarks.each do |key, yval|
			@bookmarks[key] = yval + delta if yval > y
		end
	end
	def swap_bookmarks(y1, y2)
		return if y1 == y2
		bm1 = []
		bm2 = []
		@bookmarks.each do |key, yval|
			bm1 << key if yval == y1
			bm2 << key if yval == y2
		end
		bm1.each {|key| @bookmarks[key] = y2 }
		bm2.each {|key| @bookmarks[key] = y1 }
	end
	def goto_bookmark(name)
		y = @bookmarks[name]
		@cursor_y = y
		@model_iterator.set_y(y)
		reload_current_line
		scroll_to_cursor
		reload_lines
		dirty_all
	end
	def lcache_clear(line)
		return if line < 0 or line >= @lexer_cache_valid.size
		@lexer_cache_valid[line] = false
		@lexer_cache_lines[line] = nil
	end
	def lcache_insert_line(index, invalidate_rendering=true)
		# TODO: I should really be using a struct here
		@lexer_cache_valid.insert(index, false)
		@lexer_cache_valid.pop
		state = @lexer_cache_states[index]
		state.map!{|i| i.clone} if state
		@lexer_cache_states.insert(index, state)
		@lexer_cache_states.pop
		@lexer_cache_lines.insert(index, nil)
		@lexer_cache_lines.pop
		unless invalidate_rendering
			@render_valid.insert(index, false)
			@render_valid.pop
		else
			index.upto(@lexer_cache_valid.size-1) do |index|
				render_dirty(index)
			end
		end
	end
	def lcache_remove_line(index, invalidate_rendering=true)
		# TODO: I should really be using a struct here
		@lexer_cache_valid.delete_at(index)
		@lexer_cache_valid.push(false)
		@lexer_cache_states.delete_at(index)
		@lexer_cache_states.push(nil)
		@lexer_cache_lines.delete_at(index)
		@lexer_cache_lines.push(nil)
		unless invalidate_rendering
			@render_valid.delete_at(index)
			@render_valid.push(false)
		else
			index.upto(@lexer_cache_valid.size-1) do |index|
				render_dirty(index)
			end
		end
	end
	def sync_lcache
		#require 'profiler.rb'
		#Profiler__.start_profile
		times = []
		times << Time.now.to_f
		n_lexed_lines = 0
		lexer_sync
		last = @lexer_states.last
		with_iterator_begin do |line_iterator|
			line_iterator.each_with_index do |line, index| 
				times << Time.now.to_f
				if @lexer_cache_valid[index]
					last = @lexer_cache_states[index] 
					next
				end
				render_dirty(index)
				result = nil
				unless line.kind_of?(Buffer::View::Line::Empty)
					model_line = line.model_iterator.current
					str1 = model_line.content.expand_tabs(@tabsize)
					@lexer.set_states(last.map{|i| i.clone})
					@lexer.set_result([])
					@lexer.format_end(:end)
					@lexer.lex_line(str1)
					txtsym_pairs = @lexer.result
					result_end = @lexer.result_endofline

					# maybe propagate to next line
					last = @lexer.states
					if last != @lexer_cache_states[index]
						$logger.debug(2) { "last=#{last.inspect} != " + 
							"nextstate=#{@lexer_cache_states[index].inspect}" }
						@lexer_cache_states[index] = last
						if index+1 < @lexer_cache_valid.size
							@lexer_cache_valid[index+1] = false
						end
					end

					lettersym_pairs = []
					txtsym_pairs.each do |txt, sym|
						letters = txt.split(//).each do |letter|
							lettersym_pairs << [letter, sym]
						end
					end
					if model_line.newline.size > 0
						lettersym_pairs << [model_line.newline, result_end]
					end
					result = [lettersym_pairs, result_end]
				end
				@lexer_cache_lines[index] = result
				@lexer_cache_valid[index] = true
				n_lexed_lines += 1
			end
		end
		times << Time.now.to_f
		t1 = times.shift
		restimes = times.map{|t| "%.4f" % (t-t1)}
		$logger.debug(2) { "sync timing = [" + restimes.join(" ") + "]" }
		#Profiler__.stop_profile
		$logger.debug(2) { "sync_lcache lines_recomputed = #{n_lexed_lines}" }
		#Profiler__.print_profile(STDOUT)
	end
	def render_dirty(view_line_number)
		return if view_line_number < 0
		return if view_line_number >= @render_valid.size
		@render_valid[view_line_number] = false
	end
	def render_dirty_all
		@render_valid.map!{false}
	end
	def output_cells
		cellsx = @number_of_cells_x
		scrollx = @scroll_x
		sync_lcache
		output = []
		@render_valid.each_with_index do |valid, index|
			$logger.debug(2) { "iterate valid=#{valid} index=#{index}" }
			if valid
				output << nil
				next
			end
			line_endstate = @lexer_cache_lines[index]
			unless line_endstate
				output << ([[' ', :empty]] * cellsx).transpose
				next
			end
			line, endofline_state = line_endstate

			# cloning
			lettersym_pairs = line.map{|(letter, sym)| [letter, sym] }
			(scrollx+cellsx-lettersym_pairs.size).times { 
				lettersym_pairs << [' ', endofline_state] 
			}
			data = lettersym_pairs.slice!(0, scrollx)
			# decorate with left-arrows
			left_arrow = data.any? do |(char, sym)|
				(char != ' ' and char != "\t" and char != "\n")
			end               
			lettersym_pairs[0][0] = "\001" if left_arrow

      # decorate with line numbers
      if false
				linenum = index+@scroll_y+1
				("%4i  " % linenum).split(//).reverse_each do |letter|
					lettersym_pairs.unshift([letter, :linenumber])
				end
      end
			
			# decorate with right-arrows
			n = lettersym_pairs.size
			if n > cellsx
				lettersym_pairs[cellsx-1][0] = "\002"
			end
			lettersym_pairs.slice!(cellsx, n-cellsx)
			output << lettersym_pairs.transpose
		end
		@render_valid.map!{true} 
		output
	end
end # class Caretaker

end # module View

end # module Buffer
