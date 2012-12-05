require 'aeditor/backend/edit'
require 'aeditor/backend/buffer_objects'
require 'aeditor/backend/buffer_vertical'
require 'aeditor/backend/convert'
require 'aeditor/backend/render'
require 'aeditor/backend/buffer_file'
require 'aeditor/backend/buffer_line'
require 'observer'

class LineEdit < Edit
	def initialize(tabsize=8, cursor_through_tabs=false)
		super(LineObjects::Text.new(32))
		install_editor(LineObjects::Text, EditObjects::Object.new(self))
		install_editor(
			LineObjects::Tab, 
			(cursor_through_tabs) ?
			EditObjects::TabThrough.new(self, tabsize) :
			EditObjects::Tab.new(self, tabsize)
		)
		install_editor(LineObjects::Fold, EditObjects::Fold.new(self))

		install_editor(
			LineObjects::VSpace, 
			EditObjects::VSpace.new(self)
		)
		@vspace_enable = true
		@vspace = LineObjects::VSpace.new
		push_right(vspace)

		@line = Line.new
	end
	attr_reader :vspace, :line

	def replace_line(line)
		old_line = @line
		@line = line
		new_data = line.lineobjs
		new_data.push(vspace)
		old_data = replace_content(new_data)
		old_data.pop  # remove vspace
		old_line.set_data(old_data)
		old_line
	end
	def size_bytes 
		bytes = left_bytes + right_bytes
		bytes += 1 if @line.newline
		bytes
	end
	def size_visible_lines
		return 1 if @line.newline
		0
	end
	def left_visible_lines
		0
	end
	def size_physical_lines
		nl = (@line.newline) ? 1 : 0
		left_physical_lines + right_physical_lines + nl
	end
	def is_end
		return super() unless @vspace_enable
		return true if @current == vspace
		return false if @current != nil
		return true if @right == [vspace]
		return true if @right == []
		false
	end
	def lineobjs
		lo = [] + left
		lo << current if current != nil
		lo += right
		lo
	end
	def get_right_newline_as_buffer_objects
		lo = [] + @right
		lo.pop # remove VSpace
		bo = Convert::from_lineobjs_into_bufferobjs(lo)
		bo << BufferObjects::Newline.new if self.line.newline
		bo
	end
	def get_right_as_buffer_objects
		lo = [] + @right
		lo.pop # remove VSpace
		bo = Convert::from_lineobjs_into_bufferobjs(lo)
		bo
	end
	def get_state_as_buffer_objects
		x, line_lo = self.create_memento
		bo = Convert::from_lineobjs_into_bufferobjs(line_lo)
		bo << BufferObjects::Newline.new if self.line.newline
		[x, bo]
	end
	def only_spaces?
		cnt = left.size + right.size
		cnt += 1 if current != nil
		cnt -= 1 # because of VSpace
		x, indent_lo = measure_indent
		#$log.puts "#{indent_lo.size} #{cnt}"
		(indent_lo.size >= cnt) 
	end
	def zap_right
		res = super()
		@right = [vspace]
		res
	end
	def reset
		super
		push_right(@vspace)
	end
end

