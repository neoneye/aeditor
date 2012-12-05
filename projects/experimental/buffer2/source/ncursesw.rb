lang = ENV['LANG']
if lang == nil or lang.match(/[a-z]{2}_[A-Z]{2}\.UTF-8/) == nil
	$logger.error "the LANG environment variable is not correct"
	exit
end

term = ENV['TERM']
if term == nil or term.match(/xterm-color/) == nil
	$logger.error "the TERM environment variable is not correct"
	exit
end

require 'Tui.so'

class CursesCanvas
	def initialize
		unless Tui.init
			raise 'cannot init'
		end
		@glyph2str = {}
	end
	def close
		Tui.close
	end
	def self.open(&block)
		i = self.new
		begin
			block.call(i)
		ensure
			i.close
		end
	end
	def width
		Tui.width
	end
	def height
		Tui.height
	end
	alias :w :width
	alias :h :height
	def set_color(color)
		Tui.set_color(color)
	end
	def print(utf8_string)
		Tui.print(utf8_string)
	end
	SEQ2KEY = {
		"\eOF" => 270,  # TODO: what code does these have?
		"\eOH" => 271,  # TODO: what code does these have?
		"\eOP" => 265,
		"\eOQ" => 266,
		"\eOR" => 267,
		"\eOS" => 268,
		"\e[5;5~" => 800, # TODO: what code does these have?
		"\e[6;5~" => 801, # TODO: what code does these have?
		"\e[1;5C" => 802, # TODO: what code does these have?
		"\e[1;5D" => 803, # TODO: what code does these have?
	}
	def getch
		key = Tui.getch
		return key if key != 27
		sequence = ''
		Tui.nodelay(true)
		while key >= 0 and key <= 255
			sequence << key.chr
			key = Tui.getch
		end
		Tui.nodelay(false)
		key = SEQ2KEY[sequence] || -1
		#$logger.info "curses getch sequence #{sequence.inspect} -> #{key}"
		key
	end
	def clear
		Tui.clear
	end
	def move(x, y)
		Tui.move(x, y)
	end
	def clear_to_eol
		Tui.clear_to_eol
	end
	def refresh
		Tui.refresh
	end
	def printxy(x, y, str)
		move(x, y)
		print(str)
	end
	def render_row(y, str)
		move(0, y)
		clear_to_eol
		print(str) unless str.empty?
		#clear_to_eol
	end
	def print_glyph(glyph)
		str = @glyph2str[glyph]
		unless str
			str = [glyph].pack('U')
			@glyph2str[glyph] = str
		end
		print(str)
	end
	def render_row2(y, glyphs, pens, i, n)
		raise 'error' if glyphs.size != pens.size
		move(0, y)
		clear_to_eol
		move(0, y)
		n.times do
			set_color(pens[i])
			print_glyph(glyphs[i])
			i += 1
		end
	end
	def measure_width(glyph)
		Tui.wcwidth(glyph)
	end
	def set_title(title)
		$stdout.puts "\033]0;#{title}\007"
	end
	# returns either nil or text
	def get_title
		wid = ENV['WINDOWID']
		return nil unless wid
		output = ''; 
		IO.popen("xprop -id #{wid}") do |io| 
			while s=io.gets; output << s; end 
		end
		m = output.match(/^WM_NAME\(STRING\) = "(.*)"/)
		return m ? m[1] : nil
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

if $0 == __FILE__
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
		
		#c.printxy(11, 9, 
		#	"colors=#{Curses.COLORS} " +
		#	"escdelay=#{Curses.ESCDELAY}")
		c.move(11, 10)
		c.refresh
		5.times do |i|
			key = c.getch
			#c.clear
			c.printxy(11, 10+i, "key = #{key}")
			c.move(11, 11+i)
			c.refresh
		end
		c.getch
	end
end
