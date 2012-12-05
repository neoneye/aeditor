require 'aeditor/backend/commands_movement'
require 'fake_setup'
require 'common'

class TestCommandsMovement < Common::TestCase 
	def fake_setup(total, y, top, bottom)
		i = FakeSetup::FakeControl.new
		i.setup(total, y, top, bottom) 
		i
	end
	def test_pageup_normal1
		# with this test we want to see if undo/redo 
		# is able to restore view-position + cursor
		i = fake_setup(10, 5, 1, 2)
		assert_equal([5, 1, 2], i.status)
		i.execute :do_move_page_up
		assert_equal([2, 1, 2], i.status)
		i.undo
		assert_equal([5, 1, 2], i.status)
		i.redo
		assert_equal([2, 1, 2], i.status)
	end
	def test_pageup_normal2
		# with this test we want to see if undo/redo 
		# is able to restore view-position + cursor
		i = fake_setup(9, 3, 3, 2)
		assert_equal([3, 3, 2], i.status)
		i.execute :do_move_page_up
		assert_equal([0, 0, 5], i.status)
		i.undo
		assert_equal([3, 3, 2], i.status)
		i.redo
		assert_equal([0, 0, 5], i.status)
	end
	def test_pageup_twisted1
		# with this test we want to see if undo/redo 
		# is able to restore view-position + cursor
		# VERY INTERESTING when resize is involved!
		i = fake_setup(9, 6, 2, 1)
		assert_equal([6, 2, 1], i.status)
		i.execute :do_move_page_up
		assert_equal([3, 2, 1], i.status)
		i.height(1, 2) # widen height of view
		assert_equal([3, 1, 2], i.status)
		i.undo
		assert_equal([6, 1, 2], i.status)
		i.redo
		assert_equal([3, 1, 2], i.status)
	end
	def test_pageup_view_smaller1  
		# with this test we want to see if undo/redo 
		# is able to restore view-position + cursor
		# VERY INTERESTING when resize is involved!
		i = fake_setup(7, 4, 1, 2)
		assert_equal([4, 1, 2], i.status)
		i.execute :do_move_page_up
		assert_equal([1, 1, 2], i.status)
		i.height(0, 1) # shrink height of view
		assert_equal([1, 0, 1], i.status)
		i.undo
		assert_equal([4, 0, 1], i.status)
		i.redo
		assert_equal([1, 0, 1], i.status)
	end
	def test_pageup_view_bigger1  
		# with this test we want to see if undo/redo 
		# is able to restore view-position + cursor
		# VERY INTERESTING when resize is involved!
		i = fake_setup(12, 6, 1, 2)
		assert_equal([6, 1, 2], i.status)
		i.execute :do_move_page_up
		assert_equal([3, 1, 2], i.status)
		i.height(2, 4) # widen height of view
		assert_equal([3, 2, 4], i.status)
		i.undo
		assert_equal([6, 2, 4], i.status)
		i.redo
		assert_equal([3, 2, 4], i.status)
	end
	def test_pageup_view_bigger2  
		# with this test we want to see if undo/redo 
		# is able to restore view-position + cursor
		# VERY INTERESTING when resize is involved!
		i = fake_setup(10, 7, 1, 2)
		assert_equal([7, 1, 2], i.status)
		i.execute :do_move_page_up
		assert_equal([4, 1, 2], i.status)
		i.height(2, 4) # widen height of view
		assert_equal([4, 2, 4], i.status)
		i.undo 
		# The next assertion differ from #pagedown
		# because we ARE able to preserve cursor
		assert_equal([7, 2, 4], i.status)  # TWO virtual lines!
		i.redo
		assert_equal([4, 2, 4], i.status)
	end
	def test_pageup_view_bigger3  
		# with this test we want to see if undo/redo 
		# is able to restore view-position + cursor
		# VERY INTERESTING when resize is involved!
		i = fake_setup(10, 4, 1, 2)
		assert_equal([4, 1, 2], i.status)
		i.execute :do_move_page_up
		assert_equal([1, 1, 2], i.status)
		i.height(2, 4) # widen height of view
		# the next assertion differ from #pagedown, because
		# empty lines cannot exist above the view!
		assert_equal([1, 1, 5], i.status)
		i.undo 
		assert_equal([4, 1, 5], i.status)
		i.redo
		assert_equal([1, 1, 5], i.status)
	end
	def test_pagedown_normal1
		# with this test we want to see if undo/redo 
		# is able to restore view-position + cursor
		i = fake_setup(10, 4, 2, 1)
		assert_equal([4, 2, 1], i.status)
		i.execute :do_move_page_down
		assert_equal([7, 2, 1], i.status)
		i.undo
		assert_equal([4, 2, 1], i.status)
		i.redo
		assert_equal([7, 2, 1], i.status)
	end
	def test_pagedown_normal_bottom1
		# with this test we want to see if undo/redo 
		# is able to restore view-position + cursor
		i = fake_setup(8, 3, 2, 5)
		assert_equal([3, 2, 5], i.status, i.dump.inspect) # one virtual line
		i.execute :do_move_page_down
		assert_equal([7, 6, 1], i.status) # one virtual line
		i.undo
		assert_equal([3, 2, 5], i.status) # one virtual line 
		i.redo
		assert_equal([7, 6, 1], i.status) # one virtual line 
	end
	def test_pagedown_twisted1
		# with this test we want to see if undo/redo 
		# is able to restore view-position + cursor
		# VERY INTERESTING when resize is involved!
		i = fake_setup(9, 2, 1, 2)
		assert_equal([2, 1, 2], i.status)
		i.execute :do_move_page_down
		assert_equal([5, 1, 2], i.status)
		i.height(2, 1) # widen height of view
		assert_equal([5, 2, 1], i.status)
		i.undo
		assert_equal([2, 2, 1], i.status)
		i.redo
		assert_equal([5, 2, 1], i.status)
	end
	def test_pagedown_view_smaller1  
		# with this test we want to see if undo/redo 
		# is able to restore view-position + cursor
		# VERY INTERESTING when resize is involved!
		i = fake_setup(7, 2, 2, 1)
		assert_equal([2, 2, 1], i.status)
		i.execute :do_move_page_down
		assert_equal([5, 2, 1], i.status)
		i.height(1, 0) # shrink height of view
		assert_equal([5, 1, 0], i.status)
		i.undo
		assert_equal([2, 1, 0], i.status)
		i.redo
		assert_equal([5, 1, 0], i.status)
	end
	def test_pagedown_view_bigger1  
		# with this test we want to see if undo/redo 
		# is able to restore view-position + cursor
		# VERY INTERESTING when resize is involved!
		i = fake_setup(12, 5, 2, 1)
		assert_equal([5, 2, 1], i.status)
		i.execute :do_move_page_down
		assert_equal([8, 2, 1], i.status)
		i.height(4, 2) # widen height of view
		assert_equal([8, 4, 2], i.status)
		i.undo
		assert_equal([5, 4, 2], i.status)
		i.redo
		assert_equal([8, 4, 2], i.status)
	end
	def test_pagedown_view_bigger2  
		# with this test we want to see if undo/redo 
		# is able to restore view-position + cursor
		# VERY INTERESTING when resize is involved!
		i = fake_setup(10, 2, 2, 1)
		assert_equal([2, 2, 1], i.status)
		i.execute :do_move_page_down
		assert_equal([5, 2, 1], i.status)
		i.height(4, 2) # widen height of view
		assert_equal([5, 4, 2], i.status)
		i.undo 
		# the next assertion differ from #pageup, becasue
		# preservation of cursor is IMPOSSIBLE, this is 
		# because we bump into top of buffer.
		assert_equal([2, 2, 4], i.status)
		i.redo
		assert_equal([5, 2, 4], i.status)
	end
	def test_pagedown_view_bigger3  
		# with this test we want to see if undo/redo 
		# is able to restore view-position + cursor
		# VERY INTERESTING when resize is involved!
		i = fake_setup(10, 5, 2, 1)
		assert_equal([5, 2, 1], i.status)
		i.execute :do_move_page_down
		assert_equal([8, 2, 1], i.status)
		i.height(4, 2) # widen height of view
		assert_equal([8, 4, 2], i.status) # one empty line
		i.undo 
		assert_equal([5, 4, 2], i.status)
		i.redo
		assert_equal([8, 4, 2], i.status) # one empty line
	end
end

TestCommandsMovement.run if $0 == __FILE__
