require 'test/unit'

class TestAll
	def self.suite
		suite = Test::Unit::TestSuite.new
		Object.constants.sort.each do |k|
			next if /^Test/ !~ k
			constant = Object.const_get(k)
			if constant.kind_of?(Class) && 
				constant.superclass == Test::Unit::TestCase
				suite << constant.suite
			end
		end
		suite
	end
	def self.run
		dirname = File.dirname(File.expand_path(__FILE__))
		absfiles = nil
		Dir.chdir(dirname) do
			absfiles = Dir.glob("test_*.rb").map do |file|
				File.expand_path(file)
			end
		end
		absfiles.each do |file|
			next if file == File.expand_path(__FILE__)
			require "#{file}"
		end
		require 'test/unit/ui/console/testrunner'
		Test::Unit::UI::Console::TestRunner.run(self)
	end
end

TestAll.run if __FILE__ == $0
