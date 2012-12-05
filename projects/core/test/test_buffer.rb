require 'aeditor/backend/buffer'
require 'aeditor/backend/convert'
require 'common'

class FakeBufferView
	def initialize
		clear_dirty
	end
	def update(cursor, line, all)
		@cursor << cursor
		@line << line
		@all << all
	end
	def clear_dirty
		@cursor = []
		@line = []
		@all = []
	end
	attr_reader :cursor, :line, :all
end

class FakeBuffer < Buffer
	def initialize(cursor_through_tabs=false, autoindent=true)
		super(4, cursor_through_tabs, autoindent)
		@view = FakeBufferView.new
		add_observer(@view)
	end
	attr_reader :view
	attr_reader :data_top, :data_bottom 
	attr_reader :line_top, :line_bottom
	attr_reader :notify_lock

	def status_total
		[
			total_visible_lines,
			total_bytes
		]
	end
	def status_position
		[
			position_visible_lines,
			position_bytes
		]
	end
	def status_view
		[
			line_top.size,
			line_bottom.size
		]
	end
end

class TestBuffer < Common::TestCase 
	def test_normal1
		buf = FakeBuffer.new
		assert_equal(1, buf.visible_lines)
		buf.adjust_height(25)
		assert_equal(25, buf.visible_lines)
		assert_equal(true, buf.line_top.empty?)
		assert_equal([nil]*24, buf.line_bottom.data) # empty lines
	end
	def test_replace_content1
		buf = FakeBuffer.new
		bo = Convert::from_string_into_bufferobjs("ab\ncd\nef\ngh\nij")

		# this sequence should not matter: the result should be equal
		buf.replace_content(bo)
		buf.adjust_height(3)

		assert_equal(3, buf.visible_lines)
		assert_equal(0, buf.line_top.size)
		assert_equal(2, buf.line_bottom.size)
		assert_equal(0, buf.data_top.size)
		assert_equal(5, buf.data_bottom.size)
	end
	def test_replace_content2
		buf = FakeBuffer.new
		bo = Convert::from_string_into_bufferobjs("ab\ncd\nef\ngh\nij")

		# this sequence should not matter: the result should be equal
		buf.adjust_height(3)
		buf.replace_content(bo)

		assert_equal(3, buf.visible_lines)
		assert_equal(0, buf.line_top.size)
		assert_equal(2, buf.line_bottom.size)
		assert_equal(0, buf.data_top.size)
		assert_equal(5, buf.data_bottom.size)
	end
	def test_replace_content3
		buf = FakeBuffer.new
		bo = Convert::from_string_into_bufferobjs("ab\ncd\nef\ngh")
		buf.replace_content(bo)
		buf.move_down

		assert_equal(1, buf.visible_lines)
		assert_equal(0, buf.line_top.size)
		assert_equal(0, buf.line_bottom.size)
		assert_equal(3, buf.data_top.size)
		assert_equal(5, buf.data_bottom.size)
	end
	def test_replace_content4
		buf = FakeBuffer.new
		buf.adjust_height(5)
		buf.replace_content([])
		assert_equal(5, buf.visible_lines)
		assert_equal(0, buf.position_visible_lines)
		assert_equal(0, buf.position_bytes)
		assert_equal(0, buf.total_physical_lines)
		assert_equal(0, buf.total_visible_lines)
		assert_equal([nil, nil, nil, nil], buf.line_bottom.data)
	end
