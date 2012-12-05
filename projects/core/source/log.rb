class Log
	def initialize(io)
		@io = io
		@n = 0
		@disabled = true
	end
	attr_accessor :disabled
	def Log.create(
		name = "aeditor.log", 
		dir = ENV['TMPDIR']||ENV['TMP']||ENV['TEMP']||'/tmp'
		)
		file = dir+File::SEPARATOR+name
		log = File.new(file, "w+")
		log.sync = true  # we want to avoid log.flush 
		Log.new(log)
	end
	def debug(*args)
		return if @disabled
		@io.puts "--- [#{@n}] " + ("-"*50)
		@n += 1
		@io.puts(*args)
	end
	def puts(*args)
		@io.puts "--- [#{@n}] " + ("-"*50)
		@n += 1
		@io.puts(*args)
	end
	def print_exception(e)
		msg =<<MSG
Fatal-Error in program!
please report this bug.
EXCEPTION: 
\t#{e.class.to_s}
MESSAGE:
\t#{e.message}
BACKTRACE:
#{e.backtrace.map{|t|"\t#{t}\n"}.join}
MSG
		puts msg
	end
end
$log = Log.create
