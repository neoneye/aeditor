require 'test/unit'
require 'lineedit'

class TestLineEdit < Test::Unit::TestCase
	def setup
		@edit = LineEdit.new
	end
	def test_insert_typical1
		@edit.insert('a')
		assert_equal('a', @edit.text)
		@edit.insert('b')
		assert_equal('ab', @edit.text)
	end
	def test_insert_error1
		assert_raise(TypeError) { @edit.insert(5) }
	end
	def test_insert_utf8_error1
		assert_raise(ArgumentError) { @edit.insert("\xff") }
	end
	def test_erase_left_typical1
		@edit.insert('abc')
		assert_equal('c', @edit.erase_left)
		assert_equal('ab', @edit.text)
		assert_equal('b', @edit.erase_left)
		assert_equal('a', @edit.text)
		assert_equal('a', @edit.erase_left)
		assert_equal('', @edit.text)
		assert_equal(nil, @edit.erase_left)
		assert_equal('', @edit.text)
	end
	def test_erase_left_typical2
		@edit.insert("\341\210\264\342\215\205")
		assert_equal("\342\215\205", @edit.erase_left)
		assert_equal("\341\210\264", @edit.text)
		assert_equal("\341\210\264", @edit.erase_left)
		assert_equal('', @edit.text)
	end
	def lr
		[@edit.text_left, @edit.text_right]
	end
	def test_move_left_typical1
		@edit.insert('abc')
		@edit.move_left
		assert_equal(%w(ab c), lr)
		@edit.move_left
		assert_equal(%w(a bc), lr)
		@edit.move_left
		assert_equal(['', 'abc'], lr)
	end
	def test_move_home_end1
		@edit.insert('abc')
		@edit.move_home
		assert_equal(['', 'abc'], lr)
		@edit.move_end
		assert_equal(['abc', ''], lr)
	end
	def test_move_right_typical1
		@edit.insert('abc')
		@edit.move_home
		@edit.move_right
		assert_equal(%w(a bc), lr)
	end
end