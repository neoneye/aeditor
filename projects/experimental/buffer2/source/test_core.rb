# I want a ruby-scriptable editor that isn't in your way
# responsive and powerful.. with good lexing..  (and I mean good lexing)
require 'common_test'
require 'core'

class TestModelLoad < Test::Unit::TestCase
	def setup
		super
		@model = AEditor::Model::Caretaker.new
	end
	def teardown
		super
		@model.check_integrity
	end
	def test_init1
		assert_equal([0], @model.array_of_bytes)
		assert_equal("", @model.text)
	end
	def test_typical1
		@model.load("a\nbc\ndef\nghij")
		assert_equal([2, 3, 4, 4], @model.array_of_bytes)
	end
	def test_tailing_newline1
		@model.load("123\n45\n")
		assert_equal([4, 3, 0], @model.array_of_bytes)
	end
	def test_tailing_newline2
		@model.load("\n\n\n\n")
		assert_equal([1, 1, 1, 1, 0], @model.array_of_bytes)
	end
	def test_tailing_newline3
		@model.load("\n")
		assert_equal([1, 0], @model.array_of_bytes)
	end
	def test_empty_string1
		@model.load("")
		assert_equal([0], @model.array_of_bytes)
	end
	def test_typeerror1
		assert_raise(TypeError) { @model.load(42) }
	end
	def test_invalid_utf8_string1
		e = assert_raise(ArgumentError) { @model.load("a\xffa") }
		assert_match(/malformed UTF-8/, e.message)
	end
	def test_twice1
		@model.load("ab\ncd")
		assert_equal("ab\ncd", @model.text)
		assert_equal([3, 2], @model.array_of_bytes)
		@model.load("x\ny\nz")
		assert_equal("x\ny\nz", @model.text)
		assert_equal([2, 2, 1], @model.array_of_bytes)
	end
end

class TestModelPosition2Bytes < Test::Unit::TestCase
	def setup
		super
		@model = AEditor::Model::Caretaker.new
		glyph1 = "\303\245"      # unicode U-00E5
		glyph2 = "\342\225\254"  # unicode U-256C
		@model.load("ab\ncdef\n" + glyph1 + "-" + glyph2 + "ghi\njklmn")
	end
	def teardown
		super
		@model.check_integrity
	end
	def test_typical1
		assert_equal(0, @model.p2b(0, 0))
		assert_equal(3, @model.p2b(0, 1))
		assert_equal(8, @model.p2b(0, 2))
		assert_equal(18, @model.p2b(0, 3))
	end
	def test_typical2
		assert_equal(4, @model.p2b(1, 1))
		assert_equal(10, @model.p2b(1, 2))
		assert_equal(11, @model.p2b(2, 2))
		assert_equal(14, @model.p2b(3, 2))
	end
	def test_typical3
		assert_equal(2, @model.p2b(2, 0))
		assert_equal(7, @model.p2b(4, 1))
		assert_equal(17, @model.p2b(6, 2))
		assert_equal(23, @model.p2b(5, 3))
	end
	def test_typeerror1
		assert_raise(TypeError) { @model.p2b("tanaka akira", 0) }
		assert_raise(TypeError) { @model.p2b(0, "minero aoki") }
	end
	def test_invalid_y1
		assert_raise(ArgumentError) { @model.p2b(0, -1) }
		assert_raise(ArgumentError) { @model.p2b(0, 4) }
	end
	def test_invalid_x1
		assert_raise(ArgumentError) { @model.p2b(-1, 0) }
		assert_raise(ArgumentError) { @model.p2b(3, 0) }
		assert_raise(ArgumentError) { @model.p2b(5, 1) }
		assert_raise(ArgumentError) { @model.p2b(7, 2) }
		assert_raise(ArgumentError) { @model.p2b(6, 3) }
	end
	def test_bad_first_byte1
		assert_raise(TypeError) { @model.determine_bytes_of_char(0.5) }
	end
	def test_bad_first_byte2
		e = assert_raise(ArgumentError) { @model.determine_bytes_of_char(-1) }
		assert_match(/outside range 0\.\.255/, e.message)
	end
	def test_bad_first_byte3
		e = assert_raise(ArgumentError) { @model.determine_bytes_of_char(256) }
		assert_match(/outside range 0\.\.255/, e.message)
	end
end

