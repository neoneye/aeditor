require 'aeditor/backend/global'
require 'getoptlong'

class Cmdline
	class Message < StandardError; end  # display message and exit
	class Error < StandardError; end  # display error+usage and exit

	def initialize(files_to_open)
		@files_to_open = files_to_open
	end
	attr_reader :files_to_open
	def Cmdline.parse(argv)
		save_argv = ARGV.dup
		begin
			ARGV.replace(argv)
			options = GetoptLong.new(
				["--version", "-v",     GetoptLong::NO_ARGUMENT],
				["--help",              GetoptLong::NO_ARGUMENT]
			)
			options.quiet = true
			options.each do |opt, arg|
				case opt
				when "--help"
					raise Message, "help message"
				when "--version"
					raise Message, "ver #{Global::VERSION}"
	#			else
	#				raise "Invalid option '#{opt}'"
				end
			end
			# only return Cmdline instance if everything is OK
			return Cmdline.new(ARGV.dup)
		rescue GetoptLong::InvalidOption
			raise Error
		ensure
			ARGV.replace(save_argv)
		end
	end
	def Cmdline.usage
		<<TXT
Usage: 
    #{File.basename $0} [arguments] [file..]     Edit specified file(s)

Arguments:
    --help        This information you see here and exit.
    --version     Print version info and exit.
TXT
	end
end
