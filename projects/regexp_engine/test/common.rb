require 'regexp/misc'
require 'regexp/abstract_syntax'
require 'regexp/parser'
require 'regexp/scanner'
require 'regexp/scanner_nodes'
require 'iterator'
require 'test/unit'
require 'stringio'

module Common
	class TestCase < Test::Unit::TestCase
		def self.run
			require 'test/unit/ui/console/testrunner'
			Test::Unit::UI::Console::TestRunner.run(self, Test::Unit::UI::VERBOSE)
		end

		# option handling for the P5 blackbox exercies
		def check_options(options, *optdecl)
			h = options.clone
			optdecl.each{|name|h.delete(name)}
			raise ArgumentError, "no such option: #{h.keys.join(' ')}" unless h.empty?
		end
		def check_options_regexp(options)
			check_options(options, 
				:rubywarn, 
				:bug_gnu, 
				:oniguruma_output,
				:encoding
			)
		end

		def capture_stderr(&block)
			e = StringIO.new
			$stderr = e
			block.call
			return e.string
		ensure
			$stderr = STDERR
		end

		REGISTERS_TEXTDATA = %w(a b c d e)
		def make_iterators(*positions)
			i0 = REGISTERS_TEXTDATA.create_iterator
			iterators = positions.map{|pos| i0.clone.next(pos) }
			i0.close
			iterators
		end
	end
end # module Common
