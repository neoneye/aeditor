require 'core'

module Kernel
	def dump_memory_info(msg=nil)
		msg ||= "-"
		IO.popen("ps u -p #$$") {|io| 
			$logger.info("meminfo #{msg}\n" + io.read) 
		}
	end	
end

require 'lexer'

class LexTest < AEditor::Lexer::Simple
	def initialize(model)
		super(model)
		@i = 0
	end
	def lex_line(text)
		glyphs = text.unpack('U*')
		@pens = glyphs.map{ @i }
		@i = (@i + 1) % 5
	end	
end

class LexRuby < AEditor::Lexer::Simple
	def initialize(model)
		super(model)
		@lexer = LexerRuby::Lexer.new
		@left = []
		@right = nil
	end
	def lex_line(text)
		states = (@left == 0) ? [] : @left.map{|i| i.clone}
		@lexer.set_states(states)
		@lexer.set_result([])
		@lexer.lex_line(text)
		@right = @lexer.states
		tokens, states = @lexer.result.transpose
		@pens = []
		@colors = {
			:keyword => 2, :punct => 2, :number => 2, :symbol => 2,
			:string => 4, :string1 => 3,
			:regexp => 4, :regexp1 => 3,
			:literal => 4, :literal1 => 3,
			:heredoc => 4, :heredoc1 => 3,
			:tab => 6, :comment => 6, :mcomment => 6,
			:gvar => 10
		}
		@colors.default = 1
		unless tokens
			$logger.error "no tokens"
			return
		end
		tokens.each_with_index do |tok, i|
			#$logger.info states.inspect
			@pens += [ @colors[states[i]] ] * tok.size
		end
	end	
end

class Buffer
	def initialize(text, filename)
		@filename = filename
		
		@model = AEditor::Model::Caretaker.new
		@model.load(text)
		
		@view = AEditor::View::Caretaker.new(@model)
		#@view.canvas, self.view = self, @view
		@model.attach(@view)
		
		lexer = LexRuby.new(@model)
		@view.lexer = lexer
		@model.attach(lexer)
	end
	attr_reader :view, :model, :filename
	
	def save_file
		$logger.info "outputting to file, filename=#{@filename.inspect}"
		File.open(@filename, "w+") do |f|
			f.write(@model.text)
		end
	end
end
	
class Buffers
	def initialize
		@buffers = []
	end
	def open_file(filename)
		raise TypeError unless filename.kind_of?(String)
		buf = Buffer.new(IO.read(filename), filename)
		@buffers << buf
		buf
	rescue Errno::EACCES, Errno::ENOENT => e
		$logger.info "cannot access file, filename=#{filename.inspect}"
		raise ArgumentError, 'cannot access file'
	end
	def open_dummy
		neoneye = [0xff2e, 0xff25, 0xff2f, 
			0xff2e, 0xff25, 0xff39, 0xff25].pack("U*")
		str = "Welcome to AEditor-2.0\n"
		str += "written by: " + neoneye + "\n"
		str += "homepage:   http://aeditor.rubyforge.org/\n\n\n"
		str += "features:\n"
		str += " * unicode (UTF-8 encoding).\n"
		str += " * renders halfwidth, fullwidth and tabs.\n"
		str += " * basic editing.\n"
		str += " * written in less than 1000 lines."
		buf = Buffer.new(str, 'noname00.txt')
		@buffers << buf
		buf
	end
	def size
		@buffers.size
	end
	def [](index)
		@buffers[index]
	end
end

