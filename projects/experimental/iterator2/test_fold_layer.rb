require 'test/unit'
require 'iterator'
require 'robust'
require 'fold_layer'

class TestFoldLayer < Test::Unit::TestCase
	def setup
		# buld a data structure like this
		# 01....67.......5   # top
		# ..23.5..8..1..4.
		# ....4....90.23..   # bottom
		@data = RobustArray.build_from_array((0..15).to_a)
		l0a0 = @data.create_iterator
		l0a0.first
		l1a0 = l0a0.clone
		l1a0.next
		l1a0.next
		l2a0 = l1a0.clone
		l2a0.next
		l2a0.next
		l2b0 = l2a0.clone
		l1b0 = l2b0.clone
		l1b0.next
		l1a1 = l1b0.clone
		l1a1.next
		l1a1.next
		l1a1.next
		l2a1 = l1a1.clone
		l2a1.next
		l2b1 = l2a1.clone
		l2b1.next
		l2a2 = l2b1.clone
		l2a2.next
		l2a2.next
		l2b2 = l2a2.clone
		l2b2.next
		l1b1 = l2b2.clone
		l1b1.next
		l0b0 = l1b1.clone
		l0b0.next
		node2_0 = Node.new(l2a0, l2b0, [])
		node2_1 = Node.new(l2a1, l2b1, [])
		node2_2 = Node.new(l2a2, l2b2, [])
		node1_0 = Node.new(l1a0, l1b0, [node2_0])
		node1_1 = Node.new(l1a1, l1b1, [node2_1, node2_2])
		@tree = Node.new(l0a0, l0b0, [node1_0, node1_1])
	end
	def test_setup
		assert_equal(12, @data.count_observers)
		#p @tree
	end
	def test_visisble_level0
		i = ViewIterator.new(@tree)
		assert_equal([0, 1, 6, 7, 15], i.to_a)
	end
	def test_visisble_level1
		a0 = ViewIterator.new(@tree.children[0]).to_a
		a1 = ViewIterator.new(@tree.children[1]).to_a
		assert_equal([[2, 3, 5], [8, 11, 14]], [a0, a1])
	end
end

if $0 == __FILE__
	require 'test/unit/ui/console/testrunner'
	Test::Unit::UI::Console::TestRunner.run(TestFoldLayer)
end
