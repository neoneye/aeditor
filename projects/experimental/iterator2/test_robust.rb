require 'test/unit'
require 'robust'

class TestRobust < Test::Unit::TestCase
	def setup
		@data = RobustArray.build_from_array([1, 2, 3, 4, 5])
		cursor = @data.create_iterator
		class << cursor
			attr_reader :position, :data
		end
		cursor.next
		@bookmark2 = cursor.clone
		cursor.next
		cursor.next
		@bookmark4 = cursor.clone
		cursor.close
	end
	def test_setup
		data = [@bookmark2.current, @bookmark4.current]
		pos = [@bookmark2.position, @bookmark4.position]
		assert_equal([[2, 4], [1, 3]], [data, pos])
		assert_equal(2, @data.count_observers)
	end
	def test_iterator_each
		assert_equal([1, 2, 3, 4, 5], @data.create_iterator.to_a)
	end
	def test_remove
		removed = @data.remove(2..3)
		res = [@data.to_a, removed.to_a]
		assert_equal([[1, 2, 5], [3, 4]], res)
	end
	def test_insert
		input = RobustArray.build_from_array(%w(a b c))
		@data.insert(2, input)
		assert_equal([1, 2, 'a', 'b', 'c', 3, 4, 5], @data.to_a)
	end
	def test_observer_insert_adjust
		input = RobustArray.build_from_array(%w(a b c))
		@data.insert(2, input)
		data = [@bookmark2.current, @bookmark4.current]
		pos = [@bookmark2.position, @bookmark4.position]
		assert_equal([[2, 4], [1, 6]], [data, pos])
	end
	def test_observer_remove_adjust1
		@data.remove(0..0)
		data = [@bookmark2.current, @bookmark4.current]
		pos = [@bookmark2.position, @bookmark4.position]
		assert_equal([[2, 4], [0, 2]], [data, pos])
	end
	def test_observer_remove_adjust2
		@data.remove(2..2)
		data = [@bookmark2.current, @bookmark4.current]
		pos = [@bookmark2.position, @bookmark4.position]
		assert_equal([[2, 4], [1, 2]], [data, pos])
	end
	def test_observer_remove_nothing
		@data.remove(4..4)
		data = [@bookmark2.current, @bookmark4.current]
		pos = [@bookmark2.position, @bookmark4.position]
		assert_equal([[2, 4], [1, 3]], [data, pos])
	end
	def test_observer_remove_detach1
		@data.remove(1..1)
		assert_equal(nil, @bookmark2.data)
		assert_equal(1, @data.count_observers)
	end
	def test_observer_remove_detach2
		@data.remove(3..3)
		assert_equal(nil, @bookmark4.data)
		assert_equal(1, @data.count_observers)
	end
end

if $0 == __FILE__
	require 'test/unit/ui/console/testrunner'
	Test::Unit::UI::Console::TestRunner.run(TestRobust)
end