#	def test_notify_scope1
#		buf = FakeBuffer.new
#		view = buf.view
#		view.clear_dirty
#		assert_equal(0, buf.notify_lock)
#		assert_raises(RuntimeError) do  # notify_scope catches the exception
#			buf.notify_scope do
#				raise 
#			end
#		end
#		assert_equal(0, buf.notify_lock)  # see if mutex has been restored
#	end
	def test_notify_not_all1
		buf = FakeBuffer.new
		view = buf.view
		lo = LineObjects::Text.new('a')
		view.clear_dirty
		# the Edit class is already heavyly tested 
		# in 'test_edit.rb'.. So we only check if 
		# it *seems* to work.
		buf.notify_scope { buf.cmd_insert(lo) }
		buf.notify_scope { buf.cmd_move_left }
		assert_equal([true, true], view.cursor)
		assert_equal([true, false], view.line)
		assert_equal([false, false], view.all)
	end
	def test_notify_not_all2
		buf = FakeBuffer.new
		bo = Convert::from_string_into_bufferobjs("ab\ncd\nef\ngh\nij")
		buf.replace_content(bo)
		buf.adjust_height(3)
		view = buf.view
		view.clear_dirty
		buf.notify_scope { buf.cmd_move_down }
		assert_equal([true], view.cursor)
		assert_equal([false], view.line)
		assert_equal([false], view.all)
	end
	# todo: notify_all
	# * replace content
	#
	# issues:
	# * scroll left/right is belonging to the View class.. no testing here
	def test_notify_all1
		buf = FakeBuffer.new
		bo = Convert::from_string_into_bufferobjs("ab\ncd\nef\ngh\nij")
		buf.replace_content(bo)
		buf.adjust_height(3)
		view = buf.view
		view.clear_dirty
		buf.notify_scope { buf.cmd_scroll_down }
		# view.cursor, view.line  can be either true or false. it doesn't matter
		assert_equal([true], view.all)
	end
	def test_notify_all2
		buf = FakeBuffer.new
		bo = Convert::from_string_into_bufferobjs("ab\ncd\nef\ngh\nij")
		buf.replace_content(bo)
		buf.adjust_height(3)
		view = buf.view
		view.clear_dirty
		buf.notify_scope { buf.cmd_adjust_height(4) }
		# view.cursor, view.line  can be either true or false. it doesn't matter
		assert_equal([true], view.all)
	end
	def test_notify_all3
		buf = FakeBuffer.new
		bo = Convert::from_string_into_bufferobjs("ab\ncd\nef\ngh\nij")
		buf.replace_content(bo)
		buf.adjust_height(3)
		view = buf.view
		view.clear_dirty
		buf.notify_scope { buf.cmd_scroll_down }
		# view.cursor, view.line  can be either true or false. it doesn't matter
		assert_equal([true], view.all)
	end
	def test_notify_all4
		buf = FakeBuffer.new
		bo = Convert::from_string_into_bufferobjs("ab\ncd\nef\ngh\nij\nkl")
		buf.replace_content(bo)
		buf.adjust_height(3)
		view = buf.view
		view.clear_dirty
		buf.notify_scope { buf.cmd_scroll_page_down }
		buf.notify_scope { buf.cmd_move_up } # (cursor == top) => scroll up => dirty-all
		# view.cursor, view.line  can be either true or false. it doesn't matter
		assert_equal([true, true], view.all)
	end
	def test_notify_all5
		buf = FakeBuffer.new
		bo = Convert::from_string_into_bufferobjs("abcdef\nghi")
		buf.replace_content(bo)
		buf.adjust_height(3)
		view = buf.view
		3.times { buf.cmd_move_right }
		view.clear_dirty
		buf.notify_scope { buf.cmd_breakline }
		assert_equal([true], view.all)
	end
	def test_notify_all6
		buf = FakeBuffer.new
		bo = Convert::from_string_into_bufferobjs("abcdef\nghi")
		buf.replace_content(bo)
		buf.adjust_height(3)
		buf.notify_scope { buf.cmd_move_down }
		view = buf.view
		view.clear_dirty
		buf.notify_scope { buf.cmd_joinline }
		assert_equal([true], view.all)
	end
	def test_measure_total_bytes1
		buf = FakeBuffer.new
		bo = Convert::from_string_into_bufferobjs("abc\ndef\n123456\nxy\nz")
		assert_equal(0, buf.total_bytes)
		buf.replace_content(bo)
		assert_equal(1, buf.visible_lines)
		assert_equal(0, buf.line_top.bytes)
		assert_equal(0, buf.line_bottom.bytes)
		assert_equal(0, buf.data_top.bytes)
		assert_equal(15, buf.data_bottom.bytes)
		assert_equal(19, buf.total_bytes)
	end
	def test_measure_total_bytes2
		buf = FakeBuffer.new
		bo = Convert::from_string_into_bufferobjs("abc\ndef\n123456\nxy\nz")
		buf.adjust_height(3)
		assert_equal(0, buf.total_bytes)
		buf.replace_content(bo)
		assert_equal(0, buf.line_top.bytes)
		assert_equal(0, buf.data_top.bytes)
		assert_equal(11, buf.line_bottom.bytes)
		assert_equal(4, buf.data_bottom.bytes)
		assert_equal(19, buf.total_bytes)
	end
	def test_measure_total_bytes3
		buf = FakeBuffer.new
		buf.adjust_height(3)
		bo1 = Convert.from_string_into_bufferobjs("abc\nd")
		bo2 = Convert.from_string_into_bufferobjs("01\n23\n45\n67")
		bo3 = Convert.from_string_into_bufferobjs("f\nghi")
		fold = BufferObjects::Fold.new(bo2, "{3}", false)
		assert_equal(0, buf.total_bytes)
		buf.replace_content(bo1 + [fold] + bo3)
		assert_equal(21, buf.total_bytes)
	end
	def test_measure_position_bytes1
		buf = FakeBuffer.new
		bo = Convert::from_string_into_bufferobjs("abc\ndef\n123456\nxy\nz")
		buf.adjust_height(3)
		assert_equal(0, buf.position_bytes)
		buf.replace_content(bo)
		buf.move_down
		assert_equal(4, buf.line_top.bytes)
		assert_equal(0, buf.data_top.bytes)
		assert_equal(7, buf.line_bottom.bytes)
		assert_equal(4, buf.data_bottom.bytes)
		assert_equal(4, buf.position_bytes)
	end
	def test_measure_position_bytes2
		buf = FakeBuffer.new
		bo = Convert::from_string_into_bufferobjs("abc\ndef\n123456\nxy\nz")
		buf.adjust_height(3)
		buf.replace_content(bo)
		buf.cmd_move_down
		buf.cmd_move_right
		assert_equal(4, buf.line_top.bytes)
		assert_equal(0, buf.data_top.bytes)
		assert_equal(7, buf.line_bottom.bytes)
		assert_equal(4, buf.data_bottom.bytes)
		assert_equal(5, buf.position_bytes)
	end
	def test_measure_position_bytes3
		buf = FakeBuffer.new
		bo = Convert::from_string_into_bufferobjs("abc\ndef\n123456\nxy\nz")
		buf.adjust_height(3)
		buf.replace_content(bo)
		buf.cmd_move_down
		buf.cmd_move_end
		assert_equal(7, buf.position_bytes)
		buf.cmd_move_right  
		assert_equal(7, buf.position_bytes)  # because of VSpace
		assert_equal(4, buf.line_top.bytes)
		assert_equal(0, buf.data_top.bytes)
		assert_equal(7, buf.line_bottom.bytes)
		assert_equal(4, buf.data_bottom.bytes)
	end
	def test_measure_total_lines1
		buf = FakeBuffer.new
		bo = Convert::from_string_into_bufferobjs("abc\ndef\n123456\nxy\nz")
		buf.adjust_height(3)
		assert_equal(0, buf.total_physical_lines)
		assert_equal(0, buf.total_visible_lines)
		buf.replace_content(bo)
		assert_equal(4, buf.total_physical_lines)
		assert_equal(4, buf.total_visible_lines)
	end
	def test_measure_total_lines2
		buf = FakeBuffer.new
		buf.adjust_height(3)
		bo1 = Convert.from_string_into_bufferobjs("abc\nd")
		bo2 = Convert.from_string_into_bufferobjs("01\n23\n45\n67")
		bo3 = Convert.from_string_into_bufferobjs("f\nghi")
		fold = BufferObjects::Fold.new(bo2, "{3}", false)
		assert_equal(0, buf.total_physical_lines)
		assert_equal(0, buf.total_visible_lines)
		buf.replace_content(bo1 + [fold] + bo3)
		assert_equal(5, buf.total_physical_lines)
		assert_equal(2, buf.total_visible_lines)
	end
	def test_measure_position_lines1
		buf = FakeBuffer.new
		bo = Convert::from_string_into_bufferobjs("abc\ndef\n123456\nxy\nz")
		buf.adjust_height(3)
		buf.replace_content(bo)
		assert_equal(0, buf.position_physical_lines)
		assert_equal(0, buf.position_visible_lines)
		buf.move_down
		assert_equal(1, buf.position_physical_lines)
		assert_equal(1, buf.position_visible_lines)
	end
	def test_measure_position_lines2
		buf = FakeBuffer.new
		bo1 = Convert.from_string_into_bufferobjs("abc\nd")
		bo2 = Convert.from_string_into_bufferobjs("01\n23\n45\n67")
		bo3 = Convert.from_string_into_bufferobjs("f\nghi")
		fold = BufferObjects::Fold.new(bo2, "{3}", false)
		buf.adjust_height(3)
		buf.replace_content(bo1 + [fold] + bo3)
		assert_equal(0, buf.position_physical_lines)
		assert_equal(0, buf.position_visible_lines)
		buf.cmd_move_down
		assert_equal(1, buf.position_physical_lines)
		assert_equal(1, buf.position_visible_lines)
		buf.cmd_move_end
		assert_equal(4, buf.position_physical_lines)
		assert_equal(1, buf.position_visible_lines)
	end
	# validate that the exception is derived from CommandHarmless
	def assert_harmless(expected_exception_class)
		assert_raises(expected_exception_class) { 
			begin 
				yield
			rescue CommandHarmless
				raise # this is what should happen
			rescue => e
				raise <<MSG
expected exception to be derived from CommandHarmless.
exception caught: #{e.inspect}
MSG
			end
		}
	end
	def test_exception_begin_of_line1
		buf = FakeBuffer.new
		bo = Convert::from_string_into_bufferobjs("abc\ndef\n123456\nxy\nz")
		buf.adjust_height(3)
		buf.replace_content(bo)
		assert_harmless(Edit::NotBegin) { buf.cmd_move_left }
	end
	def test_exception_begin_of_buffer1
		buf = FakeBuffer.new
		bo = Convert::from_string_into_bufferobjs("abc\ndef\n123456\nxy\nz")
		buf.adjust_height(3)
		buf.replace_content(bo)
		assert_harmless(BufferTop) { buf.cmd_move_up }
	end
	def test_exception_begin_of_buffer2
		buf = FakeBuffer.new
		bo = Convert::from_string_into_bufferobjs("abc\ndef\n123456\nxy\nz")
		buf.adjust_height(3)
		buf.replace_content(bo)
		assert_harmless(BufferTop) { buf.cmd_scroll_up }
	end
	def test_exception_end_of_buffer1
		buf = FakeBuffer.new
		bo = Convert::from_string_into_bufferobjs("abc\ndef\n123456\nxy\nz")
		buf.adjust_height(3)
		buf.replace_content(bo)
		4.times { buf.cmd_move_down }
		assert_harmless(BufferBottom) { buf.cmd_move_down }
		# eventualy insert virtual-lines here
	end
	def test_create_memento1
		buf = FakeBuffer.new
		state = buf.create_memento
		assert_equal(0, state.x)
		assert_equal(0, state.y)
		assert_equal([], state.bufobjs)
		assert_equal(false, state.blocking.enabled)
	end
	def test_create_memento2
		buf = FakeBuffer.new
		bo = Convert::from_string_into_bufferobjs("abc\ndef\n123456\nxy\nz")
		buf.replace_content(bo)
		buf.cmd_move_down
		buf.cmd_move_right
		buf.cmd_move_right
		state = buf.create_memento
		assert_equal(2, state.x)
		assert_equal(1, state.y)
		assert_equal(19, state.bufobjs.size)
	end
	def test_create_memento3
		buf = FakeBuffer.new
		bo = Convert::from_string_into_bufferobjs("abc\ndef\ngh")
		buf.adjust_height(5) # there should be 2 empty lines at the bottom
		buf.replace_content(bo)
		buf.cmd_move_down
		buf.cmd_move_right
		buf.cmd_move_right
		state = buf.create_memento
		assert_equal(2, state.x)
		assert_equal(1, state.y)
		assert_equal(10, state.bufobjs.size)
	end
	def test_create_memento4
		buf = FakeBuffer.new
		buf.adjust_height(3) 
		buf.replace_content([])
		buf.cmd_breakline
		assert_equal(0, buf.position_x)
		assert_equal(1, buf.position_visible_lines)
		assert_equal(1, buf.position_y)
		assert_equal(1, buf.total_bytes)
		assert_equal(1, buf.total_physical_lines)
		assert_equal(1, buf.total_visible_lines)
		assert_equal(3, buf.visible_lines)
		state = buf.create_memento
		assert_equal(1, state.bufobjs.size)
	end
	def test_set_memento1
		buf = FakeBuffer.new
		bo = Convert::from_string_into_bufferobjs("abc\ndef\ngh")
		buf.set_memento(Buffer::Memento::All.new(1, 1, bo, Buffer::Blocking.new))
		assert_equal(1, buf.visible_lines)
		assert_equal(1, buf.position_visible_lines)
		assert_equal(5, buf.position_bytes)
		assert_equal(2, buf.total_physical_lines)
		assert_equal(2, buf.total_visible_lines)
	end
	def test_set_memento2
		buf = FakeBuffer.new
		bo = Convert::from_string_into_bufferobjs("abc\ndef\ngh")
		blocking = Buffer::Blocking.new
		blocking.enable(2, 1)
		buf.set_memento(Buffer::Memento::All.new(1, 1, bo, blocking))
		assert_equal(1, buf.visible_lines)
		assert_equal(1, buf.position_visible_lines)
		assert_equal(5, buf.position_bytes)
		assert_equal(2, buf.total_physical_lines)
		assert_equal(2, buf.total_visible_lines)
		assert_equal(true, buf.blocking.enabled)
		assert_equal(2, buf.blocking.x)
		assert_equal(1, buf.blocking.y)
	end
	def test_set_memento3
		buf = FakeBuffer.new
		bo = Convert::from_string_into_bufferobjs("1\n2\n3\n4\n5\n6\ng\nh")
		buf.set_memento(Buffer::Memento::All.new(0, 3, bo, Buffer::Blocking.new))
		buf.resize_topbottom(2, 1)
		assert_equal([2, 1], buf.status_view)
		assert_equal([3, 6], buf.status_position)
		assert_equal([7, 15], buf.status_total)
		bo = Convert::from_string_into_bufferobjs("a\nb\nc\nd\ne\nf\ng\nh")
		buf.set_memento(Buffer::Memento::All.new(0, 5, bo, Buffer::Blocking.new))
		assert_equal([5, 10], buf.status_position)
		assert_equal([7, 15], buf.status_total)
		# are Buffer#set_memento able to preserve 
		# position-within-view ?   lets find out:
		assert_equal([2, 1], buf.status_view)  # will tell us if preservation works!
	end
	def test_set_memento_edit1
		buf = FakeBuffer.new
		bo = Convert::from_string_into_bufferobjs("abcdefghi")
		buf.set_memento(Buffer::Memento::All.new(8, 0, bo, Buffer::Blocking.new))
		class << buf
			def copy_oneliner(x)
				state = @edit.create_memento
				@edit.zap_right
				@edit.move_left until @edit.position <= x
				@edit.zap_left
				bo = @edit.get_right_as_buffer_objects
				@edit.set_memento(state)
				bo
			end
		end
		assert_equal(9, buf.total_bytes)
		bo = buf.copy_oneliner(1)
		assert_equal(9, buf.total_bytes)
		assert_equal(7, bo.size)
	end
	def test_create_memento_current_line1
		buf = FakeBuffer.new
		bo = Convert::from_string_into_bufferobjs("abc\ndef\n123456\nxy\nz")
		buf.replace_content(bo)
		buf.cmd_move_down
		buf.cmd_move_right
		buf.cmd_move_right
		mem = buf.create_memento(Buffer::Memento::Line)
		assert_kind_of(Buffer::Memento::Line, mem)
		assert_equal(2, mem.x)
		assert_equal(4, mem.bufobjs.size)
	end
	def test_set_memento_current_line1
		buf = FakeBuffer.new
		bo = Convert::from_string_into_bufferobjs("1\n2\n3")
		buf.replace_content(bo)
		buf.cmd_move_down
		bo = Convert::from_string_into_bufferobjs("abc\n")
		buf.set_memento(Buffer::Memento::Line.new(2, bo))
		assert_equal(1, buf.visible_lines)
		assert_equal(1, buf.position_visible_lines)
		assert_equal(4, buf.position_bytes)
		assert_equal(2, buf.total_physical_lines)
		assert_equal(2, buf.total_visible_lines)
	end
	def test_create_memento_position1
		buf = FakeBuffer.new
		bo = Convert::from_string_into_bufferobjs("abc\ndef\n123456\nxy\nz")
		buf.replace_content(bo)
		buf.cmd_move_down
		buf.cmd_move_right
		buf.cmd_move_right
		mem = buf.create_memento(Buffer::Memento::Position)
		assert_equal(2, mem.x)
		assert_equal(1, mem.y)
	end
	def test_set_memento_position1
		buf = FakeBuffer.new
		bo = Convert::from_string_into_bufferobjs("abc\ndef\ngh")
		buf.replace_content(bo)
		buf.set_memento(Buffer::Memento::Position.new(1, 1))
		assert_equal(1, buf.visible_lines)
		assert_equal(1, buf.position_visible_lines)
		assert_equal(5, buf.position_bytes)
		assert_equal(2, buf.total_physical_lines)
		assert_equal(2, buf.total_visible_lines)
	end
	def test_has_model_changed1
		buf = FakeBuffer.new
		bo = Convert::from_string_into_bufferobjs("ab\ncd\nef")
		buf.replace_content(bo)
		assert_harmless(BufferTop) { buf.cmd_move_up }
		buf.cmd_move_down
		assert_harmless(EditContainer::NotBegin) { buf.cmd_move_left }
		buf.cmd_move_right
	end
	def test_has_model_changed2
		buf = FakeBuffer.new
		bo = Convert::from_string_into_bufferobjs("ab\ncd\nef")
		buf.replace_content(bo)
		2.times { buf.cmd_move_down }
		assert_harmless(BufferBottom) { buf.cmd_move_down }
		buf.cmd_move_up
		buf.cmd_move_right
		buf.cmd_move_left
	end
	def test_has_model_changed3
		buf = FakeBuffer.new
		bo = Convert::from_string_into_bufferobjs("ab\ncd\nef")
		buf.replace_content(bo)
		4.times { buf.cmd_move_right } 
		# cursor is now in the virtual space area
		buf.cmd_backspace
	end
	def test_has_model_changed4
		buf = FakeBuffer.new(true, false)  # cursor through tabs, no-autoindent
		bo = Convert::from_string_into_bufferobjs("\tx")
		buf.adjust_height(2) 
		buf.replace_content(bo)
		buf.cmd_move_right
		s2 = buf.create_memento
		buf.cmd_move_right
		s1 = buf.create_memento
		assert_equal(true, buf.cmd_breakline) # splitting TAB
		assert_equal(0, buf.position_x)
		buf.set_memento(s1) # maybe return true?
		assert_equal(2, buf.position_x)
		buf.set_memento(s2) # maybe return true? 
		assert_equal(1, buf.position_x)
	end
	def test_breakline1
		buf = FakeBuffer.new
		bo = Convert::from_string_into_bufferobjs("abcdef\ngh")
		buf.adjust_height(5) # there should be 3 empty lines at the bottom
		buf.replace_content(bo)
		3.times { buf.cmd_move_right }
		buf.cmd_breakline  # normal case
		assert_equal(0, buf.position_x)
		assert_equal(1, buf.position_y)
		assert_equal(10, buf.total_bytes)
		assert_equal(2, buf.total_physical_lines)
		assert_equal(2, buf.total_visible_lines)
		assert_equal(5, buf.visible_lines)
	end
	def test_breakline2
		buf = FakeBuffer.new
		bo = Convert::from_string_into_bufferobjs("abc\ndefgh")
		buf.adjust_height(2) 
		buf.replace_content(bo)
		buf.cmd_move_down
		3.times { buf.cmd_move_right }
		buf.cmd_breakline # scrolling is involved
		assert_equal(0, buf.position_x)
		assert_equal(2, buf.position_visible_lines)
		assert_equal(1, buf.position_y)
		assert_equal(10, buf.total_bytes)
		assert_equal(2, buf.total_physical_lines)
		assert_equal(2, buf.total_visible_lines)
		assert_equal(2, buf.visible_lines)
	end
	def test_breakline3
		buf = FakeBuffer.new
		bo = Convert::from_string_into_bufferobjs("ab\ncd")
		buf.adjust_height(2) 
		buf.replace_content(bo)
		buf.cmd_move_end
		2.times { buf.cmd_move_right }
		buf.cmd_breakline # splitting Vspace
		assert_equal(0, buf.position_x)
		assert_equal(1, buf.position_visible_lines)
		assert_equal(1, buf.position_y)
		assert_equal(6, buf.total_bytes)
		assert_equal(2, buf.total_physical_lines)
		assert_equal(2, buf.total_visible_lines)
		assert_equal(2, buf.visible_lines)
	end
	def test_breakline4
		buf = FakeBuffer.new(true)  # cursor through tabs
		bo = Convert::from_string_into_bufferobjs("a\tb\ncd")
		buf.adjust_height(2) 
		buf.replace_content(bo)
		2.times { buf.cmd_move_right }
		buf.cmd_breakline # splitting TAB
		assert_equal(0, buf.position_x)
		assert_equal(1, buf.position_visible_lines)
		assert_equal(1, buf.position_y)
		assert_equal(8, buf.total_bytes)
		assert_equal(2, buf.total_physical_lines)
		assert_equal(2, buf.total_visible_lines)
		assert_equal(2, buf.visible_lines)
	end
	def test_autoindent_breakline1
		buf = FakeBuffer.new(true)  # cursor through tabs
		bo = Convert::from_string_into_bufferobjs("\t abcd")
		buf.adjust_height(2) 
		buf.replace_content(bo)
		buf.cmd_move_end
		2.times { buf.cmd_move_left }
		buf.cmd_breakline # test auto-indent
		assert_equal(5, buf.position_x)
		assert_equal(1, buf.position_visible_lines)
		assert_equal(1, buf.position_y)
		assert_equal(9, buf.total_bytes)
		assert_equal(1, buf.total_physical_lines)
		assert_equal(1, buf.total_visible_lines)
		assert_equal(2, buf.visible_lines)
	end
	def test_autoindent_breakline2
		buf = FakeBuffer.new(true)  # cursor through tabs
		bo = Convert::from_string_into_bufferobjs("\t \tabcd")
		buf.adjust_height(2) 
		buf.replace_content(bo)
		6.times { buf.cmd_move_right }
		buf.cmd_breakline # test auto-indent
		assert_equal(6, buf.position_x)
		assert_equal(1, buf.position_visible_lines)
		assert_equal(1, buf.position_y)
		assert_equal(8, buf.total_bytes)
		assert_equal(1, buf.total_physical_lines)
		assert_equal(1, buf.total_visible_lines)
		assert_equal(2, buf.visible_lines)
	end
	def test_no_autoindent_breakline1
		buf = FakeBuffer.new(true, false)  # cursor through tabs
		bo = Convert::from_string_into_bufferobjs("\t abcd")
		buf.adjust_height(2) 
		buf.replace_content(bo)
		buf.cmd_move_end
		2.times { buf.cmd_move_left }
		buf.cmd_breakline # test auto-indent
		assert_equal(0, buf.position_x)
		assert_equal(1, buf.position_visible_lines)
		assert_equal(1, buf.position_y)
		assert_equal(7, buf.total_bytes)
		assert_equal(1, buf.total_physical_lines)
		assert_equal(1, buf.total_visible_lines)
		assert_equal(2, buf.visible_lines)
	end
	def test_no_autoindent_breakline2
		buf = FakeBuffer.new(true, false)  # cursor through tabs
		bo = Convert::from_string_into_bufferobjs("\t \tabcd")
		buf.adjust_height(2) 
		buf.replace_content(bo)
		6.times { buf.cmd_move_right }
		buf.cmd_breakline # test auto-indent
		assert_equal(0, buf.position_x)
		state = buf.create_memento
		str = Convert::from_bufferobjs_into_filestring(state.bufobjs)
		assert_equal("\n  abcd", str)
		assert_equal(1, buf.position_visible_lines)
		assert_equal(1, buf.position_y)
		assert_equal(7, buf.total_bytes)
		assert_equal(1, buf.total_physical_lines)
		assert_equal(1, buf.total_visible_lines)
		assert_equal(2, buf.visible_lines)
	end
	def test_indent_home1
		buf = FakeBuffer.new(true)  # cursor through tabs
		bo = Convert::from_string_into_bufferobjs("\t abcd\n")
		buf.adjust_height(2) 
		buf.replace_content(bo)
		buf.cmd_move_down
		buf.cmd_move_right
		buf.cmd_move_home(true) # test auto-indent
		assert_equal(5, buf.position_x)
		assert_equal(1, buf.position_visible_lines)
		assert_equal(1, buf.position_y)
		assert_equal(7, buf.total_bytes)
		assert_equal(1, buf.total_physical_lines)
		assert_equal(1, buf.total_visible_lines)
		assert_equal(2, buf.visible_lines)
	end
	def test_indent_home2
		buf = FakeBuffer.new(true)  # cursor through tabs
		bo = Convert::from_string_into_bufferobjs("\t abcd\n")
		buf.adjust_height(2) 
		buf.replace_content(bo)
		buf.cmd_move_down
		assert_equal(0, buf.position_x)
		buf.cmd_move_home(true) # test auto-indent
		assert_equal(5, buf.position_x)
		assert_equal(7, buf.total_bytes)
	end
	def test_indent_home3
		buf = FakeBuffer.new(true)  # cursor through tabs
		bo = Convert::from_string_into_bufferobjs("\t abcd\n")
		buf.adjust_height(2) 
		buf.replace_content(bo)
		buf.cmd_move_home(true) 
		buf.cmd_move_down
		assert_equal(5, buf.position_x)
		buf.cmd_move_home(true) # test auto-indent
		assert_equal(0, buf.position_x)
		assert_equal(7, buf.total_bytes)
	end
	def test_indent_home4
		buf = FakeBuffer.new(true)  # cursor through tabs
		bo = Convert::from_string_into_bufferobjs("abcd\n")
		buf.adjust_height(2) 
		buf.replace_content(bo)
		assert_harmless(CommandHarmless) { buf.cmd_move_home(true) } 
	end
	def test_indent_home5
		buf = FakeBuffer.new(true)  # cursor through tabs
		bo = Convert::from_string_into_bufferobjs("abcd\n")
		buf.adjust_height(2) 
		buf.replace_content(bo)
		buf.cmd_move_down
		assert_equal(0, buf.position_x)
		assert_harmless(CommandHarmless) { buf.cmd_move_home(true) } 
	end
	def test_joinline1
		buf = FakeBuffer.new
		bo = Convert::from_string_into_bufferobjs("abc\ndef\ngh")
		buf.adjust_height(2) 
		buf.replace_content(bo)
		buf.cmd_move_down
		buf.cmd_joinline
		assert_equal(3, buf.position_x)
		assert_equal(0, buf.position_visible_lines)
		assert_equal(0, buf.position_y)
		assert_equal(9, buf.total_bytes)
		assert_equal(1, buf.total_physical_lines)
		assert_equal(1, buf.total_visible_lines)
		assert_equal(2, buf.visible_lines)
	end
	def test_joinline2
		buf = FakeBuffer.new
		bo = Convert::from_string_into_bufferobjs("abc\ndef")
		buf.adjust_height(2) 
		buf.replace_content(bo)
		buf.cmd_move_down
		buf.cmd_joinline
		assert_equal(3, buf.position_x)
		assert_equal(0, buf.position_visible_lines)
		assert_equal(0, buf.position_y)
		assert_equal(6, buf.total_bytes)
		assert_equal(0, buf.total_physical_lines)
		assert_equal(0, buf.total_visible_lines)
		assert_equal(2, buf.visible_lines)
	end
	def test_joinline3
		buf = FakeBuffer.new
		bo = Convert::from_string_into_bufferobjs("abc\ndef")
		buf.adjust_height(2) 
		buf.replace_content(bo)
		assert_harmless(BufferTop) { buf.cmd_joinline } 
	end
	def test_block_remove1
		buf = FakeBuffer.new
		class << buf 
			def remove_backward(x, y)
				@info = [x, y, position_x, position_visible_lines]
				super(x, y)
			end
			attr_reader :info
		end
		bo = Convert::from_string_into_bufferobjs("abc\ndef\nghi")
		buf.adjust_height(2) 
		buf.replace_content(bo)
		buf.cmd_move_right
		buf.cmd_block_begin
		assert_equal(true, buf.blocking.enabled)
		2.times { buf.cmd_move_down }
		buf.cmd_move_right
		buf.cmd_block_remove
		assert_equal([1, 0, 2, 2], buf.info)
		assert_equal(false, buf.blocking.enabled)
		state = buf.create_memento
		str = Convert::from_bufferobjs_into_filestring(state.bufobjs)
		assert_equal("ai".inspect, str.inspect)
		assert_equal(1, buf.position_x)
		assert_equal(0, buf.position_visible_lines)
		assert_equal(0, buf.position_y)
		assert_equal(2, buf.visible_lines)
	end
	def test_block_remove2
		buf = FakeBuffer.new
		class << buf 
			def remove_backward(x, y)
				@info = [x, y, position_x, position_visible_lines]
				super(x, y)
			end
			attr_reader :info
		end
		bo = Convert::from_string_into_bufferobjs("abc\ndef\nghi")
		buf.adjust_height(2) 
		buf.replace_content(bo)
		buf.cmd_move_right
		2.times { buf.cmd_move_down }
		buf.cmd_move_right
		buf.cmd_block_begin
		assert_equal(true, buf.blocking.enabled)
		buf.cmd_move_home
		2.times { buf.cmd_move_up }
		buf.cmd_move_right
		buf.cmd_block_remove
		assert_equal([1, 0, 2, 2], buf.info) # see if we can swap correct
		assert_equal(false, buf.blocking.enabled)
		state = buf.create_memento
		str = Convert::from_bufferobjs_into_filestring(state.bufobjs)
		assert_equal("ai".inspect, str.inspect)
		assert_equal(1, buf.position_x)
		assert_equal(0, buf.position_visible_lines)
		assert_equal(0, buf.position_y)
		assert_equal(2, buf.visible_lines)
	end
	def test_block_remove3
		buf = FakeBuffer.new
		class << buf 
			def remove_backward(x, y)
				@info = [x, y, position_x, position_visible_lines]
				super(x, y)
			end
			attr_reader :info
		end
		bo = Convert::from_string_into_bufferobjs("abcdefghi")
		buf.adjust_height(2) 
		buf.replace_content(bo)
		buf.cmd_move_right
		buf.cmd_block_begin
		assert_equal(true, buf.blocking.enabled)
		buf.cmd_move_end
		buf.cmd_move_left
		buf.cmd_block_remove
		assert_equal([1, 0, 8, 0], buf.info) # its an oneliner!
		assert_equal(false, buf.blocking.enabled)
		state = buf.create_memento
		str = Convert::from_bufferobjs_into_filestring(state.bufobjs)
		assert_equal("ai".inspect, str.inspect)
		assert_equal(1, buf.position_x)
		assert_equal(0, buf.position_visible_lines)
		assert_equal(0, buf.position_y)
		assert_equal(2, buf.visible_lines)
	end
	def test_block_remove4
		buf = FakeBuffer.new
		bo = Convert::from_string_into_bufferobjs("abcdefghi")
		buf.adjust_height(2) 
		buf.replace_content(bo)
		assert_equal(false, buf.blocking.enabled)
		assert_harmless(CommandHarmless) { buf.cmd_block_remove }  
	end
	def test_block_copy1
		buf = FakeBuffer.new
		bo = Convert::from_string_into_bufferobjs("abc\ndef\nghi")
		buf.adjust_height(2) 
		buf.replace_content(bo)
		buf.cmd_move_right
		buf.cmd_block_begin
		2.times { buf.cmd_move_down }
		buf.cmd_move_end
		buf.cmd_move_left
		buf.cmd_block_copy
		assert_equal(false, buf.blocking.enabled)
		str = Convert::from_bufferobjs_into_filestring(buf.clipboard)
		assert_equal("bc\ndef\ngh".inspect, str.inspect)
		assert_equal(11, buf.total_bytes)
	end
	def test_block_copy2
		buf = FakeBuffer.new
		bo = Convert::from_string_into_bufferobjs("abcdefghi\nxyz")
		buf.adjust_height(2) 
		buf.replace_content(bo)
		buf.cmd_move_right
		buf.cmd_block_begin
		buf.cmd_move_end
		buf.cmd_move_left
		buf.cmd_block_copy
		assert_equal(false, buf.blocking.enabled)
		str = Convert::from_bufferobjs_into_filestring(buf.clipboard)
		assert_equal("bcdefgh".inspect, str.inspect)
		assert_equal(13, buf.total_bytes)
	end
	def test_block_copy3
		buf = FakeBuffer.new
		bo = Convert::from_string_into_bufferobjs("abcdefghi\nxyz")
		buf.adjust_height(2) 
		buf.replace_content(bo)
		assert_equal(false, buf.blocking.enabled)
		assert_harmless(CommandHarmless) { buf.cmd_block_copy }
	end
	def test_block_paste1
		buf = FakeBuffer.new
		bo = Convert::from_string_into_bufferobjs("ai")
		buf.adjust_height(2) 
		buf.replace_content(bo)
		buf.cmd_move_right
		bo = Convert::from_string_into_bufferobjs("bc\ndef\ngh")
		buf.set_clipboard(bo)
		buf.cmd_block_paste
		assert_equal(2, buf.position_x)
		assert_equal(2, buf.position_visible_lines)
		assert_equal(1, buf.position_y)
		assert_equal(11, buf.total_bytes)
		assert_equal(2, buf.total_physical_lines)
		assert_equal(2, buf.total_visible_lines)
	end
	def test_block_paste2
		buf = FakeBuffer.new
		bo = Convert::from_string_into_bufferobjs("\tai") # autoindent = off
		buf.adjust_height(2) 
		buf.replace_content(bo)
		buf.cmd_move_right # cursor NOT-through tabs
		buf.cmd_move_right 
		bo = Convert::from_string_into_bufferobjs("bc\n\tdef\ngh")
		buf.set_clipboard(bo)
		buf.cmd_block_paste
		state = buf.create_memento
		str = Convert::from_bufferobjs_into_filestring(state.bufobjs)
		assert_equal("\tabc\n\tdef\nghi".inspect, str.inspect)
		assert_equal(2, buf.position_x)
		assert_equal(2, buf.position_visible_lines)
		assert_equal(1, buf.position_y)
		assert_equal(13, buf.total_bytes)
		assert_equal(2, buf.total_physical_lines)
		assert_equal(2, buf.total_visible_lines)
	end
	def assert_private
		e = assert_raises(NoMethodError) { yield }
		assert_match(/private/, e.message)
	end
	def test_privacy1
		buf = FakeBuffer.new
		assert_private { buf.create_memento_all }
		assert_private { buf.create_memento_current_line }
		assert_private { buf.create_memento_position }
	end
	def setup_fold_expand
		buf = FakeBuffer.new
		bo = Convert::from_string_into_bufferobjs("abc\nde\nfgh")
		bof = Convert::from_string_into_bufferobjs("x\ny\nz")
		fold = BufferObjects::Fold.new(bof, "{2}", false)
		bo[5, 0] = fold
		buf.adjust_height(2) 
		buf.replace_content(bo)
		buf
	end
	def test_setup_fold_expand1
		buf = setup_fold_expand
		assert_equal(15, buf.total_bytes)
		assert_equal(4, buf.total_physical_lines)
		assert_equal(2, buf.total_visible_lines)
		assert_equal(0, buf.position_y)
		state = buf.create_memento
		str = Convert::from_bufferobjs_into_filestring(state.bufobjs)
		assert_equal("abc\ndx\ny\nze\nfgh".inspect, str.inspect)
	end
	def test_locate_fold1
		buf = setup_fold_expand
		buf.cmd_move_down
		buf.fold_locate
		assert_equal(1, buf.position_x)
	end
	def test_locate_fold2
		buf = setup_fold_expand
		buf.cmd_move_down
		buf.cmd_move_end
		buf.cmd_move_right
		buf.fold_locate
		assert_equal(1, buf.position_x)
	end
	def test_locate_fold3
		buf = setup_fold_expand
		assert_raises(CommandHarmless) { buf.fold_locate }
	end
	def test_fold_expand1
		buf = setup_fold_expand
		# there is no fold on the current line
		assert_raises(CommandHarmless) { buf.cmd_fold_expand }
		buf.cmd_move_down
		# fold on current line.. we should be able to expand it
		buf.cmd_fold_expand
		assert_equal(4, buf.total_visible_lines)
		assert_equal(1, buf.position_x)
		assert_equal(1, buf.position_visible_lines)
		assert_equal(0, buf.position_y)
		state = buf.create_memento
		str = Convert::from_bufferobjs_into_filestring(state.bufobjs)
		assert_equal("abc\ndx\ny\nze\nfgh".inspect, str.inspect)
	end
	def test_fold_expand2
		buf = setup_fold_expand
		buf.cmd_move_down
		buf.cmd_move_end
		buf.cmd_move_right
		# fold on current line.. we should be able to expand it
		buf.cmd_fold_expand
		assert_equal(4, buf.total_visible_lines)
		assert_equal(1, buf.position_x)
		assert_equal(1, buf.position_visible_lines)
		assert_equal(0, buf.position_y)
	end
	def setup_buffer(text, height=2)
		buf = FakeBuffer.new
		bo = Convert::from_string_into_bufferobjs(text)
		buf.adjust_height(height) 
		buf.replace_content(bo)
		buf 
	end
	def test_fold_collapse1
		code =<<MSG
