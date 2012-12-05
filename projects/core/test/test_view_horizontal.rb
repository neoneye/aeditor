require 'aeditor/backend/view_horizontal'
require 'common'

class FakeHorzView
	include HorizontalView
	def initialize(width, x=0)
		init_render(width, x)
	end
end

class TestViewHorizontal < Common::TestCase 
	def test_render1
		buf = FakeHorzView.new(5, 0)
		line = ('a'..'n').to_a
		assert_equal(%w(a b c d e), buf.visible_part(line))
	end
	def test_render2
		buf = FakeHorzView.new(5, 3)
		line = ('a'..'n').to_a
		assert_equal(%w(d e f g h), buf.visible_part(line))
	end
	def test_render3
		buf = FakeHorzView.new(5, 3)
		line = ('a'..'f').to_a
		assert_equal(%w(d e f), buf.visible_part(line))
	end
	def test_render4
		buf = FakeHorzView.new(5, 4)
		line = %w(a b c)
		assert_equal([], buf.visible_part(line))
	end
	def test_render5
		buf = FakeHorzView.new(5, 3)
		line = []
		assert_equal([], buf.visible_part(line))
	end
	def test_data_right1
		buf = FakeHorzView.new(5, 3)
		line = ('a'..'i').to_a
		assert_equal(true, buf.data_right?(line))
	end
	def test_data_right2
		buf = FakeHorzView.new(5, 3)
		line = ('a'..'h').to_a
		assert_equal(false, buf.data_right?(line))
	end
	def test_data_right3
		buf = FakeHorzView.new(5, 3)
		line = ('a'..'f').to_a
		assert_equal(false, buf.data_right?(line))
	end
	def test_data_left1
		buf = FakeHorzView.new(5, 4)
		line = ('a'..'c').to_a
		assert_equal(true, buf.data_left?(line))
	end
	def test_data_left2
		buf = FakeHorzView.new(5, 4)
		line = []
		assert_equal(false, buf.data_left?(line))
	end
	def test_data_left3
		buf = FakeHorzView.new(5, 0)
		line = %w(a b c)
		assert_equal(false, buf.data_left?(line))
	end
#	def test_data_left4
#		buf = FakeHorzView.new(5, 2)
#		line = [' ', ' '] + %w(a b c)
#		assert_equal(false, buf.data_left?(line))
#	end
	def test_data_left5
		buf = FakeHorzView.new(5, 3)
		line = [' ', ' '] + %w(a b c)
		assert_equal(true, buf.data_left?(line))
	end
	def test_scroll_left1
		buf = FakeHorzView.new(5, 0)
		assert_raises(BufferLeft) { buf.scroll_left }
	end
	def test_scroll_left2
		buf = FakeHorzView.new(5, 3)
		buf.scroll_left
		line = ('a'..'n').to_a
		assert_equal(%w(c d e f g), buf.visible_part(line))
	end
	def test_scroll_right1
		buf = FakeHorzView.new(5, 3)
		buf.scroll_right
		line = ('a'..'n').to_a
		assert_equal(%w(e f g h i), buf.visible_part(line))
	end
	def test_refocus1
		buf = FakeHorzView.new(3, 2)
		buf.refocus_x(4) # results in nothing
		line = ('a'..'n').to_a
		assert_equal(%w(c d e), buf.visible_part(line))
	end
	def test_refocus2
		buf = FakeHorzView.new(3, 2)
		buf.refocus_x(1) # equaly to 1x scroll_left
		line = ('a'..'n').to_a
		assert_equal(%w(b c d), buf.visible_part(line))
	end
	def test_refocus3
		buf = FakeHorzView.new(3, 2)
		buf.refocus_x(5) # equaly to 1x scroll_right
		line = ('a'..'n').to_a
		assert_equal(%w(d e f), buf.visible_part(line))
	end
	def test_refocus4
		buf = FakeHorzView.new(3, 2)
		buf.refocus_x(0) # equaly to 2x scroll_left
		line = ('a'..'n').to_a
		assert_equal(%w(a b c), buf.visible_part(line))
	end
	def test_refocus5
		buf = FakeHorzView.new(3, 2)
		buf.refocus_x(6) # equaly to 2x scroll_right
		line = ('a'..'n').to_a
		assert_equal(%w(e f g), buf.visible_part(line))
	end
