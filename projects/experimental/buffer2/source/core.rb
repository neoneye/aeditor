module AEditor

class IntegrityError < Exception; end

module Helpers

def check_integer(int)
	raise TypeError, 'expected integer' unless int.kind_of?(Integer)
end

def check_boolean(bool)
	raise TypeError, 'expected boolean' unless bool == true or bool == false
end

def check_valid_utf8(str)
	raise TypeError unless str.kind_of?(String)
	str.unpack("U*")
end

def determine_bytes_of_char(first_byte)
	check_integer(first_byte)
	unless first_byte.between?(0, 255)
		raise ArgumentError, "outside range 0..255"
	end
	return 1 if first_byte < 0x80
	bytes = 2
	bit = 5
	until first_byte[bit] == 0
		bit -= 1
		bytes += 1
	end
	bytes
end

end # module Helpers

module Model

class NotifyInfo
	def initialize
		@x1, @y1 = 0, 0
		@source_x2, @source_y2 = 0, 0
		@dest_x2, @dest_y2 = 0, 0
		@event = nil
	end
	attr_accessor :x1, :y1
	attr_accessor :source_x2, :source_y2
	attr_accessor :dest_x2, :dest_y2
	attr_accessor :event
end

#
# maybe it would be good to keep track of 
# if the model is saved on disk?  In case 
# the saved-state changes then all observers
# gets a notify.
#
#
class Caretaker
	include Helpers
	def initialize
 		@bytes = [0]
 		@text = ""
		@observers = []
		@notify_info = NotifyInfo.new
	end
	attr_reader :bytes, :text, :observers
	
	def attach(observer)
		unless observer.respond_to?(:model_update)
			raise NoMethodError, "observer needs to respond to `model_update'"
		end
		@observers << observer
	end
	def detach(observer)
		@observers.delete(observer)
	end
	# convert from (x,y) to (byte offset)
	def p2b(x, y)
		check_integer(x)
		check_integer(y)
		unless y.between?(0, @bytes.size-1)
			raise ArgumentError, 
				"y must between 0..#{@bytes.size-1}, but was #{y}."
		end
		if x < 0
			raise ArgumentError, 
				"x must be greater or equal to 0, but was #{x}."
		end
		n = 0
		0.upto(y-1) do |iy|
			n += @bytes[iy]
		end
		x.downto(1) do |ix|
			char = @text[n]
			raise ArgumentError if char == 10 or char == nil
			n += determine_bytes_of_char(char)
		end
		n
	end
	# convert from (byte offset) to (x,y)
	def b2p(byte)
		check_integer(byte)
		raise ArgumentError, "byte outside range" if byte < 0
		n = 0
		0.upto(@bytes.size-1) do |y|
			nextn = n + @bytes[y]
			unless byte < nextn or (byte <= nextn and y == @bytes.size-1)
				n = nextn
				next
			end
			x = 0
			while byte > n
				char = @text[n]
				raise ArgumentError if char == 10 or char == nil
				n += determine_bytes_of_char(char)
				x += 1
			end
			x -= 1 if n > byte
			return [x, y]
		end
		raise ArgumentError, "byte outside range"
	end
	# replace a region with something else
	def replace(x1, y1, x2, y2, utf8_str)
		$logger.debug "model replace xy1=#{x1.inspect},#{y1.inspect} " +
			"xy2=#{x2.inspect},#{y2.inspect} text.size=#{utf8_str.size}"
		check_integer(x1)
		check_integer(y1)
		check_integer(x2)
		check_integer(y2)
		raise ArgumentError, "negative range" if y1 > y2
		raise ArgumentError, "negative range" if y1 == y2 and x1 > x2
		check_valid_utf8(utf8_str)

		begin		
			text_begin_line = p2b(0, y1)
			text_begin_insert = p2b(x1, y1)
		rescue ArgumentError => e
			raise ArgumentError, 
				"first position (#{x1},#{y1}) is invalid, " +
				"reason=#{e.message}"
		end
		begin
			text_end_line = p2b(0, y2) + @bytes[y2]
			text_end_insert = p2b(x2, y2)
		rescue ArgumentError => e
			raise ArgumentError, 
				"second position (#{x1},#{y1}) is invalid, " +
				"reason=#{e.message}"
		end

		b1 = text_begin_line
		w1 = text_begin_insert - text_begin_line
		b2 = text_end_insert
		w2 = text_end_line - text_end_insert
		text = @text[b1, w1] + utf8_str + @text[b2, w2]

		b3 = text_begin_insert
		w3 = text_end_insert - text_begin_insert

		bytes = text.map{|str| str.size}
		if text.empty? or 
			(y2 == @bytes.size-1 and w2 == 0 and utf8_str =~ /\n\z/)
			bytes << 0
		end
		bytes_w = 1+y2-y1
		
		notify(:before, x1, y1, x2, y2, nil, nil)
		@text[b3, w3] = utf8_str
		@bytes[y1, bytes_w] = bytes
		newx2, newy2 = b2p(b3+utf8_str.size)
		notify(:after, x1, y1, x2, y2, newx2, newy2)
	end
	def notify(notify_type, x1, y1, s_x2, s_y2, d_x2, d_y2)
		@notify_info.event = notify_type
		@notify_info.x1 = x1
		@notify_info.y1 = y1
		@notify_info.source_x2 = s_x2
		@notify_info.source_y2 = s_y2
		@notify_info.dest_x2 = d_x2
		@notify_info.dest_y2 = d_y2
		@observers.each do |obs|
			obs.model_update(self, @notify_info)
		end
	end
	private :notify
	def line(y)
		w = @bytes[y]
		b = p2b(0, y)
		@text[b, w]
	end
	def glyphs(y)
		line(y).unpack('U*')
	end
	# replace everything
	def load(utf8_str)
		y2 = @bytes.size-1
		x2 = glyphs(y2).size
		replace(0, 0, x2, y2, utf8_str)
	end
	def array_of_bytes
		@bytes.map
	end
	def check_integrity
		errors = []
		# ensure that the number of bytes is in sync
		bytes = array_of_bytes.inject(0) {|a, b| a + b}
		ts = @text.size
		if bytes != ts
			errors << "mismatch bytes=#{bytes}, text.size=#{ts}"
		end
		# all lines should be valid UTF-8 encoded
		# all lines (except the last line) should end with newline
		n = 0
		ary = array_of_bytes
		ary.pop
		ary.each_with_index do |b, i|
			text = @text[n, b]
			break if text == nil
			if text =~ /[^\n]\z/
				errors << "missing newline on line ##{i}"
			end
			if text =~ /\n(?!\z)/
				errors << "newline in the middle of the line ##{i}"
			end
			begin
				text.unpack("U*")
			rescue ArgumentError
				errors << "malformed UTF-8 in line ##{i}"
			end
			n += b
		end
		begin
			@text.unpack("U*")
		rescue ArgumentError
			errors << "malformed UTF-8 somewhere (maybe on last line)"
		end
		return if errors.empty?
		raise IntegrityError, errors.join("\n")
	end
