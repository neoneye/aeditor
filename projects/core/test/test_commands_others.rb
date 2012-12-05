require 'aeditor/backend/commands_others'
require 'fake_setup'
require 'common'

class TestCommandsOthers < Common::TestCase 
	def fake_setup(total, y, top, bottom)
		i = FakeSetup::FakeControl.new
		i.setup(total, y, top, bottom) 
		i
	end
	def test_screw_block_remove1
		i = fake_setup(12, 3, 1, 4)
		assert_equal([3, 1, 4], i.status)
		i.execute :do_block_toggle
		3.times { i.execute :do_move_down } # forward
		assert_equal([6, 4, 1], i.status)
		i.execute :do_block_remove
		assert_equal([3, 1, 4], i.status)
		assert_equal(8, i.total)
		# we want to see if undo/redo of removal
		# will screw the cursor_y position.
		i.undo
		assert_equal([6, 4, 1], i.status)
		assert_equal(11, i.total)
		i.redo
		assert_equal([3, 1, 4], i.status)
		assert_equal(8, i.total)
	end
	def test_screw_block_remove2
		i = fake_setup(12, 6, 4, 1)
		assert_equal([6, 4, 1], i.status)
		i.execute :do_block_toggle
		3.times { i.execute :do_move_up } # backward
		assert_equal([3, 1, 4], i.status)
		i.execute :do_block_remove
		assert_equal([3, 1, 4], i.status)
		assert_equal(8, i.total)
		# we want to see if undo/redo of removal
		# will screw the cursor_y position.
		i.undo
		assert_equal([3, 1, 4], i.status)
		assert_equal(11, i.total)
		i.redo
		assert_equal([3, 1, 4], i.status)
		assert_equal(8, i.total)
	end
end

TestCommandsOthers.run if $0 == __FILE__
