# purpose:
# AEditor Frontend for Ncurses

require 'aeditor/backend/control'
require 'aeditor/backend/cellarea'
require 'aeditor/backend/view'
require 'ncurses'

# purpose:
# Ncurses Controller (MVC pattern) 
#
# issues:
# * hardcoded keybindings
class ControlNcurses < Control
	def initialize(buffer, view)
		super(buffer, view)
		@bindings = {
			Ncurses::KEY_HOME   => :do_move_home, 
			Ncurses::KEY_END    => :do_move_end,   
			Ncurses::KEY_SELECT => :do_move_end,   
			Ncurses::KEY_LEFT   => :do_move_left,
			Ncurses::KEY_RIGHT  => :do_move_right,
			Ncurses::KEY_UP     => :do_move_up,
			Ncurses::KEY_DOWN   => :do_move_down,
			Ncurses::KEY_PPAGE  => :do_move_page_up,
			Ncurses::KEY_NPAGE  => :do_move_page_down, 
			Ncurses::KEY_F3     => :do_block_toggle,
			Ncurses::KEY_F4     => :do_block_paste,
			Ncurses::KEY_F5     => :do_block_remove,
			Ncurses::KEY_F10    => :do_play_macro,  
			13                  => :do_breakline,  
			Ncurses::KEY_BACKSPACE => :do_backspace, 
			127                 => :do_backspace  
		}
	end
	def dispatch(event)
		command = nil
		case event
		when 27  # escape key
			raise ExitClean
		when 32..126,  # ascii range
			128..254   # extended ascii range
			command = Commands::Insert.new(LineObjects::Text.new(event)) 
		when Ascii::TAB 
			command = Commands::Insert.new(LineObjects::Tab.new) 
		when Ncurses::KEY_F7  # expand fold  (normal)
			command = Commands::FoldExpand.new
		when Ncurses::KEY_F8  # collapse fold  (normal)
			command = Commands::FoldCollapse.new
#		when Ncurses::KEY_F8  # insert fake fold  (normal)
#			bo = Convert::from_string_into_bufferobjs("abc\ndef\nghi")
#			fold = LineObjects::Fold.new(bo, "{2}", false)
#			command = Commands::Insert.new(fold) 
		when Ncurses::KEY_F2
			@buffer.file_save
		when Ncurses::KEY_F6
			@scroll_mode = !@scroll_mode
		when Ncurses::KEY_F9
			if @caretaker.record_mode
				@macro = @caretaker.macro_end
			else
				@caretaker.macro_begin
			end
			@view.update
		#when Ncurses::KEY_F11
		#when Ncurses::KEY_F12
		when 21  # CTRL-U  => Undo
			begin
				execute_undo
			rescue Caretaker::Nothing2Undo
				$log.puts "Caretaker: nothing to undo"
			end
		when 18  # CTRL-U  => Redo
			begin
				execute_redo
			rescue Caretaker::Nothing2Redo
				$log.puts "Caretaker: nothing to redo"
			end
		when Ncurses::KEY_RESIZE
			command = Commands::Resize.new(
				@view.cellarea.getx,
				@view.cellarea.gety
			)
		else
			binding = @bindings[event]
			if binding
				command = method(binding).call 
			else
				msg = <<MSG
Control#dispatch:  Unknown event occured
ncurses-event = #{event.inspect}
MSG
				$log.puts msg
			end
		end
		if command
			execute(command)
		end
	end
end # ControlNcurses