p "before"
def test  #[
\tp 42
end #]
p "after"
MSG
		buf = setup_buffer(code, 2)
		assert_equal(47, buf.total_bytes)
		assert_equal(5, buf.total_physical_lines)
		assert_equal(5, buf.total_visible_lines)
		assert_equal(0, buf.position_y)
		2.times { buf.cmd_move_down }
		assert_equal(2, buf.position_visible_lines)
		buf.cmd_fold_collapse
		assert_equal(5, buf.total_physical_lines)
		assert_equal(3, buf.total_visible_lines)
		assert_equal(1, buf.position_visible_lines)
	end
	def test_fold_locate_begin_end1
		code =<<MSG
p "before"
def test  #[
\tp 42
end #]
p "after"
MSG
		buf = setup_buffer(code, 2)
		assert_equal(47, buf.total_bytes)
		assert_equal(5, buf.total_physical_lines)
		assert_equal(5, buf.total_visible_lines)
		assert_equal(0, buf.position_y)
		2.times { buf.cmd_move_down }
		assert_equal(2, buf.position_visible_lines)
		begin_xy = buf.fold_get_begin_goto_end
		assert_equal([10, 1], begin_xy)
		assert_equal(3, buf.position_visible_lines)
		assert_equal(6, buf.position_x)
	end
	def test_fold_locate_begin_end2
		code =<<MSG
