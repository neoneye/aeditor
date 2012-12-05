require 'aeditor/backend/convert'
require 'common'

class TestConvert < Common::TestCase 
	def test_buffer2line_1
		buffer_objs = [
			BufferObjects::Text.new("a"[0]),
			BufferObjects::Text.new("\t"[0]),
			BufferObjects::Text.new("b"[0])
		]
		line_objs = Convert.from_bufferobjs_into_lineobjs(buffer_objs)
		assert_equal("a"[0], line_objs[0].ascii_value)
		assert_kind_of(LineObjects::Text, line_objs[0])
		assert_kind_of(LineObjects::Tab, line_objs[1])
		assert_equal("b"[0], line_objs[2].ascii_value)
		assert_kind_of(LineObjects::Text, line_objs[2])
	end
	def test_buffer2line_2
		bof = Convert::from_string_into_bufferobjs("abc\ndef\nghi")
		fold = BufferObjects::Fold.new(bof, "title", true)
		bo1 = Convert::from_string_into_bufferobjs("123")
		bo2 = Convert::from_string_into_bufferobjs("456")
		buffer_objs = bo1 + [fold] + bo2
		line_objs = Convert.from_bufferobjs_into_lineobjs(buffer_objs)
		assert_equal(7, line_objs.size)
		#assert_equal("123", line_objs[0..3])
		assert_equal("1"[0], line_objs.first.ascii_value)
		assert_kind_of(LineObjects::Text, line_objs.first)
		assert_kind_of(LineObjects::Fold, line_objs[3])
		fold = line_objs[3]
		assert_equal("title", fold.title)
		assert_equal(true, fold.whole_line)
		#assert_equal("456", line_objs[3..7])
		assert_equal("6"[0], line_objs.last.ascii_value)
		assert_kind_of(LineObjects::Text, line_objs.last)
	end
	def test_buffer2line_3
		bo = Convert::from_string_into_bufferobjs("abcdef")
		bo[3, 0] = BufferObjects::Mark.new("1")
		line_objs = Convert.from_bufferobjs_into_lineobjs(bo)
		assert_equal(7, line_objs.size)
		#assert_equal("abc", line_objs[0..2])
		assert_equal("a"[0], line_objs.first.ascii_value)
		assert_kind_of(LineObjects::Text, line_objs.first)
		assert_kind_of(LineObjects::Mark, line_objs[3])
		assert_equal("1", line_objs[3].text)
		#assert_equal("def", line_objs[3..6])
		assert_equal("f"[0], line_objs.last.ascii_value)
		assert_kind_of(LineObjects::Text, line_objs.last)
	end
	def test_buffer2line_error1
		bo = Convert::from_string_into_bufferobjs("abcdef")
		bo[3, 0] = "123"  # don't know how to convert this class 
		assert_raises(Convert::CannotConvert) { 
			Convert.from_bufferobjs_into_lineobjs(bo)
		}
	end
	def test_buffer2line_error2
		bo = Convert::from_string_into_bufferobjs("abc\ndef")
		# newline is illegal and should result in exception
		assert_raises(Convert::CannotConvert) { 
			Convert.from_bufferobjs_into_lineobjs(bo)
		}
	end
	def test_line2buffer_1
		line_objs = [
			LineObjects::Text.new("a"[0]),
			LineObjects::Tab.new,
			LineObjects::Text.new("b"[0])
		]
		buffer_objs = Convert::from_lineobjs_into_bufferobjs(line_objs)
		assert_equal("a"[0], buffer_objs[0].ascii_value)
		assert_kind_of(BufferObjects::Text, buffer_objs[0])
		assert_equal("\t"[0], buffer_objs[1].ascii_value)
		assert_kind_of(BufferObjects::Text, buffer_objs[1])
		assert_equal("b"[0], buffer_objs[2].ascii_value)
		assert_kind_of(BufferObjects::Text, buffer_objs[2])
	end
	def test_line2buffer_2
		bof = Convert::from_string_into_bufferobjs("abc\ndef\nghi")
		fold = LineObjects::Fold.new(bof, "{5}", false)
		lo1 = Convert::from_string_into_lineobjs("123")
		lo2 = Convert::from_string_into_lineobjs("456")
		line_objs = lo1 + [fold] + lo2
		buffer_objs = Convert.from_lineobjs_into_bufferobjs(line_objs)
		assert_equal(7, buffer_objs.size)
		#assert_equal("123", buffer_objs[0..3])
		assert_equal("1"[0], buffer_objs.first.ascii_value)
		assert_kind_of(BufferObjects::Text, buffer_objs.first)
		assert_kind_of(BufferObjects::Fold, buffer_objs[3])
		#assert_equal("456", buffer_objs[3..7])
		assert_equal("6"[0], buffer_objs.last.ascii_value)
		assert_kind_of(BufferObjects::Text, buffer_objs.last)
	end
	def test_line2buffer_3
		line_objs = Convert::from_string_into_lineobjs("abcdef")
		line_objs[3, 0] = LineObjects::Mark.new("1")
		buffer_objs = Convert.from_lineobjs_into_bufferobjs(line_objs)
		assert_equal(7, buffer_objs.size)
		#assert_equal("abc", buffer_objs[0..2])
		assert_equal("a"[0], buffer_objs.first.ascii_value)
		assert_kind_of(BufferObjects::Text, buffer_objs.first)
		assert_kind_of(BufferObjects::Mark, buffer_objs[3])
		assert_equal("1", buffer_objs[3].text)
		#assert_equal("def", buffer_objs[4..6])
		assert_equal("f"[0], buffer_objs.last.ascii_value)
		assert_kind_of(BufferObjects::Text, buffer_objs.last)
	end
	def test_line2buffer_error1
		line_objs = [
			LineObjects::Text.new("a"[0]),
			LineObjects::VSpace.new
		]
		assert_raises(Convert::CannotConvert) {
			Convert::from_lineobjs_into_bufferobjs(line_objs)
		}
	end
	def test_string2bufobj1
		bo = Convert::from_string_into_bufferobjs("abc")
		assert_equal(3, bo.size)
		assert_kind_of(BufferObjects::Text, bo[0])
		assert_kind_of(BufferObjects::Text, bo[1])
		assert_kind_of(BufferObjects::Text, bo[2])
	end
	def test_string2bufobj2
		bo = Convert::from_string_into_bufferobjs("a\nc")
		assert_equal(3, bo.size)
		assert_kind_of(BufferObjects::Text, bo[0])
		assert_kind_of(BufferObjects::Newline, bo[1])
		assert_kind_of(BufferObjects::Text, bo[2])
	end
	def test_string2lineobjs
		text = "abc"
		bo = Convert::from_string_into_bufferobjs(text)
		assert_equal(3, bo.size)
		lineobjs = Convert::from_bufferobjs_into_lineobjs(bo)
		assert_equal(3, lineobjs.size)
		assert_equal("a"[0], lineobjs[0].ascii_value)
		assert_equal("b"[0], lineobjs[1].ascii_value)
		assert_equal("c"[0], lineobjs[2].ascii_value)
	end
	def test_string2lineobjs_illegal
		assert_raises(Convert::CannotConvert) { 
			Convert::from_string_into_lineobjs("ab\ncd")
		}
	end
	def test_bufobjs2filestring1
		txt_in = "abc\ndef\nghi"
		bo = Convert::from_string_into_bufferobjs(txt_in)
		txt_out = Convert::from_bufferobjs_into_filestring(bo)
		assert_equal(txt_in, txt_out)
	end
	def test_bufobjs2filestring2
		txt_in = "abcd\nef\nghi"
		expect = txt_in.dup
		bo = Convert::from_string_into_bufferobjs(txt_in)
		bo[2, 0] = BufferObjects::Mark.new
		txt_out = Convert::from_bufferobjs_into_filestring(bo)
		assert_equal(expect, txt_out)
	end
	def test_bufobjs2filestring3
		bo1 = Convert.from_string_into_bufferobjs("abc\nd")
		bo2 = Convert.from_string_into_bufferobjs("01\n23\n45\n67")
		bo3 = Convert.from_string_into_bufferobjs("f\nghi")
		fold = BufferObjects::Fold.new(bo2, "title", "false")
		bo = bo1 + [fold] + bo3
		txt_out = Convert::from_bufferobjs_into_filestring(bo)
		expect = "abc\nd01\n23\n45\n67f\nghi"
		assert_equal(expect, txt_out)
	end
end

TestConvert.run if $0 == __FILE__
