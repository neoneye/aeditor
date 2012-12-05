require 'test/unit'

class Array
	def has_index?(index)
		(0...size) === index
	end
end # class Array


module Depend

class Base
	def initialize
		@datasource = nil
	end
	def set_datasource(node)
		@datasource = node
	end
	def refresh(caller=nil)
		hook_visit
 		@datasource.refresh(self) if @datasource
 		return unless is_dirty?
		hook_refresh(caller)
		clear_dirty
	end
	def is_dirty?
		# template method
	end
	def clear_dirty
		# template method
	end
	def hook_visit
		# template method
	end
	def hook_refresh(caller)
		# template method
	end
end # class Base

class Node < Base
	def initialize
		super()
		@dirty = true
	end
	def is_dirty?
		@dirty
	end
	def clear_dirty
		@dirty = false
	end
end # class Node

# purpose:
# keep track of dirty lines
#
#
class LineCache < Base
	def initialize
		super()
		@dirty = [true]
	end
	attr_reader :dirty
	def adjust_top(count)
		@datasource.adjust_top(count) if @datasource
		if count > 0
			count.times do
				@dirty.unshift(true)
			end
		end
		count = -count
		if count >= @dirty.size
			return
		end
		count.times do
			@dirty.shift
		end
	end
	def is_dirty?
		@dirty.any?
	end
	def clear_dirty
		@dirty.fill(false)
	end
	def set_dirty(index)
		@dirty[index] = true if @dirty.has_index?(index)
	end
	def insert_at(index)
		@datasource.insert_at(index) if @datasource
		@dirty.insert(index, true) if (0..@dirty.size) === index
	end
	def remove_at(index)
		@datasource.remove_at(index) if @datasource
		@dirty.delete_at(index) if @dirty.has_index?(index)
	end
end # class LineCache

end # module Depend

class TestDepend < Test::Unit::TestCase
	include Depend
	class MockNode < Node
		@@order = []
		def self.order
			@@order
		end
		def self.setup
			@@order = []
		end
		def initialize(name)
			super()
			@name = name
		end
		def hook_visit
			@@order << (@name+'1')
		end
		def hook_refresh(caller)
			@@order << (@name+'2')
		end
	end # class MockNode
	def mk_abc_mocknodes
		MockNode.setup
		a = MockNode.new('a')
		b = MockNode.new('b')
		c = MockNode.new('c')
		a.set_datasource(b)
		b.set_datasource(c)
		[a, b, c]
	end
	def test_mocknode_refresh1
		a, b, c = mk_abc_mocknodes
		assert_equal([], MockNode.order)
		a.refresh
		assert_equal(%w[a1 b1 c1 c2 b2 a2], MockNode.order)
	end
	def test_mocknode_refresh2
		a, b, c = mk_abc_mocknodes
		a.refresh
		MockNode.setup
		assert_equal([], MockNode.order)
		a.refresh
		assert_equal(%w[a1 b1 c1], MockNode.order)
	end
	def test_mocknode_refresh3
		a, b, c = mk_abc_mocknodes
		c.refresh
		MockNode.setup
		assert_equal([], MockNode.order)
		a.refresh
		assert_equal(%w[a1 b1 c1 b2 a2], MockNode.order)
	end
	class MockLineCache < LineCache
		@@order = []
		def self.order
			@@order
		end
		def self.setup
			@@order = []
		end
		def initialize(name)
			super()
			@name = name
		end
		def hook_visit
			@@order << (@name+'1')
		end
		def hook_refresh(caller)
			res = []
			@dirty.each_with_index do |dirty, i|
				next unless dirty
				res << i
				caller.set_dirty(i) if caller
			end
			@@order << (@name+'2_'+res.join)
		end
	end # class MockLineCache
	def mk_abc_linecaches
		MockLineCache.setup
		a = MockLineCache.new('a')
		b = MockLineCache.new('b')
		c = MockLineCache.new('c')
		a.set_datasource(b)
		b.set_datasource(c)
		a.adjust_top(3)
		[a, b, c]
	end
	def test_mocklinecache_adjust_top1
		a, b, c = mk_abc_linecaches
		assert_equal(4, a.dirty.size)
		assert_equal(4, b.dirty.size)
		assert_equal(4, c.dirty.size)
		a.refresh
		MockLineCache.setup
		a.adjust_top(3)
		assert_equal(7, a.dirty.size)
		a.adjust_top(-1)
		assert_equal(6, a.dirty.size)
		assert_equal(6, b.dirty.size)
		assert_equal(6, c.dirty.size)
		a.refresh
		assert_equal(%w[a1 b1 c1 c2_01 b2_01 a2_01],
			MockLineCache.order)
	end
	def test_mocklinecache_refresh1
		a, b, c = mk_abc_linecaches
		a.refresh
		assert_equal(%w[a1 b1 c1 c2_0123 b2_0123 a2_0123],
			MockLineCache.order)
	end
	def test_mocklinecache_refresh2
		a, b, c = mk_abc_linecaches
		a.refresh
		MockLineCache.setup
		a.refresh
		assert_equal(%w[a1 b1 c1], MockLineCache.order)
	end
	def test_mocklinecache_refresh3
		a, b, c = mk_abc_linecaches
		a.refresh
		MockLineCache.setup
		c.set_dirty(0)
		b.set_dirty(1)
		a.set_dirty(2)
		a.refresh
		assert_equal(%w[a1 b1 c1 c2_0 b2_01 a2_012],
			MockLineCache.order)
	end
	def test_mocklinecache_insert1
		a, b, c = mk_abc_linecaches
		a.refresh
		MockLineCache.setup
		a.insert_at(4)
		a.refresh
		assert_equal(%w[a1 b1 c1 c2_4 b2_4 a2_4],
			MockLineCache.order)
		MockLineCache.setup
		a.insert_at(0)
		a.refresh
		assert_equal(%w[a1 b1 c1 c2_0 b2_0 a2_0],
			MockLineCache.order)
		assert_equal(6, a.dirty.size)
		assert_equal(6, b.dirty.size)
		assert_equal(6, c.dirty.size)
	end
	def test_mocklinecache_remove1
		a, b, c = mk_abc_linecaches
		a.refresh
		MockLineCache.setup
		a.insert_at(0)
		a.remove_at(0)
		a.refresh
		assert_equal(%w[a1 b1 c1], MockLineCache.order)
		assert_equal(4, a.dirty.size)
		assert_equal(4, b.dirty.size)
		assert_equal(4, c.dirty.size)
	end
	def setup
		MockNode.setup
		MockLineCache.setup
	end
end # class TestDepend