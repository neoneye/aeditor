require 'optparse'
require 'logger'

class CommandLineInterface
	VERSION = '1.9'
	def initialize
		@filenames = []
		@program_name = File.basename($0)
	end
	attr_reader :filenames
	def parse(argv)
		option_parser = OptionParser.new do |opts|
			opts.banner = '(GUI mode) Programmers editor with syntax ' +
				'coloring for Ruby and C/C++.'
			opts.separator ''
			opts.separator "Usage: #{@program_name} [options] [file..]"
			opts.separator ''
			opts.separator 'Options:'
			opts.on_tail('-h', '--help', 'print help (this message) and exit') do 
				show_help(opts)
				return
			end
			opts.on('--version', 'print version information and exit') do 
				show_version
				return
			end
			opts.on('--selftest', 'perform tests and exit') do 
				launch_selftest
				return
			end
			opts.on('-d', '--debug [LEVEL]', 'run with debug output') do |level|
                $logger.level = Logger::DEBUG
                $logger.debug_level = level.to_i || 1
			end
		end
		begin
			option_parser.parse(argv)
		rescue OptionParser::InvalidOption => e
			show_badoption(e.message)
			return
		end
		@filenames += argv
		launch_editor
	end
	def show_help(msg)
		puts msg
	end
	def show_badoption(msg)
		puts msg
		puts "get more info with \"#{@program_name} -h\""
	end
	def get_version_fox_toolkit
		"UNDEF"
	end
	def get_version_fxruby
		"UNDEF"
	end
	def get_version_iterator
		"UNDEF"
	end
	def get_version_ruby
		::VERSION
	end
	def get_version_editor
		VERSION
	end
	def get_platform
		::RUBY_PLATFORM
	end
	def show_version
		out = <<-HERE
			versions:
			  editor           #{get_version_editor.inspect}
			  fox toolkit      #{get_version_fox_toolkit.inspect}
			  fxruby           #{get_version_fxruby.inspect}
			  iterator         #{get_version_iterator.inspect}
			  ruby             #{get_version_ruby.inspect}

			other info:
			  platform         #{get_platform.inspect}
		HERE
        
        out.gsub!(/^\t\t\t/,'')
        puts out
	end
	def launch_editor
		puts "launch editor with filenames=#{@filenames.inspect}"
	end
	def launch_selftest
		puts "launch selftest"
	end
	def self.parse(argv)
		i = self.new
		i.parse(argv)
		i
	end
end # class CommandLineInterface

if $0 == __FILE__
	#puts "parsing ARGV=#{ARGV.inspect}" 
	CommandLineInterface.parse(ARGV) 
end
