require 'test/unit'
require 'iterator'

class TestIterator < Test::Unit::TestCase
	def test_collection_compare
		b = (0..8).to_a.create_iterator
		class << b; alias p position end
		b.next
		a = b.clone
		b.next
		assert_equal([true, true, false], [a.p<b.p, a.p<=b.p, a.p==b.p])
		a.next
		assert_equal([false, true, true], [a.p<b.p, a.p<=b.p, a.p==b.p])
		a.next
		assert_equal([false, false, false], [a.p<b.p, a.p<=b.p, a.p==b.p])
	end
	def test_collection_is_done
		input = [-1, 0, 1, 2, 3]
		exp = [true, false, false, false, true]
		i = (0..2).to_a.create_iterator
		i.first
		class << i
			attr_writer :position
		end
		res = input.map{|p| i.position=p; i.is_done?}
		assert_equal(exp, res)
	end
	def test_collection_empty
		iterator = [].create_iterator
		iterator.first
		assert_equal(true, iterator.is_done?)
	end
	def test_collection_exercise_next
		iterator = (1..5).to_a.create_iterator
		res = []
		iterator.first
		until iterator.is_done?
			res << iterator.current
			iterator.next
		end
		assert_equal((1..5).to_a, res)
	end
	def test_collection_exercise_prev
		iterator = (1..5).to_a.create_iterator
		res = []
		iterator.last
		until iterator.is_done?
			res << iterator.current
			iterator.prev
		end
		assert_equal((1..5).to_a.reverse, res)
	end
	def test_collection_each
		iterator = (1..5).to_a.create_iterator
		assert_equal((1..5).to_a, iterator.to_a)
	end
	def test_collection_reverse_each
		iterator = (1..5).to_a.create_iterator
		res = []
		iterator.reverse_each{|i| res << i }
		assert_equal((1..5).to_a.reverse, res)
	end
	def test_collection_assignment
		data = (1..5).to_a
		iterator = data.create_iterator
		iterator.next
		iterator.current = 5
		assert_equal([1, 5, 3, 4, 5], data)
	end
	def test_collection_bidirectional
		i = (0..2).to_a.create_iterator
		i.first
		res = []
		res << i.current
		i.next
		res << i.current
		i.next
		res << i.current
		res << i.is_done?
		i.prev
		res << i.current
		i.prev
		res << i.current
		res << i.is_done?
		assert_equal([0, 1, 2, false, 1, 0, false], res)
	end
	def test_collection_exercise_position
		iterator = (0..3).to_a.create_iterator
		res = []
		iterator.first
		until iterator.is_done?
			res << iterator.position
			iterator.next
		end
		assert_equal((0..3).to_a, res)
	end
	def test_reverse_exercise_next
		iterator = (1..5).to_a.create_iterator.reverse
		assert_equal((1..5).to_a, iterator.to_a.reverse)
	end
	def test_reverse_exercise_prev
		iterator = (1..5).to_a.create_iterator.reverse.reverse
		assert_equal((1..5).to_a, iterator.to_a)
	end
	def test_reverse_exercise_position
		iterator = (0..3).to_a.create_iterator.reverse
		res = []
		iterator.first
		until iterator.is_done?
			res << iterator.position
			iterator.next
		end
		assert_equal((0..3).to_a.reverse, res)
	end
	def test_range_exercise_next
		data = (0..4).to_a
		i = data.create_iterator
		i.next
		a = i.clone
		i.next
		i.next
		b = i.clone
		iterator = Iterator::Range.new(a, b)
		assert_equal((1..3).to_a, iterator.to_a)
	end
	def test_range_exercise_prev
		data = (0..4).to_a
		i = data.create_iterator
		i.next
		a = i.clone
		i.next
		i.next
		b = i.clone
		iterator = Iterator::Reverse.new(Iterator::Range.new(a, b))
		assert_equal((1..3).to_a.reverse, iterator.to_a)
	end
	def test_concat_exercise_next
		i0 = [].create_iterator   # an obstacle which should be ignored
		i1 = (1..3).to_a.create_iterator
		i2 = [].create_iterator   # an obstacle which should be ignored
		i3 = (5..7).to_a.create_iterator
		i4 = [].create_iterator   # an obstacle which should be ignored
		iterator = Iterator::Concat.new(i0, i1, i2, i3, i4)
		assert_equal((1..3).to_a + (5..7).to_a, iterator.to_a)
	end
	def test_concat_exercise_prev
		i0 = [].create_iterator   # an obstacle which should be ignored
		i1 = (1..3).to_a.create_iterator
		i2 = [].create_iterator   # an obstacle which should be ignored
		i3 = (5..7).to_a.create_iterator
		i4 = [].create_iterator   # an obstacle which should be ignored
		iterator = Iterator::Reverse.new(
			Iterator::Concat.new(i0, i1, i2, i3, i4))
		assert_equal((1..3).to_a + (5..7).to_a, iterator.to_a.reverse)
	end
	def test_concat_assignment
		data1 = (1..3).to_a
		data2 = (5..7).to_a
		i1 = data1.create_iterator
		i2 = data2.create_iterator
		iterator = Iterator::Concat.new(i1, i2)
		iterator.next
		iterator.current = 5
		iterator.next
		iterator.next
		iterator.next
		iterator.current = 3
		assert_equal([1, 5, 3, 5, 3, 7], data1 + data2)
	end
	def test_concat_sort
		i1 = [5, 3, 1].create_iterator
		i2 = [2, 4, 6].create_iterator
		iterator = Iterator::Concat.new(i1, i2)
		assert_equal((1..6).to_a, iterator.sort)
	end
	def test_continuation_next
		ary = (1..5).to_a
		i = Iterator::Continuation.new(ary, :reverse_each)
		res = []
		until i.is_done?
			v = i.current
			i.next
			res.unshift(v)
		end
		i.close
		assert_equal(ary, res)
	end
	def test_continuation_inject
		ary = (1..5).to_a
		iterator = Iterator::Continuation.new(ary, :reverse_each)
		res = iterator.inject(0){|v, i| v+i}
		iterator.close
		assert_equal(15, res)
	end
end

if $0 == __FILE__
	require 'test/unit/ui/console/testrunner'
	Test::Unit::UI::Console::TestRunner.run(TestIterator)
end