# todo:
# * send RESIZE event when appending menues.
# * waitkey is strongly platform dependent at the moment, make
#   it completely independent.
# * seperate menu behavier from cellarea.  Cellarea is only supposed
#   to be used for rendering text.. NOT menues!
#   This could be solved by making an output device class, which
#   has Cellarea as one of its children.
#   /OutputDevice
#       /Cellarea
#       /Status
#       /Menu
class CellareaNcurses < Cellarea
	def initialize
		Ncurses.initscr
		init_colors
		Ncurses.cbreak()                     #
		Ncurses.noecho()                     #
		Ncurses.nonl()                       #
		Ncurses.curs_set(2)                  # 2 = big cursor
		Ncurses.keypad(Ncurses.stdscr, true) #
		Ncurses.meta(Ncurses.stdscr, true)   # force 8bit instead of 7bit
		@window = Ncurses.stdscr
		@x = @window.getmaxx
		@y = @window.getmaxy

		@menu_top = nil
		@menu_bottom = nil
	end
	# todo: send RESIZE event when appending menu
	def set_menu_top(menu)
		@menu_top = menu
	end
	# todo: send RESIZE event when appending menu
	def set_menu_bottom(menu)
		@menu_bottom = menu
	end
	def render_menues
		internal_render_line(0, @menu_top)
		internal_render_line(@window.getmaxy-1, @menu_bottom)
	end
	attr_reader :x, :y
	def getx
		@window.getmaxx
	end
	def gety
		n = 0
		n += 1 if @menu_top != nil
		n += 1 if @menu_bottom != nil
		@window.getmaxy - n
	end
	def close
		Ncurses.move(@window.getmaxy, 0)
		@window.refresh
		Ncurses.curs_set(1)
		Ncurses.endwin()
		$stdout.puts ""
	end
	def cursor_position(x, y)
		y += 1 if @menu_top != nil
		# todo: hilite the cell so that it is *visible*.
		Ncurses.move(y, x)
	end
	def theme_no_color1 
		[
			Ncurses::COLOR_BLACK, Ncurses::COLOR_WHITE, 0,
			Ncurses::COLOR_BLACK, Ncurses::COLOR_WHITE, 0,
			Ncurses::COLOR_BLACK, Ncurses::COLOR_WHITE, 0,
			Ncurses::COLOR_BLACK, Ncurses::COLOR_WHITE, 0,
			Ncurses::COLOR_BLACK, Ncurses::COLOR_WHITE, Ncurses::A_REVERSE|Ncurses::A_BOLD,
			Ncurses::COLOR_BLACK, Ncurses::COLOR_WHITE, Ncurses::A_REVERSE,
			Ncurses::COLOR_BLACK, Ncurses::COLOR_WHITE, 0,
			Ncurses::COLOR_BLACK, Ncurses::COLOR_WHITE, Ncurses::A_UNDERLINE,
			Ncurses::COLOR_BLACK, Ncurses::COLOR_WHITE, Ncurses::A_REVERSE|Ncurses::A_BLINK,
			Ncurses::COLOR_BLACK, Ncurses::COLOR_WHITE, 0
		]
	end
	def theme_white 
		[
			Ncurses::COLOR_BLACK, Ncurses::COLOR_WHITE, 0,
			Ncurses::COLOR_BLACK, Ncurses::COLOR_WHITE, 0,
			Ncurses::COLOR_BLUE, Ncurses::COLOR_CYAN, 0, 
			Ncurses::COLOR_BLACK, Ncurses::COLOR_RED, 0,
			Ncurses::COLOR_BLACK, Ncurses::COLOR_CYAN, 0,
			Ncurses::COLOR_WHITE, Ncurses::COLOR_BLACK, 0,
			Ncurses::COLOR_YELLOW, Ncurses::COLOR_WHITE, 0,
			Ncurses::COLOR_BLACK, Ncurses::COLOR_BLUE, 0,
			Ncurses::COLOR_BLACK, Ncurses::COLOR_CYAN, Ncurses::A_BLINK,
			Ncurses::COLOR_BLACK, Ncurses::COLOR_WHITE, 0
		]
	end
	def theme_black 
		[
			Ncurses::COLOR_BLUE, Ncurses::COLOR_BLACK, 0,
			Ncurses::COLOR_CYAN, Ncurses::COLOR_BLACK, 0,
			Ncurses::COLOR_CYAN, Ncurses::COLOR_BLACK, 0, 
			Ncurses::COLOR_BLACK, Ncurses::COLOR_RED, 0,
			Ncurses::COLOR_BLACK, Ncurses::COLOR_CYAN, 0,
			Ncurses::COLOR_WHITE, Ncurses::COLOR_BLACK, 0,
			Ncurses::COLOR_BLUE, Ncurses::COLOR_BLACK, 0,
			Ncurses::COLOR_RED, Ncurses::COLOR_BLACK, 0,
			Ncurses::COLOR_BLACK, Ncurses::COLOR_CYAN, Ncurses::A_BLINK,
			Ncurses::COLOR_BLACK, Ncurses::COLOR_WHITE, 0
		]
	end
	def theme_blue
		[
			Ncurses::COLOR_WHITE, Ncurses::COLOR_BLUE, 0,
			Ncurses::COLOR_CYAN, Ncurses::COLOR_BLUE, Ncurses::A_BOLD,
			Ncurses::COLOR_CYAN, Ncurses::COLOR_BLACK, 0,
			Ncurses::COLOR_BLACK, Ncurses::COLOR_RED, 0,
			Ncurses::COLOR_BLACK, Ncurses::COLOR_CYAN, Ncurses::A_BOLD,
			Ncurses::COLOR_WHITE, Ncurses::COLOR_BLACK, 0,
			Ncurses::COLOR_RED, Ncurses::COLOR_BLUE, 0,
			Ncurses::COLOR_BLACK, Ncurses::COLOR_BLUE, Ncurses::A_UNDERLINE,
			Ncurses::COLOR_BLACK, Ncurses::COLOR_RED, Ncurses::A_BLINK,
			Ncurses::COLOR_WHITE, Ncurses::COLOR_RED, Ncurses::A_BOLD
		]
	end
	def init_colors
		if Ncurses.has_colors?
			Ncurses.start_color
			
			palette = theme_blue
			#palette = theme_black
			#palette = theme_white
		else
			palette = theme_no_color1
		end
		class << palette
			def each
				until empty?
					a, b, attr = slice!(0, 3)
					yield(a, b, attr)
				end
			end
		end

		i = 0
		@color2attr = Hash.new
		palette.each do |fg, bg, attr|
			Ncurses.init_pair(i+1, fg, bg);
			@color2attr[i] = Ncurses.COLOR_PAIR(i+1) | attr
			i += 1
		end
		
		# background to be used for 'clear' and 'clrtoeol'
		Ncurses.bkgdset(Ncurses.COLOR_PAIR(1))
	end
	def waitkey
		Ncurses.getch
	end
	def internal_render_line(y, cells)
		@window.move(y, 0)
		cells.each do |cell|
			@window.addch(cell.to_s[0] | @color2attr[cell.color])
		end
		Ncurses.clrtoeol if cells.size < getx 
	end
	def render_line(y, cells)
		y += 1 if @menu_top != nil
		internal_render_line(y, cells)
	end
	def refresh
		@window.refresh
	end
	def clear
		Ncurses.clear
	end