# purpose:
# the model in the MVC pattern.
#
# todo:
#
class Buffer
	include BufferLine
	include BufferVertical
	include Observable

	class Blocking
		def initialize
			@enabled = false
			@x = 0
			@y = 0
		end
		attr_reader :enabled, :x, :y
		def enable(x, y)
			@enabled = true
			@x = x
			@y = y
		end
		def disable!
			@enabled = false
		end
		def set_x(x)
			@x = x
		end
		def set_y(y)
			@y = y
		end
	end
	module Memento
		class All
			def initialize(x, y, bufobjs, blocking)
				@x = x
				@y = y
				@bufobjs = bufobjs
				@blocking = blocking
			end
			attr_reader :x, :y, :bufobjs, :blocking
		end
		class Line
			def initialize(x, bufobjs)
				@x = x
				@bufobjs = bufobjs
			end
			attr_reader :x, :bufobjs
		end
		class Position
			def initialize(x, y)
				@x = x
				@y = y
			end
			attr_reader :x, :y
		end
	end


	def initialize(tabsize = 4, cursor_through_tabs=true, autoindent=true)
		@tabsize = tabsize
		@option_autoindent = autoindent

		@filename = "unnamed"

		# render buffer content
		@render = Render.new
		@render.set_tabsize(@tabsize)

		# contains buffer-objects
		@data_top = BufferObjectArray.new
		@data_bottom = BufferObjectArray.new

		# contains line-objects
		@line_top = LineArray.new
		@line_bottom = LineArray.new

		# blocking mode
		@blocking = Blocking.new
		@clipboard = []

		# setup edit
		@notify_lock = 0 
		@edit = LineEdit.new(@tabsize, cursor_through_tabs)
		clear_dirty
		@edit.add_observer(self)
	end
	attr_reader :tabsize, :filename, :clipboard, :blocking
	attr_reader :data_bottom

	def set_clipboard(buf_objs)
		@clipboard = buf_objs
	end

	# import_bottom uses this method to decide if the last-line
	# is terminated with newline. If so then an empty line will
	# be imported.
	def bottom_newline?
		@line_bottom.data.reverse_each { |line|
			return line.newline if line != nil
		}
		@edit.line.newline
	end
	def total_bytes
		@data_top.bytes + @line_top.bytes + @edit.size_bytes +
		@line_bottom.bytes + @data_bottom.bytes
	end
	def position_bytes
		@data_top.bytes + @line_top.bytes + @edit.left_bytes
	end
	def total_physical_lines
		@data_top.physical_lines + @line_top.physical_lines + 
		@edit.size_physical_lines + @line_bottom.physical_lines +
		@data_bottom.physical_lines
	end
	def position_physical_lines
		@data_top.physical_lines + @line_top.physical_lines +
		@edit.left_physical_lines
	end
	def total_visible_lines
		@data_top.visible_lines + @line_top.visible_lines +
		@edit.size_visible_lines + @line_bottom.visible_lines +
		@data_bottom.visible_lines
	end
	def position_visible_lines
		@data_top.visible_lines + @line_top.visible_lines +
		@edit.left_visible_lines
	end
	def position_visible_lines_view
		@data_top.visible_lines
	end
	def clear_dirty
		@dirty_cursor = false
		@dirty_line = false
		@dirty_all = false
	end
	def set_dirty_all
		@dirty_all = true
	end
	# we get notify from @edit
	def update(cursor_changed, content_changed)
		@dirty_cursor |= cursor_changed
		@dirty_line |= content_changed
	end

	def position_x
		@edit.position
	end
	def position_y
		@line_top.size
	end
	def visible_lines
		@line_top.size + 1 + @line_bottom.size
	end
	def each_line
		@line_top.each { |line| 
			if line == nil
				cells = nil # empty lines (should not occur)
			else
				cells = @render.render(line.lineobjs)
			end
			yield cells
		}
		yield(edit_to_cells)
		@line_bottom.each { |line| 
			if line == nil
				cells = nil # empty lines
			else
				cells = @render.render(line.lineobjs)
			end
			yield cells
		}
	end
	def edit_to_cells
		@render.render(@edit.lineobjs)
	end
	def replace_current_line(line)
		@edit.replace_line(line)
	end
	# purpose:
	# replace content of the whole buffer, 
	# place cursor at Begin of Buffer
	def replace_content(bufobjs)
		height = visible_lines

		# load new content.. hackish.. but works
		@data_top.replace([])
		@line_top.replace([])
		@line_bottom.replace([])
		@data_bottom.replace(bufobjs)
		begin
			import_bottom(false)  # empty lines is NOT allowed!
		rescue BufferBottom
			# in case of an empty line
			@line_bottom.push(Line.new([], false)) 
		end
		change_focus_to_line_below
		@line_top.replace([])

		adjust_height(height)
	end
	def file_save
		BufferFile.save(create_memento.bufobjs, @filename, @filename+".bak")
	end
	def file_open(file)
		bo = BufferFile.open(file)
		@filename = file
		set_memento(Memento::All.new(0, 0, bo, Blocking.new))
	end
	# determine if we are on the *last* line in the buffer
	def is_last_line?
		not @line_bottom.data.any?
	end
	# purpose:
	# adjust cursor so it is within the view
	def force_range_x(min, width)
		@edit.force_range(min, width)
	end
	def notify_scope
		mem_old = create_memento_position

		if @notify_lock == 0
			clear_dirty
		end
		
		begin
			@notify_lock += 1 
			@edit.notify_scope {
				result = yield
			}
			#yield
			#result = true
		rescue CommandHarmless => e
			#puts "exception occured: #{e}"
			#$log.print_exception(e)
			result = false
		ensure
			@notify_lock -= 1
		end
		return result if @notify_lock != 0

		cursor = @dirty_cursor
		line = @dirty_line
		all = @dirty_all

		if @blocking.enabled
			mem = create_memento_position
			if mem.y != mem_old.y
				all = true
			elsif mem.x != mem_old.x
				line = true
			end
		end

		if cursor or line or all
			changed
			notify_observers(
				cursor,  # true if cursor has moved
				line,    # true if current_line has changed
				all      # true if multiple lines changes
			)
		end

		result
	end
	def adjust_height(height)
		raise "window is too small" if height < 1 
		#resize_bottom(height)
		resize_center(height)
	end
	def cmd_adjust_height(height)
		#return if height == @height
		adjust_height(height)
		@dirty_all = true
	end
	def cmd_insert(obj)
		@edit.insert(obj)
	end
	def cmd_backspace
		@edit.backspace
	end
	def cmd_move_home(toggle_mode = false)
		if toggle_mode == false
			return @edit.move_home(toggle_mode) 
		elsif @edit.only_spaces? == false
			return @edit.move_home(toggle_mode) 
		end
		# search backwards, find indentation
		old_position = @edit.position
		state = create_memento_position
		begin
			cmd_move_up while @edit.only_spaces?
			x, = @edit.measure_indent
		rescue BufferTop
			x = 0
		end
		set_memento_position(state) # todo: restore scrolling position

		# yes this can happen, see #test_indent_home5 
		raise CommandHarmless if (x == old_position) and (x == 0)

		# goto begin of line
		harmless { @edit.move_home(false) }
		return if x == old_position

		# goto indentation point
		@edit.move_right while @edit.position < x
	end
	def cmd_move_end
		@edit.move_end
	end
	def cmd_move_left
		@edit.move_left
	end
	def cmd_move_right
		@edit.move_right
	end
	def cmd_move_up
		move_up
		@dirty_cursor = true
	end
	def cmd_move_down
		move_down
		@dirty_cursor = true
	end
	def preserve_x
		x = position_x
		yield
	ensure
		harmless { @edit.move_home(false) }
		@edit.move_right while @edit.position < x
	end
	def cmd_move_page_up(height=nil)
		preserve_x {
			move_page_up(height || visible_lines)
		}
		@dirty_cursor = true
	end
	def cmd_move_page_down(height=nil)
		preserve_x {
			move_page_down(height || visible_lines)
		}
		@dirty_cursor = true
	end
	def scroll_up(cursor_follow=false)
		super(cursor_follow)
		@dirty_all = true
	end
	def cmd_scroll_up
		scroll_up
	end
	def scroll_down(cursor_follow=false)
		super(cursor_follow)
		@dirty_all = true
	end
	def cmd_scroll_down
		scroll_down
	end
	def cmd_scroll_page_up
		scroll_page_up
	end
	def cmd_scroll_page_down
		scroll_page_down
	end
	# purpose:
	# split current-line at the cursor position.
	# place cursor on the next line.
	# do autoindentation if enabled.
	def cmd_breakline
		indent_lineobjs = LineIndent.extract_indent(@edit.left)
		split_zap = (@edit.left.size > indent_lineobjs.size)
		clear_indent = false
		unless @option_autoindent
			clear_indent = true unless split_zap
			split_zap = true
			indent_lineobjs = []
		end
		if split_zap
			@edit.split if @edit.current
			lo = @edit.zap_left
		else
			clear_indent = true
		end
		if clear_indent
			lo = []
			indent_lineobjs = []
		end
		line = Line.new(lo, true)
		@line_top.push(line)
		if @line_bottom.empty? #last_line
			export_top
		else
			export_bottom
		end
		indent_lineobjs.each {|lo| @edit.insert(lo)}
		@dirty_all = true
	end
	# purpose:
	# join previous-line into current-line. 
	# place cursor at join-point.
	def cmd_joinline
		if @line_top.empty?
			import_top 
		else
			import_bottom  # allow empty lines
		end
		line = @line_top.pop
		harmless { cmd_move_home }
		line.lineobjs.each do |lo|
			cmd_insert(lo)
		end
		@dirty_all = true
	end
	def cmd_block_begin
		@blocking.enable(position_x, position_visible_lines)
	end
	def remove_backward(x, y)
		height = visible_lines
		lines = (position_visible_lines - y) - 1
		while lines > 0  # remove full lines
			import_top if @line_top.empty? 
			line = @line_top.pop
			lines -= 1
		end
		if lines >= 0  # skip if block is a oneliner 
			@edit.zap_left
			cmd_joinline
		end
		cmd_backspace until position_x <= x
		safe_import(0, height - visible_lines)
	end
	def goto_block_end(x, y)
		# swap current position with block_xy if necessary
		cy = position_visible_lines
		cx = position_x
		if (cy < y) or ((cy == y) and (cx < x))
			set_memento_position(Memento::Position.new(x, y))
			return [cx, cy]
		end
		[x, y]
	end
	def cmd_block_remove
		raise CommandHarmless if @blocking.enabled == false
		x = @blocking.x
		y = @blocking.y
		x, y = goto_block_end(x, y)
		remove_backward(x, y)
		@blocking.disable!
		@dirty_all = true
	end
	def copy_data(x, y)
		mem = create_memento(Buffer::Memento::Position)
		x, y = goto_block_end(x, y)
		lines = (position_visible_lines - y) - 1
		if lines >= 0 # spanning multiple lines
			# copy left part
			line_objs = @edit.left
			bo = Convert::from_lineobjs_into_bufferobjs(line_objs)
			# copy full lines
			harmless { cmd_move_home(false) }
			while lines > 0  # remove full lines
				cmd_move_up
				bo = @edit.get_right_newline_as_buffer_objects + bo
				lines -= 1
			end
			# copy right part
			set_memento_position(Memento::Position.new(x, y))
			bo = @edit.get_right_newline_as_buffer_objects + bo
		else # oneliner
			state = @edit.create_memento
			@edit.zap_right
			@edit.move_left until @edit.position <= x
			@edit.zap_left
			bo = @edit.get_right_as_buffer_objects
			@edit.set_memento(state)
		end
		set_memento_position(mem)
		bo
	end
	def cmd_block_copy
		raise CommandHarmless if @blocking.enabled == false
		@clipboard = copy_data(@blocking.x, @blocking.y)
		@blocking.disable!
		@dirty_all = true
	end
	def cmd_block_paste(paste_data=@clipboard)
		save = @option_autoindent
		@option_autoindent = false
		paste_data.each do |bo|
			case bo
			when BufferObjects::Newline
				cmd_breakline
			else
				lo = Convert::from_bufferobjs_into_lineobjs([bo])[0]
				cmd_insert(lo)
			end
		end
		@option_autoindent = save
		@dirty_all = true
	end
	def fold_locate
		found = false
		@edit.scan_right do |i|
			if i.kind_of?(LineObjects::Fold)
				found = true
				break
			end
		end
		raise CommandHarmless if not found
	end
	def cmd_fold_expand
		fold_locate # cursor must point at fold in order to unlink
		mem = create_memento_position
		fold = @edit.unlink_fold!
		cmd_block_paste(fold.child_bufobjs)
		set_memento_position(mem, false)
	end
	def scan_foldtag_begin
		mem = nil
		state = 0
		found = false
		@edit.scan_right do |i|
			break if found
			str = nil
			if i.kind_of?(LineObjects::Text)
				str = i.ascii_value.chr
			end
			case state
			when 0
				mem = create_memento_position
				state = 1 if str == "#"
			when 1
				found = true if str == "["
				state = 0
			end
		end
		if found 
			set_memento_position(mem)
		end
		found
	end
	def fold_goto_begin
		loop do
			return if scan_foldtag_begin
			begin
				move_up
			rescue BufferTop
				raise FoldTagbeginMissing
			end
		end
	end
	def scan_foldtag_end
		state = 0
		found = false
		@edit.scan_right do |i|
			break if found
			str = nil
			if i.kind_of?(LineObjects::Text)
				str = i.ascii_value.chr
			end
			case state
			when 0
				state = 1 if str == "#"
			when 1
				found = true if str == "]"
				state = 0
			end
		end
		found
	end
	def fold_goto_end
		loop do
			return if scan_foldtag_end
			begin
				move_down
			rescue BufferBottom
				raise FoldTagendMissing
			end
		end
	end
	def fold_get_begin_goto_end
		memento = create_memento_position
		fold_goto_begin
		xy_begin = create_memento_position
		set_memento_position(memento, false)
		fold_goto_end
		[xy_begin.x, xy_begin.y]
	rescue # we could not find fold-begin/end tags
		set_memento_position(memento, false)
		raise
	end
	def fold_make_title(data)
		title = ""
		data.each do |i|
			if i.kind_of?(BufferObjects::Text)
				title << i.ascii_value.chr
			end
			break if i.kind_of?(BufferObjects::Newline)
		end
		title.slice!(0, 2) # remove "#[" foldtag-begin
		title.strip!
		bytes, phys, vis = Measure::count(data)
		str = vis.to_s
		str += " " + title unless title.empty?
		"[ #{str} ]"
	end
	# identify begin/end of fold, this requires
	# knowledge about the specific-language which 
	# the buffer is representing.
	def cmd_fold_collapse
		# implementation plan: only parse ruby
		# later parse other languages.
		x, y = fold_get_begin_goto_end
		data = copy_data(x, y)
		remove_backward(x, y) 
		title = fold_make_title(data)
		fold = LineObjects::Fold.new(data, title, false)
		cmd_insert(fold)
	#rescue
		# no harm done
	end
