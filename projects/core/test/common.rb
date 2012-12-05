require 'test/unit' 

module Common
	class TestCase < Test::Unit::TestCase
		def self.run
			require 'test/unit/ui/console/testrunner'
			Test::Unit::UI::Console::TestRunner.run(self, Test::Unit::UI::VERBOSE)
		end
	end
end # module Common
