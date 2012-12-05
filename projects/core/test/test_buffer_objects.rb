require 'aeditor/backend/buffer_objects'
require 'aeditor/backend/convert'
require 'common'

class TestBufferObjects < Common::TestCase 
	def test_empty1
		bo = Convert.from_string_into_bufferobjs("abc\ndef")
		ary = BufferObjectArray.new(bo)
		assert_equal(false, ary.empty?)
		ary.replace([])
		assert_equal(true, ary.empty?)
	end
	def test_array_line_pop1
		bo = Convert.from_string_into_bufferobjs("abc\ndef")
		ary = BufferObjectArray.new(bo)
		objs, nl = ary.line_pop
		assert_equal("def", objs.to_s)
		assert_equal(nil, nl)
	end
	def test_array_line_pop2
		bo = Convert.from_string_into_bufferobjs("abc\ndef\n")
		ary = BufferObjectArray.new(bo)
		objs, nl = ary.line_pop
		assert_kind_of(BufferObjects::Newline, nl)
		assert_equal("def", objs.to_s)
	end
	def test_array_line_push1
		bo = Convert.from_string_into_bufferobjs("abc\n")
		ary = BufferObjectArray.new(bo)
		bo = Convert.from_string_into_bufferobjs("def")
		ary.line_push(bo, nil)
		assert_equal("abc\ndef", ary.to_s)
	end
	def test_array_line_push2
		bo = Convert.from_string_into_bufferobjs("abc\n")
		ary = BufferObjectArray.new(bo)
		bo = Convert.from_string_into_bufferobjs("def")
		ary.line_push(bo, BufferObjects::Newline.new)
		assert_equal("abc\ndef\n", ary.to_s)
	end
	def test_array_line_push3
		bo = Convert.from_string_into_bufferobjs("abc\n")
		ary = BufferObjectArray.new(bo)
		ary.line_push([], BufferObjects::Newline.new)
		assert_equal("abc\n\n", ary.to_s)
	end
	def test_array_line_shift1
		bo = Convert.from_string_into_bufferobjs("abc")  # End of buffer
		ary = BufferObjectArray.new(bo)
		objs, nl = ary.line_shift
		assert_equal("abc", objs.to_s)
		assert_equal(nil, nl)
	end
	def test_array_line_shift2
		bo = Convert.from_string_into_bufferobjs("abc\ndef")
		ary = BufferObjectArray.new(bo)
		objs, nl = ary.line_shift
		assert_equal("abc", objs.to_s)
		assert_kind_of(BufferObjects::Newline, nl)
	end
	def test_array_line_unshift1
		ary = BufferObjectArray.new
		bo = Convert.from_string_into_bufferobjs("abc") # End of buffer
		ary.line_unshift(bo, nil)
		assert_equal("abc", ary.to_s)
	end
	def test_array_line_unshift2
		bo = Convert.from_string_into_bufferobjs("def\n")
		ary = BufferObjectArray.new(bo)
		bo = Convert.from_string_into_bufferobjs("abc")
		ary.line_unshift(bo, BufferObjects::Newline.new)
		assert_equal("abc\ndef\n", ary.to_s)
	end
	def test_array_line_unshift3
		bo = Convert.from_string_into_bufferobjs("abc\n")
		ary = BufferObjectArray.new(bo)
		ary.line_unshift([], BufferObjects::Newline.new)
		assert_equal("\nabc\n", ary.to_s)
	end
end

TestBufferObjects.run if $0 == __FILE__