private
	def harmless
		begin
			yield
		rescue CommandHarmless
		end
	end
	# purpose:
	# take a snapshot of the current state (everything)
	def create_memento_all
		# data_top
		bo = @data_top.data
		# line_top
		@line_top.data.each do |line|
			bo += Convert::from_lineobjs_into_bufferobjs(line.lineobjs)
			bo << BufferObjects::Newline.new if line.newline
		end
		# current line
		x, edit_bo = @edit.get_state_as_buffer_objects
		bo += edit_bo
		# line_bottom
		@line_bottom.data.each do |line|
			break unless line # empty lines can occur at bottom of file
			bo += Convert::from_lineobjs_into_bufferobjs(line.lineobjs)
			bo << BufferObjects::Newline.new if line.newline
		end
		# data_bottom
		bo += @data_bottom.data

		y = position_visible_lines
		Memento::All.new(x, y, bo, @blocking.deep_clone)
	end
	# purpose:
	# restore an earlier state (everything)
	def set_memento_all(state)
		height = [@line_top.size, @line_bottom.size]
		replace_content(state.bufobjs)
		cmd_move_down while position_visible_lines < state.y
		harmless { cmd_move_home }
		cmd_move_right while position_x < state.x
		@blocking = state.blocking
		resize_topbottom(*height)
		@dirty_all = true
	end
	# purpose:
	# take a snapshot of the current state (current-line-only)
	def create_memento_current_line
		x, bo = @edit.get_state_as_buffer_objects
		Memento::Line.new(x, bo)
	end
	# purpose:
	# restore an earlier state (current-line-only)
	def set_memento_current_line(memento)
		x = memento.x 
		bo = memento.bufobjs
		newline = false
		if bo.last.kind_of?(BufferObjects::Newline)
			newline = true
			bo.pop
		end
		lo = Convert::from_bufferobjs_into_lineobjs(bo)
		line = Line.new(lo, newline)
		replace_current_line(line)
		harmless { cmd_move_home }
		cmd_move_right while position_x < x
		@dirty_line = true
	end
	# purpose:
	# take a snapshot of the current state (x, y only)
	def create_memento_position
		x = @edit.position
		y = position_visible_lines
		Memento::Position.new(x, y)
	end
	def set_memento_position(memento, lock_view_y=false)
		x = memento.x
		y = memento.y
		harmless { cmd_move_home }
		if lock_view_y
			begin
				scroll_down(true) while position_visible_lines < y
				scroll_up(true) while position_visible_lines > y
			rescue
			end
		end
		# in case scrolling fails then try movement
		cmd_move_down while position_visible_lines < y
		cmd_move_up while position_visible_lines > y

		cmd_move_right while position_x < x
	end