#	def sig_resize
#		x = @windows.getmaxx
#		y = @windows.getmaxy
#		resize(x, y)
#	end
#	def resize(x, y)
#		puts "resize: x=#{x}  y=#{y}"
#	end
end # CellareaNcurses


# purpose:
# Ncurses view which supports menues.
#
# issues:
# * hardcoded color-theme.
#
# todo:
# * repaint of the cursor-area is unncessarily slow, because 
#   the menues also gets repainted.
#   1st repaint cursor-area.. 2nd repaint border areas!
# * scroll_up/down/left/right is slow.. this is because
#   it repaints everything.. instead use Ncurses-scrolling
#   features.
#
class ViewNcurses < View
	def initialize(buffer)
		ca = CellareaNcurses.new
		super(buffer, ca)
		ca.set_menu_top(build_menu_top)
		ca.set_menu_bottom(build_menu_bottom)
	end
	def build_menu_top(name = "unnamed", info="xxx %yyy")
		padding = @cell_width - (name.size + info.size)
		if padding > 0
			res = name.to_cells(Cell::MENU)
		else
			padding = @cell_width - info.size
			res = []
		end
		if padding >= 0
			res += (" "*padding).to_cells(Cell::MENU_SEP) +
				"#{info}".to_cells(Cell::MENU)
		else
			padding = @cell_width
			res = (" "*padding).to_cells(Cell::MENU_SEP) 
		end
		res 
	end
	def build_menu_bottom
		if @caretaker == nil
			text = "?"
			color = Cell::MENU
		else
			if @caretaker.record_mode
				text = " Stop "
				color = Cell::MENU_BLINK
			else
				text = "Record"
				color = Cell::MENU
			end
		end
		
		menu = [
			"2", "Save", Cell::MENU,
			" 3", "Block", Cell::MENU,
			" 4", "Paste", Cell::MENU,
			" 5", "Remove", Cell::MENU,
			" 6", "Scroll", Cell::MENU,
			" 7", "Unfold", Cell::MENU,
			" 8", "Fold", Cell::MENU,
			" 9", text, color,
			" 10", "Play", Cell::MENU
		]
		class << menu
			def slice3
				until empty?
					yield(*slice!(0, 3))
				end
			end
		end
		res = []
		menu.slice3 do |sep, text, color|
			res += sep.to_cells(Cell::MENU_SEP) +
				text.to_cells(color)
		end
		padding = @cell_width - res.size
		if padding > 0
			res += (" "*padding).to_cells(Cell::MENU_SEP)
		end
		res
	end
	def rebuild_menues
		percent = Render.percent_to_string(
			@buffer.position_visible_lines,
			@buffer.total_visible_lines
		)    
		current = @buffer.position_physical_lines
		str = "#{current+1} #{percent}"
		@cellarea.set_menu_top(
			build_menu_top(@buffer.filename, str))
		@cellarea.set_menu_bottom(
			build_menu_bottom)
	end
	def render
		rebuild_menues
		@cellarea.render_menues
		super
	end
	def render_line
		rebuild_menues
		@cellarea.render_menues
		super
	end
	def render_cursor
		rebuild_menues
		@cellarea.render_menues
		super
	end
	def adjust_to_new_window_size(width, height)  # todo: height is unused!
		@width = width
		@cell_width = width
	end
end # ViewNcurses  

if $0 == __FILE__
	ca = CellareaNcurses.new
	ca.clear
	ca.render_line(0, "first line".to_cells(Cell::ERROR))
	ca.render_line(1, "hello world".to_cells)
	menu_bottom = 
		"1".to_cells(Cell::MENU_SEP) +
		"help  ".to_cells(Cell::MENU) +
		" 2".to_cells(Cell::MENU_SEP) +
		"save  ".to_cells(Cell::MENU) +
		" 3".to_cells(Cell::MENU_SEP) +
		"mark  ".to_cells(Cell::MENU) +
		(" "*30).to_cells(Cell::MENU_SEP) +
		" 10".to_cells(Cell::MENU_SEP) +
		"exit  ".to_cells(Cell::MENU)
	ca.render_line(ca.y - 1, menu_bottom)
	ca.refresh
	x, y = ca.x, ca.y
	event = ca.waitkey
	ca.close
	puts "sizex=#{x} sizey=#{y}"
	puts "event=#{event.inspect}"
end
