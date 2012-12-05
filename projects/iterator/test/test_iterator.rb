require 'test/unit'
require 'iterator'

class TestIterator < Test::Unit::TestCase
	def test_collection_compare1
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
	def test_collection_has_next
		input = [0, 1]
		i = input.create_iterator
		n = 0
		while i.has_next?
			n += 1
			i.next
		end
		assert_equal(2, n)
	end
	def test_collection_has_prev
		input = [0, 1]
		i = input.create_iterator_end
		n = 0
		while i.has_prev?
			n += 1
			i.prev
		end
		assert_equal(2, n)
	end
	def test_collection_empty
		iterator = [].create_iterator
		iterator.first
		assert_equal(false, iterator.has_next?)
	end
	def test_collection_exercise_next
		iterator = (1..5).to_a.create_iterator
		res = []
		iterator.first
		while iterator.has_next?
			res << iterator.current
			iterator.next
		end
		assert_equal((1..5).to_a, res)
	end
	def test_collection_exercise_prev
		iterator = (1..5).to_a.create_iterator
		res = []
		iterator.last
		while iterator.has_prev?
			# observe that this inner-loop are different
			# from #test_collection_exercise_next
			iterator.prev
			res << iterator.current
		end
		assert_equal((1..5).to_a.reverse, res)
	end
	def test_collection_each
		iterator = (1..5).to_a.create_iterator
		assert_equal((1..5).to_a, iterator.to_a)
	end
	def test_collection_each2
		data = (1..5).to_a
		i1 = data.create_iterator
		i2 = data.create_iterator_end 
		assert_equal((1..5).to_a, Array.copy(i1, i2))
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
		res << i.has_next?
		i.next
		res << i.has_next?
		i.prev
		i.prev
		res << i.current
		i.prev
		res << i.current
		res << i.has_prev?
		assert_equal([0, 1, 2, true, false, 1, 0, false], res)
	end
	def test_collection_prev
		iterator = %w(a b c d).create_iterator
		iterator.last
		assert_equal(4, iterator.position)
		assert_equal('d', iterator.current_prev)
		iterator.prev(3)
		assert_equal(1, iterator.position)
		assert_equal('a', iterator.current_prev)
		iterator.prev
		assert_equal(0, iterator.position)
		assert_raise(RuntimeError) { iterator.current_prev }
	end
	def test_collection_exercise_position
		iterator = (0..3).to_a.create_iterator
		res = []
		iterator.first
		while iterator.has_next?
			res << iterator.position
			iterator.next
		end
		assert_equal((0..3).to_a, res)
	end
	def test_collection_compare2
		iterator = (0..3).to_a.create_iterator
		i2a = iterator.clone.next(2)
		iterator.next
		i2b = iterator.clone.next
		assert_equal(i2a, i2b)
	end
	def test_collection_comparable
		i1 = %w(a b c d e).to_a.create_iterator
		i2 = i1.clone.next
		i3 = i2.clone.next
		assert_equal([i1, i2, i3], [i2, i3, i1].sort)
		assert_equal(true, i2.between?(i1, i3))
		assert_equal(true, i3 > i2)
		assert_equal(false, i1 > i3)
		assert_raises(TypeError) { (i2 > 'evil') }
	end
	def test_collection_clone
		iterator = (0..3).to_a.create_iterator
		i2 = iterator.clone.next(2)
		iterator.next(2)
		assert_equal(i2, iterator)
	end
	def test_collection_clone2
		string_ary = %w(a b c d e)
		i1 = string_ary.create_iterator.next(2)
		assert_equal(2, i1.position)
		assert_equal('c', i1.current)
		i2 = i1.clone.next
		assert_equal(3, i2.position)
		assert_equal('d', i2.current)
		assert_equal(string_ary.object_id, i2.data.object_id)
		# check if clone were harmless
		assert_equal(2, i1.position)
		assert_equal('c', i1.current)
		assert_equal(string_ary.object_id, i1.data.object_id)
	end
	def test_collection_string1
		ascii = "abcde"
		iterator = ascii.create_iterator
		assert_equal((97..101).to_a, iterator.to_a)
	end
	def test_reverse_exercise_next
		iterator = (1..5).to_a.create_iterator.reverse
		assert_equal((1..5).to_a, iterator.to_a.reverse)
		iterator = (1..5).to_a.create_iterator.reverse.reverse
		assert_equal((1..5).to_a, iterator.to_a)
	end
	def test_reverse_exercise_position
		iterator = (0..3).to_a.create_iterator.reverse
		res = []
		iterator.first
		while iterator.has_next?
			res << iterator.position
			iterator.next
		end
		assert_equal((1..4).to_a.reverse, res)
	end
	def test_reverse_comparable
		i1 = (1..5).to_a.create_iterator.reverse
		i1.first
		i2 = i1.clone.next
		i3 = i2.clone.next
		assert_equal([i3, i2, i1], [i3, i1, i2].sort)
	end
	def test_reverse_clone
		string_ary = %w(a b c d e)
		i1 = string_ary.create_iterator.next(3)
		r1 = i1.reverse
		assert_equal(3, r1.position)
		r2 = r1.clone.next
		assert_equal(2, r2.position)
		# check that #clone were harmless
		assert_equal(3, r1.position)
	end
	def test_range_exercise_next
		data = (0..4).to_a
		i = data.create_iterator
		i.next
		a = i.clone
		i.next(2)
		b = i.clone
		iterator = Iterator::Range.new(a, b)
		assert_equal((1..2).to_a, iterator.to_a)
	end
	def test_range_exercise_prev
		data = (0..4).to_a
		i = data.create_iterator
		i.next
		a = i.clone
		i.next(2)
		b = i.clone
		iterator = Iterator::Reverse.new(Iterator::Range.new(a, b))
		assert_equal((1..2).to_a.reverse, iterator.to_a)
	end
	def test_concat_exercise_next
		i0 = [].create_iterator   # an obstacle which should be ignored
		i1 = (1..3).to_a.create_iterator
		i2 = [].create_iterator   # an obstacle which should be ignored
		i3 = (5..7).to_a.create_iterator
		i4 = [].create_iterator   # an obstacle which should be ignored
		iterator = Iterator::Concat.new([i0, i1, i2, i3, i4])
		assert_equal(1, iterator.position)
		assert_equal((1..3).to_a + (5..7).to_a, iterator.to_a)
	end
	def test_concat_exercise_prev
		i0 = [].create_iterator   # an obstacle which should be ignored
		i1 = (1..3).to_a.create_iterator
		i2 = [].create_iterator   # an obstacle which should be ignored
		i3 = (5..7).to_a.create_iterator
		i4 = [].create_iterator   # an obstacle which should be ignored
		iterator = Iterator::Reverse.new(
			Iterator::Concat.new([i0, i1, i2, i3, i4]))
		assert_equal((1..3).to_a + (5..7).to_a, iterator.to_a.reverse)
	end
	def test_concat_assignment
		data1 = (1..3).to_a
		data2 = (5..7).to_a
		i1 = data1.create_iterator
		i2 = data2.create_iterator
		iterator = Iterator::Concat.new([i1, i2])
		iterator.next
		iterator.current = 5
		iterator.next(3)
		iterator.current = 3
		assert_equal([1, 5, 3, 5, 3, 7], data1 + data2)
	end
	def test_concat_sort
		i1 = [5, 3, 1].create_iterator
		i2 = [2, 4, 6].create_iterator
		iterator = Iterator::Concat.new([i1, i2])
		assert_equal((1..6).to_a, iterator.sort)
	end
	def test_continuation_next
		ary = (1..5).to_a
		i = Iterator::Continuation.new(ary, :reverse_each)
		res = []
		while i.has_next?
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
	def test_continuation_clone
		ary = (1..5).to_a
		i1 = Iterator::Continuation.new(ary, :reverse_each)
		i1.next(2)
		i2 = i1.clone 
		assert_equal(i1.position, i2.position)
	end
	def test_continuation_comparable
		ary = (1..5).to_a
		i1 = Iterator::Continuation.new(ary, :reverse_each)
		i2 = i1.clone.next
		i3 = i2.clone.next
		assert_equal([i1, i2, i3], [i2, i1, i3].sort)
		assert_equal(false, i2 > i3)
		assert_equal(true, i2 > i1)
	end
	def test_proxylast_next1
		idata = %w(a b c).create_iterator
		input = Iterator::ProxyLast.new(idata)
		assert_equal(nil, input.last_value)
		assert_equal("a", input.current)
		input.next
		assert_equal("a", input.last_value)
		assert_equal("b", input.current)
		input.next
		assert_equal("b", input.last_value)
		assert_equal("c", input.current)
	end
	def test_proxylast_clone1
		idata = %w(a b c).create_iterator
		i1 = Iterator::ProxyLast.new(idata)
		i1.next
		i2 = i1.clone
		assert_equal(i1, i2)
		assert_equal("a", i2.last_value)
		i2.next
		assert_not_equal(i1, i2)
		assert_equal("a", i1.last_value)
		assert_equal("b", i2.last_value)
	end
	def test_proxylast_position1
		idata = %w(a b c).create_iterator
		input = Iterator::ProxyLast.new(idata)
		input.next
		assert_equal(1, input.position)
	end
	def test_proxylast_comparable
		idata = %w(a b c d e).create_iterator
		i1 = Iterator::ProxyLast.new(idata)
		i2 = i1.clone.next
		i3 = i2.clone.next
		assert_equal([i1, i2, i3], [i3, i1, i2].sort)
		assert_equal(true, i3 > i1)
		assert_equal(false, i1 > i3)
	end
	def test_proxylast_reverse1
		idata = %w(a b c).create_iterator
		input = Iterator::ProxyLast.new(idata)
		input.next
		rev_input = input.reverse
		assert_equal(1, rev_input.position)
		assert_equal('a', rev_input.current)
		assert_equal('b', rev_input.last_value)
	end
	def test_proxylast_reverse2
		idata = %w(a b c).create_iterator
		input = Iterator::ProxyLast.new(idata)
		input.next
		input2 = input.reverse.reverse
		assert_equal(1, input2.position)
		assert_equal('b', input2.current)
		assert_equal('a', input2.last_value)
		input2.next
		assert_equal(2, input2.position)
		assert_equal('c', input2.current)
		assert_equal('b', input2.last_value)
	end
	def test_proxylast_reverse3
		data = %w(a b c).create_iterator
		input = Iterator::ProxyLast.new(data)
		input.next(3)
		assert_equal(3, input.position)
		assert_equal('c', input.last_value)
		assert_raises(RuntimeError) { input.current }
		rev_input = input.reverse
		assert_equal(3, rev_input.position)
		assert_equal('c', rev_input.current)
		assert_equal(nil, rev_input.last_value)
	end
	def test_proxylast_reverse_reverse1
		data = %w(a b c d).create_iterator
		input = Iterator::ProxyLast.new(data)
		input.next(2)
		rev_input = input.reverse
		assert_equal(2, rev_input.position)
		assert_equal('b', rev_input.current)
		assert_equal('c', rev_input.last_value)
		rev_input2 = rev_input.reverse
		assert_kind_of(Iterator::Collection, rev_input2.i)
		assert_equal(input.position, rev_input2.position)
		assert_equal(input.current, rev_input2.current)
		assert_equal(input.last_value, rev_input2.last_value)
	end
	def test_algorithm_copy0
		ary = (0..9).to_a
		i1 = ary.create_iterator.next(3)
		assert_equal([], Array.copy(i1, i1.clone))  # copy nothing
	end
	def test_algorithm_copy1
		ary = (0..9).to_a
		i1 = ary.create_iterator.next(3)
		i2 = i1.clone.next(2)
		assert_equal([3, 4], Array.copy(i1, i2))
	end
	def test_algorithm_copy_n1
		ary = (0..9).to_a
		i1 = ary.create_iterator.next(3)
		assert_equal([3, 4], Array.copy_n(i1, 2))
	end
	def test_algorithm_copy_backward1
		ary = (0..9).to_a
		i1 = ary.create_iterator.next(3)
		i2 = i1.clone.next(2)
		assert_equal([4, 3], Array.copy_backward(i1, i2))
	end
	def test_algorithm_fill1
		ary = (0..3).to_a
		i1 = ary.create_iterator.next
		i2 = ary.create_iterator_end.prev
		Iterator::Algorithm.fill(i1, i2, 4)
		assert_equal([0, 4, 4, 3], ary)
	end
	def test_algorithm_fill_n1
		ary = (0..3).to_a
		i1 = ary.create_iterator.next(1)
		Iterator::Algorithm.fill_n(i1, 2, 4)
		assert_equal([0, 4, 4, 3], ary)
	end
	def test_algorithm_transform1
		ary = (0..3).to_a
		i1 = ary.create_iterator
		i2 = ary.create_iterator_end
		res = []
		i3 = res.create_iterator_end
		Iterator::Algorithm.transform(i1, i2, i3) {|val|  val+1}
		assert_equal((1..4).to_a, res)
	end
	def test_algorithm_transform2
		a = (1..4).to_a
		a1 = a.create_iterator
		a2 = a.create_iterator_end
		b = (0..3).to_a.reverse
		b1 = b.create_iterator
		b2 = b.create_iterator_end
		res = []
		r1 = res.create_iterator_end
		Iterator::Algorithm.transform2(a1, a2, b1, b2, r1) {|va, vb| va+vb}
		assert_equal([4]*4, res)
	end
	def test_algorithm_transform3
		ary = (0..3).to_a
		a1 = ary.create_iterator
		a2 = ary.create_iterator_end
		b1 = Iterator::Continuation.new(ary, :reverse_each)
		b2 = b1.clone.next(4)
		res = []
		r1 = res.create_iterator_end
		Iterator::Algorithm.transform2(a1, a2, b1, b2, r1) {|va, vb| va+vb}
		assert_equal([3]*4, res)
	end
end

if $0 == __FILE__
	require 'test/unit/ui/console/testrunner'
	Test::Unit::UI::Console::TestRunner.run(TestIterator)
end