end

end # module Model

module View

DIRTY_NONE = 0
DIRTY_CURSOR = 1
DIRTY_ALL = 0xff


class Line
	def initialize
		@folded_lines = 0
		@lexer_state = 0
		@bookmark = false
		@dirty = true
	end
	attr_reader :lexer_state
	attr_accessor :dirty, :folded_lines, :bookmark
end

class Base
	include Helpers
	def initialize(model)
		raise TypeError unless model.kind_of?(Model::Caretaker)
		@model = model
		@canvas = nil
		@lexer = nil
		@lines = []
		@dirty = DIRTY_ALL
		@scroll_x, @scroll_y = 0, 0
		@cursor_x, @cursor_y = 0, 0
		@width, @height = 5, 5
		@sel_x, @sel_y = 0, 0
		@sel_mode = false
		@search_pattern = ''
		@search_results = nil
		sync_lines
	end
	attr_reader :model, :canvas, :lexer, :lines, :dirty
	attr_reader :scroll_x, :scroll_y, :cursor_x, :cursor_y
	attr_reader :sel_x, :sel_y, :sel_mode
	attr_reader :width, :height

	def sync_lines
		@lines = @model.bytes.map { Line.new }
	end
	def model_update(model, info)
		if info.event == :before
			@old_p = xy2p(@cursor_x, @cursor_y)
			#$logger.info "view old_p=#{@old_p}"
			return
		end
		return if info.event != :after
 		if @cursor_y > info.source_y2
 			@cursor_y += info.dest_y2 - info.source_y2
 		elsif @cursor_y >= info.y1
			is_before = ((@cursor_y == info.y1) and 
				(@old_p < info.x1))
			is_after = ((@cursor_y == info.source_y2) and 
				(@old_p >= info.source_x2))
			case 
			when is_before
				# do nothing
			when is_after
				@old_p += info.dest_x2 - info.source_x2
 				@cursor_y += info.dest_y2 - info.source_y2
				@cursor_x = py2x(@old_p, @cursor_y)
			else
 				@cursor_y = info.y1
				@cursor_x = py2x(info.x1, @cursor_y)
 			end
		end
		# flag affected lines as dirty
		sy = info.source_y2
		dy = info.dest_y2
		n = dy - sy
		if n > 0
			n.times { @lines.insert(sy, Line.new) }
		else
			@lines.slice!(dy, -n)
		end
		info.y1.upto([sy, dy].min) do |i|
			@lines[i].dirty = true
		end
		@search_results = nil  # clear search results
	end
	def canvas=(can)
		raise TypeError unless can == nil or can.kind_of?(Canvas::Base)
		@canvas = can
	end
	def lexer=(lex)
		raise TypeError unless lex == nil or lex.kind_of?(Lexer::Base)
		@lexer = lex
	end
	def update
		#$logger.info "view update,  " +
		#	"scroll=#{@scroll_x},#{@scroll_y}  " +
		#	"cursor=#{@cursor_x},#{@cursor_y}  " +
		#	"size=#{@width},#{@height}"
		
		return unless @canvas

		@canvas.reset_counters
		
		if @lexer
			@lexer.reset_counters
			@lexer.resize(@height*5) 
		end
			
		vis = visible
		found_i = nil
		if @scroll_y >= 0
			vis.each_with_index do |y, i|
				if y >= @scroll_y
					found_i = i
					break
				end
			end
		else
			found_i = @scroll_y
		end
		@canvas.scroll_x = @scroll_x
		cy = nil
		0.upto(@height-1) do |y|
			fragment = nil
			ay = nil
			options = 0
			render_ay = nil
			if found_i and (found_i + y).between?(0, vis.size-1)
				ay = vis[found_i + y]
			end
			if @cursor_y == ay
				cy = y
			end
			pens = nil
			if ay and ay.between?(0, @model.bytes.size-1)
				b = @model.p2b(0, ay)
				w = @model.bytes[ay]
				fragment = @model.text[b, w]
				options |= 1 if @lines[ay].bookmark
				options |= 2 if @lines[ay].folded_lines > 0
				render_ay = ay
				pens = @lexer.colorize(ay) if @lexer
			end
			@canvas.render_row(y, fragment, render_ay, pens, options)
		end
		@canvas.cursor_show(@cursor_x, cy) if cy
		@canvas.refresh
	
		msg = "" 
		if @lexer
			msg = " lexer=#{@lexer.status}"
		end
		$logger.info "update: " +
			"scroll=#{@scroll_x},#{@scroll_y} " +
			"cursor=#{@cursor_x},#{@cursor_y} " +
			"size=#{@width},#{@height} " + 
			"canvas=#{@canvas.count_hit},#{@canvas.count_miss}" + msg
	end
	def update_cursor
		return unless @canvas
		vis = visible
		found_i = nil
		if @scroll_y >= 0
			vis.each_with_index do |y, i|
				if y >= @scroll_y
					found_i = i
					break
				end
			end
		else
			found_i = @scroll_y
		end
		@canvas.scroll_x = @scroll_x
		cy = nil
		0.upto(@height-1) do |y|
			ay = nil
			if found_i and (found_i + y).between?(0, vis.size-1)
				ay = vis[found_i + y]
			end
			if @cursor_y == ay
				cy = y
			end
		end
		@canvas.cursor_show(@cursor_x, cy)
		@canvas.refresh
	end
	# NOTE: there is intentionally no check for if y is 
	# inside the buffer.. because we want to be able to
	# scroll outside the buffer.
	def scroll_y=(y)
		check_integer(y)
		@scroll_y = y
	end
	def scroll_x=(x)
		check_integer(x)
		@scroll_x = x
	end
	# purpose:
	# convert from visible y coordinates to absolute y coordinates.
	def vy2ay(vy)
		check_integer(vy)
		vis = visible
		unless vy.between?(0, vis.size-1)
			raise ArgumentError, "#{vy} is outside 0..#{vis.size-1}"
		end
		vis[vy]
	end
	# purpose:
	# convert from absolute y coordinates to visible y coordinates.
	#
	# in case the specified y coordinate are not-visible 
	# the it floors the y coordinate to the nearest visible.
	def ay2vy(ay)
		check_integer(ay)
		raise ArgumentError unless ay.between?(0, lines.size-1)
		vis = visible
		vis.each_with_index do |y, i|
			fl = @lines[y].folded_lines
			return i if ay.between?(y, y+fl)
		end
		raise 'should not happen'
	end
	def cursor_y=(y)
		check_integer(y)
		raise ArgumentError unless y.between?(0, @lines.size-1)
		return if y == @cursor_y
		@cursor_y = y
		@dirty |= DIRTY_CURSOR
	end
	def cursor_x=(x)
		check_integer(x)
		raise ArgumentError if x < 0
		@cursor_x = x
	end
	def cursor
		[@cursor_x, @cursor_y]
	end
	def scroll
		[@scroll_x, @scroll_y]
	end
	def size
		[@width, @height]
	end
	def resize(width, height)
		check_integer(width)
		check_integer(height)
		raise ArgumentError, "width must be positive" if width < 1
		raise ArgumentError, "height must be positive" if height < 1
		$logger.info "view resize  from #{@width}x#{@height}  " +
			"to #{width}x#{height}"
		@width, @height = width, height
	end
	# determine how wide the glyph are: 1=halfwidth, 2=fullwidth.
	def measure_width(x, glyph)
		return 1 unless @canvas
		return 1 unless @canvas.respond_to?(:measure_width)
		w = @canvas.measure_width(x, glyph)
		return w if glyph == 9
		return 1 if w != 1 and w != 2
		w
	end
	# translate from canvas coordinates to buffer coordinates
	def xy2p(x, y)
		sx = 0
		glyphs = @model.glyphs(y)
		glyphs.each_with_index do |glyph, i|
			return i if sx >= x or glyph == 10
			sx += measure_width(sx, glyph)
		end
		glyphs.size
	end
	# translate from buffer coordinates to canvas coordinates
	def py2x(p, y)
		sx = 0
		@model.glyphs(y).each_with_index do |glyph, i|
			return sx if i >= p or glyph == 10
			sx += measure_width(sx, glyph)
		end
		sx
	end
	# convert from visual-x, abs-y to byte
	def vxay2b(x, y)
		@model.p2b(xy2p(x, y), y)
	end
	# convert from byte to visual-x, abs-y
	def b2vxay(b)
		px, y = @model.b2p(b)
		x = py2x(px, y)
		[x, y]
	end
	# get list of folding levels
	def folds
		@lines.map{|l| l.folded_lines}
	end
	# get list of visible lines
	def visible
		res = []
		i = 0
		while i < @lines.size
			res << i
			i += @lines[i].folded_lines + 1
		end
		res
	end
	def check_integrity
		errors = []
		if @lines.size < 1
			errors << "the number of lines must be 1 or greater"
		end
		if @dirty & DIRTY_CURSOR == 0
			unless @scroll_y.between?(0, @lines.size-1)
				errors << "scrolled over the edge, scroll_y=#{@scroll_y}"
			end
		end
		unless @cursor_y.between?(0, @lines.size-1)
			errors << "cursor over the edge, cursor_y=#{@cursor_y}"
		end
		return if errors.empty?
		raise IntegrityError, errors.join("\n")
	end
