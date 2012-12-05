require 'aeditor/backend/edit_container'
require 'common'

class String
	include MeasureMixins::One 
end

class TestEditContainer < Common::TestCase 
	def test_notify1
		edit = EditContainer.new
		edit.clear_dirty
		edit.push_left('a')
		assert_equal(true, edit.is_dirty)
	end
	def test_notify2
		edit = EditContainer.new
		edit.clear_dirty
		edit.push_right('a')
		assert_equal(true, edit.is_dirty)
	end
	def test_notify3
		edit = EditContainer.new
		edit.push_left('a')
		edit.clear_dirty
		edit.pop_left
		assert_equal(true, edit.is_dirty)
	end
	def test_notify4
		edit = EditContainer.new
		edit.push_right('a')
		edit.clear_dirty
		edit.pop_right
		assert_equal(true, edit.is_dirty)
	end
	def test_notify5
		edit = EditContainer.new
		edit.push_left('a')
		edit.push_left('b')
		edit.push_left('c')
		edit.clear_dirty
		edit.move_home_internal([])
		# 'move_home_internal' should NOT generate dirty
		# when you invoke it, you must administer 'dirty' yourself.
		assert_equal(false, edit.is_dirty)
	end
	def test_notify_none1
		edit = EditContainer.new
		edit.push_left('a')
		edit.clear_dirty
		edit.left2right
		assert_equal(false, edit.is_dirty)
	end
	def test_notify_none2
		edit = EditContainer.new
		edit.push_right('a')
		edit.clear_dirty
		edit.right2left
		assert_equal(false, edit.is_dirty)
	end
	def test_notify_none3
		edit = EditContainer.new
		edit.push_left('a')
		edit.clear_dirty
		edit.left2current
		assert_equal(false, edit.is_dirty)
	end
	def test_notify6
		edit = EditContainer.new
		edit.push_left('a')
		edit.set_current('b')
		edit.clear_dirty
		edit.left2current
		assert_equal(true, edit.is_dirty)
	end
	def test_notify_none4
		edit = EditContainer.new
		edit.push_right('a')
		edit.clear_dirty
		edit.right2current
		assert_equal(false, edit.is_dirty)
	end
	def test_notify_none5
		edit = EditContainer.new
		edit.set_current('a')
		edit.clear_dirty
		edit.current2left
		assert_equal(false, edit.is_dirty)
	end
	def test_notify_none6
		edit = EditContainer.new
		edit.set_current('a')
		edit.clear_dirty
		edit.current2right
		assert_equal(false, edit.is_dirty)
	end
	def test_notify7
		edit = EditContainer.new
		edit.push_left('a')
		edit.clear_dirty
		edit.set_current('b')
		assert_equal(true, edit.is_dirty)
	end
	def test_error_left1
		edit = EditContainer.new
		assert_raises(EditContainer::NotBegin) { edit.pop_left }
	end
	def test_error_left2
		edit = EditContainer.new
		assert_raises(EditContainer::NotBegin) { edit.left2right }
	end
	def test_error_right1
		edit = EditContainer.new
		assert_raises(EditContainer::NotEnd) { edit.pop_right }
	end
	def test_error_right2
		edit = EditContainer.new
		assert_raises(EditContainer::NotEnd) { edit.right2left }
	end
	def test_error_current1
		edit = EditContainer.new
		edit.push_left('a')
		edit.set_current('b')
		assert_raises(EditContainer::Error) { edit.left2right }
	end
	def test_error_current2
		edit = EditContainer.new
		edit.push_right('a')
		edit.set_current('b')
		assert_raises(EditContainer::Error) { edit.right2left }
	end
	def test_zap_left1
		edit = EditContainer.new
		class << edit
			attr_reader :left_x, :size_left, :left, :x
		end
		edit.push_left('a')
		edit.push_left('b')
		edit.set_current('c')
		lo = edit.zap_left
		assert_equal(%w(a b), lo)
		assert_equal(0, edit.x)
		assert_equal([], edit.left)
		assert_equal([], edit.left_x)
		assert_equal(0, edit.size_left.bytes)
	end
	def test_zap_right1
		edit = EditContainer.new
		class << edit
			attr_reader :size_right, :right, :x
		end
		edit.push_right('c')
		edit.push_right('b')
		edit.set_current('a')
		lo = edit.zap_right
		assert_equal(%w(b c), lo)
		assert_equal(0, edit.x)
		assert_equal([], edit.right)
		assert_equal(0, edit.size_right.bytes)
	end
end

TestEditContainer.run if $0 == __FILE__
