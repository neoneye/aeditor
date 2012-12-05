lang = ENV['LANG']
unless lang.match(/[a-z]{2}_[A-Z]{2}\.UTF-8/)
	puts "the LANG environment variable is not correct"
	exit
end


require 'dl/import'
require 'dl/struct'
module Curses
	extend DL::Importable
	dlload 'libncursesw.so'
	
	typealias 'NCURSES_SIZE_T', 'short'
	typealias 'chtype', 'unsigned long'
	typealias 'attr_t', 'chtype'
	typealias 'bool', 'int'
	
	WINDOW = struct [
		# current cursor position
		'NCURSES_SIZE_T cury',
		'NCURSES_SIZE_T curx',

		# window location and size
		# maximums of x and y, NOT window size 
		'NCURSES_SIZE_T maxy',
		'NCURSES_SIZE_T maxx',
		# screen coords of upper-left-hand corner
		'NCURSES_SIZE_T begy', 
		'NCURSES_SIZE_T begx',

		# window state flags
		'short flags',

		# attribute tracking
		'attr_t attrs',    # current attribute for non-space character
		'chtype bkgd',     # current background char/attribute pair

		# option values set by user
		'bool notimeout',  # no time out on function-key entry?
		'bool clear',      # consider all data in the window invalid?
		'bool leaveok',    # OK to not reset cursor on exit?
		'bool scroll',     # OK to scroll this window?
		'bool idlok',      # OK to use insert/delete line?
		'bool idcok',      # OK to use insert/delete char?
		'bool immed',      # window in immed mode? (not yet used)
		'bool sync',       # window in sync mode?
		'bool use_keypad', # process function keys into KEY_ symbols?
		'int delay',       # 0 = nodelay, <0 = blocking, >0 = delay
		
		# the actual line data
		'void *line',    # TODO: ldat is used.. but what is ldat?
		
		# global screen state
		'NCURSES_SIZE_T regtop', # top line of scrolling region
		'NCURSES_SIZE_T regbottom', # bottom line of scrolling region
		
		# these are used only if this is a sub-window
		'int parx',  # x coordinate of this window in parent
		'int pary', # y coordinate of this window in parent
		# pointer to parent if a sub-window
		'void *parent',   # TODO: this is a struct window * pointer
		
		# these are used only if this is a pad
		'NCURSES_SIZE_T pad_y',
		'NCURSES_SIZE_T pad_x',
		'NCURSES_SIZE_T pad_top',
		'NCURSES_SIZE_T pad_left',
		'NCURSES_SIZE_T pad_bottom',
		'NCURSES_SIZE_T pad_right',
		
		# real begy is _begy + _yoffset
		'NCURSES_SIZE_T yoffset'
	]

	# setup
	extern 'void *initscr()'
	extern 'int cbreak()'
	extern 'int keypad(void *, bool)'
	extern 'int noecho()'
	extern 'int nonl()'
	extern 'int meta(void *, bool)'

	# teardown
	extern 'int endwin()'

	# runtime
	extern 'int clear()'
	extern 'int addstr(const char *)'
	extern 'int getch()'
	extern 'int refresh()'
	extern 'int addnstr(const char *, int)'
	extern 'int move(int, int)'
end

module LibC
	extend DL::Importable
	dlload 'libc.so.6'
	extern 'void setlocale(int, const char *)'
end

class CursesCanvas
	def initialize
		LibC.setlocale(6, '')  # LC_ALL == 6
		ptr = Curses.initscr
		@window = Curses::WINDOW.new(ptr)
		Curses.cbreak          # TODO: what does this do?
		Curses.noecho          # TODO: what does this do?
		Curses.nonl            # TODO: what does this do?
		Curses.keypad(ptr, 1)  # TODO: what does this do?
		Curses.meta(ptr, 1)    # force 8bit instead of 7bit
	end
	def close
		Curses.endwin
	end
	def self.open(&block)
		i = self.new
		block.call(i)
		i.close
	end
	def width
		@window.maxx+1
	end
	def height
		@window.maxy+1
	end
	alias :w :width
	alias :h :height
	def print(utf8_string)
		Curses.addnstr(utf8_string, utf8_string.size)
	end
	def puts(utf8_string)
		s = utf8_string
		Curses.addnstr(s, s.size)
	end
	def p(obj)
		s = obj.inspect
		Curses.addnstr(s, s.size)
	end
	def getch
		Curses.getch
	end
	def clear
		Curses.clear
	end
	def move(x, y)
		Curses.move(y, x)
	end
	def printxy(x, y, str)
		move(x, y)
		print(str)
	end
	def box(x, y, w, h)
		str_h = [0x2500].pack("U*")
		str_v = [0x2502].pack("U*")
		str_tl = [0x250c].pack("U*")
		str_tr = [0x2510].pack("U*")
		str_bl = [0x2514].pack("U*")
		str_br = [0x2518].pack("U*")
		(y+1).upto(y+h-2) do |i|
			printxy(x, i, str_v)
			printxy(x+w-1, i, str_v)
		end
		(x+1).upto(x+w-2) do |i|
			printxy(i, y, str_h)
			printxy(i, y+h-1, str_h)
		end
		printxy(x, y, str_tl)
		printxy(x+w-1, y, str_tr)
		printxy(x, y+h-1, str_bl)
		printxy(x+w-1, y+h-1, str_br)
	end
end

CursesCanvas.open do |c|
	c.printxy(0, 0, " File | Edit | Buffers | View |")
	c.printxy(c.w-7, 0, "| Help ")
	c.box(0, 1, c.w, c.h-2)
	c.printxy(2, 1, " main.rb ")
	c.printxy(0, c.h-1, "Press F1 for help.")
	c.box(10, 5, c.w-20, c.h-10)
	c.printxy(12, 5, " About AEditor ")
	c.printxy(c.w-15, 5, "[x]")
	c.printxy(11, 6, "w=#{c.w}  h=#{c.h}")
	c.printxy(11, 7, "A programmers editor written entirely in Ruby.")
	c.printxy(11, 8, "By Simon Strandgaard <neoneye@gmail.com>.")
	#c.printxy(11, 9, Curses.curses_version)
	c.move(11, 10)
	5.times do |i|
		key = c.getch
		#c.clear
		c.printxy(11, 10+i, "key = #{key}")
		c.move(11, 11+i)
	end
	c.getch
end