end


class Caretaker < Base
	def scroll_to_cursor
		if @cursor_x < @scroll_x
			@scroll_x = @cursor_x
		end
		if @cursor_x >= @scroll_x + @width
			@scroll_x = @cursor_x + 1 - @width
		end
		if @cursor_y < @scroll_y
			@scroll_y = @cursor_y
		end
		if @cursor_y >= @scroll_y
			h1 = @height - 1
			bot = ay2vy(@scroll_y) + h1
			cvy = ay2vy(@cursor_y)
			if cvy > bot
				say = vy2ay(bot)
				if @cursor_y > say
					newsvy = [cvy - h1, 0].max
					@scroll_y = vy2ay(newsvy)
				end
			end
		end
	end
	def insert(utf8_string)
		ary = utf8_string.unpack("U*")
		#raise ArgumentError, 'supply only one letter' if ary.size != 1
		cx, cy = cursor
		$logger.info "view operation insert " +
			"x=#{cx} y=#{cy} text=#{utf8_string.inspect}"
		p = xy2p(cx, cy)
		@model.replace(p, cy, p, cy, utf8_string)
	end
	def edit_breakline
		b = @model.p2b(0, @cursor_y)
		w = @model.bytes[@cursor_y]
		istr = @model.text[b, w].match(/\A\s*/).to_s
		cb = vxay2b(@cursor_x, @cursor_y)
		if b + istr.size >= cb
			cx, cy = @cursor_x, @cursor_y
			@model.replace(0, cy, 0, cy, "\n")
			@cursor_x, @cursor_y = cx, (cy+1)
			return
		end
		rem = b + istr.size - cb
		if rem >= 0
			cx, cy = @cursor_x, @cursor_y
			@model.replace(0, cy, istr.size, cy, "\n" + istr)
			@cursor_x, @cursor_y = cx, (cy+1)
			return
		end
		insert("\n" + istr)
	end
	def delete_left
		cx, cy = cursor
		$logger.info "view operation backspace x=#{cx} y=#{cy}"
		return if cy == 0 and cx == 0
		p = xy2p(cx, cy)
		if p == 0
			x = @model.glyphs(cy-1).size-1
			@model.replace(x, cy-1, 0, cy, '')
			return
		end
		@model.replace(p-1, cy, p, cy, '')
	end
	def delete_right
		cx, cy = cursor
		$logger.info "view operation backspace x=#{cx} y=#{cy}"
		pos = xy2p(cx, cy)
		x = @model.glyphs(cy).size
		if cy+1 < @model.bytes.size and pos >= x-1
			@model.replace(x-1, cy, 0, cy+1, '')
			return 
		end
		if cy+1 >= @model.bytes.size and pos >= x
			return  # reached end of buffer.. nothing to do
		end
		@model.replace(pos, cy, pos+1, cy, '')
	end
	def move_to_lineend
		x = 0
		@model.glyphs(@cursor_y).each do |glyph|
			break if glyph == 10
			x += measure_width(x, glyph)
		end
		@cursor_x = x
	end
	def move_to_linebegin(smart=true)
		unless smart
			@cursor_x = 0
			return
		end
		cx = @cursor_x
		b1 = vxay2b(0, @cursor_y)
		b2 = vxay2b(@cursor_x, @cursor_y)
		move_to_lineend
		b3 = vxay2b(@cursor_x, @cursor_y)
		text = @model.text[b1, b3-b1]
		m = text.match(/\A\s*/)
		if m.to_s.size == text.size
			b = @model.p2b(0, @cursor_y)
			(@cursor_y-1).downto(0) do |y|
				w = @model.bytes[y]
				b -= w
				m = @model.text[b, w].match(/\A\s*(?=\S)/u)
				next unless m
				rx, ry = b2vxay(b + m.to_s.size)
				@cursor_x = (cx != rx) ? rx : 0
				return
			end
			@cursor_x = 0
			return
		end
		br = m.end(0) + b1
		if b2 != br
			@cursor_x, dummy = b2vxay(br)
			return
		end
		@cursor_x = 0
	end
	def move_pageup
		$logger.info "view operation pageup"
		scroll_vy = ay2vy(@scroll_y)
		cursor_vy = ay2vy(@cursor_y)
		h1 = @height - 1
		if scroll_vy == 0
			@cursor_y = 0
		elsif scroll_vy - h1 >= 0
			@scroll_y = vy2ay(scroll_vy - h1)
			@cursor_y = vy2ay(cursor_vy - h1)
		else
			@scroll_y = 0
			@cursor_y = vy2ay(cursor_vy - scroll_vy)
		end
	end
	def move_pagedown
		$logger.info "view operation pagedown"
		scroll_vy = ay2vy(@scroll_y)
		cursor_vy = ay2vy(@cursor_y)
		last_vy = ay2vy(@lines.size-1)
		h1 = @height - 1
		if scroll_vy + h1 >= last_vy
			@cursor_y = vy2ay(last_vy)
		elsif cursor_vy + h1 <= last_vy
			@scroll_y = vy2ay(scroll_vy + h1)
			@cursor_y = vy2ay(cursor_vy + h1)
		else
			@cursor_y = vy2ay(last_vy - h1 + cursor_vy - scroll_vy)
			@scroll_y = vy2ay(last_vy - h1)
		end
	end
	def move_top
		$logger.info "view operation top"
		@cursor_y = 0
	end
	def move_bottom
		$logger.info "view operation bottom"
		@cursor_y = visible.last
	end
	def move_wordleft
		$logger.info "view operation wordleft"
		b1 = vxay2b(0, @cursor_y)
		b2 = vxay2b(@cursor_x, @cursor_y)
		text = @model.text[b1, b2-b1]
		m = /(?: \s+ | \w+ | . )\z/ux.match(text)
		return false unless m
		@cursor_x, @cursor_y = b2vxay(m.begin(0) + b1)
		true
	end
	def move_wordright
		$logger.info "view operation wordright"
		oldx = @cursor_x
		b1 = vxay2b(@cursor_x, @cursor_y)
		move_to_lineend
		b2 = vxay2b(@cursor_x, @cursor_y)
		@cursor_x = oldx
		text = @model.text[b1, b2-b1]
		m = /\A(?: \s+ | \w+ | . )/ux.match(text)
		return false unless m
		@cursor_x, @cursor_y = b2vxay(m.end(0) + b1)
		true
	end
	def selection_begin
		$logger.info "view operation selection begin"
		@sel_x, @sel_y = @cursor_x, @cursor_y
		@sel_mode = true
	end
	def selection_end
		$logger.info "view operation selection end"
		@sel_mode = false
	end
	def selection
		return '' unless @sel_mode
		sb = vxay2b(@sel_x, @sel_y)
		cb = vxay2b(@cursor_x, @cursor_y)
		min, max = [sb, cb].sort
		txt = @model.text[min, max-min]
		#$logger.info "text: #{txt.inspect}"
		txt
	end
	def selection_erase
		$logger.info "view operation selection erase"
		return unless @sel_mode
		@sel_mode = false
		
		sb = vxay2b(@sel_x, @sel_y)
		cb = vxay2b(@cursor_x, @cursor_y)
		min, max = [sb, cb].sort

		ax, ay = @model.b2p(min)
		bx, by = @model.b2p(max)
		@model.replace(ax, ay, bx, by, '')
	end
	def selection_to_fold
		return unless @sel_mode
		@sel_mode = false
		min, max = [[@sel_y, @sel_x], [@cursor_y, @cursor_x]].sort
		miny, minx = min
		maxy, maxx = max
		collapse(miny, maxy - ((maxx == 0) ? 1 : 0))
		@cursor_y = miny
	end
	def toggle_bookmark
		$logger.info "view operation toggle bookmark"
		l = @lines[@cursor_y]
		l.bookmark = !l.bookmark
	end
	def goto_prev_bookmark
		$logger.info "view operation goto prev bookmark"
		before = []
		after = []
		@lines.each_with_index do |l, y|
			if l.bookmark
				if y < @cursor_y
					before << y
				else
					after << y
				end
			end
		end
		res = before.reverse + after.reverse
		@cursor_y = res[0] if res.size > 0
	end
	def goto_next_bookmark
		$logger.info "view operation goto next bookmark"
		before = []
		after = []
		@lines.each_with_index do |l, y|
			if l.bookmark
				if y <= @cursor_y
					before << y
				else
					after << y
				end
			end
		end
		res = after + before
		@cursor_y = res[0] if res.size > 0
	end
	def search_init(pattern)
		$logger.info "view search init, pattern=#{pattern.inspect}"
		unless pattern.kind_of?(String) or pattern.kind_of?(Regexp)
			raise TypeError, "must be either String or Regexp"	
		end
		@search_pattern = pattern
		@search_results = nil
		search_sync
		@search_results.size
	end
	def search_sync
		return if @search_results
		@search_results = []
		@model.text.scan(@search_pattern) do
			@search_results << [
				Regexp.last_match.begin(0), Regexp.last_match.end(0)]
		end
		$logger.info "view search_sync, results = #{@search_results.size}"
		@search_results.size
	end
	def search_down
		search_sync
		$logger.info "view search down"
		cb = vxay2b(@cursor_x, @cursor_y)
		@search_results.each do |b1, b2|
			if b1 > cb
				@sel_x, @sel_y = b2vxay(b1)
				@cursor_x, @cursor_y = b2vxay(b2)
				@sel_mode = true
				return true
			end
		end
		false
	end
	def search_up
		search_sync
		$logger.info "view search up"
		cb = vxay2b(@cursor_x, @cursor_y)
		@search_results.reverse_each do |b1, b2|
			if b1 < cb
				@cursor_x, @cursor_y = b2vxay(b1)
				@sel_x, @sel_y = b2vxay(b2)
				@sel_mode = true
				return true
			end
		end
		false
	end
	def collapse(y1, y2)
		check_integer(y1)
		check_integer(y2)
		if y1 < 0 or y2 >= @lines.size
			raise ArgumentError, "invalid line number"
		end
		if y2 <= y1
			raise ArgumentError, 
				"second argument must be greater than first argument"
		end
		@lines[y1].folded_lines = y2-y1
	end
	def expand
		@lines[@cursor_y].folded_lines = 0
	end
	def move_to_prev_visible_line
		visible.reverse_each do |y|
			if @cursor_y > y
				@cursor_y = y
				return
			end
		end
	end
	def move_to_next_visible_line
		visible.each do |y|
			if @cursor_y < y
				@cursor_y = y
				return
			end
		end
	end
