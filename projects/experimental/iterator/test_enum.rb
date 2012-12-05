require 'test/unit'
require 'stream'

class TestEnum < Test::Unit::TestCase
	def setup
		@data = (1..3).create_stream + (5..7).create_stream
	end
	def test_findall
		res = @data.find_all{|i| i % 2 == 0 }
		assert_equal([2, 6], res)
	end
	def test_findall_notfound
		res = @data.find_all{|i| i == 4 }
		assert_equal([], res)
	end
	def test_partition
		res = @data.partition{|i| i % 2 == 1 }
		assert_equal([1, 3, 5, 7], res[0])
	end
	def test_map
		res = @data.map{|i| i.to_s }
		assert_equal(%w(1 2 3 5 6 7), res)
	end
end

if $0 == __FILE__
	require 'test/unit/ui/console/testrunner'
	Test::Unit::UI::Console::TestRunner.run(TestEnum)
end