class MainTUI < AEditor::Canvas::Base
	class RenderInfo
		def initialize(
			text, absolute_y, options, 
			sel1, sel2, sel_mode, 
			scroll_x, pens)
			@text = text
			@absolute_y = absolute_y
			@options = options
			@sel1 = sel1
			@sel2 = sel2
			@sel_mode = sel_mode
			@scroll_x = scroll_x
			@pens = pens
		end
		attr_reader :text, :absolute_y, :options
		attr_reader :sel1, :sel2, :sel_mode, :scroll_x
		attr_reader :pens
		def equal?(other)
			return false unless other.kind_of?(RenderInfo)
			return false if @text != other.text
			return false if @absolute_y != other.absolute_y
			return false if @options != other.options
			return false if @sel1 != other.sel1
			return false if @sel2 != other.sel2
			return false if @sel_mode != other.sel_mode
			return false if @scroll_x != other.scroll_x
			return false if @pens != other.pens
			true
		end
	end
	
	def initialize(canvas, filenames)
		super()
		@dispatch2 = nil
		@canvas = canvas
		
		@buffers = Buffers.new
		if filenames.empty?
			@buffers.open_dummy
		else
			filenames.each do |filename|
				@buffers.open_file(filename)
			end
		end
		@buffer_index = -1
		@buffer = nil
		
		@tabsize = 4
		@red_column = 70
		@selection_mode = 0
		@selection_text = ''
		
		@render_width = 1000
		@render_glyphs = [32] * @render_width
		@render_pens = [32] * @render_width
		
		@render_info = {}
	end
	def self.run(filenames)
		require 'ncursesw'
		#dump_memory_info
		CursesCanvas.open do |c|
			oldtitle = c.get_title || "AEditor has exited"
			begin
				self.new(c, filenames).event_loop
			ensure
				c.set_title(oldtitle)
			end
		end
	end
	def render_cache_clear
		@render_info = {}
	end
	def switch_to_buffer(index)
		$logger.info "switch to buffer ##{index} from buffer ##{@buffer_index}"
		return if index == @buffer_index
		return if index >= @buffers.size
		@buffer_index = index
		@buffer = @buffers[index]
		@view = @buffer.view
		@model = @buffer.model
		@view.canvas, self.view = self, @view
		name = File.basename(@buffer.filename || '')
		@canvas.set_title("[#{index}] #{name} - AEditor")
		@view.resize(width, height)
		@canvas.clear
		render_cache_clear
		#@view.update_cursor
		@view.update
	end
	def cycle_buffer
		$logger.info "cycle buffer"
		switch_to_buffer((@buffer_index + 1) % @buffers.size)
	end
	def dialog_search
		$logger.info "show search dialog"
		
		ary = []

		g = [0x2500]*@canvas.width
		g[5] = 0x2534
		g[6 + @red_column] = 0x2534
		p = [6] * g.size
		ary << [g, p]

		g = "      search [^\\s*def\\b________________________]".unpack('U*')
		p = [2] * g.size
		9.times {|i| p[14+i] = 1}
		ary << [g, p]
		
		keys = ["F1 regex", "F2 case", "F3 cursor", "F4 word", "F5 down"]
		g = keys.join(' ').unpack('U*')
		p = []
		keys.each_with_index do |txt, i|
			p += [2] if i != 0
			p += [3] * txt.size
		end
		ary << [[32]*6 + g, [1]*6 + p]
		
		ary.each_with_index do |(glyphs, pens), i|
			while glyphs.size < @canvas.width
				glyphs << 32
				pens << 1
			end
			@canvas.render_row2(
				@canvas.height - ary.size + i, 
				glyphs,
				pens,
				0,
				glyphs.size
			)
		end
	end
	def event_loop
		switch_to_buffer(0)
		#@view.resize(width, height)
		#dump_memory_info("before update")
		#@view.update
		#dump_memory_info("after update")
		#dump_statistics
		dump_memory_info
		timeout = true
		loop do
			#GC.disable
			
			event = nil
			should_update = true
			r = (timeout) ? select([$stdin], nil, nil, 0.05) : [1]
			if r and r.size > 0
				event = @canvas.getch
				timeout = true
				should_update = false
				
			else
				timeout = false
				should_update = true
			end

			t1 = Time.now
			if event
				break if event == 24
				begin
					if @dispatch2 
						$logger.debug "dispatch2 with " +
							"#{@dispatch2.to_s} key-code=#{event}"
						send(@dispatch2, event)
						@dispatch2 = nil
					else
						$logger.debug "dispatch key-code=#{event}"
						dispatch(event)
					end
				rescue => e
					bt = e.backtrace.map{|s| 
						a, b, c = s.split(':', 3)
						bn = File.basename(a)
						"%15s | %5s | %s" % [bn, b, c]
					}.join("\n")
					$logger.error "exception:\n" +
						"#{e.class} #{e.message}\n" + bt
				end
			end
			@view.scroll_to_cursor
			if should_update
				#dump_memory_info("before update")
				@view.update
				#dump_memory_info("after update, before GC")
				#GC.enable
				GC.start
				#dump_memory_info("after GC")
			else
				@view.update_cursor
			end
			t2 = Time.now
			$logger.info "this operation took #{t2 - t1} seconds"
			#end
		end
		@canvas.clear
	end
	def dispatch_bookmark(event)
		case event
		when 11
			@view.toggle_bookmark
		when 14
			@view.goto_next_bookmark
		when 16
			@view.goto_prev_bookmark
		end
	end
	def dispatch_fold(event)
		case event
		when 6
			@view.expand
		when 22, 118   # ctrl-v  or  v
			@view.selection_to_fold
		when 49..57
			@view.collapse(@view.cursor_y, @view.cursor_y+event-48)
		end
	end
	def install(dispatcher)
		$logger.info "install #{dispatcher.to_s}"
		@dispatch2 = dispatcher
	end
	def dispatch(event)
		case event
		when 15
			@buffer.save_file
		when 6
			install(:dispatch_fold)
		when 9, 32..127
			@view.insert(event.chr)
		when 11
			install(:dispatch_bookmark)
		when 13
			@view.edit_breakline
		when 16  # ctrl-p    paste selected data
			@view.insert(@selection_text)
		when 22  # ctrl-v    cycle through selection modes
			@selection_mode = (@selection_mode + 1) % 2
			case @selection_mode
			when 1:
				@view.selection_begin
			when 0:
				@selection_text = @view.selection
				@view.selection_end
			end
		when 263
			case @selection_mode
			when 1:
				@view.selection_erase
				@selection_mode = 0
			when 0:
				@view.delete_left
			end
		when 259
			@view.move_to_prev_visible_line
		when 260
			@view.cursor_x -= 1
		when 258
			@view.move_to_next_visible_line
		when 261
			@view.cursor_x += 1
		when 265
			@view.insert([0x301c].pack("U*"))
		when 270 # End
			@view.move_to_lineend
		when 271 # Home
			@view.move_to_linebegin
		when 276 # F12
			cycle_buffer
		when 21  # ctrl-u    use clipboard as find pattern
			@view.search_init(@selection_text)
		when 267 # F3
			@view.search_down
		when 277 # Shift-F3
			@view.search_up
		when 268 # F4  search
			dialog_search
		when 266
			dump_statistics
			dump_memory_info
		when 330
			case @selection_mode
			when 1:
				@view.selection_erase
				@selection_mode = 0
			when 0:
				@view.delete_right
			end
		when 338
			@view.move_pagedown
		when 339
			@view.move_pageup
		when 410
			@view.resize(width, height)
			render_cache_clear
		when 800
			@view.move_top
		when 801
			@view.move_bottom
		when 803
			@view.move_wordleft
		when 802
			@view.move_wordright
		else
			$logger.debug "dispatch unknown key, event=#{event}"
		end
	end
	def width
		@canvas.width - 6  # because of line numbers
	end
	def height
		@canvas.height
	end
	def push_halfwidth(glyph, pen)
		@x += 1
		return if @x - @scroll_x <= 0
		return if @x - @scroll_x > width
		@render_glyphs[@n] = glyph
		@render_pens[@n] = pen
		@n += 1
	end
	def push_fullwidth(glyph, pen)
		if @x - @scroll_x == -1 
			@x += 1
			push_halfwidth(32, pen)
			return
		end
		if @x - @scroll_x == width - 1
			push_halfwidth(32, pen)
			return
		end
		@x += 2
		return if @x - @scroll_x <= 0
		return if @x - @scroll_x > width
		@render_glyphs[@n] = glyph
		@render_pens[@n] = pen
		@n += 1
	end
	def render_row(vy, text, ay, pens, options)
		

		sy1, sy2 = [@view.sel_y, @view.cursor_y].sort
		is_selected = (ay and @view.sel_mode and sy1 <= ay and ay <= sy2)
			
		sel1, sel2 = 0, -1
		if is_selected
			if (@view.sel_y == ay and @view.cursor_y == ay)
				sel1, sel2 = [@view.sel_x, @view.cursor_x].sort
			elsif @view.sel_y == ay
				if @view.sel_y < @view.cursor_y
					sel1, sel2 = @view.sel_x, width
				else
					sel1, sel2 = 0, @view.sel_x
				end
			elsif @view.cursor_y == ay
				if @view.cursor_y < @view.sel_y
					sel1, sel2 = @view.cursor_x, width
				else
					sel1, sel2 = 0, @view.cursor_x
				end
			end
		end
		
		info = RenderInfo.new(
			text, ay, options, 
			sel1, sel2, is_selected, 
			@scroll_x, pens)
		if info.equal?(@render_info[vy])
			#$logger.debug "row ##{vy} - ignore:  #{info.inspect}"
			@count_hit += 1
			return  # nothing to render
		end
		@render_info[vy] = info
		#$logger.debug "row ##{vy} - store:  #{info.inspect}"
		@count_miss += 1

		@n = 6 # reserve some space for line-numbers
		@x = 0
		(text || '').unpack('U*').each_with_index do |glyph, index|
			w = measure_width(@x, glyph)
			pen = nil
			if pens
				pen = pens[index]
			end
			if sel1 <= @x and @x < sel2
				pen = 3
			end
			if @x <= @red_column and @x + w > @red_column
				pen = 9
			end
			if glyph == 10 or glyph == 13
				w = 0   # ignore newlines
			elsif glyph == 9
				# these are also nice glyphs:  0x2192, 0x2500, 46
				push_halfwidth(32, pen || 8)
				(w-1).times do
					push_halfwidth(32, pen || 8)
				end
			elsif w == 1
				push_halfwidth(glyph, pen || 1)
			elsif w == 2
				push_fullwidth(glyph, pen || 1)
			else
				$logger.error "unknown glyph code=#{glyph.inspect} w=#{w}"
				push_halfwidth('?'[0], 9)
			end
		end
		while @x < @scroll_x + width
			pen = nil
			if sel1 <= @x and @x < sel2
				pen = 3
			end
			if @x == @red_column
				push_halfwidth(0x2502, pen || 6)
			else
				push_halfwidth(32, pen || 1)
			end
		end

		# format linenumbers
		5.times do |i|
			@render_pens[i] = 4
		end
		if ay
			number = (ay+1).to_s.rjust(5)
			0.upto(4) do |i|
				@render_glyphs[i] = number[i]
			end
		else
			0.upto(4) do |i|
				@render_glyphs[i] = 32
			end
		end
		@render_pens[5] = 6
		@render_glyphs[5] = 0x2502

		# show fold
		if (options & 2) != 0
			@render_glyphs[5] = 32 # 0x256f # 0x2570 
			@render_pens.map!{5}
		end
		
		# show bookmark
		if (options & 1) != 0
			#@render_glyphs[x + 5] = 0x2570 # 45
			5.times do |i|
				@render_pens[i] = 3
			end
		end
		
		# show selection
		if @view.sel_mode and ay
			if (@view.sel_y < ay and ay < @view.cursor_y) or 
				(@view.cursor_y < ay and ay < @view.sel_y)
				(@n-6).times do |i|
					@render_pens[6 + i] = 3
				end
			end
		end

		#if ay == 0
		#	$logger.info "line0 = #{@render_glyphs[0, @n].inspect}  n=#{@n}"
		#end