end

end # module View

module Canvas

class Base
	def initialize
		reset_counters
		@view = nil
		@scroll_x = 0
	end
	attr_reader :view
	attr_accessor :scroll_x
	attr_reader :count_hit, :count_miss
	def view=(v)
		raise TypeError unless v == nil or v.kind_of?(View::Caretaker)
		@view = v
	end
	def render_row(y, utf8_string, render_ay, pens, options)
		raise NoMethodError, "derived class should implement this method"
	end
	def width
		raise NoMethodError, "derived class should implement this method"
	end
	def height
		raise NoMethodError, "derived class should implement this method"
	end
	def cursor_show(x, y)
		raise NoMethodError, "derived class should implement this method"
	end
	def reset_counters
		@count_hit = 0
		@count_miss = 0
	end
end

end # module Canvas

module Lexer


# purpose:
# remember the most recently used pen-lines
class LRU
	def initialize
		@capacity = 1
		@pens = {}
		@used = []
	end
	attr_reader :capacity, :used, :pens
	def resize(n)
		raise ArgumentError if n < 0
		@capacity = n
		wipe
	end
	def wipe
		while @used.size > @capacity
			@pens.delete(@used.pop)
		end
	end
	private :wipe
	def size
		@used.size
	end
	def store(key, value)
		@used.delete(key)
		@used.unshift(key)
		@pens[key] = value
		wipe
	end
	alias_method('[]=', :store)
	def has_key?(key)
		@pens.has_key?(key)
	end
	# note: remember to .clone the data you get from .load
	def load(key)
		return nil unless has_key?(key)
		@used.delete(key)
		@used.unshift(key)
		@pens[key]
	end
	alias_method('[]', :load)
	def delete(key)
		@used.delete(key)
		@pens.delete(key)
	end
	def displace(y, n)
		displaced = {}
		@used.each_with_index do |key, i|
			if key >= y
				@used[i] = key+n
				displaced[key+n] = @pens.delete(key)
			end
		end
		@pens.merge!(displaced)
	end
	alias :insert :displace
	private :displace
	public :insert
	def remove_in_range(y, n)
		ary = []
		@used.each {|key| ary << key if key >= y and key < y+n }
		ary.each {|key| delete(key) }
	end
	private :remove_in_range
	def remove(y, n)
		remove_in_range(y, n)
		displace(y+n, -n)
	end
