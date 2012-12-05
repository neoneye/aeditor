require 'aeditor/backend/buffer_vertical'
require 'common'

class FakeVertBuffer
	include BufferVertical
	def initialize(buf_top, line_top, current, line_bottom, buf_bottom)
		@current = current
		@line_top = line_top
		@line_bottom = line_bottom
		@buf_top = buf_top
		@buf_bottom = buf_bottom
	end
	def FakeVertBuffer.create(top, cur, bottom)
		FakeVertBuffer.new(nil, top, cur, bottom, nil)
	end
	attr_reader :current, :line_top, :line_bottom, :buf_top, :buf_bottom
	def replace_current_line(line)
		old = @current
		@current = line
		old
	end
	def line_export_top(line)
		return if line == nil
		@buf_top.push(line)
	end
	def line_export_bottom(line)
		return if line == nil
		@buf_bottom.unshift(line)
	end
	def line_import_top 
		raise BufferTop if @buf_top.empty?
		@buf_top.pop
	end
	def line_import_bottom
		raise BufferBottom if @buf_bottom.empty?
		@buf_bottom.shift
	end
	def import_top
		@line_top.unshift(line_import_top)
	end
	def import_bottom(allow_empty_lines=true)
		begin
			@line_bottom.push(line_import_bottom)
		rescue BufferBottom
			raise unless allow_empty_lines 
			@line_bottom.push(nil)
		end
	end
	def export_top
		raise CannotExport if @line_top.empty?
		line_export_top(@line_top.shift)
	end
	def export_bottom
		raise CannotExport if @line_bottom.empty?
		line_export_bottom(@line_bottom.pop)
	end
	def top_empty?
		@buf_top.empty?
	end
	def bottom_empty?
		@buf_bottom.empty?
	end
	# determine if we are on the *last* line in the buffer
	def is_last_line?
		not @line_bottom.any?
	end
end

