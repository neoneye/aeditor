require 'test/unit'
require 'aeditor/editor'
require 'iterator'

class TestEdit < Test::Unit::TestCase
	class Model < Iterator::Collection
		def insert_before(text)
			@data[@position, 0] = text
			@position += 1
		end
		def insert_after(text)
			@data[@position, 0] = text
		end
		def erase_after
			@data.slice!(@position, 1)
		end
		def erase_before
			unless has_prev?
				raise 'cannot erase before begining'
			end
			@position -= 1
			@data.slice!(@position, 1)
		end
	end
	def setup
		@model = []
		@model_iterator = Model.new(@model)
		@edit = Editor.new(@model_iterator)
	end
	def insert(text)
		text.split(//).each {|char| @edit.do_insert(char)} 
	end
	def enable_cursor_through_tabs
		@edit.use_cursor_through_tabs_strategy(true)
	end
	def enable_virtual_space
		@edit.use_virtual_space_strategy(true)
	end
	def test_insert_via_seperator1
		ary_x = [@edit.x]
		ary_return = []
		"\ta\tab\tx".split(//).each do |char|
			ary_return << @edit.do_insert(char)
			ary_x << @edit.x
		end
		assert_equal([0, 8, 9, 16, 17, 18, 24, 25], ary_x)
		assert_equal("\ta\tab\tx", @model.join)
		assert_equal([true]*7, ary_return)
	end
	def test_moveleft_via_seperator1
		insert("ab\t\tcde")
		ary_x = [@edit.x]
		ary_return = []
		7.times do
			ary_return << @edit.do_move_left
			ary_x.unshift(@edit.x)
		end
		assert_equal([0, 1, 2, 8, 16, 17, 18, 19], ary_x)
		assert_equal([true]*7, ary_return)
	end
	def test_moveleft_false1
		assert_equal(false, @edit.move_left)
		assert_equal(false, @edit.move_right)
	end
	def test_moveright_via_seperator1
		insert("ab\tcde\t")
		@edit.do_move_begin
		ary_x = [@edit.x]
		ary_return = []
		7.times do
			ary_return << @edit.do_move_right
			ary_x << @edit.x
		end
		assert_equal([0, 1, 2, 8, 9, 10, 11, 16], ary_x)
		assert_equal([true]*7, ary_return)
	end
	def test_movebegin1
		assert_equal(false, @model_iterator.has_prev?)
		assert_equal(false, @model_iterator.has_next?)
		insert("def")
		@edit.do_move_begin
		assert_equal(0, @edit.x)
		assert_equal(false, @model_iterator.has_prev?)
		assert_equal(true, @model_iterator.has_next?)
		insert("abc")
		assert_equal(3, @edit.x)
		assert_equal(true, @model_iterator.has_prev?)
		assert_equal(true, @model_iterator.has_next?)
		@edit.do_move_begin
		assert_equal(0, @edit.x)
		assert_equal(false, @model_iterator.has_prev?)
		assert_equal(true, @model_iterator.has_next?)
		assert_equal("abcdef", @model.join)
	end
	def test_moveend1
		insert("def")
		@edit.do_move_begin
		assert_equal(false, @model_iterator.has_prev?)
		assert_equal(true, @model_iterator.has_next?)
		assert_equal(0, @edit.x)
		insert("abc")
		assert_equal(3, @edit.x)
		@edit.do_move_end
		assert_equal(6, @edit.x)
		assert_equal(true, @model_iterator.has_prev?)
		assert_equal(false, @model_iterator.has_next?)
	end
	def test_moveend2
		insert("\tabc\tdef")
		@edit.do_move_begin
		@edit.do_move_end
		ary_x = [@edit.x]
		ary_return = []
		8.times do
			ary_return << @edit.do_move_left
			ary_x.unshift(@edit.x)
		end
		assert_equal([0, 8, 9, 10, 11, 16, 17, 18, 19], ary_x)
		assert_equal([true]*8, ary_return)
	end
	def test_backspace1
		insert("abc\txz")
		assert_equal(10, @edit.cursor_x)
		@edit.do_move_left
		assert_equal(9, @edit.cursor_x)
		assert_equal(true, @edit.do_backspace)
		assert_equal(8, @edit.cursor_x)
		assert_equal(true, @edit.do_backspace)
		assert_equal(3, @edit.cursor_x)
		assert_equal("abcz", @model.join)
	end
	def test_backspace2
		assert_equal(false, @edit.do_backspace)
	end
	def test_through_tabs_moveleft1
		enable_cursor_through_tabs
		insert("a\tb")
		ary_x = [@edit.cursor_x]
		ary_return = []
		ary_pos = [@model_iterator.position]
		10.times do
			ary_return << @edit.do_move_left
			ary_x.unshift(@edit.cursor_x)
			ary_pos.unshift(@model_iterator.position)
		end
		assert_equal([0] + (0..9).to_a, ary_x)
		assert_equal(([true]*9) + [false], ary_return)
		assert_equal([0, 0, 1, 1, 1, 1, 1, 1, 1, 2, 3], ary_pos)
	end
	def test_through_tabs_moveright1
		enable_cursor_through_tabs
		insert("a\tb")
		@edit.do_move_begin
		ary_x = [@edit.cursor_x]
		ary_return = []
		ary_pos = [@model_iterator.position]
		10.times do
			ary_return << @edit.do_move_right
			ary_x << @edit.cursor_x
			ary_pos << @model_iterator.position
		end
		assert_equal((0..9).to_a + [9], ary_x)
		assert_equal(([true]*9) + [false], ary_return)
		assert_equal([0, 1, 1, 1, 1, 1, 1, 1, 2, 3, 3], ary_pos)
	end
	def generic_through_tabs_insert(insert_str, times_right, expected)
		enable_cursor_through_tabs
		@edit.set_tabsize(4)
		insert(insert_str)
		@edit.do_move_begin
		times_right.times { @edit.do_move_right }
		assert_equal(times_right, @edit.cursor_x)
		insert("x")
		assert_equal(times_right+1, @edit.cursor_x)
		assert_equal(expected, @model.join)
	end
	def test_through_tabs_insert_middle1 
		generic_through_tabs_insert("\tz", 1, " x   z")
	end
	def test_through_tabs_insert_middle2
		generic_through_tabs_insert("a\tz", 2, "a x  z")
	end
	def test_through_tabs_insert_middle3
		generic_through_tabs_insert("ab\tz", 3, "ab x z")
	end
	def test_through_tabs_insert_begin1
		generic_through_tabs_insert("a\tz", 1, "ax\tz")
	end
	def test_through_tabs_insert_begin2
		generic_through_tabs_insert("abc\tz", 3, "abcx\tz")
	end
	def test_through_tabs_insert_end1
		generic_through_tabs_insert("a\tz", 4, "a\txz")
	end
	def generic_through_tabs_backspace(insert_str, times_left, expected)
		enable_cursor_through_tabs
		@edit.set_tabsize(6)
		insert(insert_str)
		times_left.times { @edit.do_move_left }
		assert_equal(true, @edit.do_backspace)
		insert('x')
		assert_equal(expected, @model.join)
	end
	def test_through_tabs_backspace1 
		generic_through_tabs_backspace("ab\tcd", 2, "abxcd")
	end
	def test_through_tabs_backspace2 
		generic_through_tabs_backspace("ab\tcd", 3, "ab  x cd")
	end
	def test_through_tabs_backspace3 
		generic_through_tabs_backspace("ab\tcd", 4, "ab x  cd")
	end
	def test_through_tabs_backspace4 
		generic_through_tabs_backspace("ab\tcd", 5, "abx   cd")
	end
	def test_through_tabs_backspace5 
		generic_through_tabs_backspace("ab\tcd", 6, "ax\tcd")
	end
	def test_through_tabs_backspace20
		enable_cursor_through_tabs
		@edit.set_tabsize(2)
		insert("\t")
		@edit.do_move_left
		assert_equal(1, @edit.cursor_x)
		assert_equal(true, @edit.do_backspace)
		assert_equal(" ", @model.join)
		assert_equal(0, @edit.cursor_x)
		assert_equal(false, @edit.do_backspace)
		assert_equal(" ", @model.join)
	end
	def generic_through_tabs_split(
		times_left, expected_cursor_x, 
		expected_model_x_before, expected_model_x_after, 
		expected_str)
		enable_cursor_through_tabs
		@edit.set_tabsize(4)
		insert("\t")
		times_left.times { @edit.do_move_left }
		assert_equal(expected_model_x_before, @model_iterator.position)
		assert_equal(expected_cursor_x, @edit.cursor_x)
		@edit.do_split
		assert_equal(expected_model_x_after, @model_iterator.position)
		assert_equal(expected_cursor_x, @edit.cursor_x)
		@edit.do_insert('x')
		assert_equal(expected_str, @model.join)
	end
	def test_through_tabs_split0
		generic_through_tabs_split(0, 4, 1, 1, "\tx")
	end
	def test_through_tabs_split1
		generic_through_tabs_split(1, 3, 0, 3, "   x ")
	end
	def test_through_tabs_split2
		generic_through_tabs_split(2, 2, 0, 2, "  x  ")
	end
	def test_through_tabs_split3
		generic_through_tabs_split(3, 1, 0, 1, " x   ")
	end
	def test_through_tabs_split4
		generic_through_tabs_split(4, 0, 0, 0, "x\t")
	end
	def test_through_tabs_split20
		enable_cursor_through_tabs
		@edit.set_tabsize(4)
		insert("\t")
		@edit.do_move_left
		assert_equal(0, @model_iterator.position)
		assert_equal(3, @edit.cursor_x)
		@edit.do_split
		assert_equal(3, @model_iterator.position)
		assert_equal(3, @edit.cursor_x)
		@edit.do_insert('x')
		assert_equal("   x ", @model.join)
	end
	def test_vspace_moveright1
		enable_virtual_space
		assert_equal(true, @edit.do_move_right)
		assert_equal(1, @edit.cursor_x)
		assert_equal(true, @edit.do_move_right)
		assert_equal(2, @edit.cursor_x)
		assert_equal(0, @model_iterator.position)
		insert('xyz')
		assert_equal('  xyz', @model.join)
		assert_equal(5, @model_iterator.position)
		assert_equal(5, @edit.cursor_x)
	end
	def test_vspace_moveright2
		enable_virtual_space
		insert('abc')
		@edit.do_move_begin
		@edit.do_move_end
		assert_equal(3, @edit.cursor_x)
	end
	def test_vspace_moveright3
		enable_virtual_space
		insert('abc')
		@edit.do_move_begin
		ary_x = [@edit.cursor_x]
		ary_modelx = [@model_iterator.position]
		ary_return = []
		6.times do 
			ary_return << @edit.do_move_right
			ary_x << @edit.cursor_x
			ary_modelx << @model_iterator.position
		end
		assert_equal((0..6).to_a, ary_x)
		assert_equal([0, 1, 2, 3, 3, 3, 3], ary_modelx)
		assert_equal([true]*6, ary_return)
	end
	def test_vspace_moveright4
		enable_virtual_space
		enable_cursor_through_tabs
		@edit.set_tabsize(4)
		insert("\t\tabcd")
		@edit.do_move_end
		assert_equal(12, @edit.cursor_x)
		@edit.do_move_right
		assert_kind_of(EditStrategies::VirtualSpace, @edit.strategy)
		@edit.do_move_right
		assert_equal(14, @edit.cursor_x)
		@edit.do_move_right
		assert_equal(15, @edit.cursor_x)
	end
	def test_vspace_moveleft1
		enable_virtual_space
		insert('abc')
		2.times { @edit.do_move_right }
		assert_equal(5, @edit.cursor_x)
		assert_equal(3, @model_iterator.position)
		assert_equal(true, @edit.do_move_left)
		assert_equal(4, @edit.cursor_x)
		assert_equal(true, @edit.do_move_left)
		assert_equal(3, @edit.cursor_x)
		assert_equal(true, @edit.do_move_left)
		assert_equal(2, @edit.cursor_x)
	end
	def test_vspace_moveleft2
		enable_virtual_space
		assert_equal(true, @edit.do_move_right)
		assert_equal(1, @edit.cursor_x)
		assert_equal(true, @edit.do_move_left)
		assert_equal(0, @edit.cursor_x)
		assert_equal(false, @edit.do_move_left)
		assert_equal(0, @edit.cursor_x)
	end
	def test_vspace_moveleft3
		enable_virtual_space
		assert_equal(true, @edit.do_move_right)
		assert_equal(true, @edit.do_backspace)
		assert_equal(false, @edit.do_backspace)
	end
	def test_vspace_moveleft3
		enable_virtual_space
		insert('abc')
		3.times { @edit.do_move_right }
		assert_equal(6, @edit.cursor_x)
		@edit.do_move_end
		assert_equal(3, @edit.cursor_x)
		assert_equal(3, @model_iterator.position)
	end
	def test_vspace_split1
		enable_virtual_space
		insert('abc')
		3.times { @edit.do_move_right }
		assert_equal(3, @model_iterator.position)
		@edit.do_split
		assert_equal(3, @model_iterator.position)
		assert_equal("abc", @model.join)
		@edit.do_insert('x')
		assert_equal("abc   x", @model.join)
	end
end