end

class Base
	def initialize(model)
		@model = model
	end
	def resize(n)
		raise "derived class must overload"
	end
	def model_update(model, info)
		raise "derived class must overload"
	end
	def colorize(ay)
		raise "derived class must overload"
	end
	def status
		"-none-"
	end
end

class Simple < Base
	def initialize(model)
		erase
		super(model)
	end
	attr_reader :lru, :count_sync_hit, :count_sync_miss
	attr_reader :count_color_hit, :count_color_miss, :dirty_lines
	def reset_counters
		@count_sync_hit = 0
		@count_sync_miss = 0
		@count_color_hit = 0
		@count_color_miss = 0
	end
	def count_hit
		@count_sync_hit + @count_color_hit
	end
	def count_miss
		@count_sync_miss + @count_color_miss
	end
	def erase
		reset_counters
		@dirty_lines = []
		@right_states = []
		@left = 0
		@right = 0
		@pens = []
		@lru = LRU.new
	end
	def status
		"#{@count_sync_hit}+#{@count_color_hit}/#{@count_sync_miss}+#{@count_color_miss}"
	end
	def resize(n)
		@lru.resize(n)
	end
	def dirty(y)
		#puts "dirty #{y}" if $dbg
		@dirty_lines[y] = true if y < @dirty_lines.size
		@lru.delete(y)
	end
	def model_update(model, info)
		return if info.event == :before
		return if info.event != :after
		sy = info.source_y2
		dy = info.dest_y2
		n = dy - sy
		if n > 0
			#puts "model_update: insert n=#{n}, dy=#{dy}" if $dbg
			dirty(sy) # dirtify the line before splitting
			n.times do
				@right_states.insert(sy, nil) 
				@dirty_lines.insert(sy, true)
			end
			@lru.insert(sy, n) # displace all cached pens
		else
			#puts "model_update: removing n=#{n}, dy=#{dy}" if $dbg
			@right_states.slice!(dy, -n)
			@dirty_lines.slice!(dy, -n)
			@lru.remove(dy, -n) # displace all cached pens
		end
		info.y1.upto([sy, dy].min) {|i| dirty(i) }
	end
	def set_right_state(y, state)
		propagate = false
		rs = @right_states
		if y < @right_states.size
			old = @right_states[y]
			if state != old
				propagate = true
				#if $dbg
				#	puts "propagate #{y}->#{y+1}, because #{state.inspect} is " +
				#		"distinct from #{old.inspect}"
				#end
			end
		elsif y >= @right_states.size
			propagate = true
			#puts "propagate #{y}->#{y+1}, because y >= size" if $dbg
		end
		dirty(y)
		(y-@right_states.size).times { @right_states << nil }
		(y-@dirty_lines.size).times { @dirty_lines << true }
		@right_states[y] = state
		@dirty_lines[y] = false
		#puts "rs=#{@right_states.inspect} prop=#{propagate}" if $dbg
		dirty(y+1) if propagate
		#puts "rs=#{@right_states.inspect}" if $dbg
	end
	def sync_states(number_of_states)
		0.upto(number_of_states) do |i|
			if i < @dirty_lines.size and i > @right_states.size
				raise "should not happen, i=#{i} " + 
					"rs.size=#{@right_states.size} dl=#{@dirty_lines.size}"
			end
			if i < @dirty_lines.size and @dirty_lines[i] == false
				@count_sync_hit += 1
				next
			end
			@count_sync_miss += 1
			
			@left = (i == 0) ? 0 : @right_states[i - 1]
			lex_line(@model.line(i))
			set_right_state(i, @right)
		end
	end
	def colorize(line_number)
		#puts "line #{line_number}"
		sync_states(line_number-1)  # TODO: move outside renderloop
		
		if @lru.has_key?(line_number)
			@count_color_hit += 1
			return @lru[line_number]
		end
		@count_color_miss += 1

		i = line_number
		@left = (i == 0) ? 0 : @right_states[i - 1]
		lex_line(@model.line(i))
		set_right_state(i, @right)
		@lru[i] = @pens
		@pens
	end
end










end # module Lexer

end # module AEditor