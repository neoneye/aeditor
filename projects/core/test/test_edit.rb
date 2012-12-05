require 'aeditor/backend/edit'
require 'aeditor/backend/buffer_measure'
require 'aeditor/backend/convert'
require 'common'

class Tab
	include MeasureMixins::One
end

class VSpace
	include MeasureMixins::Zero
end

class Mark
	include MeasureMixins::Zero
end

class String
	include MeasureMixins::One
end

class FakeEdit < Edit
	def initialize(
		cursor_through_tabs = false,
		vspace_enable = false)
		super()

		install_editor(String, EditObjects::Object.new(self))

		# normal insert mode  or  overwrite mode
		install_editor(
			Tab, 
			cursor_through_tabs ?
			EditObjects::TabThrough.new(self, 4) :
			tab = EditObjects::Tab.new(self, 4)
		)

		@vspace_enable = vspace_enable
		if vspace_enable
			install_editor(VSpace, EditObjects::VSpace.new(self))
			push_right(@vspace = VSpace.new)
		end

		install_editor(Mark, EditObjects::Mark.new(self))
	end
	attr_reader :vspace

	def is_end
		return super() unless @vspace_enable

		return true if @current == vspace
		return false if @current != nil
		return true if @right == [vspace]
		return true if @right == []
		false
	end
	attr_reader :notify_lock

	def create_memento
		x, lo = super
		lo.pop if lo.last.kind_of?(VSpace)
		[x, lo]
	end
	def reset
		super
		push_right(@vspace) if @vspace_enable
	end
end

class FakeEdit2 < Edit
	def initialize(
		cursor_through_tabs = false)
		super()

		install_editor(LineObjects::Text, EditObjects::Object.new(self))
		install_editor(LineObjects::Fold, EditObjects::Fold.new(self))

		# normal insert mode  or  overwrite mode
		install_editor(
			LineObjects::Tab, 
			cursor_through_tabs ?
			EditObjects::TabThrough.new(self, 4) :
			EditObjects::Tab.new(self, 4)
		)
	end
end

class FakeEditWatcher
	def initialize
		clear
	end
	def update(cursor_changed, content_changed)
		# >>> normaly we OR the values... but! <<<
		# here we ACCUMULATE the values into an array,
		# so that we can inspect all changes and
		# ensure everything is working as expected.
		@cursor << cursor_changed
		@content << content_changed
	end
	def clear
		@cursor = []
		@content = []
	end
	attr_reader :cursor, :content
end

