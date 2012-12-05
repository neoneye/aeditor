require 'aeditor/backend/buffer_line'
require 'aeditor/backend/convert'
require 'common'

class FakeBufferLine
	include BufferLine
	def initialize(top=[], bottom=[])
		@data_top = BufferObjectArray.new
		@data_bottom = BufferObjectArray.new
		@data_top.replace(top)
		@data_bottom.replace(bottom)
		@line_top = []
		@line_bottom = []
		@bottom_nl = false
	end
	def bottom_newline?
		@bottom_nl
	end
	attr_reader :data_top, :data_bottom
	attr_accessor :bottom_nl
end

class TestBufferLine < Common::TestCase 
	def test_fake_buffer_line1
		bo = Convert.from_string_into_bufferobjs("abc\n")
		buf = FakeBufferLine.new(bo)
		assert_equal(4, buf.data_top.size)
		assert_equal("abc\n", buf.data_top.to_s)
	end
	def test_fake_buffer_line2
		bo = Convert.from_string_into_bufferobjs("abc\n")
		buf = FakeBufferLine.new([], bo)
		assert_equal(4, buf.data_bottom.size)
		assert_equal("abc\n", buf.data_bottom.to_s)
	end
	def test_export_top1
		bo = Convert.from_string_into_bufferobjs("abc\n")
		buf = FakeBufferLine.new(bo)
		lo = Convert.from_string_into_lineobjs("def")
		line = Line.new(lo, true)
		buf.line_export_top(line)
		assert_equal(8, buf.data_top.size)
		assert_equal("abc\ndef\n", buf.data_top.to_s)
	end
	def test_export_top2
		bo = Convert.from_string_into_bufferobjs("abc\n")
		buf = FakeBufferLine.new(bo)
		lo = Convert.from_string_into_lineobjs("def")
		line = Line.new(lo, false)
		buf.line_export_top(line)
		assert_equal(7, buf.data_top.size)
		assert_equal("abc\ndef", buf.data_top.to_s)
	end
	def test_export_bottom1
		bo = Convert.from_string_into_bufferobjs("def\n")
		buf = FakeBufferLine.new([], bo)
		lo = Convert.from_string_into_lineobjs("abc")
		line = Line.new(lo, true)
		buf.line_export_bottom(line)
		assert_equal(8, buf.data_bottom.size)
		assert_equal("abc\ndef\n", buf.data_bottom.to_s)
	end
	def test_export_bottom2
		buf = FakeBufferLine.new([], [])
		lo = Convert.from_string_into_lineobjs("abc")
		line = Line.new(lo, false)
		buf.line_export_bottom(line)
		assert_equal(3, buf.data_bottom.size)
		assert_equal("abc", buf.data_bottom.to_s)
	end
	def test_export_bottom_nil1
		buf = FakeBufferLine.new([], [])
		buf.line_export_bottom(nil)
		assert_equal(true, buf.data_bottom.empty?)  # nil's gets discarded
	end
	def test_import_top1
		bo = Convert.from_string_into_bufferobjs("abcd\nef\n")
		buf = FakeBufferLine.new(bo)
		line = buf.line_import_top
		assert_equal(5, buf.data_top.size)
		assert_equal(2, line.lineobjs.size)
		assert_equal(true, line.newline)
	end
	def test_import_top2
		bo = Convert.from_string_into_bufferobjs("abc\n\n")
		buf = FakeBufferLine.new(bo)
		line = buf.line_import_top
		assert_equal(4, buf.data_top.size)
		assert_equal(0, line.lineobjs.size)
		assert_equal(true, line.newline)
	end
	def test_import_top3
		bo = Convert.from_string_into_bufferobjs("abc\nxy\n")
		bo[5, 0] = BufferObjects::Mark.new
		buf = FakeBufferLine.new(bo)
		line = buf.line_import_top
		assert_equal(4, buf.data_top.size)
		assert_equal(3, line.lineobjs.size)
		assert_equal(true, line.newline)
	end
	def test_import_top4
		buf = FakeBufferLine.new
		assert_raises(BufferTop) { buf.line_import_top }
	end
#	def test_import_top4
#		bo = Convert.from_string_into_bufferobjs("abc")
#		buf = FakeBufferLine.new(bo)
#		assert_raises(BufferLine::IntegrityError) { buf.line_import_top }
#	end
	def test_import_bottom1
		bo = Convert.from_string_into_bufferobjs("ab\ncdef\n")
		buf = FakeBufferLine.new([], bo)
		line = buf.import_bottom
		assert_equal(5, buf.data_bottom.size)
		assert_equal(2, line.lineobjs.size)
		assert_equal(true, line.newline)
	end
	def test_import_bottom2
		bo = Convert.from_string_into_bufferobjs("\nabc\n")
		buf = FakeBufferLine.new([], bo)
		line = buf.import_bottom
		assert_equal(4, buf.data_bottom.size)
		assert_equal(0, line.lineobjs.size)
		assert_equal(true, line.newline)
	end
	def test_import_bottom3
		buf = FakeBufferLine.new
		buf.bottom_nl = true
		assert_equal(true, buf.bottom_newline?)
		line = buf.import_bottom(false)  # no BufferBottom should occur here !
		assert_equal(false, line.newline)
		assert_equal(0, line.lineobjs.size)
	end
	def test_import_bottom4
		buf = FakeBufferLine.new
		buf.bottom_nl = false
		assert_equal(false, buf.bottom_newline?)
		assert_raises(BufferBottom) { buf.import_bottom(false) }
	end
	def test_import_bottom5
		buf = FakeBufferLine.new
		assert_equal(nil, buf.import_bottom(true))
	end
	def test_import_bottom6
		buf = FakeBufferLine.new
		assert_raises(BufferBottom) { buf.import_bottom(false) }
	end
end

TestBufferLine.run if $0 == __FILE__
