require 'aeditor/cli'
require 'logger'

class MainCLI < CommandLineInterface
	def maybe_fork(&block)
		fork(&block)
	rescue NotImplementedError
		$logger.debug(1) {"cannot use fork, using block"}
		block.call
	end
	def launch_editor
		require 'aeditor/viewfox'
		maybe_fork do
			OurApp.run(@filenames)
		end
	end
	def launch_selftest
		require 'aeditor/test_all'
		TestAll.run
	end
	def get_version_fox_toolkit
		require 'fox'
		Fox::fxversion
	rescue LoadError
		"not installed"
	end
	def get_version_fxruby
		require 'fox'
		Fox::fxrubyversion
	rescue LoadError
		"not installed"
	end
	def get_version_iterator
		require 'iterator'
		Iterator::VERSION
	rescue LoadError
		"not installed"
	end
end


$logger = Logger.new(STDOUT)

class << $logger

    attr_accessor :debug_level

    $logger.instance_variable_set(:@debug_level, 1)
    
    # higher "level" number means more output
    def debug(dlevel = 1, progname = nil, &block)
        add(DEBUG, nil, progname, &block) if dlevel <= @debug_level
  end
end

$logger.level = Logger::ERROR

MainCLI.parse(ARGV)