class TestEdit < Common::TestCase 
	def test_plain_text1
		edit = FakeEdit.new
		edit.insert('a')
		assert_equal(1, edit.x)
		edit.insert('b')
		assert_equal(2, edit.x)
		edit.insert('c')
		assert_equal(3, edit.x)
		edit.move_left
		assert_equal(2, edit.x)
		edit.move_right
		assert_equal(3, edit.x)
	end
	def test_plain_text2
		edit = FakeEdit.new
		edit.insert('c')
		assert_equal(['c'], edit.left)
		assert_equal([], edit.right)
		edit.move_left
		assert_equal([], edit.left)
		assert_equal(['c'], edit.right)
		edit.insert('b')
		edit.move_left
		edit.insert('a')
		assert_equal(['a'], edit.left)
		assert_equal(['b', 'c'], edit.right)
	end
	def test_plain_text3
		edit = FakeEdit.new
		edit.insert('a')
		edit.insert('c')
		assert_equal(['a', 'c'], edit.left)
		assert_equal([], edit.right)
		edit.move_left
		edit.move_left
		assert_equal([], edit.left)
		assert_equal(['a', 'c'], edit.right)
		edit.insert('b')
		assert_equal(['b'], edit.left)
		assert_equal(['a', 'c'], edit.right)
		edit.move_right
		assert_equal(['b', 'a'], edit.left)
		assert_equal(['c'], edit.right)
		edit.move_right
		edit.insert('d')
		assert_equal(['b', 'a', 'c', 'd'], edit.left)
		assert_equal([], edit.right)
	end
	def test_plain_text4
		edit = FakeEdit.new
		edit.insert('a')
		edit.insert('b')
		edit.insert('c')
		edit.move_left
		assert_equal(['a', 'b'], edit.left)
		assert_equal(['c'], edit.right)
		assert_equal(2, edit.x)
		edit.backspace
		assert_equal(['a'], edit.left)
		assert_equal(['c'], edit.right)
		assert_equal(1, edit.x)
	end
	def test_normal_tab1
		edit = FakeEdit.new
		edit.insert(Tab.new)
		assert_equal(4, edit.x)
		edit.insert('a')
		assert_equal(5, edit.x)
		edit.insert(Tab.new)
		assert_equal(8, edit.x)
		edit.insert('b')
		edit.insert('c')
		assert_equal(10, edit.x)
		edit.insert(Tab.new)
		assert_equal(12, edit.x)
		edit.insert('d')
		edit.insert('e')
		edit.insert('f')
		assert_equal(15, edit.x)
		edit.insert(Tab.new)
		assert_equal(16, edit.x)
		edit.insert('g')
		edit.insert('h')
		edit.insert('i')
		edit.insert('j')
		assert_equal(20, edit.x)
		edit.insert(Tab.new)
		assert_equal(24, edit.x)
	end
	def test_normal_tab2
		edit = FakeEdit.new
		edit.insert(Tab.new)
		edit.insert('e')
		assert_equal(5, edit.x)
		edit.move_left
		edit.move_left
		assert_equal(0, edit.x)
		edit.insert('a')
		edit.insert('b')
		edit.insert('c')
		edit.insert('d')
		assert_equal(4, edit.x)
		edit.move_right
		assert_equal(8, edit.x)
	end
	def test_normal_tab3
		edit = FakeEdit.new
		edit.insert('a')
		edit.insert('b')
		edit.insert(Tab.new)
		assert_equal(4, edit.x)
		edit.move_left
		# this TAB is only 2 cells wide
		assert_equal(2, edit.x)
		edit.move_left
		assert_equal(1, edit.x)
	end
	def test_normal_tab4
		edit = FakeEdit.new
		edit.insert('a')
		edit.insert('b')
		edit.insert('c')
		edit.insert('d')
		edit.insert(t1 = Tab.new)
		edit.insert('e')
		edit.move_left
		edit.move_left
		assert_equal(['a', 'b', 'c', 'd'], edit.left)
		assert_equal([t1, 'e'], edit.right)
		assert_equal(4, edit.x)
		edit.backspace
		assert_equal(3, edit.x)
		edit.move_right
		edit.move_right
		assert_equal(['a', 'b', 'c', t1, 'e'], edit.left)
		assert_equal([], edit.right)
		assert_equal(5, edit.x)
	end
	def test_cursor_through_tabs1
		edit = FakeEdit.new(true)
		edit.insert(Tab.new)
		edit.insert('b')
		assert_equal(5, edit.x)
		edit.move_left
		assert_equal(4, edit.x)
		edit.move_left
		assert_equal(3, edit.position)
		edit.move_left
		assert_kind_of(Tab, edit.current)
		assert_equal([], edit.left)
		assert_equal(['b'], edit.right)
		assert_equal(2, edit.position)
		edit.insert('a')
		assert_equal(3, edit.x)
		assert_equal([' ', ' ', 'a'], edit.left)
		assert_equal([' ', ' ', 'b'], edit.right)
	end
	def test_cursor_through_tabs2
		edit = FakeEdit.new(true)
		edit.insert('a')
		edit.insert(t1 = Tab.new)
		edit.insert(t2 = Tab.new)
		edit.insert('c')
		assert_equal(9, edit.x)
		edit.move_left
		assert_equal(8, edit.x)
		assert_equal(['a', t1, t2], edit.left)
		edit.move_left
		edit.move_left
		edit.move_left
		assert_equal(5, edit.position)
		assert_equal(['a', t1], edit.left)
		assert_equal(['c'], edit.right)
		edit.move_left
		assert_equal(4, edit.position)
		assert_equal(['a', t1], edit.left)
		assert_equal([t2, 'c'], edit.right)
		edit.move_left
		assert_equal(3, edit.position)
		edit.insert('b')
		assert_equal(['a', ' ', ' ', 'b'], edit.left)
		assert_equal([' ', t2, 'c'], edit.right)
	end
	def test_cursor_through_tabs3
		edit = FakeEdit.new(true)
		edit.insert('a')
		edit.insert(t1 = Tab.new)
		edit.insert('b')
		assert_equal(5, edit.x)
		edit.move_left
		edit.move_left
		assert_equal(3, edit.position)
		edit.backspace
		assert_equal(2, edit.x)
		assert_equal(['a', ' '], edit.left)
		assert_equal([' ', 'b'], edit.right)
	end
	def test_line_begin
		edit = FakeEdit.new
		edit.insert('a')
		edit.move_left
		assert_equal([], edit.left)
		assert_equal(['a'], edit.right)
		assert_raises(FakeEdit::NotBegin) { edit.move_left }
		assert_equal([], edit.left)
		assert_equal(['a'], edit.right)
		assert_raises(FakeEdit::NotBegin) { edit.backspace }
		assert_equal([], edit.left)
		assert_equal(['a'], edit.right)
	end
	def test_line_end
		edit = FakeEdit.new
		edit.insert('a')
		assert_equal(['a'], edit.left)
		assert_equal([], edit.right)
		assert_raises(FakeEdit::NotEnd) { edit.move_right }
		assert_equal(['a'], edit.left)
		assert_equal([], edit.right)
	end
	def test_vspace1
		edit = FakeEdit.new(false, true)
		edit.insert('a')
		assert_equal(['a'], edit.left)
		assert_equal([edit.vspace], edit.right)
		3.times { edit.move_right }
		edit.move_left
		assert_equal(3, edit.position)
		edit.insert('b')
		assert_equal(['a', ' ', ' ', 'b'], edit.left)
		assert_equal([edit.vspace], edit.right)
	end
	def test_mark1
		edit = FakeEdit.new
		edit.insert('a')
		# the mark we want to insert looks like '[1]'
		# the mark is 3 cells wide!
		edit.insert(m = Mark.new)
		edit.insert('b')
		edit.move_home
		edit.move_right
		assert_equal(1, edit.position)
		edit.move_right  # move over the mark.. its 3 cells wide!
		assert_equal(4, edit.position)
	end
	def test_mark2
		edit = FakeEdit.new
		edit.insert('a')
		# the mark we want to insert looks like '[1]'
		# the mark is 3 cells wide!
		edit.insert(m = Mark.new)
		edit.insert('b')
		edit.move_left
		assert_equal(4, edit.position)
		edit.move_left  # move over the mark.. its 3 cells wide!
		assert_equal(1, edit.position)
	end
	def test_replace_content1
		edit = FakeEdit.new(false)
		edit.insert('a')
		edit.insert('b')
		edit.insert('c')
		edit.insert('d')
		edit.move_left
		assert_equal(3, edit.position)
		old = edit.replace_content(['0', '1', '2', '3', '4'])
		assert_equal(['a', 'b', 'c', 'd'], old)
		assert_equal(['0', '1', '2'], edit.left)
		assert_equal(['3', '4'], edit.right)
	end
	def test_replace_content2
		edit = FakeEdit.new(false)
		edit.insert('a')
		edit.insert(t1 = Tab.new)
		edit.insert('b')
		edit.move_left
		assert_equal(4, edit.position)
		old = edit.replace_content(['0', '1', '2', '3', '4'])
		assert_equal(['a', t1, 'b'], old)
		assert_equal(['0', '1', '2', '3'], edit.left)
		assert_equal(['4'], edit.right)
	end
	def test_replace_content3
		edit = FakeEdit.new(false)
		edit.insert('0')
		edit.insert('1')
		edit.insert('2')
		edit.insert('3')
		edit.move_left
		edit.move_left
		assert_equal(2, edit.position)
		old = edit.replace_content(['a', t1=Tab.new, 'b'])
		assert_equal(['0', '1', '2', '3'], old)
		assert_equal(['a', t1], edit.left)
		assert_equal(4, edit.position)
		assert_equal(['b'], edit.right)
	end
	def test_replace_content4
		edit = FakeEdit.new(true)
		edit.insert('0')
		edit.insert('1')
		edit.insert('2')
		edit.insert('3')
		edit.move_left
		edit.move_left
		assert_equal(2, edit.position)
		old = edit.replace_content(['a', t1=Tab.new, 'b'])
		assert_equal(['0', '1', '2', '3'], old)
		assert_equal(['a'], edit.left)
		assert_equal(t1, edit.current)
		assert_equal(2, edit.position)
		assert_equal(['b'], edit.right)
	end
	def test_replace_content5
		edit = FakeEdit.new(false, true)
		edit.insert('0')
		edit.insert('1')
		edit.insert('2')
		edit.insert('3')
		assert_equal(4, edit.position)
		old = edit.replace_content(['a', edit.vspace])
		assert_equal(['0', '1', '2', '3', edit.vspace], old)
		assert_equal(['a'], edit.left)
		assert_equal(edit.vspace, edit.current)
		assert_equal(4, edit.position)
		assert_equal([], edit.right)
	end
	def test_move_home1
		edit = FakeEdit.new(false)
		edit.insert('0')
		edit.insert('1')
		edit.insert('2')
		edit.insert('3')
		assert_equal(4, edit.position)
		edit.move_home  # position has changed
		assert_equal(0, edit.position)
		assert_equal([], edit.left)
		assert_equal(['0', '1', '2', '3'], edit.right)
	end
	def test_move_home2
		edit = FakeEdit.new(false)
		edit.insert('0')
		edit.move_left
		assert_equal(0, edit.position)
		assert_raises(CommandHarmless) { edit.move_home } # position has not changed
		assert_equal(0, edit.position)
		assert_equal([], edit.left)
		assert_equal(%w(0), edit.right)
	end
	def test_move_home_indent1
		edit = FakeEdit2.new(false)
		lo = Convert.from_string_into_lineobjs("\t a")
		edit.set_memento([2, lo])
		edit.move_home(true)  # position has changed
		assert_equal(5, edit.position)
		assert_equal(2, edit.left.size)
		assert_equal(1, edit.right.size)
	end
	def test_move_home_indent2
		edit = FakeEdit2.new(false)
		lo = Convert.from_string_into_lineobjs("\t a")
		edit.set_memento([5, lo])
		edit.move_home(true)  # position has changed
		assert_equal(0, edit.position)
		assert_equal(0, edit.left.size)
		assert_equal(3, edit.right.size)
	end
	def test_move_home_indent3
		edit = FakeEdit2.new(false)
		lo = Convert.from_string_into_lineobjs("a")
		edit.set_memento([0, lo])
		assert_raises(CommandHarmless) { edit.move_home(true) }
		assert_equal(0, edit.position)
		assert_equal(0, edit.left.size)
		assert_equal(1, edit.right.size)
	end
	def test_move_end1
		edit = FakeEdit.new(false)
		edit.insert('0')
		edit.insert('1')
		edit.insert('2')
		edit.insert('3')
		edit.move_left
		edit.move_left
		edit.move_left
		edit.move_left
		assert_equal(0, edit.position)
		edit.move_end  # change position
		assert_equal(4, edit.position)
		assert_equal(['0', '1', '2', '3'], edit.left)
		assert_equal([], edit.right)
	end
	def test_move_end2
		edit = FakeEdit.new(false)
		edit.insert('0')
		edit.insert('1')
		edit.insert('2')
		edit.insert('3')
		assert_equal(4, edit.position)
		assert_raises(CommandHarmless) { edit.move_end } # position has not changed
		assert_equal(4, edit.position)
		assert_equal(['0', '1', '2', '3'], edit.left)
		assert_equal([], edit.right)
	end
	def test_move_end3
		edit = FakeEdit.new(false, true)
		edit.insert('0')
		edit.insert('1')
		edit.move_right
		edit.move_right
		assert_equal(4, edit.position)
		edit.move_end  # change position
		assert_equal(2, edit.position)
		assert_equal(['0', '1'], edit.left)
		assert_equal([edit.vspace], edit.right)
	end
	def test_force_range1
		edit = FakeEdit.new(false)
		('0'..'5').each { |i| edit.insert(i) }
		edit.move_home
		edit.move_right
		assert_equal(1, edit.position)
		edit.force_range(0, 4)   # position is within range => nothing happens
		assert_equal(1, edit.position)
		# "0"+"123" is inside the view.. thus visible
		assert_equal(%w(0), edit.left)
		# "45" is outside the view...... thus hidden
		assert_equal(%w(1 2 3 4 5), edit.right)
	end
	def test_force_range2
		edit = FakeEdit.new(false)
		('0'..'5').each { |i| edit.insert(i) }
		assert_equal(6, edit.position)
		edit.force_range(0, 4)  # position is outside range => adjust position
		assert_equal(3, edit.position)
		# "012"+"3" is inside the view.. thus visible
		assert_equal(%w(0 1 2), edit.left)
		# "45" is outside the view...... thus hidden
		assert_equal(%w(3 4 5), edit.right) 
	end
	def test_force_range3
		edit = FakeEdit.new(false)
		('0'..'5').each { |i| edit.insert(i) }
		edit.move_home
		assert_equal(0, edit.position)
		edit.force_range(3, 4)  # position is outside range => adjust position
		assert_equal(3, edit.position)
		# "012"  is outside the view.. thus hidden
		assert_equal(%w(0 1 2), edit.left)
		# "345" is inside the view.... thus visible
		assert_equal(%w(3 4 5), edit.right)
	end
	def test_measure_bytes1
		edit = FakeEdit.new
		edit.insert('0')
		edit.insert('1')
		assert_equal(2, edit.left_bytes)
		assert_equal(0, edit.right_bytes)
		edit.move_home
		assert_equal(0, edit.left_bytes)
		assert_equal(2, edit.right_bytes)
	end
	def test_measure_bytes2
		edit = FakeEdit.new
		edit.insert('0')
		edit.insert('1')
		assert_equal(2, edit.left_bytes)
		assert_equal(0, edit.right_bytes)
		edit.move_left
		edit.backspace
		assert_equal(0, edit.left_bytes)
		assert_equal(1, edit.right_bytes)
	end
	def test_measure_bytes3
		edit = FakeEdit.new(true)
		edit.insert('a')
		edit.insert(t1 = Tab.new)
		edit.insert('b')
		assert_equal(5, edit.x)
		edit.move_left
		edit.move_left
		# see if we can get the 'bytes' correct 
		# if we are in cursor-through-tabs-mode
		assert_equal(1, edit.x)
		assert_equal(3, edit.position)
		assert_equal(1, edit.left_bytes)
		assert_equal(2, edit.right_bytes)
		edit.backspace
		assert_equal(2, edit.left_bytes)
		assert_equal(2, edit.right_bytes)
		assert_equal(2, edit.x)
		assert_equal(['a', ' '], edit.left)
		assert_equal([' ', 'b'], edit.right)
	end
	def test_measure_newline1
		edit = FakeEdit2.new
		bo = Convert.from_string_into_bufferobjs("01\n23\n45\n67")
		fold = LineObjects::Fold.new(bo, "{3}", false)
		lo1 = Convert.from_string_into_lineobjs("a")
		lo2 = Convert.from_string_into_lineobjs("b")
		edit.replace_content(lo1 + [fold] + lo2)
		assert_equal(0, edit.position)
		assert_equal(0, edit.left_bytes)
		assert_equal(0, edit.left_physical_lines)
		assert_equal(13, edit.right_bytes)
		assert_equal(3, edit.right_physical_lines)
		edit.move_right
		edit.move_right
		assert_equal(12, edit.left_bytes)
		assert_equal(3, edit.left_physical_lines)
		assert_equal(1, edit.right_bytes)
		assert_equal(0, edit.right_physical_lines)
	end
	def test_notify_scope1
		edit = FakeEdit.new
		assert_equal(0, edit.notify_lock)
		assert_raises(RuntimeError) do
			edit.notify_scope do
				raise "test"
			end
		end
		assert_equal(0, edit.notify_lock)  # see if mutex has been restored
	end
	def test_notify_optimal1
		# 'move_left' should *only* tell 
		# that the cursor has changed
		edit = FakeEdit.new
		edit.insert('a')
		edit.add_observer(watcher = FakeEditWatcher.new)
		edit.notify_scope { edit.move_left }
		assert_equal([true], watcher.cursor)
		assert_equal([false], watcher.content)
	end
	def test_notify_optimal2
		# 'move_left' through tabs should *only* tell 
		# than the cursor has changed
		edit = FakeEdit.new(true)
		edit.insert('a')
		edit.insert(Tab.new)
		edit.insert('b')
		edit.move_left  
		edit.add_observer(watcher = FakeEditWatcher.new)
		edit.notify_scope { edit.move_left } # notify from Edit.. position has changed
		assert_equal([true], watcher.cursor)
		assert_equal([false], watcher.content) 
	end
	def test_notify_correct1
		# 'move_left' through tabs should tell 
		# than the cursor has changed
		edit = FakeEdit.new(true)
		edit.insert('a')
		edit.insert(Tab.new)
		edit.move_left  
		edit.add_observer(watcher = FakeEditWatcher.new)
		edit.notify_scope { edit.move_left }  # notify from Edit.. position has changed
		# move_left == (change position within tab)
		assert_equal([true], watcher.cursor) 
		assert_equal([false], watcher.content) 
	end
	def test_notify_correct2
		# 'move_right' through vspace should tell 
		# than the cursor has changed
		edit = FakeEdit.new(false, true)
		edit.insert('a')
		edit.insert('b')
		edit.move_right  
		edit.add_observer(watcher = FakeEditWatcher.new)
		edit.notify_scope { edit.move_right } # notify from Edit.. position has changed
		# move_right == (change position within vspace)
		assert_equal([true], watcher.cursor) 
		assert_equal([false], watcher.content)
	end
	def test_split_tab1
		edit = FakeEdit.new(true)
		edit.insert('a')
		edit.insert(Tab.new)
		edit.insert('b')
		edit.move_left
		edit.move_left
		edit.split
		assert_equal(1, edit.position)
		# this is supposed to NOT result in any spaces
		assert_equal(['a'], edit.left)
		assert_equal(nil, edit.current)
		assert_equal([' ', 'b'], edit.right)
	end
	def test_split_vspace1
		edit = FakeEdit.new(false, true)
		edit.insert('a')
		edit.insert('b')
		edit.move_right
		edit.move_right
		edit.split
		assert_equal(2, edit.position)
		# this is supposed to NOT result in any spaces
		assert_equal(['a', 'b'], edit.left)
		assert_equal(nil, edit.current)
		assert_equal([edit.vspace], edit.right)
	end
	def test_split_seperator1
		edit = FakeEdit.new
		edit.insert('a')
		edit.insert('b')
		edit.move_left
		edit.split
		assert_equal(1, edit.position)
		assert_equal(['a'], edit.left)
		assert_equal(nil, edit.current)
		assert_equal(['b'], edit.right)
	end
	def test_create_memento1
		edit = FakeEdit.new
		assert_equal([0, []], edit.create_memento)
	end
	def test_create_memento2
		edit = FakeEdit.new
		edit.push_left('a')
		edit.push_right('c')
		edit.set_current('b')
		assert_equal([1, ['a', 'b', 'c']], edit.create_memento)
	end
	def test_create_memento3
		edit = FakeEdit.new(false, true)
		edit.push_left('a')
		edit.move_right  # vspace
		x, data = edit.create_memento
		assert_equal(2, x)
		# we must not see any VSpace within 'data'
		assert_equal(['a'], data)  
	end
	def test_create_memento4
		edit = FakeEdit.new(false, true)
		edit.push_left('a')
		edit.move_right  # vspace
		x, data = edit.create_memento
		edit.move_right  # vspace
		assert_equal(2, x)
		# we must not see any VSpace within 'data'
		assert_equal(['a'], data)  

		# I experienced a really ugly situation where
		# Edit#create_memento, executed code like this:
		#### objs = @left
		#### objs << @current if @current
		# Appending @current to @left because of references,
		# leaving @left clobbered up and wasted.
		#
		# with this test case we want to ensure that edit.left
		# stays untouched (readonly)
		assert_equal(['a'], edit.left)  
	end
	def test_set_memento1
		edit = FakeEdit.new
		edit.set_memento([1, ['a', 'b', 'c']])
		assert_equal(1, edit.position)
		assert_equal(1, edit.left_bytes)
		assert_equal(2, edit.right_bytes)
	end
	def test_set_memento2
		edit = FakeEdit.new(false, true)
		edit.set_memento([5, ['a', 'b', 'c']])
		assert_equal(3, edit.x)
		assert_equal(5, edit.position)
		assert_equal(3, edit.left_bytes)
		assert_equal(0, edit.right_bytes)
	end
	def test_set_memento3
		edit = FakeEdit.new
		edit.set_memento([2, ['a', 'b', 'c', 'd']])
		assert_equal(2, edit.position)
		assert_equal(2, edit.left_bytes)
		assert_equal(2, edit.right_bytes)
	end
	def test_only_spaces1
		edit = FakeEdit2.new(false)
		lo = Convert.from_string_into_lineobjs("\t \t ")
		edit.set_memento([2, lo])
		assert_equal(true, edit.only_spaces?)
	end
	def test_only_spaces2
		edit = FakeEdit2.new(false)
		lo = Convert.from_string_into_lineobjs("\t \t a")
		edit.set_memento([2, lo])
		assert_equal(false, edit.only_spaces?)
	end
	def test_only_spaces3
		edit = FakeEdit2.new(false)
		lo = Convert.from_string_into_lineobjs("a")
		edit.set_memento([0, lo])
		assert_equal(false, edit.only_spaces?)
	end
	def test_unlink_fold1
		bof = Convert::from_string_into_bufferobjs("x\ny\nz")
		fold = LineObjects::Fold.new(bof, "{2}", false)
		lo = Convert.from_string_into_lineobjs("ab")
		lo[1, 0] = fold
		edit = FakeEdit2.new(false)
		edit.set_memento([1, lo])
		assert_equal(1, edit.position)
		assert_equal(1, edit.left_bytes)
		assert_equal(6, edit.right_bytes)
		fold = edit.unlink_fold!
		assert_kind_of(LineObjects::Fold, fold)
		assert_equal(1, edit.right_bytes)
	end
	def test_unlink_fold2
		lo = Convert.from_string_into_lineobjs("ab")
		edit = FakeEdit2.new(false)
		edit.set_memento([1, lo])
		# there no fold to expand.. therefore exception
		assert_raises(RuntimeError) { edit.unlink_fold! }
	end
	def assert_fold_width(n, title, width)
		assert_equal(width, title.length)
		s = ('a'..('a'[0]+n).chr).to_a.join('\n')
		bof = Convert::from_string_into_bufferobjs(s)
		fold = LineObjects::Fold.new(bof, title, false)
		lo = Convert.from_string_into_lineobjs("ab")
		lo[1, 0] = fold
		edit = FakeEdit2.new(false)
		edit.set_memento([1, lo])
		assert_equal(1, edit.x)
		# this is the interesting part:  see if Edit
		# is aware of the correct width of the fold
		edit.move_right  
		assert_equal(1+width, edit.x)
	end
	def test_fold_width1
		assert_fold_width(7, "{7}", 3)
	end
	def test_fold_width2
		assert_fold_width(17, "{17}", 4)
	end
	def test_fold_width3
		assert_fold_width(2, "== 2 == title ==", 16)
	end
	def test_scan1
		lo = Convert.from_string_into_lineobjs(expect = "abcdefgh")
		edit = FakeEdit2.new(false)
		edit.set_memento([6, lo])
		assert_equal(6, edit.x)
		res = ""
		edit.scan_right{|lo| res << lo.ascii_value.chr}
		assert_equal(expect, res)
		assert_equal(res.length, edit.x)
	end
	def test_scan2
		lo = Convert.from_string_into_lineobjs("abcdefgh")
		edit = FakeEdit2.new(false)
		edit.set_memento([6, lo])
		assert_equal(6, edit.x)
		res = ""
		edit.scan_right{|lo| 
			break if lo.ascii_value.chr == "e"
			res << lo.ascii_value.chr
		}
		assert_equal("abcd", res)
		assert_equal(4, edit.x)
	end
	# todo:
	# * notify emitted from 'force_range'
end

TestEdit.run if $0 == __FILE__
