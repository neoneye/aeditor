require 'aeditor/config'
require 'aeditor/buffer'
require 'aeditor/lexer'

module Session

class OneBuffer
	def initialize
		data_model = Buffer::Model::Caretaker.new
		@view = Buffer::View::Caretaker.new(data_model, 80, 50)
		@title = 'unnamed'
		@filename = nil
		set_mode(nil)
	end
	attr_reader :title, :filename, :mode, :view
	def model
		@view.model
	end
	def set_mode(mode)
		@mode = mode
		unless mode
			@view.set_lexer(LexerText::Lexer.new)
			@view.set_tabsize(8)
			@view.set_mode_cursor_through_tabs(false)
			@view.set_mode_autoindent(true)  
			return
		end
		$logger.debug(2) {"#{title}, setting lexer #{@mode.lexer}"}

		# find an appropriate lexer
		lexer = case @mode.lexer.to_s
		when 'ruby' : LexerRuby::Lexer.new
		when 'cpp' : LexerCplusplus::Lexer.new
		else LexerText::Lexer.new
		end

		@view.set_lexer(lexer)
		@view.set_tabsize(@mode.tabsize)
		@view.set_mode_cursor_through_tabs(@mode.cursor_through_tabs)
	end
	def set_title(title)
		@title = title
	end
	def set_filename(filename)
		@filename = filename
	end
end

class Caretaker
	include Config
	def initialize
		@buffers = []
		@modes = []
		@themes = []
		@global_conf = Global.new
		@buffer_index = 0
		@suffixes = {}
		@clipboard = ''
	end
	attr_reader :buffers, :buffer_index, :suffixes, :clipboard
	attr_reader :modes, :themes, :global_conf
	def rebuild_file_suffix_hash
		suffixes = {}
		@modes.each do |mode|
			mode.file_suffixes.each do |sfx|
				esfx = Regexp.escape('.' + sfx)
				re = Regexp.new(esfx + '\z')
				suffixes[re] = mode
			end
		end
		@suffixes = suffixes
	end
	def set_clipboard(text)
		@clipboard = text
	end
	def lookup(name)
		@modes.each do |mode|
			return mode if mode.name == name
		end
		nil
	end
	def register(mode)
		@modes << mode
	end
	def register_theme(theme)
		@themes << theme
	end
	def puts2(text)
		$logger.warn text
	end
	def load_config(filename)
		unless File.exists?(filename)
			$logger.warn { "did not find config, " +
				"filename=#{filename.inspect}" }
		end
		self.instance_eval(IO.read(filename)) 
		rebuild_file_suffix_hash
		$logger.warn { "successfully loaded config, " +
			"filename=#{filename.inspect}" }
	end
	def open_buffer(filename)
		abs_filename = File.expand_path(filename)
		begin
			text = IO.read(abs_filename)
		rescue Errno::EACCES, Errno::ENOENT => e
			raise "cannot read, #{e.message}"
		end
		buffer = OneBuffer.new
		buffer.model.append_text(text)
		buffer.set_filename(abs_filename)
		buffer.set_title(File.basename(abs_filename))
		@buffers << buffer
		@buffer_index = @buffers.size-1 
		switch_mode_via_filename 
	end
	def switch_mode_via_filename
		unless buffer.filename
			buffer.set_mode(nil)
			return
		end
		mode = nil
		@suffixes.each do |re, m|
			if re =~ buffer.filename
				mode = m
				break
			end
		end
		buffer.set_mode(mode)
	end
	def open_buffer_empty
		buffer = OneBuffer.new
		@buffers << buffer
		@buffer_index = @buffers.size-1
	end
	def set_buffer_index(index)
		@buffer_index = index
	end
	def buffer
		@buffers[@buffer_index]
	end
	def close_buffer
		@buffers.delete_at(@buffer_index)
	end
end

end # module Session
