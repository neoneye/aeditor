require 'aeditor/backend/misc'
require 'aeditor/backend/log'
require 'aeditor/backend/buffer'
require 'aeditor/ncurses/cmdline'
require 'aeditor/ncurses/frontend'

class Application
	def initialize(options)
		@options = options

		@buffer = Buffer.new
		@view = ViewNcurses.new(@buffer)
		@buffer.add_observer(@view)
		@buffer.adjust_height(@view.cellarea.gety)
		@ctrl = ControlNcurses.new(@buffer, @view)
	end
	def run
		# at the moment we can only deal with one file at a time
		# therefore only open the first file. 

		files = @options.files_to_open
		if files.size > 0
			@buffer.file_open(files[0])
		end

		@view.update(@buffer)
		loop do
			event = @view.cellarea.waitkey
			@ctrl.dispatch(event)
		end
	end
	def close
		@view.cellarea.close
	end
	def Application.launch
		options = Cmdline.parse(ARGV)
		app = Application.new(options)
		begin
			app.run
		rescue Control::ExitClean
			$log.puts "Clean Exit - Everything is normal"
			app.close
		rescue Exception => e
			$log.print_exception(e)
			app.close
			raise e, e.message, e.backtrace
		end
	rescue Cmdline::Message => e
		$stdout.puts e
	rescue Cmdline::Error => e
		$stderr.puts "Error: #{e}"
		$stdout.puts Cmdline.usage
	end
end

if $0 == __FILE__
	Application.launch
end