end

class FakeHorzView2
	include HorizontalViewDecorated
	def initialize(width, x=0)
		init_render(width, x)
	end
end

class TestViewHorizontalDecorated < Common::TestCase 
	def test_render1
		buf = FakeHorzView2.new(5, 0)
		line = "abcdefg".to_cells
		res = buf.visible_part(line)
		assert_equal("abcd>", res.to_s)
	end
	def test_render2
		buf = FakeHorzView2.new(5, 1)
		line = "abcdefg".to_cells
		res = buf.visible_part(line)
		assert_equal("<cde>", res.to_s)
	end
	def test_render3
		buf = FakeHorzView2.new(5, 2)
		line = "abcdefg".to_cells
		res = buf.visible_part(line)
		assert_equal("<defg", res.to_s)
	end
	def test_render4
		buf = FakeHorzView2.new(5, 3)
		line = "abcdefg".to_cells
		res = buf.visible_part(line)
		assert_equal("<efg.", res.to_s)
	end
	def test_render5
		buf = FakeHorzView2.new(5, 4)
		line = "abcdefg".to_cells
		res = buf.visible_part(line)
		assert_equal("<fg.", res.to_s)
	end
	def test_render6
		buf = FakeHorzView2.new(5, 6)
		line = "abcdefg".to_cells
		res = buf.visible_part(line)  
		assert_equal("<.", res.to_s)  
		# this output is nasty !  can it be improved ?
		# perhaps either "<" or "." is better ?
	end                             
	def test_render7
		buf = FakeHorzView2.new(5, 0)
		line = []
		res = buf.visible_part(line)
		assert_equal(".", res.to_s)
	end                             
	def test_render8
		buf = FakeHorzView2.new(5, 2)
		line = "  abcdefg".to_cells
		res = buf.visible_part(line)
		assert_equal("abcd>", res.to_s) # no arrow because of indent
	end                             
	def test_render9
		buf = FakeHorzView2.new(5, 7)
		line = "abcdefg".to_cells
		res = buf.visible_part(line)
		assert_equal("", res.to_s) # don't show any dot here!
	end                             
	def test_render10
		buf = FakeHorzView2.new(5, 3)
		line = []
		res = buf.visible_part(line)
		assert_equal("", res.to_s) # don't show any dot here!
	end                             
	def test_data_left1
		buf = FakeHorzView2.new(5, 0)
		line = "abc".to_cells
		assert_equal(false, buf.data_left?(line))
	end
	def test_data_left2
		buf = FakeHorzView2.new(5, 1)
		line = "abc".to_cells
		assert_equal(true, buf.data_left?(line))
	end
	def test_data_left_indent1
		buf = FakeHorzView2.new(5, 1)
		line = " abc".to_cells
		assert_equal(false, buf.data_left?(line))
	end
	def test_data_left_indent2
		buf = FakeHorzView2.new(5, 2)
		line = " abc".to_cells
		assert_equal(true, buf.data_left?(line))
	end
	def test_data_left_indent3
		buf = FakeHorzView2.new(5, 2)
		line = "  a  bc".to_cells
		assert_equal(false, buf.data_left?(line))
	end
	def test_data_left_indent4
		buf = FakeHorzView2.new(5, 3)
		line = "  a  bc".to_cells
		assert_equal(true, buf.data_left?(line))
	end
	def test_data_left_indent5
		buf = FakeHorzView2.new(5, 4)
		line = "  a  bc".to_cells
		assert_equal(true, buf.data_left?(line))
	end
end

if $0 == __FILE__
	TestViewHorizontal.run
	TestViewHorizontalDecorated.run
end
