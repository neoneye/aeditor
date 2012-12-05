require 'test/unit'

class TestAll
	def TestAll.suite
		suite = Test::Unit::TestSuite.new
		Object.constants.sort.each do |k|
			next if /^Test/ !~ k
			constant = Object.const_get(k)
			if constant.kind_of?(Class) && 
				constant.ancestors.include?(Test::Unit::TestCase)
				suite << constant.suite
			end
		end
		suite
	end
end

if __FILE__ == $0
	Dir.glob("test_*.rb").each do |file|
		next if file == $0
		begin
			require "#{file}"
		rescue RuntimeError => e
			warn "skipping #{file} because #{e.message}"
		end
	end
	require 'test/unit/ui/console/testrunner'
	Test::Unit::UI::Console::TestRunner.run(TestAll)
end
