require 'aeditor/backend/misc'
require 'common'

class TestMisc < Common::TestCase 
	def test_shift_until
		ary = [1, 2, "a", 3, 4, "b", 5, 6]
		res = ary.shift_until(String)
		assert_equal([1, 2], res)
		assert_equal(["a", 3, 4, "b", 5, 6], ary)
	end
	def test_shift_until_non_existing_class
		ary = [1, 2, "a", 3, 4, "b", 5, 6]
		res = ary.shift_until(IO)
		assert_equal([], ary)
		assert_equal([1, 2, "a", 3, 4, "b", 5, 6], res)
	end
	def test_shift_until_regex
		ary = [1, 2, "a", 3, 4, "b", 5, 6]
		res = ary.shift_until(/^b/)
		assert_equal(["b", 5, 6], ary)
		assert_equal([1, 2, "a", 3, 4], res)
	end
	def test_pop_until
		ary = [1, 2, "a", 3, 4, "b", 5, 6]
		res = ary.pop_until(String)
		assert_equal([5, 6], res)
		assert_equal([1, 2, "a", 3, 4, "b"], ary)
	end
	def test_pop_until_non_existing_class
		ary = [1, 2, "a", 3, 4, "b", 5, 6]
		res = ary.pop_until(IO)
		assert_equal([], ary)
		assert_equal([1, 2, "a", 3, 4, "b", 5, 6], res)
	end
	def test_pop_until_regex
		ary = [1, 2, "a", 3, 4, "b", 5, 6]
		res = ary.pop_until(/^a/)
		assert_equal([1, 2, "a"], ary)
		assert_equal([3, 4, "b", 5, 6], res)
	end
	def test_push0
		ary = %w(a b c)
		ary.push(*[])
		assert_equal(%w(a b c), ary)
	end
	def test_push1
		ary = [1]
		ary.push(*[2, 3])
		assert_equal([1, 2, 3], ary)
	end
	def test_unshift0
		ary = %w(a b c)
		ary.unshift(*[])
		assert_equal(%w(a b c), ary)
	end
	def test_unshift1
		ary = [3]
		ary.unshift(*[1, 2])
		assert_equal([1, 2, 3], ary)
	end
	def test_ary_class_inspect1
		assert_equal([], [].class_inspect) 
	end
	def test_ary_class_inspect2
		ary = ["a", 2, "b", "c", 4, 5]
		expect = ["String 1","Fixnum 1","String 2","Fixnum 2"]
		assert_equal(expect, ary.class_inspect) 
	end
end

TestMisc.run if $0 == __FILE__