class TestModelObserver < Test::Unit::TestCase
	def setup
		super
		@model = AEditor::Model::Caretaker.new
	end
	def teardown
		super
		@model.check_integrity
	end
	def model_update(notify_type, y, lines_to_remove, lines_to_insert)
	end
	def test_typical1
		assert_equal([], @model.observers)
		@model.attach(self)
		assert_equal([self], @model.observers)
		@model.detach(self)
		assert_equal([], @model.observers)
	end
	def test_nomethoderror1
		e = assert_raise(NoMethodError) { @model.attach(nil) }
		assert_match(/observer needs to respond to `model_update'/, e.message)
	end
end

class TestModelReplace < Test::Unit::TestCase
	def setup
		super
		@before = []
		@after = []
		@model = AEditor::Model::Caretaker.new
		@model.attach(self)
	end
	def teardown
		super
		@model.check_integrity
	end
	def model_update(model, info)
		ary = case info.event
		when :before
			@before
		when :after
			@after
		else
			raise "unknown notify_type (#{info.event})"
		end
		ary << [
			info.x1, info.y1, 
			info.source_x2, info.source_y2,
			info.dest_x2, info.dest_y2
		]
	end
	def test_typical1
		@model.replace(0, 0, 0, 0, "line1\nline2")
		assert_equal([6, 5], @model.array_of_bytes)
		assert_equal([[0, 0, 0, 0, nil, nil]], @before)
		assert_equal([[0, 0, 0, 0, 5, 1]], @after)
	end
	def test_typical2
		@model.load("ab")
		@model.replace(1, 0, 1, 0, "\n")
		assert_equal("a\nb", @model.text)
		assert_equal([2, 1], @model.array_of_bytes)
		assert_equal([[0, 0, 0, 0, nil, nil], 
			[1, 0, 1, 0, nil, nil]], @before)
		assert_equal([[0, 0, 0, 0, 2, 0], 
			[1, 0, 1, 0, 0, 1]], @after)
	end
	def test_typical3
		@model.load("ab\ncd\nefg")
		assert_equal([3, 3, 3], @model.array_of_bytes)
		@model.replace(0, 1, 2, 1, "x\ny\nz")
		assert_equal("ab\nx\ny\nz\nefg", @model.text)
		assert_equal([3, 2, 2, 2, 3], @model.array_of_bytes)
		assert_equal([[0, 0, 0, 0, nil, nil],
			[0, 1, 2, 1, nil, nil]], @before)
		assert_equal([[0, 0, 0, 0, 3, 2],
			[0, 1, 2, 1, 1, 3]], @after)
	end
	def test_typical4
		@model.load("abcd\nefghi")
		@model.replace(3, 0, 1, 1, "xyz")
		assert_equal("abcxyzfghi", @model.text)
		assert_equal([10], @model.array_of_bytes)
		assert_equal([[0, 0, 0, 0, nil, nil], 
			[3, 0, 1, 1, nil, nil]], @before)
		assert_equal([[0, 0, 0, 0, 5, 1], 
			[3, 0, 1, 1, 6, 0]], @after)
	end
	def test_typeerror
		assert_raise(TypeError) { @model.replace("nobu nokada", 0, 0, 0, '') }
		assert_raise(TypeError) { @model.replace(0, "pragprog", 0, 0, '') }
		assert_raise(TypeError) { @model.replace(0, 0, "guy decoux", 0, '') }
		assert_raise(TypeError) { @model.replace(0, 0, 0, "shugo maeda", '') }
	end
	def test_invalid_range_y1
		@model.load("1\n2\n3\n4")
		e = assert_raise(ArgumentError) { @model.replace(0, 2, 0, 1, '') }
		assert_match(/negative range/, e.message)
	end
	def test_invalid_range_x1
		@model.load("1234")
		e = assert_raise(ArgumentError) { @model.replace(2, 0, 1, 0, '') }
		assert_match(/negative range/, e.message)
	end
end

class TestModelBytes2Position < Test::Unit::TestCase
	def setup
		super
		@model = AEditor::Model::Caretaker.new
		glyph1 = "\303\245"      # unicode U-00E5
		glyph2 = "\342\225\254"  # unicode U-256C
		@model.load("line1\nline2\n" + glyph1 + "-" + glyph2 + "\nxy")
	end
	def teardown
		super
		@model.check_integrity
	end
	def test_typical1
		assert_equal([0, 0], @model.b2p(0))
		assert_equal([5, 0], @model.b2p(5))
		assert_equal([0, 1], @model.b2p(6))
		assert_equal([2, 1], @model.b2p(8))
		assert_equal([5, 1], @model.b2p(11))
		assert_equal([0, 2], @model.b2p(12))
		assert_equal([1, 2], @model.b2p(14))
		assert_equal([2, 2], @model.b2p(15))
		assert_equal([3, 2], @model.b2p(18))
		assert_equal([0, 3], @model.b2p(19))
		assert_equal([1, 3], @model.b2p(20))
		assert_equal([2, 3], @model.b2p(21))
	end
	def test_strange_byte_offsets1
		assert_equal([0, 2], @model.b2p(13))
		assert_equal([2, 2], @model.b2p(16))
		assert_equal([2, 2], @model.b2p(17))
	end
	def test_typeerror
		assert_raise(TypeError) { @model.b2p(0.7) }
	end
	def test_outside_range1
		e = assert_raise(ArgumentError) { @model.b2p(-1) }
		assert_match(/byte outside range/, e.message)
	end
	def test_outside_range2
		e = assert_raise(ArgumentError) { @model.b2p(22) }
		assert_match(/byte outside range/, e.message)
	end
end

class MockCanvas < AEditor::Canvas::Base
	def initialize(w, h)
		super()
		@w = w
		@h = h
		@tabsize = 8
		clear
	end
	attr_reader :data, :dx, :dy, :sx
	def clear
		@data = []
		@dx = []
		@dy = []
		@sx = []
	end
	def scroll_x=(x)
		@sx << x
	end
	def render_row(y, utf8_string, ay, pens, options)
		@data << utf8_string
	end
	def repaint_output
		@view.update
		@data
	end
	def width
		@w
	end
	def height
		@h
	end
	def cursor_show(x, y)
		@dx << x
		@dy << y
	end
	def refresh
	end
	def measure_width(x, glyph)
		case glyph
		when 9
			@tabsize - (x % @tabsize)
		when ?A..?Z
			2 # lets pretend uppercase letters span 2 columns
		else
			1
		end
	end
end

class MockLexer < AEditor::Lexer::Simple
	def initialize(model)
		super(model)
		@state_counter = 1
	end
	def lex_line(text)
		#puts "lex #{text.inspect}"
		pen = text[0, 1].to_i
		glyphs = text.unpack('U*')
		@pens = glyphs.map{|g| pen}
		@right = @state_counter
		@state_counter += 1
		nil
	end
end

class TestViewInit < Test::Unit::TestCase
	def setup
		super
		@model = AEditor::Model::Caretaker.new
		glyph1 = "\303\245"      # unicode U-00E5
		glyph2 = "\342\225\254"  # unicode U-256C
		@model.load("line1\nline2\n" + glyph1 + "-" + glyph2 + "\nxy")
	end
	def teardown
		super
		@model.check_integrity
	end
	def test_init_with_canvas1
		view = AEditor::View::Caretaker.new(@model)
		assert_equal(@model.object_id, view.model.object_id)
		canvas = MockCanvas.new(80, 25)
		assert_nil(view.canvas)
		assert_nil(canvas.view)
		view.canvas, canvas.view = canvas, view
		assert_equal(canvas.object_id, view.canvas.object_id)
		assert_equal(view.object_id, canvas.view.object_id)
		view.canvas, canvas.view = nil, nil
		assert_nil(view.canvas)
		assert_nil(canvas.view)
		view.canvas, canvas.view = nil, nil
		assert_nil(view.canvas)
		assert_nil(canvas.view)
	end
	def test_init_with_lexer1
		lexer = MockLexer.new(@model)
		view = AEditor::View::Caretaker.new(@model)
		assert_nil(view.lexer)
		view.lexer = lexer
		assert_equal(lexer.object_id, view.lexer.object_id)
		view.lexer = nil
		assert_nil(view.lexer)
	end
	def test_typeerror1
		assert_raise(TypeError) { 
			AEditor::View::Caretaker.new("linus torvalds")
		}
	end
	def test_canvas_bad1
		v = AEditor::View::Caretaker.new(@model)
		assert_nil(v.canvas)
		assert_raise(TypeError) { v.canvas = :bad }
	end
	def test_lexer_bad1
		v = AEditor::View::Caretaker.new(@model)
		assert_nil(v.lexer)
		assert_raise(TypeError) { v.lexer = :bad }
	end
end

class TestViewNotifyCursor < Test::Unit::TestCase
	def setup
		super
		@model = AEditor::Model::Caretaker.new
		@view = AEditor::View::Caretaker.new(@model)
		@model.attach(@view)
	end
	def teardown
		super
		@model.check_integrity
		@view.check_integrity
	end
	def exercise1(x, y)
		@model.load((1..6).to_a.map{|s| s.to_s*4}.join("\n"))
		@view.cursor_x = x
		@view.cursor_y = y
		@model.replace(2, 1, 2, 3, 'xy')
		@view.cursor
	end
	def test_multiline0
		assert_equal([2, 0], exercise1(2, 0))
	end
	def test_multiline1
		assert_equal([1, 1], exercise1(1, 1))
		assert_equal([2, 1], exercise1(2, 1))
		assert_equal([2, 1], exercise1(3, 1))
	end
	def test_multiline2
		assert_equal([2, 1], exercise1(0, 2))
	end
	def test_multiline3
		assert_equal([2, 1], exercise1(1, 3))
		assert_equal([4, 1], exercise1(2, 3))
		assert_equal([5, 1], exercise1(3, 3))
	end
	def test_multiline4
		assert_equal([2, 2], exercise1(2, 4))
	end
	def exercise2(x, y)
		@model.load((1..3).to_a.map{|s| s.to_s*10}.join("\n"))
		@view.cursor_x = x
		@view.cursor_y = y
		@model.replace(2, 1, 6, 1, 'xy')
		@view.cursor
	end
	def test_oneliner
		assert_equal([1, 1], exercise2(1, 1))
		assert_equal([2, 1], exercise2(2, 1))
		assert_equal([2, 1], exercise2(3, 1))
		assert_equal([2, 1], exercise2(5, 1))
		assert_equal([4, 1], exercise2(6, 1))
		assert_equal([5, 1], exercise2(7, 1))
	end
	def test_cursory_typeerror1
		assert_raise(TypeError) { @view.cursor_y = :bad }
	end
	def test_cursory_bad1
		assert_raise(ArgumentError) { @view.cursor_y = -1 }
	end
	def test_cursory_bad2
		assert_raise(ArgumentError) { @view.cursor_y = 6 }
	end
	def test_cursorx_typeerror1
		assert_raise(TypeError) { @view.cursor_x = "john carmack" }
	end
	def test_cursorx_bad1
		assert_raise(ArgumentError) { @view.cursor_x = -1 }
	end
end


class TestViewNotifyDirtifyLines < Test::Unit::TestCase
	def setup
		super
		@model = AEditor::Model::Caretaker.new
		@model.load((1..4).to_a.map{|i|i.to_s*3}.join("\n"))
		@view = AEditor::View::Caretaker.new(@model)
		@model.attach(@view)
	end
	def teardown
		super
		@model.check_integrity
		@view.check_integrity
	end
	def get_dirty
		@view.lines.map{|l| l.dirty}
	end
	def test_init
		assert_equal([true] * 4, get_dirty)
	end
	def exercise1(x1, y1, x2, y2, text)
		@view.lines.each { |l| l.dirty = false }
		@model.replace(x1, y1, x2, y2, text)
		get_dirty
	end
	def test_remove1
		assert_equal([false, true, false],
			exercise1(0, 1, 0, 2, ''))
	end
	def test_remove2
		assert_equal([false, true, true],
			exercise1(1, 1, 1, 3, "\n"))
	end
	def test_remove3
		# NOTE: the optimal would be not to touch the last line.
		assert_equal([false, true, true],
			exercise1(0, 1, 0, 3, "\n"))
	end
	def test_insert1
		assert_equal([false, true, false, false, false],
			exercise1(0, 1, 0, 1, "\n"))
	end
	def test_insert2
		assert_equal([false, true, true, false, false],
			exercise1(0, 1, 0, 2, "\n\n"))
	end
	def test_equal1
		assert_equal([false, true, false, false],
			exercise1(2, 1, 3, 1, 'x'))
	end
	def test_equal2
		assert_equal([false, true, true, false],
			exercise1(2, 1, 2, 2, "a\nb"))
	end
end


class TestViewRepaint < Test::Unit::TestCase
	def setup
		super
		@model = AEditor::Model::Caretaker.new
		@model.load("ab\nc\ndefg\nhi")
		@view = AEditor::View::Caretaker.new(@model)
		@canvas = MockCanvas.new(4, 2)
		@view.resize(4, 2)
		@view.canvas, @canvas.view = @canvas, @view
		@lexer = MockLexer.new(@model)
		@view.lexer = @lexer
	end
	def teardown
		super
		@model.check_integrity
		@view.check_integrity
	end
	def test_init1
		assert_equal([0, 0], @view.cursor)
		assert_equal([0, 0], @view.scroll)
		assert_equal([4, 2], @view.size)
		assert_equal([], @canvas.data)
		assert_equal([], @canvas.dy)
		assert_equal([], @canvas.dx)
		assert_equal([], @canvas.sx)
	end
	def test_vertical_inside1
		assert_equal(0, @view.scroll_y)
		assert_equal(["ab\n", "c\n"], @canvas.repaint_output)
		assert_equal([0], @canvas.dy)
		assert_equal([0], @canvas.sx)
	end
	def test_vertical_inside2
		@view.scroll_y = 1
		assert_equal(1, @view.scroll_y)
		assert_equal(["c\n", "defg\n"], @canvas.repaint_output)
		assert_equal([], @canvas.dy)
		assert_equal([0], @canvas.sx)
	end
	def test_vertical_inside3
		@view.scroll_y = 2
		assert_equal(2, @view.scroll_y)
		assert_equal(["defg\n", "hi"], @canvas.repaint_output)
		assert_equal([], @canvas.dy)
	end
	def test_vertical_outside_top1
		@view.scroll_y = -1
		assert_equal(-1, @view.scroll_y)
		assert_equal([nil, "ab\n"], @canvas.repaint_output)
		assert_equal([1], @canvas.dy)
	end
	def test_vertical_outside_bottom1
		@view.scroll_y = 3
		assert_equal(3, @view.scroll_y)
		assert_equal(["hi", nil], @canvas.repaint_output)
		assert_equal([], @canvas.dy)
	end
	def test_vertical_outside_bottom2
		@view.scroll_y = 4
		assert_equal(4, @view.scroll_y)
		assert_equal([nil, nil], @canvas.repaint_output)
		assert_equal([], @canvas.dy)
	end
	def test_horizontal1
		@view.cursor_x = 5
		@view.scroll_x = 4
		assert_equal(["ab\n", "c\n"], @canvas.repaint_output)
		assert_equal([4], @canvas.sx)
		assert_equal([5], @canvas.dx)
	end
	def test_no_canvas
		@view.canvas = nil
		assert_equal([], @canvas.repaint_output)
	end
	def test_resize1
		@view.resize(15, 10)
		assert_equal([15, 10], @view.size)
		assert_equal([], @canvas.data, 'resize should not repaint')
	end
	def test_bad_resize1
		assert_raise(TypeError) { @view.resize('richard stallman', 42) }
		assert_raise(TypeError) { @view.resize(42, 'yukihiro matsumoto') }
	end
	def test_bad_resize2
		assert_raise(ArgumentError) { @view.resize(-1, 42) }
		assert_raise(ArgumentError) { @view.resize(0, 42) }
		assert_raise(ArgumentError) { @view.resize(42, -1) }
		assert_raise(ArgumentError) { @view.resize(42, 0) }
	end
end


class TestViewCanvas2BufferCoordinates < Test::Unit::TestCase
	def setup
		super
		@model = AEditor::Model::Caretaker.new
		@model.load("line1\nlInE2\nli\tne3")
		@view = AEditor::View::Caretaker.new(@model)
		@model.attach(@view)
		@canvas = MockCanvas.new(80, 25)
		@view.canvas = @canvas
	end
	def teardown
		super
		@model.check_integrity
		@view.check_integrity
	end
	def conv(x, y)
		@view.xy2p(x, y)
	end
	def test_line1
		output = (0..6).map{|x| conv(x, 0)}
		assert_equal([0, 1, 2, 3, 4, 5, 5], output)
	end
	def test_line2
		output = (0..8).map{|x| conv(x, 1)}
		assert_equal([0, 1, 2, 2, 3, 4, 4, 5, 5], output)
	end
	def test_line3
		output = (0..12).map{|x| conv(x, 2)}
		assert_equal([0, 1, 2, 3, 3, 3, 3, 3, 3, 4, 5, 6, 6], output)
	end
end


class TestViewBuffer2CanvasCoordinates < Test::Unit::TestCase
	def setup
		super
		@model = AEditor::Model::Caretaker.new
		@model.load("line1\nlInE2\nli\tne3")
		@view = AEditor::View::Caretaker.new(@model)
		@model.attach(@view)
		@canvas = MockCanvas.new(80, 25)
		@view.canvas = @canvas
	end
	def teardown
		super
		@model.check_integrity
		@view.check_integrity
	end
	def conv(p, y)
		@view.py2x(p, y)
	end
	def test_line1
		output = (0..6).map{|i| conv(i, 0)}
		assert_equal([0, 1, 2, 3, 4, 5, 5], output)
	end
	def test_line2
		output = (0..6).map{|i| conv(i, 1)}
		assert_equal([0, 1, 3, 4, 6, 7, 7], output)
	end
	def test_line3
		output = (0..7).map{|i| conv(i, 2)}
		assert_equal([0, 1, 2, 8, 9, 10, 11, 11], output)
	end
end


class TestViewInsert < Test::Unit::TestCase
	def setup
		super
		@model = AEditor::Model::Caretaker.new
		@model.load("abcdef")
		@view = AEditor::View::Caretaker.new(@model)
		@model.attach(@view)
		@view.cursor_x = 3
		@canvas = MockCanvas.new(80, 25)
		@view.canvas = @canvas
	end
	def teardown
		super
		@model.check_integrity
		@view.check_integrity
	end
	def test_init1
		assert_equal([3, 0], @view.cursor)
	end
	def test_halfwidth1
		@view.insert("x")
		assert_equal("abcxdef", @model.text)
		assert_equal(4, @view.cursor_x)
		@view.insert("y")
		assert_equal("abcxydef", @model.text)
		assert_equal(5, @view.cursor_x)
	end
	def test_fullwidth1
		@view.insert("X")
		assert_equal("abcXdef", @model.text)
		assert_equal(5, @view.cursor_x)
		@view.insert("Y")
		assert_equal("abcXYdef", @model.text)
		assert_equal(7, @view.cursor_x)
	end
	def test_newline1
		assert_equal([3, 0], @view.cursor)
		@view.insert("\n")
		assert_equal("abc\ndef", @model.text)
		assert_equal([0, 1], @view.cursor)
	end
	def test_tabs1
		@view.insert("\t")
		assert_equal("abc\tdef", @model.text)
		assert_equal(8, @view.cursor_x)
		@view.insert("\t")
		assert_equal("abc\t\tdef", @model.text)
		assert_equal(16, @view.cursor_x)
	end
	def test_strange_offsets1
		@view.insert("X")
		assert_equal("abcXdef", @model.text)
		assert_equal(5, @view.cursor_x)
		@view.cursor_x = 4
		@view.insert("Y")
		assert_equal(7, @view.cursor_x)
		assert_equal("abcXYdef", @model.text)
	end
	def test_strange_offsets2
		@view.insert("\t")
		assert_equal("abc\tdef", @model.text)
		assert_equal(8, @view.cursor_x)
		@view.cursor_x = 6
		@view.insert("x")
		assert_equal(9, @view.cursor_x)
		assert_equal("abc\txdef", @model.text)
	end
	def test_multiple1
		@view.insert("xyz")
		assert_equal("abcxyzdef", @model.text)
		assert_equal(6, @view.cursor_x)
	end
	def test_none1
		@view.insert("")
		assert_equal("abcdef", @model.text)
		assert_equal(3, @view.cursor_x)
	end
end


class TestViewDeleteLeft < Test::Unit::TestCase
	def setup
		super
		@model = AEditor::Model::Caretaker.new
		@model.load("abcdef")
		@view = AEditor::View::Caretaker.new(@model)
		@model.attach(@view)
		@view.cursor_x = 3
		@canvas = MockCanvas.new(80, 25)
		@view.canvas = @canvas
	end
	def teardown
		super
		@model.check_integrity
		@view.check_integrity
	end
	def test_init1
		assert_equal([3, 0], @view.cursor)
	end
	def test_halfwidth1
		@view.delete_left
		assert_equal("abdef", @model.text)
		assert_equal(2, @view.cursor_x)
		@view.delete_left
		assert_equal("adef", @model.text)
		assert_equal(1, @view.cursor_x)
	end
	def test_fullwidth1
		@model.load("aXYZb")
		@view.cursor_x = 5
		@view.delete_left
		assert_equal("aXZb", @model.text)
		assert_equal(3, @view.cursor_x)
		@view.delete_left
		assert_equal("aZb", @model.text)
		assert_equal(1, @view.cursor_x)
	end
	def test_newline1
		@model.load("ab\ncd")
		@view.cursor_x, @view.cursor_y = 0, 1
		@view.delete_left
		assert_equal("abcd", @model.text)
		assert_equal([2, 0], @view.cursor)
	end
	def test_tab1
		@model.load("ab\tcd")
		@view.cursor_x = 8
		@view.delete_left
		assert_equal("abcd", @model.text)
		assert_equal(2, @view.cursor_x)
	end
	def test_strange_offsets1
		@model.load("abcde\txyz")
		@view.cursor_x = 7
		@view.delete_left
		assert_equal("abcdexyz", @model.text)
		assert_equal(5, @view.cursor_x)
	end
	def test_strange_offsets2
		@model.load("abXcd")
		@view.cursor_x = 3
		@view.delete_left
		assert_equal("abcd", @model.text)
		assert_equal(2, @view.cursor_x)
	end
	def test_strange_offsets3
		@model.load("abc\ndef")
		@view.cursor_x, @view.cursor_y = 5, 0
		@view.delete_left
		assert_equal("ab\ndef", @model.text)
		assert_equal(2, @view.cursor_x)
	end
end


class TestViewDeleteRight < Test::Unit::TestCase
	def setup
		super
		@model = AEditor::Model::Caretaker.new
		@model.load("abcdef")
		@view = AEditor::View::Caretaker.new(@model)
		@model.attach(@view)
		@view.cursor_x = 3
		@canvas = MockCanvas.new(80, 25)
		@view.canvas = @canvas
	end
	def teardown
		super
		@model.check_integrity
		@view.check_integrity
	end
	def test_init1
		assert_equal([3, 0], @view.cursor)
	end
	def test_halfwidth1
		@view.delete_right
		assert_equal("abcef", @model.text)
		assert_equal(3, @view.cursor_x)
		@view.delete_right
		assert_equal("abcf", @model.text)
		assert_equal(3, @view.cursor_x)
	end
	def test_newline1
		@model.load("abc\ndef")
		@view.cursor_x, @view.cursor_y = 3, 0
		@view.delete_right
		assert_equal("abcdef", @model.text)
		assert_equal(3, @view.cursor_x)
	end
	def test_endofbuffer1
		@model.load("abc\ndef")
		@view.cursor_x, @view.cursor_y = 2, 1
		@view.delete_right
		assert_equal("abc\nde", @model.text)
		assert_equal(2, @view.cursor_x)
	end
	def test_endofbuffer2
		@view.cursor_x = 6
		@view.delete_right
		assert_equal("abcdef", @model.text, 'should be harmless')
		assert_equal(6, @view.cursor_x)
	end
end


class TestViewConvertVisibley2Absolutey < Test::Unit::TestCase
	def setup
		super
		@model = AEditor::Model::Caretaker.new
		@model.load((0..11).to_a.join("\n"))
		@view = AEditor::View::Caretaker.new(@model)
		@model.attach(@view)
		@view.collapse(1, 4)
		@view.collapse(6, 9)
	end
	def teardown
		super
		@model.check_integrity
		@view.check_integrity
	end
	def test_init
		assert_equal([0, 1, 5, 6, 10, 11], @view.visible)
	end
	def exercise1(expected_ay, vy)
		assert_equal(expected_ay, @view.vy2ay(vy))
	end
	def test_typical_before1
		exercise1(0, 0)
	end
	def test_typical_before2
		exercise1(1, 1)
	end
	def test_typical_middle1
		exercise1(5, 2)
	end
	def test_typical_middle2
		exercise1(6, 3)
	end
	def test_typical_after1
		exercise1(10, 4)
	end
	def test_typical_after2
		exercise1(11, 5)
	end
	def test_typeerror1
		e = assert_raise(TypeError) { @view.vy2ay('chad fowler') }
		assert_match(/expected integer/, e.message)
	end
	def test_typeerror2
		e = assert_raise(TypeError) { @view.vy2ay(0.42) }
		assert_match(/expected integer/, e.message)
	end
	def test_illegal1
		assert_raise(ArgumentError) { @view.vy2ay(-1) }
	end
	def test_illegal2
		assert_raise(ArgumentError) { @view.vy2ay(6) }
	end
end

class TestViewConvertAbsolutey2Visibley < Test::Unit::TestCase
	def setup
		super
		@model = AEditor::Model::Caretaker.new
		@model.load((0..11).to_a.join("\n"))
		@view = AEditor::View::Caretaker.new(@model)
		@model.attach(@view)
		@view.collapse(1, 4)
		@view.collapse(6, 9)
	end
	def teardown
		super
		@model.check_integrity
		@view.check_integrity
	end
	def test_init
		assert_equal([0, 1, 5, 6, 10, 11], @view.visible)
	end
	def exercise1(expected_vy, ay)
		assert_equal(expected_vy, @view.ay2vy(ay))
	end
	def test_typical_before1
		exercise1(0, 0)
	end
	def test_typical_before2
		exercise1(1, 1)
	end
	def test_nonvisible1
		exercise1(1, 2)
	end
	def test_nonvisible2
		exercise1(1, 3)
	end
	def test_nonvisible3
		exercise1(1, 4)
	end
	def test_typical_middle1
		exercise1(2, 5)
	end
	def test_typical_middle2
		exercise1(3, 6)
	end
	def test_nonvisible4
		exercise1(3, 7)
	end
	def test_nonvisible5
		exercise1(3, 8)
	end
	def test_nonvisible6
		exercise1(3, 9)
	end
	def test_typical_after1
		exercise1(4, 10)
	end
	def test_typical_after2
		exercise1(5, 11)
	end
	def test_typeerror1
		e = assert_raise(TypeError) { @view.ay2vy('mauricio fernández') }
		assert_match(/expected integer/, e.message)
	end
	def test_illegal1
		assert_raise(ArgumentError) { @view.ay2vy(-1) }
	end
	def test_illegal2
		assert_raise(ArgumentError) { @view.ay2vy(12) }
	end
end

class TestViewScroll2Cursor < Test::Unit::TestCase
	def setup
		super
		@model = AEditor::Model::Caretaker.new
		@model.load((1..20).to_a.join("\n"))
		@view = AEditor::View::Caretaker.new(@model)
		@model.attach(@view)
		@view.cursor_x, @view.cursor_y = 3, 3
		@view.scroll_x, @view.scroll_y = 3, 3
		@canvas = MockCanvas.new(5, 5)
		@view.canvas = @canvas
	end
	def teardown
		super
		@model.check_integrity
		@view.check_integrity
	end
	def test_init
		assert_equal([3, 3], @view.cursor)
		assert_equal([3, 3], @view.scroll)
	end
	def exercise1(x)
		@view.cursor_x = x
		@view.scroll_to_cursor
		@view.scroll
	end
	def exercise2(y)
		@view.cursor_y = y
		@view.scroll_to_cursor
		@view.scroll
	end
	def test_scroll_left1
		assert_equal([2, 3], exercise1(2))
	end
	def test_noscroll_left1
		assert_equal([3, 3], exercise1(3))
	end
	def test_scroll_right1
		assert_equal([4, 3], exercise1(8))
	end
	def test_noscroll_right1
		assert_equal([3, 3], exercise1(7))
	end
	def test_scroll_up1
		assert_equal([3, 2], exercise2(2))
	end
	def test_noscroll_up1
		assert_equal([3, 3], exercise2(3))
	end
	def test_scroll_down1
		assert_equal([3, 4], exercise2(8))
	end
	def test_noscroll_down1
		assert_equal([3, 3], exercise2(7))
	end
	def exercise_fold1(expected_sy, cy)
		@view.collapse(2, 5)
		@view.scroll_y, @view.cursor_y = 0, cy
		@view.scroll_to_cursor
		assert_equal(expected_sy, @view.scroll_y)
	end
	def test_folded_down1
		exercise_fold1(0, 7)
	end
	def test_folded_down2
		exercise_fold1(1, 8)
	end
	def exercise_fold2(expected_sy, cy)
		@view.collapse(1, 3)
		@view.collapse(5, 8)
		@view.scroll_y, @view.cursor_y = 0, cy
		@view.scroll_to_cursor
		assert_equal(expected_sy, @view.scroll_y)
	end
	def test_folded_down3
		exercise_fold2(0, 9)
	end
	def test_folded_down4
		exercise_fold2(1, 10)
	end
	def test_folded_down5
		exercise_fold2(4, 11)
	end
	def test_folded_down6
		@model.load((1..3).to_a.join("\n"))
		@view.scroll_to_cursor
	end
end

class TestViewMove2End < Test::Unit::TestCase
	def setup
		super
		@model = AEditor::Model::Caretaker.new
		@model.load("line1\nLINE2\n\t3")
		@view = AEditor::View::Caretaker.new(@model)
		@model.attach(@view)
		@view.cursor_x, @view.cursor_y = 0, 0
		@view.scroll_x, @view.scroll_y = 0, 0
		@canvas = MockCanvas.new(3, 1)
		@view.canvas = @canvas
	end
	def teardown
		super
		@model.check_integrity
		@view.check_integrity
	end
	def test_end1
		@view.move_to_lineend
		assert_equal(5, @view.cursor_x)
	end
	def test_end2
		@view.cursor_y = 1
		@view.move_to_lineend
		assert_equal(9, @view.cursor_x)
	end
	def test_end3
		@view.cursor_y = 2
		@view.move_to_lineend
		assert_equal(9, @view.cursor_x)
	end
end


class TestViewMove2Home < Test::Unit::TestCase
	def setup
		super
		@model = AEditor::Model::Caretaker.new
		@model.load("ruvi\n  smed\n\ttextmate\n\n\n\n\t  diakonos")
		@view = AEditor::View::Caretaker.new(@model)
		@model.attach(@view)
		@view.cursor_x, @view.cursor_y = 12, 0
		@view.scroll_x, @view.scroll_y = 0, 0
		@canvas = MockCanvas.new(3, 1)
		@view.canvas = @canvas
	end
	def teardown
		super
		@model.check_integrity
		@view.check_integrity
	end
	def test_normal1
		@view.move_to_linebegin(false)
		assert_equal(0, @view.cursor_x)
		@view.move_to_linebegin(false)
		assert_equal(0, @view.cursor_x)
	end
	def test_normal2
		@view.cursor_y = 1
		@view.move_to_linebegin(false)
		assert_equal(0, @view.cursor_x)
		@view.move_to_linebegin(false)
		assert_equal(0, @view.cursor_x)
	end
	def test_smart1
		@view.cursor_y = 1
		@view.move_to_linebegin(true)
		assert_equal(2, @view.cursor_x)
		@view.move_to_linebegin(true)
		assert_equal(0, @view.cursor_x)
		@view.move_to_linebegin(true)
		assert_equal(2, @view.cursor_x)
	end
	def test_smart_autoindent1
		# in case of empty lines.. we goto the indentation point
		@view.cursor_y = 5
		@view.move_to_linebegin(true)
		assert_equal(8, @view.cursor_x)
		@view.move_to_linebegin(true)
		assert_equal(0, @view.cursor_x)
		@view.move_to_linebegin(true)
		assert_equal(8, @view.cursor_x)
	end
	# TODO: if cursor is inside the indent area.. then goto the string begin..  not goto the linebegin.
end

class TestViewBreakline < Test::Unit::TestCase
	def setup
		super
		@model = AEditor::Model::Caretaker.new
		@view = AEditor::View::Caretaker.new(@model)
		@model.attach(@view)
		@view.cursor_x, @view.cursor_y = 12, 0
		@view.scroll_x, @view.scroll_y = 0, 0
		@canvas = MockCanvas.new(3, 1)
		@view.canvas = @canvas
	end
	def teardown
		super
		@model.check_integrity
		@view.check_integrity
	end
	def test_typical1
		@model.load("lyle")
		@view.cursor_x = 2
		@view.edit_breakline
		assert_equal("ly\nle", @model.text)
		assert_equal(0, @view.cursor_x)
	end
	def test_typical2
		@model.load(" hal9000")
		@view.cursor_x = 3
		@view.edit_breakline
		assert_equal(" ha\n l9000", @model.text)
		assert_equal(1, @view.cursor_x)
	end
	def test_typical3
		@model.load("    ts")
		@view.cursor_x = 2
		@view.edit_breakline
		assert_equal("\n    ts", @model.text)
		assert_equal([2, 1], @view.cursor)
		@view.edit_breakline
		assert_equal("\n\n    ts", @model.text)
		assert_equal([2, 2], @view.cursor)
	end
	def test_typical4
		@model.load("tom\n  copeland")
		@view.cursor_x, @view.cursor_y = 2, 1
		@view.edit_breakline
		assert_equal("tom\n\n  copeland", @model.text)
		assert_equal([2, 2], @view.cursor)
		@view.edit_breakline
		assert_equal("tom\n\n\n  copeland", @model.text)
		assert_equal([2, 3], @view.cursor)
	end
	def test_typical5
		@model.load("abc\n\n\n\ndef")
		@view.cursor_x, @view.cursor_y = 4, 2
		@view.edit_breakline
		assert_equal("abc\n\n\n\n\ndef", @model.text)
		assert_equal([4, 3], @view.cursor)
	end
end


class TestViewFolding < Test::Unit::TestCase
	def setup
		super
		@model = AEditor::Model::Caretaker.new
		@model.load((1..9).to_a.join("\n"))
		@view = AEditor::View::Caretaker.new(@model)
		@model.attach(@view)
		@view.cursor_x, @view.cursor_y = 0, 0
		@view.scroll_x, @view.scroll_y = 0, 0
		@canvas = MockCanvas.new(3, 3)
		@view.canvas, @canvas.view = @canvas, @view
		@view.resize(3, 3)
	end
	def teardown
		super
		@model.check_integrity
		@view.check_integrity
	end
	def test_init1
		assert_equal([0]*9, @view.folds)
		assert_equal((0..8).to_a, @view.visible)
	end
	def test_typical1
		@view.collapse(3, 5)
		assert_equal([0, 0, 0, 2, 0, 0, 0, 0, 0], @view.folds)
		assert_equal([0, 1, 2, 3, 6, 7, 8], @view.visible)
		@view.collapse(1, 7)
		assert_equal([0, 6, 0, 2, 0, 0, 0, 0, 0], @view.folds)
		assert_equal([0, 1, 8], @view.visible)
	end
	def test_typeerror1
		assert_raise(TypeError) { @view.collapse('hal fulton', 5) }
		assert_raise(TypeError) { @view.collapse(5, 'david a black') }
	end
	def test_bad1
		e = assert_raise(ArgumentError) { @view.collapse(5, 4) }
		assert_match(/second argument must be greater than first/, e.message)
	end
	def test_bad2
		e = assert_raise(ArgumentError) { @view.collapse(-1, 4) }
		assert_match(/invalid line number/, e.message)
	end
	def test_bad2
		e = assert_raise(ArgumentError) { @view.collapse(4, 9) }
		assert_match(/invalid line number/, e.message)
	end
	def test_render1
		assert_equal(["1\n", "2\n", "3\n"], @canvas.repaint_output)
		@view.collapse(1, 3)
		@canvas.clear
		assert_equal(["1\n", "2\n", "5\n"], @canvas.repaint_output)
	end
	def exercise1(sy)
		@view.collapse(0, 3)
		@view.collapse(4, 6)
		assert_equal(["1\n", "5\n", "8\n"], @canvas.repaint_output)
		@canvas.clear
		@view.scroll_y = sy
		assert_equal(["5\n", "8\n", "9"], @canvas.repaint_output)
	end
	def test_render2_ciel1
		exercise1(1)
	end
	def test_render2_ciel2
		exercise1(2)
	end
	def test_render2_ciel3
		exercise1(3)
	end
	def test_render2  # this is the normal case
		exercise1(4)
	end
end

class TestViewMovePagedown < Test::Unit::TestCase
	def setup
		super
		@model = AEditor::Model::Caretaker.new
		@model.load((1..15).to_a.join("\n"))
		@view = AEditor::View::Caretaker.new(@model)
		@model.attach(@view)
		@view.cursor_x, @view.cursor_y = 0, 0
		@view.scroll_x, @view.scroll_y = 0, 0
		@view.resize(10, 3)
	end
	def teardown
		super
		@model.check_integrity
		@view.check_integrity
	end
	def exercise1(expected_cy, expected_sy, cy=nil, sy=nil)
		@view.cursor_y = cy if cy
		@view.scroll_y = sy if sy
		@view.move_pagedown
		assert_equal(expected_cy, @view.cursor_y)
		assert_equal(expected_sy, @view.scroll_y)
	end
	def test_typical1
		exercise1(2, 2, 0, 0)
		exercise1(4, 4)
	end
	def test_typical2
		exercise1(3, 2, 1, 0)
		exercise1(5, 4)
	end
	def test_typical3
		exercise1(4, 2, 2, 0)
		exercise1(6, 4)
	end
	def test_folded1
		@view.collapse(1, 4)
		exercise1(5, 5, 0, 0)
	end
	def test_folded2
		@view.collapse(0, 3)
		@view.collapse(4, 7)
		exercise1(8, 8, 0, 0)
	end
	def test_folded3
		@view.collapse(0, 3)
		@view.collapse(4, 7)
		exercise1(9, 8, 4, 0)
	end
	def test_folded4
		@view.collapse(0, 3)
		@view.collapse(4, 7)
		exercise1(10, 8, 8, 0)
	end
	def test_end1
		exercise1(14, 13, 12, 11)
	end
	def test_end2
		exercise1(14, 12, 13, 11)
	end
	def test_end3
		@view.resize(10, 4)
		exercise1(13, 12, 10, 9)
		exercise1(14, 12)
	end
end

class TestViewMovePageup < Test::Unit::TestCase
	def setup
		super
		@model = AEditor::Model::Caretaker.new
		@model.load((1..15).to_a.join("\n"))
		@view = AEditor::View::Caretaker.new(@model)
		@model.attach(@view)
		@view.cursor_x, @view.cursor_y = 0, 14
		@view.scroll_x, @view.scroll_y = 0, 14
		@view.resize(10, 4)
	end
	def teardown
		super
		@model.check_integrity
		@view.check_integrity
	end
	def exercise1(expected_cy, expected_sy, cy=nil, sy=nil)
		@view.cursor_y = cy if cy
		@view.scroll_y = sy if sy
		@view.move_pageup
		assert_equal(expected_cy, @view.cursor_y)
		assert_equal(expected_sy, @view.scroll_y)
	end
	def test_typical1
		exercise1(10, 9, 13, 12)
		exercise1(7, 6)
		exercise1(4, 3)
	end
	def test_begin1
		exercise1(1, 0, 3, 2)
		exercise1(0, 0)
	end
end

class TestViewMoveTopBottom < Test::Unit::TestCase
	def setup
		super
		@model = AEditor::Model::Caretaker.new
		@model.load((1..15).to_a.join("\n"))
		@view = AEditor::View::Caretaker.new(@model)
		@model.attach(@view)
		@view.cursor_x, @view.cursor_y = 1, 7
		@view.scroll_x, @view.scroll_y = 0, 5
		@view.resize(10, 3)
	end
	def teardown
		super
		@model.check_integrity
		@view.check_integrity
	end
	def test_top1
		@view.move_top
		assert_equal(0, @view.cursor_y)
	end
	def test_bottom1
		@view.move_bottom
		assert_equal(14, @view.cursor_y)
	end
end

class TestViewMoveWordright < Test::Unit::TestCase
	def setup
		super
		@model = AEditor::Model::Caretaker.new
		@model.load("empty")
		@view = AEditor::View::Caretaker.new(@model)
		@model.attach(@view)
		@view.cursor_x, @view.cursor_y = 0, 0
		@view.scroll_x, @view.scroll_y = 0, 0
		@view.resize(10, 3)
	end
	def teardown
		super
		@model.check_integrity
		@view.check_integrity
	end
	def exercise1(input_str, times_right, expected_x)
		@model.load(input_str)
		ary_x = [@view.cursor_x]
		ary_return = []
		times_right.times do
			ary_return << @view.move_wordright
			ary_x << @view.cursor_x
		end
		assert_equal(expected_x, ary_x)
		ary_return
	end
	def test_typical1
		ret = exercise1("abcd ef g\nxyz", 6, [0, 4, 5, 7, 8, 9, 9])
		assert_equal([true, true, true, true, true, false], ret)
	end
	def test_typical2
		@canvas = MockCanvas.new(4, 2)  # this sets tabsize=8
		@view.resize(4, 2)
		@view.canvas, @canvas.view = @canvas, @view
		exercise1("\tab\t\nxyz", 4, [0, 8, 10, 16, 16])
	end
	def test_typical3
		exercise1("obj.call_me(42, 3.4, count)\nxyz", 15, 
			[0, 3, 4, 11, 12, 14, 15, 16, 17, 18, 19, 20, 21, 26, 27, 27])
	end
end

class TestViewMoveWordleft < Test::Unit::TestCase
	def setup
		super
		@model = AEditor::Model::Caretaker.new
		@model.load("empty")
		@view = AEditor::View::Caretaker.new(@model)
		@model.attach(@view)
		@view.cursor_x, @view.cursor_y = 0, 0
		@view.scroll_x, @view.scroll_y = 0, 0
		@view.resize(10, 3)
	end
	def teardown
		super
		@model.check_integrity
		@view.check_integrity
	end
	def exercise1(input_str, times_left, expected_x)
		model = @model.load(input_str)
		@view.move_to_lineend
		ary_x = [@view.cursor_x]
		ary_return = []
		times_left.times do
			ary_return << @view.move_wordleft
			ary_x.unshift(@view.cursor_x)
		end
		assert_equal(expected_x, ary_x)
		ary_return
	end
	def test_typical1
		ret = exercise1("abcd ef g\nxyz", 6, [0, 0, 4, 5, 7, 8, 9])
		assert_equal([true, true, true, true, true, false], ret)
	end
	def test_typical2
		exercise1("obj.call_me(42, 3.4, count)\nxyz", 15, 
			[0, 0, 3, 4, 11, 12, 14, 15, 16, 17, 18, 19, 20, 21, 26, 27])
	end
	def test_typical3
		@canvas = MockCanvas.new(4, 2)  # this sets tabsize=8
		@view.resize(4, 2)
		@view.canvas, @canvas.view = @canvas, @view
		exercise1("\tab\t\nxyz", 4, [0, 0, 8, 10, 16])
	end
end

class TestViewSelectionGet < Test::Unit::TestCase
	def setup
		super
		@model = AEditor::Model::Caretaker.new
		@model.load("Alexander Kellett\nAllan Odgaard\nBram Moolenar")
		@view = AEditor::View::Caretaker.new(@model)
		@model.attach(@view)
		@view.cursor_x, @view.cursor_y = 0, 0
		@view.scroll_x, @view.scroll_y = 0, 0
		@view.resize(10, 4)
	end
	def teardown
		super
		@model.check_integrity
		@view.check_integrity
	end
	def test_typical1
		@view.cursor_x, @view.cursor_y = 3, 0
		@view.selection_begin
		@view.cursor_x, @view.cursor_y = 8, 0
		assert_equal("xande", @view.selection)
	end
	def test_typical2
		@view.cursor_x, @view.cursor_y = 2, 1
		@view.selection_begin
		@view.cursor_x, @view.cursor_y = 12, 0
		assert_equal("llett\nAl", @view.selection)
	end
	def test_typical3
		@view.collapse(1, 2)
		@view.cursor_x, @view.cursor_y = 16, 0
		@view.selection_begin
		@view.cursor_x, @view.cursor_y = 1, 2
		assert_equal("t\nAllan Odgaard\nB", @view.selection)
	end
end


class TestViewSearch < Test::Unit::TestCase
	TEXT = <<-EOTEXT.gsub(/^\s*/, '')
	I began programming on an Amiga500 with AMOS.
	AMOS had it's own IDE where multiple lines could be 
	collapsed into a single line. Later I switched to 
	Turbo Pascal, which also were a nice environment.
	I learned OOP and assembler, got addicted to introes.
	EOTEXT
	def setup
		super
		@model = AEditor::Model::Caretaker.new
		@model.load(TEXT)
		@view = AEditor::View::Caretaker.new(@model)
		@model.attach(@view)
		@view.cursor_x, @view.cursor_y = 0, 0
		@view.scroll_x, @view.scroll_y = 0, 0
		@view.resize(10, 4)
	end
	def teardown
		super
		@model.check_integrity
		@view.check_integrity
	end
	def exercise_down(exp_cx, exp_cy, exp_sx, exp_sy)
		assert_equal(true, @view.search_down)
		assert_equal(exp_cy, @view.cursor_y)
		assert_equal(exp_cx, @view.cursor_x)
		assert_equal(exp_sy, @view.sel_y)
		assert_equal(exp_sx, @view.sel_x)
	end
	def exercise_down_bottom(exp_cx, exp_cy)
		assert_equal(false, @view.search_down)
		assert_equal(exp_cy, @view.cursor_y)
		assert_equal(exp_cx, @view.cursor_x)
	end
	def test_typical_down1
		assert_equal(2, @view.search_init("a "))
		exercise_down(17, 2, 15, 2)
		exercise_down(32, 3, 30, 3)
		exercise_down_bottom(32, 3)
	end
	def test_typical_down2
		assert_equal(2, @view.search_init("AMOS"))
		exercise_down(44, 0, 40, 0)
		exercise_down(4, 1, 0, 1)
		exercise_down_bottom(4, 1)
	end
	def test_typical_down3
		assert_equal(1, @view.search_init(/IDE.*OOP/um))
		exercise_down(13, 4, 18, 1)
		exercise_down_bottom(13, 4)
	end
	def test_sync1
		assert_equal(1, @view.search_init(/\d+/u))
		@model.load("mov ax,13;\nint 10;")
		exercise_down(9, 0, 7, 0)
		exercise_down(6, 1, 4, 1)
		exercise_down_bottom(6, 1)
	end
	def test_typeerror1
		e = assert_raise(TypeError) { @view.search_init(nil) }
		assert_match("String or Regexp", e.message)
	end
	def exercise_up(exp_cx, exp_cy, exp_sx, exp_sy)
		assert_equal(true, @view.search_up)
		assert_equal(exp_cy, @view.cursor_y)
		assert_equal(exp_cx, @view.cursor_x)
		assert_equal(exp_sy, @view.sel_y)
		assert_equal(exp_sx, @view.sel_x)
	end
	def exercise_up_top(exp_cx, exp_cy)
		assert_equal(false, @view.search_up)
		assert_equal(exp_cy, @view.cursor_y)
		assert_equal(exp_cx, @view.cursor_x)
	end
	def test_typical_up1
		@view.cursor_x, @view.cursor_y = 53, 4
		assert_equal(5, @view.search_init("o "))
		exercise_up(43, 4, 45, 4)
		exercise_up(23, 3, 25, 3)
		exercise_up(4, 3, 6, 3)
		exercise_up(48, 2, 50, 2)
		exercise_up(13, 2, 15, 2)
		exercise_up_top(13, 2)
	end
end


class TestViewReplace < Test::Unit::TestCase
	TEXT = <<-EOTEXT.gsub(/^\s*/, '')
	I began programming on an Amiga500 with AMOS.
	AMOS had it's own IDE where multiple lines could be 
	collapsed into a single line. Later I switched to 
	Turbo Pascal, which also were a nice environment.
	I learned OOP and assembler, got addicted to introes.
	EOTEXT
	def setup
		super
		@model = AEditor::Model::Caretaker.new
		@model.load(TEXT)
		@view = AEditor::View::Caretaker.new(@model)
		@model.attach(@view)
		@view.cursor_x, @view.cursor_y = 0, 0
		@view.scroll_x, @view.scroll_y = 0, 0
		@view.resize(10, 4)
	end
	def teardown
		super
		@model.check_integrity
		@view.check_integrity
	end
	def test_1
		# TODO: implement me
	end
end


class TestLRUCache < Test::Unit::TestCase
	def setup
		@lru = AEditor::Lexer::LRU.new
	end
	def test_init
		assert_equal(1, @lru.capacity)
	end
	def test_store1
		@lru.resize(4)
		assert_equal([], @lru.used)
		@lru[5] = 'im 5'
		assert_equal([5], @lru.used)
		@lru[3] = 'im 3'
		assert_equal([3, 5], @lru.used)
		@lru[7] = 'im 7'
		assert_equal([7, 3, 5], @lru.used)
		@lru[1] = 'im 1'
		assert_equal([1, 7, 3, 5], @lru.used)
		assert_equal([1, 3, 5, 7], @lru.pens.keys.sort)
		@lru[9] = 'im 9'
		assert_equal([9, 1, 7, 3], @lru.used)
		assert_equal([1, 3, 7, 9], @lru.pens.keys.sort)
		@lru.resize(2)
		assert_equal([9, 1], @lru.used)
		assert_equal([1, 9], @lru.pens.keys.sort)
		assert_equal(true, @lru.has_key?(1))
		assert_equal(false, @lru.has_key?(3))
	end
	def test_store2
		@lru.resize(4)
		@lru[3] = 'c'
		@lru[1] = 'a'
		@lru[2] = 'b'
		assert_equal([2, 1, 3], @lru.used)
		@lru[1] = 'A'
		assert_equal([1, 2, 3], @lru.used)
	end
	def test_load1
		@lru.resize(4)
		@lru[1] = 'a'
		@lru[2] = 'b'
		@lru[3] = 'c'
		assert_equal('a', @lru[1])
		assert_equal('b', @lru[2])
		assert_equal('c', @lru[3])
		assert_equal(nil, @lru[4])
	end
	def test_insert1
		@lru.resize(4)
		@lru[3] = 'z'
		@lru[1] = 'x'
		@lru[2] = 'y'
		assert_equal(%w(x y z), @lru.pens.values.sort)
		assert_equal([1, 2, 3], @lru.pens.keys.sort)
		@lru.insert(2, 1)
		assert_equal([3, 1, 4], @lru.used)
		assert_equal(%w(x y z), @lru.pens.values.sort)
		assert_equal([1, 3, 4], @lru.pens.keys.sort)
	end
	def test_remove1
		@lru.resize(4)
		@lru[3] = 'z'
		@lru[1] = 'x'
		@lru[2] = 'y'
		@lru[4] = 'w'
		@lru.remove(2, 2)
		assert_equal([2, 1], @lru.used)
		assert_equal(%w(w x), @lru.pens.values.sort)
		assert_equal([1, 2], @lru.pens.keys.sort)
	end
	def test_delete1
		@lru.resize(4)
		@lru[3] = 'z'
		@lru[1] = 'x'
		@lru[2] = 'y'
		assert_equal('x', @lru.delete(1))
		assert_equal([2, 3], @lru.used)
		assert_equal(%w(y z), @lru.pens.values.sort)
		assert_equal([2, 3], @lru.pens.keys.sort)
		assert_equal('y', @lru.delete(2))
		assert_equal([3], @lru.used)
		assert_equal(%w(z), @lru.pens.values.sort)
		assert_equal([3], @lru.pens.keys.sort)
	end
end

module LexerHelpers
	def a_size(count)
		assert_equal(count, @lexer.lru.size)
	end
	def lex(line_number)
		@lexer.colorize(line_number)
	end
	def reset
		@lexer.reset_counters
	end
	def a_color(expected, line_number)
		res = @lexer.colorize(line_number)
		e = [expected, expected, expected]
		assert_equal(e, res)
	end
	def a_stats(sync_hit, sync_miss, color_hit, color_miss)
		exp = [sync_hit, sync_miss, color_hit, color_miss]
		res = [@lexer.count_sync_hit, @lexer.count_sync_miss,
			@lexer.count_color_hit, @lexer.count_color_miss]
		assert_equal(exp, res)
		@lexer.reset_counters
	end
	def a_color_stats(color_hit, color_miss)
		exp = [color_hit, color_miss]
		res = [@lexer.count_color_hit, @lexer.count_color_miss]
		assert_equal(exp, res)
		@lexer.reset_counters
	end
	def a_right(*expected_right_states)
		assert_equal(expected_right_states, @lexer.right_states)
	end
	def a_dirty(*expected)
		assert_equal(expected, @lexer.dirty_lines)
	end
	extend self
end

class TestLexerSimple < Test::Unit::TestCase
	class MockLexer < AEditor::Lexer::Simple
		def initialize(model)
			super(model)
			@count = 0
		end
		attr_accessor :count, :right_states
		def lex_line(text)
			@pens = "s#{@count}"
			@right = @count
			@count += 1
			nil
		end
	end
	include LexerHelpers
	def setup
		@model = AEditor::Model::Caretaker.new
		@model.load(('a'..'z').to_a.map{|i| i * 20}.join("\n"))
		@lexer = MockLexer.new(@model)
		@model.attach(@lexer)
		@lexer.resize(10)
	end
	def test_accumulate_by_incremental_access1
		a_size(0)
		a_stats(0, 0, 0, 0)
		a_right()
		lex(0)
		a_stats(0, 0, 0, 1)
		a_right(0)
		lex(1)
		a_stats(1, 0, 0, 1)
		a_right(0, 1)
		lex(2)
		a_stats(2, 0, 0, 1)
		a_right(0, 1, 2)
		lex(3)
		a_stats(3, 0, 0, 1)
		a_right(0, 1, 2, 3)
		a_size(4)
	end
	def test_accumulate_by_random_access1
		lex(2)
		a_dirty(false, false, false)
		a_stats(0, 2, 0, 1)
		a_right(0, 1, 2)
		lex(5)
		a_stats(3, 2, 0, 1)
		a_right(0, 1, 2, 3, 4, 5)
		lex(3)
		a_stats(3, 0, 0, 1)
		a_right(0, 1, 2, 6, 4, 5)
		a_dirty(false, false, false, false, true, false)
		lex(2)
		a_stats(2, 0, 1, 0)
		a_right(0, 1, 2, 6, 4, 5)
		a_dirty(false, false, false, false, true, false)
		lex(5)
		a_right(0, 1, 2, 6, 7, 8)
		a_stats(4, 1, 0, 1)
		a_size(3)
	end
	def test_typical1
		assert_equal("s0", @lexer.colorize(0))
		assert_equal("s1", @lexer.colorize(1))
		a_color_stats(0, 2)
		assert_equal("s0", @lexer.colorize(0))
		assert_equal("s1", @lexer.colorize(1))
		a_color_stats(2, 0)
		assert_equal("s2", @lexer.colorize(2))
		a_color_stats(0, 1)
	end
	def test_modelnotify_same1
		lex(5)
		@model.replace(0, 2, 1, 2, "0")
		a_right(0, 1, 2, 3, 4, 5)
		a_dirty(false, false, true, false, false, false)
	end
	def test_modelnotify_same2
		lex(5)
		@model.replace(0, 2, 1, 3, "0\n0")
		a_right(0, 1, 2, 3, 4, 5)
		a_dirty(false, false, true, true, false, false)
	end
	def test_modelnotify_remove1
		lex(5)
		@model.replace(0, 2, 0, 3, "")
		a_right(0, 1, 3, 4, 5)
		a_dirty(false, false, true, false, false)
	end
	def test_modelnotify_remove2
		lex(5)
		@model.replace(0, 1, 0, 4, "")
		a_right(0, 4, 5)
		a_dirty(false, true, false)
	end
	def test_modelnotify_insert1
		lex(5)
		@model.replace(0, 3, 0, 3, "0\n")
		assert_equal(
			"c0d", 
			@model.line(2)[0, 1] + 
			@model.line(3)[0, 1] + 
			@model.line(4)[0, 1])
		a_right(0, 1, 2, nil, 3, 4, 5)
		a_dirty(false, false, false, true, true, false, false)
	end
	def test_modelnotify_insert2
		lex(5)
		@model.replace(0, 3, 0, 3, "0\n0\n0\n")
		a_right(0, 1, 2, nil, nil, nil, 3, 4, 5)
		a_dirty(false, false, false, true, true, true, true, false, false)
	end
	def test_caching_insert1
		@lexer.resize(5)
		5.times {|y| @lexer.colorize(y) }
		assert_equal([4, 3, 2, 1, 0], @lexer.lru.used)
		@model.replace(0, 2, 0, 2, "0\n")
		# line #2 is dirtified
		# line #3 and #4 is displaced
		assert_equal([5, 4, 1, 0], @lexer.lru.used, 'positive displacement')
	end
	def test_caching_insert2
		@model.load("aaaa\nbbbb\ncccc\ndddd\neeee\nffff")
		@lexer.resize(5)
		5.times {|y| @lexer.colorize(y) }
		assert_equal([4, 3, 2, 1, 0], @lexer.lru.used)
		@model.replace(2, 2, 2, 2, "\n")
		assert_equal("aaaa\nbbbb\ncc\ncc\ndddd\neeee\nffff", @model.text)
		# line #2 is splitted into 2 parts..  which becomes line #2 and #3
		# line #3 and #4 is displaced.. and becomes line #4 and #5
		assert_equal([5, 4, 1, 0], @lexer.lru.used, 'positive displacement')
	end
	def test_caching_remove1
		@lexer.resize(5)
		5.times {|y| @lexer.colorize(y) }
		assert_equal([4, 3, 2, 1, 0], @lexer.lru.used)
		@model.replace(0, 2, 0, 3, "") # delete the whole line
		# line #2 is erased, line #3 is dirtified, these lines are not in the LRU
		assert_equal([3, 1, 0], @lexer.lru.used, 'negative displacement')
	end
	def test_caching_remove2
		@model.load(('a'..'i').to_a.join("\n"))
		@lexer.resize(5)
		5.times {|y| @lexer.colorize(y) }
		assert_equal([4, 3, 2, 1, 0], @lexer.lru.used)
		@model.replace(1, 2, 0, 3, "")  # simulate joinline
		assert_equal("a\nb\ncd\ne\nf\ng\nh\ni", @model.text)
		# line #2 is erased, line #3 is dirtified, these lines are not in the LRU
		assert_equal([3, 1, 0], @lexer.lru.used, 'negative displacement')
	end
	def test_caching_remove3
		@model.load("a\nbcd\nefg\nh")
		@lexer.resize(5)
		4.times {|y| @lexer.colorize(y) }
		assert_equal([3, 2, 1, 0], @lexer.lru.used)
		@model.replace(3, 1, 0, 2, '')  # simulate joinline
		assert_equal("a\nbcdefg\nh", @model.text)
		# line #1 #2 is merged, line #2 is dirtified, these lines are not in the LRU
		assert_equal([2, 0], @lexer.lru.used, 'negative displacement')
	end
	# requesting a line which has already been computed
	# must result in the exact same result as first time
	# it was computed.. because its cached.
	# except if it was too long ago..
	def test_caching1
		assert_equal([], @lexer.lru.pens.keys.sort)
		pens1 = @lexer.colorize(1)
		assert_equal('s1', pens1)
		assert_equal([1], @lexer.lru.pens.keys.sort)
		pens2 = @lexer.colorize(1)
		assert_same(pens1, pens2, 'should be cached')
		@lexer.dirty(1)
		assert_equal([], @lexer.lru.used)
		pens3 = @lexer.colorize(1)
		assert_not_same(pens1, pens3, 'should not be cached')
	end
	def test_caching2
		@lexer.resize(2)
		assert_equal([], @lexer.lru.pens.keys.sort)
		pens1 = @lexer.colorize(1)
		assert_equal('s1', pens1)
		assert_equal([1], @lexer.lru.pens.keys.sort)
		pens2 = @lexer.colorize(2)
		assert_equal('s2', pens2)
		assert_equal([2, 1], @lexer.lru.used)
		pens3 = @lexer.colorize(1)
		assert_same(pens1, pens3, 'should be cached')
		assert_equal([1, 2], @lexer.lru.used)
		pens4 = @lexer.colorize(3)
		assert_equal('s3', pens4)
		assert_equal([3, 1], @lexer.lru.used)
		pens5 = @lexer.colorize(2)
		assert_not_same(pens2, pens5, 'should not be cached')
	end
	def test_caching3
		@lexer.resize(1)
		assert_equal([], @lexer.lru.pens.keys.sort)
		pens1 = @lexer.colorize(1)
		assert_equal('s1', pens1)
		assert_equal([1], @lexer.lru.pens.keys.sort)
		pens2 = @lexer.colorize(2)
		assert_equal('s2', pens2)
		assert_equal([2], @lexer.lru.pens.keys.sort)
		assert_not_same(pens1, pens2, 'should not be cached')
		pens3 = @lexer.colorize(1)  # this is what we want to test
		assert_equal('s3', pens3)
		assert_equal([1], @lexer.lru.pens.keys.sort)
		assert_not_same(pens1, pens3, 'should not be cached')
	end
	def test_caching4
		@lexer.resize(5)
		5.times {|y| @lexer.colorize(y) }
		assert_equal([4, 3, 2, 1, 0], @lexer.lru.used)
		@model.replace(0, 2, 1, 2, '0')
		assert_equal([4, 3, 1, 0], @lexer.lru.used, 'dirtification')
	end
end

class TestLexerReal < Test::Unit::TestCase
	class MockLexer < AEditor::Lexer::Simple
		def initialize(model)
			super(model)
			@count = 0
		end
		attr_accessor :count, :right_states
		def lex_line(text)
			@pens = "s#{@count}"
			@right = @count
			@count += 1
			nil
		end
	end
	include LexerHelpers
	def setup
		@model = AEditor::Model::Caretaker.new
		@model.load(('a'..'z').to_a.map{|i| i * 20}.join("\n"))
		@lexer = MockLexer.new(@model)
		@model.attach(@lexer)
		@lexer.resize(10)
	end
	def test_typical_insert1
		# the number of visible lines is only 5, but due to the LRU
		# and the propagation.. when inserting a new line and in case
		# the view is too narrow then full propagation will occur.
		# in order to avoid it the LRU's capacity must be 5 + number of 
		# newlines that we want to insert
		@lexer.resize(6)  # NOTE: LRU capacity=6, but view height=5.
		5.times {|y| @lexer.colorize(y) }
		assert_equal([4, 3, 2, 1, 0], @lexer.lru.used)
		a_right(0, 1, 2, 3, 4)
		a_color_stats(0, 5)
		@model.replace(5, 1, 5, 1, "\n")
		assert_equal([5, 4, 3, 0], @lexer.lru.used)
		a_right(0, nil, 1, 2, 3, 4)
		a_dirty(false, true, true, false, false, false)
		@lexer.colorize(0)
		a_color_stats(1, 0)
		@lexer.count = 1
		@lexer.colorize(1)
		a_right(0, 1, 1, 2, 3, 4)
		a_dirty(false, false, true, false, false, false)
		assert_equal([1, 0, 5, 4, 3], @lexer.lru.used)
		a_color_stats(0, 1)
		@lexer.count = 1
		@lexer.colorize(2)
		a_color_stats(0, 1)
		a_right(0, 1, 1, 2, 3, 4)
		a_dirty(false, false, false, false, false, false)
		assert_equal([2, 1, 0, 5, 4, 3], @lexer.lru.used)
		@lexer.colorize(3)
		a_right(0, 1, 1, 2, 3, 4)
		a_dirty(false, false, false, false, false, false)
		assert_equal([3, 2, 1, 0, 5, 4], @lexer.lru.used)
		a_color_stats(1, 0)
		@lexer.colorize(4)
		assert_equal([4, 3, 2, 1, 0, 5], @lexer.lru.used)
		a_color_stats(1, 0)
	end
	def test_typical_remove1
		@model.load("aa\nbb\ncc\ndd\nee\nff\ngg\nhh\nii")
		@lexer.erase
		@lexer.resize(7)
		7.times {|y| @lexer.colorize(y) }
		assert_equal([6, 5, 4, 3, 2, 1, 0], @lexer.lru.used)
		a_dirty(false, false, false, false, false, false, false)
		a_right(0, 1, 2, 3, 4, 5, 6)
		a_color_stats(0, 7)
		assert_equal([6, 5, 4, 3, 2, 1, 0], @lexer.lru.used)
		@model.replace(1, 1, 1, 3, '')
		assert_equal("aa\nbd\nee\nff\ngg\nhh\nii", @model.text)
		a_dirty(false, true, false, false, false)
		a_right(0, 3, 4, 5, 6)
		# line #1 and merges with #3 into line #1.. which becomes dirty
		# line #4..#6 gets displaced to #2..#4
		assert_equal([4, 3, 2, 0], @lexer.lru.used)
		@lexer.colorize(0)
		a_color_stats(1, 0)
		assert_equal([0, 4, 3, 2], @lexer.lru.used)
		@lexer.count = 3
		@lexer.colorize(1)
		a_color_stats(0, 1)
		a_right(0, 3, 4, 5, 6)
		a_dirty(false, false, false, false, false)
		assert_equal([1, 0, 4, 3, 2], @lexer.lru.used)
		5.times {|y| @lexer.colorize(2+y) }
		a_color_stats(3, 2)
	end
end




