public
	def create_memento(type = Memento::All)
		case type.object_id
		when Memento::All.object_id
			return create_memento_all
		when Memento::Line.object_id
			return create_memento_current_line
		when Memento::Position.object_id
			return create_memento_position
		else
			raise <<MSG
Buffer#create_memento: unknown type (#{type.inspect}), thus dont know what to do.
MSG
		end
	end
	def set_memento(memento, lock_view_y=false)
		case memento
		when Memento::All
			set_memento_all(memento)
		when Memento::Line
			set_memento_current_line(memento)
		when Memento::Position
			set_memento_position(memento, lock_view_y)
		else
			raise <<MSG
Buffer#set_memento: unknown type (#{memento.inspect}), thus dont know what to do.
MSG
		end
	end
end

if $0 == __FILE__
	require 'aeditor/ncurses/frontend'
	begin
		$log = File.new("log", "w+")
		buf = Buffer.new
		view = ViewNcurses.new(buf)
		buf.add_observer(view)
		buf.file_open(__FILE__)
		buf.adjust_height(view.cellarea.gety)
		view.update(buf)
		ctrl = ControlNcurses.new(buf, view)
		loop do
			event = view.cellarea.waitkey
			ctrl.dispatch(event)
		end
		view.cellarea.close
	rescue Exception => e
		view.cellarea.close
		raise e, e.message, e.backtrace
	end
end