p "before"
def test
\tp 42
end #]
p "after"
MSG
		buf = setup_buffer(code, 2)
		2.times { buf.cmd_move_down }
		assert_raises(FoldTagbeginMissing) { buf.fold_get_begin_goto_end }
		assert_equal(2, buf.position_visible_lines)
		assert_equal(0, buf.position_x)
	end
	def test_fold_goto_end1
		code = "a\nb\nz#]x\nc\nd" 
		buf = setup_buffer(code, 2)
		assert_equal(0, buf.position_bytes)
		buf.fold_goto_end
		assert_equal(7, buf.position_bytes)
	end
	def test_fold_goto_end2
		code = "a\nb\nc\nd\ne" 
		buf = setup_buffer(code, 2)
		assert_equal(0, buf.position_bytes)
		assert_raises(FoldTagendMissing) { buf.fold_goto_end }
		assert_equal(9, buf.position_bytes)
	end
	def test_fold_goto_begin1
		code = "a\nb\nz#[x\nc\nd" 
		buf = setup_buffer(code, 2)
		4.times { buf.cmd_move_down }
		assert_equal(11, buf.position_bytes)
		buf.fold_goto_begin
		assert_equal(5, buf.position_bytes)
	end
	def test_fold_goto_begin2
		code = "a\nb\nc\nd\ne" 
		buf = setup_buffer(code, 2)
		4.times { buf.cmd_move_down }
		assert_equal(8, buf.position_bytes)
		assert_raises(FoldTagbeginMissing) { buf.fold_goto_begin }
		assert_equal(1, buf.position_bytes) # end of first line == 1
	end
	def test_fold_scantag_end1
		code = "a\nb\nz#]x\nc\nd" 
		buf = setup_buffer(code, 2)
		assert_equal(0, buf.position_bytes)
		2.times { buf.cmd_move_down }
		assert_equal(true, buf.scan_foldtag_end)
		assert_equal(7, buf.position_bytes)
	end
	def test_fold_scantag_end2
		code = "a\nb\n# ]z#]x\nc\nd" 
		buf = setup_buffer(code, 2)
		assert_equal(0, buf.position_bytes)
		2.times { buf.cmd_move_down }
		assert_equal(true, buf.scan_foldtag_end)
		assert_equal(10, buf.position_bytes)
	end
	def test_fold_scantag_begin1
		code = "a\nb\nxyz#[vw\nc\nd" 
		buf = setup_buffer(code, 2)
		assert_equal(0, buf.position_bytes)
		2.times { buf.cmd_move_down }
		assert_equal(true, buf.scan_foldtag_begin)
		assert_equal(7, buf.position_bytes)
	end
	def test_fold_scantag_begin2
		code = "a\nb\n\t xyz#[vw\nc\nd" 
		buf = setup_buffer(code, 2)
		assert_equal(0, buf.position_bytes)
		2.times { buf.cmd_move_down }
		assert_equal(true, buf.scan_foldtag_begin)
		assert_equal(9, buf.position_bytes)
	end
	def test_fold_scantag_begin3
		code = "a\nb\n#\t[ xyz#[vw\nc\nd" 
		buf = setup_buffer(code, 2)
		assert_equal(0, buf.position_bytes)
		2.times { buf.cmd_move_down }
		assert_equal(true, buf.scan_foldtag_begin)
		assert_equal(11, buf.position_bytes)
	end
	def test_fold_make_title1
		str = "#[ title  \na\nend #]" 
		bo = Convert::from_string_into_bufferobjs(str)
		code = "a\nb" 
		buf = setup_buffer(code, 2)
		res = buf.fold_make_title(bo) 
		assert_equal("[ 2 title ]", res)
	end
	def test_fold_make_title2
		str = "#[   \na\nend #]" 
		bo = Convert::from_string_into_bufferobjs(str)
		code = "a\nb" 
		buf = setup_buffer(code, 2)
		res = buf.fold_make_title(bo) 
		assert_equal("[ 2 ]", res)
	end
	def test_if_page_up_preserves_x1
		buf = FakeBuffer.new
		bo = Convert::from_string_into_bufferobjs("ab\n\tc\nde")
		buf.set_memento(Buffer::Memento::All.new(1, 2, bo, Buffer::Blocking.new))
		buf.resize_topbottom(0, 2)
		assert_equal(1, buf.position_x)
		buf.cmd_move_page_up
		assert_equal(1, buf.position_x) # x should be unharmed
	end
	def test_if_page_down_preserves_x1
		buf = FakeBuffer.new
		bo = Convert::from_string_into_bufferobjs("ab\n\tc\nde")
		buf.adjust_height(3) 
		buf.replace_content(bo)
		buf.cmd_move_right
		assert_equal(1, buf.position_x)
		buf.cmd_move_page_down
		assert_equal(1, buf.position_x) # x should be unharmed 
	end
end

TestBuffer.run if $0 == __FILE__