class TestBufferVert < Common::TestCase 
	def test_oneliner_change_above1
		buf = FakeVertBuffer.new(%w(a b), [], 'c', [], %w(d))
		assert_equal(true, buf.scroll_up)
		assert_equal(%w(a), buf.buf_top)
		assert_equal([], buf.line_top)
		assert_equal('b', buf.current)
		assert_equal([], buf.line_bottom)
		assert_equal(%w(c d), buf.buf_bottom)
	end
	def test_oneliner_change_below1
		buf = FakeVertBuffer.new(%w(a), [], 'b', [], %w(c d))
		assert_equal(true, buf.scroll_down)
		assert_equal(%w(a b), buf.buf_top)
		assert_equal([], buf.line_top)
		assert_equal('c', buf.current)
		assert_equal([], buf.line_bottom)
		assert_equal(%w(d), buf.buf_bottom)
	end
	def test_oneliner_move_up1
		buf = FakeVertBuffer.new(%w(a b), [], 'c', [], %w(d))
		buf.move_up # oneline is abnormal
		assert_equal(%w(a), buf.buf_top)
		assert_equal([], buf.line_top)
		assert_equal('b', buf.current)
		assert_equal([], buf.line_bottom)
		assert_equal(%w(c d), buf.buf_bottom)
	end
	def test_oneliner_move_down1
		buf = FakeVertBuffer.new(%w(a), [], 'b', [], %w(c d))
		buf.move_down # oneline is abnormal
		assert_equal(%w(a b), buf.buf_top)
		assert_equal([], buf.line_top)
		assert_equal('c', buf.current)
		assert_equal([], buf.line_bottom)
		assert_equal(%w(d), buf.buf_bottom)
	end
	def test_oneliner_move_page_up1
		buf = FakeVertBuffer.new(%w(a b), [], 'c', [], %w(d))
		buf.move_page_up # oneline is abnormal => move_up
		assert_equal(%w(a), buf.buf_top)
		assert_equal([], buf.line_top)
		assert_equal('b', buf.current)
		assert_equal([], buf.line_bottom)
		assert_equal(%w(c d), buf.buf_bottom)
	end
	def test_oneliner_move_page_down1
		buf = FakeVertBuffer.new(%w(a), [], 'b', [], %w(c d))
		buf.move_page_down # oneline is abnormal => move_down
		assert_equal(%w(a b), buf.buf_top)
		assert_equal([], buf.line_top)
		assert_equal('c', buf.current)
		assert_equal([], buf.line_bottom)
		assert_equal(%w(d), buf.buf_bottom)
	end
	def test_change_above1
		buf = FakeVertBuffer.create(%w(1 2 3), 'a', %w(b))
		buf.change_focus_to_line_above
		assert_equal(%w(1 2), buf.line_top)
		assert_equal('3', buf.current)
		assert_equal(%w(a b), buf.line_bottom)
	end
	def test_change_below1
		buf = FakeVertBuffer.create(%w(1), '2', %w(3 a b))
		buf.change_focus_to_line_below
		assert_equal(%w(1 2), buf.line_top)
		assert_equal('3', buf.current)
		assert_equal(%w(a b), buf.line_bottom)
	end
	def test_change_below2
		buf = FakeVertBuffer.create(%w(1), '2', [nil])
		assert_raises(BufferBottom) {
			buf.change_focus_to_line_below
		}
		assert_equal(%w(1), buf.line_top)
		assert_equal('2', buf.current)
		assert_equal([nil], buf.line_bottom)
	end
	def test_scroll_up1
		buf = FakeVertBuffer.new(%w(a b), [], 'c', %w(d), %w(e))
		assert_equal(false, buf.scroll_up)
		assert_equal(%w(a), buf.buf_top)
		assert_equal(%w(b), buf.line_top)
		assert_equal('c', buf.current)
		assert_equal([], buf.line_bottom)
		assert_equal(%w(d e), buf.buf_bottom)
	end
	def test_scroll_up2
		buf = FakeVertBuffer.new(%w(a b), %w(c), 'd', [], %w(e))
		assert_equal(true, buf.scroll_up)
		assert_equal(%w(a), buf.buf_top)
		assert_equal(%w(b), buf.line_top)
		assert_equal('c', buf.current)
		assert_equal([], buf.line_bottom)
		assert_equal(%w(d e), buf.buf_bottom)
	end
	def test_scroll_up3
		buf = FakeVertBuffer.new(%w(a b), %w(1 2), 'c', %w(d e), %w(f))
		assert_equal(false, buf.scroll_up)
		assert_equal(%w(a), buf.buf_top)
		assert_equal(%w(b 1 2), buf.line_top)
		assert_equal('c', buf.current)
		assert_equal(%w(d), buf.line_bottom)
		assert_equal(%w(e f), buf.buf_bottom)
	end
	def test_scroll_up4
		buf = FakeVertBuffer.new([], %w(a b), 'c', %w(d), %w(e))
		assert_raises(BufferTop) { buf.scroll_up }
		assert_equal([], buf.buf_top)
		assert_equal(%w(a b), buf.line_top)
		assert_equal('c', buf.current)
		assert_equal(%w(d), buf.line_bottom)
		assert_equal(%w(e), buf.buf_bottom)
	end
	def test_scroll_up5
		buf = FakeVertBuffer.new(%w(a b), %w(c), 'd', %w(e), [])
		assert_equal(true, buf.scroll_up(true))
		assert_equal(%w(a), buf.buf_top)
		assert_equal(%w(b), buf.line_top)
		assert_equal('c', buf.current)
		assert_equal(%w(d), buf.line_bottom)
		assert_equal(%w(e), buf.buf_bottom)
	end
	def test_scroll_down1
		buf = FakeVertBuffer.new(%w(e), %w(d), 'c', [], %w(b a))
		assert_equal(false, buf.scroll_down)
		assert_equal(%w(e d), buf.buf_top)
		assert_equal([], buf.line_top)
		assert_equal('c', buf.current)
		assert_equal(%w(b), buf.line_bottom)
		assert_equal(%w(a), buf.buf_bottom)
	end
	def test_scroll_down2
		buf = FakeVertBuffer.new(%w(d), [], 'c', %w(2 1), %w(b a))
		assert_equal(true, buf.scroll_down)
		assert_equal(%w(d c), buf.buf_top)
		assert_equal([], buf.line_top)
		assert_equal('2', buf.current)
		assert_equal(%w(1 b), buf.line_bottom)
		assert_equal(%w(a), buf.buf_bottom)
	end
	def test_scroll_down3
		buf = FakeVertBuffer.new(%w(e), %w(d), 'c', %w(2 1), %w(b a))
		assert_equal(false, buf.scroll_down)
		assert_equal(%w(e d), buf.buf_top)
		assert_equal([], buf.line_top)
		assert_equal('c', buf.current)
		assert_equal(%w(2 1 b), buf.line_bottom)
		assert_equal(%w(a), buf.buf_bottom)
	end
	def test_scroll_down4
		buf = FakeVertBuffer.new(%w(a), %w(b), 'c', %w(d), %w(e))
		assert_equal(true, buf.scroll_down(true))
		assert_equal(%w(a b), buf.buf_top)
		assert_equal(%w(c), buf.line_top)
		assert_equal('d', buf.current)
		assert_equal(%w(e), buf.line_bottom)
		assert_equal([], buf.buf_bottom)
	end
	def test_scroll_down_nil1
		buf = FakeVertBuffer.new(%w(e), %w(d), 'c', %w(b a), [])
		buf.scroll_down
		assert_equal(%w(e d), buf.buf_top)
		assert_equal([], buf.line_top)
		assert_equal('c', buf.current)
		assert_equal(['b', 'a', nil], buf.line_bottom)
		assert_equal([], buf.buf_bottom)
	end
	def test_scroll_down_nil2
		buf = FakeVertBuffer.new(%w(c), %w(b), 'a', [nil, nil], [])
		buf.scroll_down
		assert_equal(%w(c b), buf.buf_top)
		assert_equal([], buf.line_top)
		assert_equal('a', buf.current)
		assert_equal([nil, nil, nil], buf.line_bottom)
		assert_equal([], buf.buf_bottom)
	end
	def test_scroll_down_nil3
		buf = FakeVertBuffer.new(%w(b), [], 'a', [nil, nil], [])
		assert_raises(BufferBottom) { buf.scroll_down }
		assert_equal(%w(b), buf.buf_top)
		assert_equal([], buf.line_top)
		assert_equal('a', buf.current)
		assert_equal([nil, nil], buf.line_bottom)
		assert_equal([], buf.buf_bottom)
	end
	def test_scroll_down_nil4
		buf = FakeVertBuffer.new(
			[], %w(a), 'b', %w(c d), %w(e))
		buf.scroll_page_down 
		assert_equal(%w(a b c), buf.buf_top)
		assert_equal([], buf.line_top)
		assert_equal('d', buf.current)
		assert_equal(['e', nil, nil], buf.line_bottom)
		assert_equal([], buf.buf_bottom)
	end
	def test_scroll_down_nil5
		buf = FakeVertBuffer.new(
			%w(a), %w(b), 'c', %w(d), [])
		buf.scroll_down(true)
		assert_equal(%w(a b), buf.buf_top)
		assert_equal(%w(c), buf.line_top)
		assert_equal('d', buf.current)
		assert_equal([nil], buf.line_bottom)
		assert_equal([], buf.buf_bottom)
	end
	def test_scroll_down_nil6
		buf = FakeVertBuffer.new(
			%w(a), %w(b c), 'd', [], [])
		assert_raises(BufferBottom) { buf.scroll_down(true) }
		assert_equal(%w(a), buf.buf_top)
		assert_equal(%w(b c), buf.line_top)
		assert_equal('d', buf.current)
		assert_equal([], buf.line_bottom)
		assert_equal([], buf.buf_bottom)
	end
	def test_scroll_down_nil7
		buf = FakeVertBuffer.new(
			%w(a b), %w(c), 'd', [nil], [])
		assert_raises(BufferBottom) { buf.scroll_down(true) }
		assert_equal(%w(a b), buf.buf_top)
		assert_equal(%w(c), buf.line_top)
		assert_equal('d', buf.current)
		assert_equal([nil], buf.line_bottom)
		assert_equal([], buf.buf_bottom)
	end
	def test_move_up1
		buf = FakeVertBuffer.new([], %w(a), 'b', %w(c), [])
		buf.move_up  # normal up
		assert_equal([], buf.buf_top)
		assert_equal([], buf.line_top)
		assert_equal('a', buf.current)
		assert_equal(%w(b c), buf.line_bottom)
		assert_equal([], buf.buf_bottom)
	end
	def test_move_up2
		buf = FakeVertBuffer.new(%w(a), [], 'b', %w(c), [])
		buf.move_up  # up => scroll
		assert_equal([], buf.buf_top)
		assert_equal([], buf.line_top)
		assert_equal('a', buf.current)
		assert_equal(%w(b), buf.line_bottom)
		assert_equal(%w(c), buf.buf_bottom)
	end
	def test_move_down1
		buf = FakeVertBuffer.new([], %w(a), 'b', %w(c), [])
		buf.move_down  # normal down
		assert_equal([], buf.buf_top)
		assert_equal(%w(a b), buf.line_top)
		assert_equal('c', buf.current)
		assert_equal([], buf.line_bottom)
		assert_equal([], buf.buf_bottom)
	end
	def test_move_down2
		buf = FakeVertBuffer.new([], %w(a), 'b', [], %w(c))
		buf.move_down  # down => scroll
		assert_equal(%w(a), buf.buf_top)
		assert_equal(%w(b), buf.line_top)
		assert_equal('c', buf.current)
		assert_equal([], buf.line_bottom)
		assert_equal([], buf.buf_bottom)
	end
	def test_move_page_up1
		buf = FakeVertBuffer.new(
			%w(a b c d), %w(1), '2', %w(3 4), %w(x y z))
		buf.move_page_up  # normal pageup
		assert_equal(%w(a), buf.buf_top)
		assert_equal(%w(b), buf.line_top)
		assert_equal('c', buf.current)
		assert_equal(%w(d 1), buf.line_bottom)
		assert_equal(%w(2 3 4 x y z), buf.buf_bottom)
	end
	def test_move_page_up2
		# pageup/pagedown is assymetric in this particular case
		# try compare this code against 'test_move_page_down2'
		buf = FakeVertBuffer.new(
			%w(a b), %w(1), '2', %w(3 4), %w(x y z))
		buf.move_page_up # abnormal pageup (topofbuffer#1)
		assert_equal([], buf.buf_top)
		assert_equal(%w(a), buf.line_top)
		assert_equal('b', buf.current)
		assert_equal(%w(1 2), buf.line_bottom)
		assert_equal(%w(3 4 x y z), buf.buf_bottom)
	end
	def test_move_page_up3
		buf = FakeVertBuffer.new(
			[], %w(1), '2', %w(3 4), %w(x y z))
		buf.move_page_up # abnormal pageup (topofbuffer#2)
		assert_equal([], buf.buf_top)
		assert_equal([], buf.line_top)
		assert_equal('1', buf.current)
		assert_equal(%w(2 3 4), buf.line_bottom)
		assert_equal(%w(x y z), buf.buf_bottom)
	end
	def test_move_page_up4
		buf = FakeVertBuffer.new(
			%w(a b c d), %w(1), '2', [nil, nil], [])  # bottom of buffer
		buf.move_page_up # normal pageup 
		assert_equal(%w(a), buf.buf_top)
		assert_equal(%w(b), buf.line_top)
		assert_equal('c', buf.current)
		assert_equal(%w(d 1), buf.line_bottom)
		assert_equal(%w(2), buf.buf_bottom)
	end
	def test_move_page_up5
		buf = FakeVertBuffer.new(
			[], [], 'a', [nil, nil], [])  # top of buffer
		assert_raises(BufferTop) { buf.move_page_up } # nothing should happen
		assert_equal([], buf.buf_top)
		assert_equal([], buf.line_top)
		assert_equal('a', buf.current)
		assert_equal([nil, nil], buf.line_bottom)
		assert_equal([], buf.buf_bottom)
	end
	def test_move_page_down1
		buf = FakeVertBuffer.new(
			%w(z y x), %w(4 3), '2', %w(1), %w(d c b a))
		buf.move_page_down  # normal pagedown
		assert_equal(%w(z y x 4 3 2), buf.buf_top)
		assert_equal(%w(1 d), buf.line_top)
		assert_equal('c', buf.current)
		assert_equal(%w(b), buf.line_bottom)
		assert_equal(%w(a), buf.buf_bottom)
	end
	def test_move_page_down2
		# pageup/pagedown is assymetric in this particular case
		# try compare this code against 'test_move_page_up2'
		buf = FakeVertBuffer.new(
			[], %w(a), 'b', %w(c d), %w(e))
		# will reach bottom in this operation
		buf.move_page_down # abnormal pagedown (bottomofbuffer#1)
		assert_equal(%w(a b c), buf.buf_top)
		assert_equal(%w(d), buf.line_top)
		assert_equal('e', buf.current)
		assert_equal([nil, nil], buf.line_bottom)
		assert_equal([], buf.buf_bottom)
	end
	def test_move_page_down3
		buf = FakeVertBuffer.new(
			[], %w(a b c d e), 'f', %w(g), %w(h i j))
		# will reach bottom in this operation
		buf.move_page_down # abnormal pagedown (bottomofbuffer#1)
		assert_equal(%w(a b c d), buf.buf_top)
		assert_equal(%w(e f g h i), buf.line_top)
		assert_equal('j', buf.current)
		assert_equal([nil], buf.line_bottom)
		assert_equal([], buf.buf_bottom)
	end
	def test_move_page_down4
		buf = FakeVertBuffer.new(
			%w(a b c), %w(d e), 'f', %w(g), [])
		# goto bottom line
		buf.move_page_down # abnormal pagedown (bottomofbuffer#2)
		assert_equal(%w(a b c), buf.buf_top)
		assert_equal(%w(d e f), buf.line_top)
		assert_equal('g', buf.current)
		assert_equal([], buf.line_bottom)
		assert_equal([], buf.buf_bottom)
	end
	def test_move_page_down5
		buf = FakeVertBuffer.new(
			%w(a b c), %w(d), 'e', ['f', nil], [])
		# goto bottom line
		buf.move_page_down # abnormal pagedown (bottomofbuffer#2)
		assert_equal(%w(a b c), buf.buf_top)
		assert_equal(%w(d e), buf.line_top)
		assert_equal('f', buf.current)
		assert_equal([nil], buf.line_bottom)
		assert_equal([], buf.buf_bottom)
	end
	def test_move_page_down6
		buf = FakeVertBuffer.new(
			[], %w(a b), 'c', [nil], []) # already on bottom-line
		assert_raises(BufferBottom) { buf.move_page_down }
		assert_equal([], buf.buf_top)
		assert_equal(%w(a b), buf.line_top)
		assert_equal('c', buf.current)
		assert_equal([nil], buf.line_bottom)
		assert_equal([], buf.buf_bottom)
	end
	def test_move_page_up_height1
		buf = FakeVertBuffer.new(
			%w(a b c), %w(d e), 'f', %w(g), %w(h)) 
		buf.move_page_up(3)  # height of view = 3  => scroll 2 lines
		assert_equal(%w(a), buf.buf_top)
		assert_equal(%w(b c), buf.line_top)
		assert_equal('d', buf.current)
		assert_equal(%w(e), buf.line_bottom)
		assert_equal(%w(f g h), buf.buf_bottom)
	end
	def test_move_page_up_height2
		buf = FakeVertBuffer.new(
			%w(a b c d), %w(e), 'f', %w(g), %w(h)) 
		buf.move_page_up(4)  # height of view = 4  => scroll 3 lines
		assert_equal(%w(a), buf.buf_top)
		assert_equal(%w(b), buf.line_top)
		assert_equal('c', buf.current)
		assert_equal(%w(d), buf.line_bottom)
		assert_equal(%w(e f g h), buf.buf_bottom)
	end
	def test_move_page_up_height3
		buf = FakeVertBuffer.new(
			%w(a b c d), [], 'e', [], %w(f)) 
		buf.move_page_up(4)  # height of view = 4  => scroll 3 lines
		assert_equal(%w(a), buf.buf_top)
		assert_equal([], buf.line_top)
		assert_equal('b', buf.current)
		assert_equal([], buf.line_bottom)
		assert_equal(%w(c d e f), buf.buf_bottom)
	end
	def test_move_page_up_height4
		buf = FakeVertBuffer.new(
			%w(a b), %w(c), 'd', %w(e), %w(f)) 
		buf.move_page_up(1)  # height of view = 1  => scroll 1 lines !!!
		assert_equal(%w(a), buf.buf_top)
		assert_equal(%w(b), buf.line_top)
		assert_equal('c', buf.current)
		assert_equal(%w(d), buf.line_bottom)
		assert_equal(%w(e f), buf.buf_bottom)
	end
	def test_move_page_down_height1
		buf = FakeVertBuffer.new(
			%w(a), %w(b), 'c', %w(d e), %w(f g h)) 
		buf.move_page_down(3)  # height of view = 3  => scroll 2 lines
		assert_equal(%w(a b c), buf.buf_top)
		assert_equal(%w(d), buf.line_top)
		assert_equal('e', buf.current)
		assert_equal(%w(f g), buf.line_bottom)
		assert_equal(%w(h), buf.buf_bottom)
	end
	def test_move_page_down_height2
		buf = FakeVertBuffer.new(
			%w(a), %w(b), 'c', %w(d), %w(e f g h)) 
		buf.move_page_down(4)  # height of view = 4  => scroll 3 lines
		assert_equal(%w(a b c d), buf.buf_top)
		assert_equal(%w(e), buf.line_top)
		assert_equal('f', buf.current)
		assert_equal(%w(g), buf.line_bottom)
		assert_equal(%w(h), buf.buf_bottom)
	end
	def test_move_page_down_height3
		buf = FakeVertBuffer.new(
			%w(a), [], 'b', [], %w(c d e f)) 
		buf.move_page_down(4)  # height of view = 4  => scroll 3 lines
		assert_equal(%w(a b c d), buf.buf_top)
		assert_equal([], buf.line_top)
		assert_equal('e', buf.current)
		assert_equal([], buf.line_bottom)
		assert_equal(%w(f), buf.buf_bottom)
	end
	def test_move_page_down_height4
		buf = FakeVertBuffer.new(
			%w(a), %w(b), 'c', %w(d), %w(e f)) 
		buf.move_page_down(1)  # height of view = 1  => scroll 1 lines !!!
		assert_equal(%w(a b), buf.buf_top)
		assert_equal(%w(c), buf.line_top)
		assert_equal('d', buf.current)
		assert_equal(%w(e), buf.line_bottom)
		assert_equal(%w(f), buf.buf_bottom)
	end
	def test_move_page_down_height5
		buf = FakeVertBuffer.new(
			%w(a), [], 'b', %w(c d e) + [nil, nil], []) 
		buf.move_page_down(3)  # height of view = 3  => move 2 lines !!!
		assert_equal(%w(a), buf.buf_top)
		assert_equal(%w(b c), buf.line_top)
		assert_equal('d', buf.current)
		assert_equal(%w(e) + [nil, nil], buf.line_bottom)
		assert_equal([], buf.buf_bottom)
	end
	def test_resize_topbottom1
		buf = FakeVertBuffer.new(%w(a b c), %w(d), 'x', %w(1 2 3), %w(4))
		assert_equal(5, buf.visible_lines)
		buf.resize_topbottom(3, 1)
		assert_equal(%w(a), buf.buf_top)
		assert_equal(%w(b c d), buf.line_top)
		assert_equal('x', buf.current)
		assert_equal(%w(1), buf.line_bottom)
		assert_equal(%w(2 3 4), buf.buf_bottom)
	end
	def test_resize_topbottom2
		buf = FakeVertBuffer.new(%w(a), %w(b c d), 'x', %w(1), %w(2 3 4))
		assert_equal(5, buf.visible_lines)
		buf.resize_topbottom(1, 3)
		assert_equal(%w(a b c), buf.buf_top)
		assert_equal(%w(d), buf.line_top)
		assert_equal('x', buf.current)
		assert_equal(%w(1 2 3), buf.line_bottom)
		assert_equal(%w(4), buf.buf_bottom)
	end
	def test_resize_topbottom3
		buf = FakeVertBuffer.new([], %w(a), 'x', %w(1), %w(2 3 4))
		assert_equal(3, buf.visible_lines)
		buf.resize_topbottom(3, 1)
		assert_equal([], buf.buf_top)
		assert_equal(%w(a), buf.line_top) # nothing to import at the top
		assert_equal('x', buf.current)
		assert_equal(%w(1 2 3), buf.line_bottom) # thus bottom-import!
		assert_equal(%w(4), buf.buf_bottom)
	end
	def test_resize_center1
		buf = FakeVertBuffer.new(%w(a b c), %w(d), 'x', %w(1), %w(2 3 4))
		assert_equal(3, buf.visible_lines)
		buf.resize_center(5)
		assert_equal(%w(a b), buf.buf_top)
		assert_equal(%w(c d), buf.line_top)
		assert_equal('x', buf.current)
		assert_equal(%w(1 2), buf.line_bottom)
		assert_equal(%w(3 4), buf.buf_bottom)
	end
	def test_resize_center2
		buf = FakeVertBuffer.new(%w(a b c d e), %w(f), 'x', %w(1 2 3 4 5), %w(6))
		assert_equal(7, buf.visible_lines)
		buf.resize_center(8)
		assert_equal(%w(a b c d), buf.buf_top)
		assert_equal(%w(e f), buf.line_top)
		assert_equal('x', buf.current)
		assert_equal(%w(1 2 3 4 5), buf.line_bottom)
		assert_equal(%w(6), buf.buf_bottom)
	end
	def test_resize_center3
		buf = FakeVertBuffer.new(%w(a b), %w(c d), 'x', %w(1 2), %w(3 4))
		assert_equal(5, buf.visible_lines)
		buf.resize_center(3)
		assert_equal(%w(a b c), buf.buf_top)
		assert_equal(%w(d), buf.line_top)
		assert_equal('x', buf.current)
		assert_equal(%w(1), buf.line_bottom)
		assert_equal(%w(2 3 4), buf.buf_bottom)
	end
	def test_resize_center4
		buf = FakeVertBuffer.new(%w(a), %w(b c d e f), 'x', %w(1 2 3), %w(4))
		assert_equal(9, buf.visible_lines)
		buf.resize_center(5)
		assert_equal(%w(a b c d), buf.buf_top)
		assert_equal(%w(e f), buf.line_top)
		assert_equal('x', buf.current)
		assert_equal(%w(1 2), buf.line_bottom)
		assert_equal(%w(3 4), buf.buf_bottom)
	end
	def test_resize_center_nil_import1
		buf = FakeVertBuffer.new(%w(a b c), [], 'x', [], [])
		assert_equal(1, buf.visible_lines)
		buf.resize_center(8)
		assert_equal([], buf.buf_top)
		assert_equal(%w(a b c), buf.line_top)
		assert_equal('x', buf.current)
		assert_equal([nil, nil, nil, nil], buf.line_bottom)
		assert_equal([], buf.buf_bottom)
	end
	def test_resize_center_nil_import2
		buf = FakeVertBuffer.new([], %w(a b c), 'x', [], [])
		assert_equal(4, buf.visible_lines)
		buf.resize_center(8)
		assert_equal([], buf.buf_top)
		assert_equal(%w(a b c), buf.line_top)
		assert_equal('x', buf.current)
		assert_equal([nil, nil, nil, nil], buf.line_bottom)
		assert_equal([], buf.buf_bottom)
	end
	def test_resize_center_nil_import3
		buf = FakeVertBuffer.new([], [], 'x', %w(a b c), [])
		assert_equal(4, buf.visible_lines)
		buf.resize_center(8)
		assert_equal([], buf.buf_top)
		assert_equal([], buf.line_top)
		assert_equal('x', buf.current)
		assert_equal(['a', 'b', 'c', nil, nil, nil, nil], buf.line_bottom)
		assert_equal([], buf.buf_bottom)
	end
	def test_resize_center_nil_import4
		buf = FakeVertBuffer.new([], [], 'x', [], %w(a b c))
		assert_equal(1, buf.visible_lines)
		buf.resize_center(8)
		assert_equal([], buf.buf_top)
		assert_equal([], buf.line_top)
		assert_equal('x', buf.current)
		assert_equal(['a', 'b', 'c', nil, nil, nil, nil], buf.line_bottom)
		assert_equal([], buf.buf_bottom)
	end
	def test_resize_center_nil_import5
		buf = FakeVertBuffer.new([], [], 'x', [], %w(a b c d e f g))
		assert_equal(1, buf.visible_lines)
		buf.resize_center(4)
		assert_equal([], buf.buf_top)
		assert_equal([], buf.line_top)
		assert_equal('x', buf.current)
		assert_equal(%w(a b c), buf.line_bottom)
		assert_equal(%w(d e f g), buf.buf_bottom)
	end
	def test_resize_center_nil_export1
		buf = FakeVertBuffer.new([], %w(a b c), 'x', [nil, nil, nil], [])
		assert_equal(7, buf.visible_lines)
		buf.resize_center(3)
		assert_equal(%w(a b), buf.buf_top)
		assert_equal(%w(c), buf.line_top)
		assert_equal('x', buf.current)
		assert_equal([nil], buf.line_bottom)
		assert_equal([], buf.buf_bottom)  # nil's gets discarded
	end
	def test_resize_top1
		buf = FakeVertBuffer.new(%w(a b c), %w(d), 'x', %w(1 2 3), %w(4))
		assert_equal(5, buf.visible_lines)
		buf.resize_top(7)
		assert_equal(%w(a), buf.buf_top)
		assert_equal(%w(b c d), buf.line_top)
		assert_equal('x', buf.current)
		assert_equal(%w(1 2 3), buf.line_bottom)
		assert_equal(%w(4), buf.buf_bottom)
	end
	def test_resize_top2
		buf = FakeVertBuffer.new(%w(a), %w(b c d), 'x', %w(1 2 3), %w(4))
		assert_equal(7, buf.visible_lines)
		buf.resize_top(5)
		assert_equal(%w(a b c), buf.buf_top)
		assert_equal(%w(d), buf.line_top)
		assert_equal('x', buf.current)
		assert_equal(%w(1 2 3), buf.line_bottom)
		assert_equal(%w(4), buf.buf_bottom)
	end
	def test_resize_top3
		buf = FakeVertBuffer.new(%w(a), %w(b c d), 'e', %w(f x 1 2 3), %w(4))
		assert_equal(9, buf.visible_lines)
		buf.resize_top(4)
		assert_equal(%w(a b c d e f), buf.buf_top)
		assert_equal([], buf.line_top)
		assert_equal('x', buf.current)
		assert_equal(%w(1 2 3), buf.line_bottom)
		assert_equal(%w(4), buf.buf_bottom)
	end
	def test_resize_top4
		buf = FakeVertBuffer.new(%w(a), %w(b), 'c', [], %w(d))
		assert_equal(2, buf.visible_lines)
		buf.resize_top(5)
		# I don't think this paticular case is aesteticly nice 
		assert_equal([], buf.buf_top)
		assert_equal(%w(a b), buf.line_top)
		assert_equal('c', buf.current)
		assert_equal(['d', nil], buf.line_bottom)
		assert_equal([], buf.buf_bottom)
	end
	def test_resize_bottom1
		buf = FakeVertBuffer.new(%w(4), %w(3 2 1), 'x', %w(d), %w(c b a))
		assert_equal(5, buf.visible_lines)
		buf.resize_bottom(7)
		assert_equal(%w(4), buf.buf_top)
		assert_equal(%w(3 2 1), buf.line_top)
		assert_equal('x', buf.current)
		assert_equal(%w(d c b), buf.line_bottom)
		assert_equal(%w(a), buf.buf_bottom)
	end
	def test_resize_bottom2
		buf = FakeVertBuffer.new(%w(4), %w(3 2 1), 'x', %w(d c b), %w(a))
		assert_equal(7, buf.visible_lines)
		buf.resize_bottom(5)
		assert_equal(%w(4), buf.buf_top)
		assert_equal(%w(3 2 1), buf.line_top)
		assert_equal('x', buf.current)
		assert_equal(%w(d), buf.line_bottom)
		assert_equal(%w(c b a), buf.buf_bottom)
	end
	def test_resize_bottom3
		buf = FakeVertBuffer.new(%w(4), %w(3 2 1 x f), 'e', %w(d c b), %w(a))
		assert_equal(9, buf.visible_lines)
		buf.resize_bottom(4)
		assert_equal(%w(4), buf.buf_top)
		assert_equal(%w(3 2 1), buf.line_top)
		assert_equal('x', buf.current)
		assert_equal([], buf.line_bottom)
		assert_equal(%w(f e d c b a), buf.buf_bottom)
	end
end

TestBufferVert.run if $0 == __FILE__
