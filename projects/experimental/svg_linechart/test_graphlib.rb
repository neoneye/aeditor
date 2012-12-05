require 'test/unit'
require 'graphlib'

class TestGraphlib < Test::Unit::TestCase
	include Graphlib
	def assert_values(expected, actual)
		assert_equal(expected.size, actual.size)
		expected.zip(actual).each_with_index do |(e, a), index|
			assert_in_delta(e, a, 0.01, "index=#{index}")
		end
	end
	def test_create_pieces1
		act = Helper.create_pieces(0, 40, 5)
		assert_values([0, 10, 20, 30, 40], act)
	end
	def test_create_pieces2
		act = Helper.create_pieces(100, 200, 4)
		assert_values([100, 133.33, 166.66, 200], act)
	end
	def test_normalize_values1
		values = [100, 80, 40, 10, 0]
		act = Helper.normalize_values(0, 100, 10, values)
		assert_values([10, 8, 4, 1, 0], act)
	end
	def test_normalize_values2
		values = [200, 180, 150, 110, 100]
		act = Helper.normalize_values(100, 200, 10, values)
		assert_values([10, 8, 5, 1, 0], act)
	end
	def test_normalize_values3
		values = [400, 100, 200, 300]
		act = Helper.normalize_values(100, 400, 10, values)
		assert_values([10, 0, 3.33, 6.66], act)
	end
end