#=begin				
		@canvas.render_row2(
			vy, 
			@render_glyphs, 
			@render_pens, 
			0, 
			@n
		)
#=end
	end
	def cursor_show(x, y)
		cx = 6 + x - @scroll_x
		#$logger.info "cx=#{cx} cy=#{y}"
		@canvas.move(cx, y)
	end
	def refresh
		#$logger.info "curses refresh"
		@canvas.refresh
	end
	def measure_width(x, glyph)
		case glyph
		when 9
			@tabsize - (x % @tabsize)
		else
			@canvas.measure_width(glyph)
		end
	end
	def dump_statistics
		cnt = Hash.new
		cnt.default = 0
		ObjectSpace.each_object{|i| cnt[i.class.to_s] += 1}
		str_size = 0
		ObjectSpace.each_object(String) {|i| str_size += i.size}
		ary_size = 0
		ObjectSpace.each_object(Array) {|i| ary_size += i.size}
		ary = cnt.map{|k, v| [v, k] }.sort.last(10).reverse
		w = ary.map{|(v, k)| k.size}.max
		res = ["statistics"]
		res += ary.map{|(v, k)| 
			if k == 'String'
				v = "#{v}  (total size=#{str_size})"
			elsif k == 'Array'
				v = "#{v}  (total size=#{ary_size})"
			end
			k.rjust(w) + " | #{v}"
		}
		$logger.info res.join("\n")
	end
end

if $0 == __FILE__
	require 'logger'
	logfile = File.join(ENV['HOME'], 'aeditor-2.0.log')
	$logger = Logger.new(logfile, 0, 102400)
	$logger.level = Logger::DEBUG
	begin
		$logger.info "program begin."
		#dump_memory_info
		MainTUI.run(ARGV)
	rescue Exception => e
		bt = e.backtrace.map{|s| 
			a, b, c = s.split(':', 3)
			bn = File.basename(a)
			"%15s | %5s | %s" % [bn, b, c]
		}.join("\n")
		$logger.fatal "uncaught exception occured\n" +
			"#{e.class} #{e.message}\n" + bt
	end
	dump_memory_info
 	$logger.info "program end."
	$logger.close
end
