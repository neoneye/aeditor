require 'unicode'
require 'test/unit'

class TestConvert < Test::Unit::TestCase
	def utf8_count(value)
		EncodeUTF8.count_bytes(value)
	end
	def utf8_to_ucs4(input)
		DecodeUTF8.slice_one_char(input)
	end
	def ucs4_to_utf8(input)
		EncodeUTF8.one_char(input)
	end
	def encode_utf8_decode(input)
		s = EncodeUTF8.string(input)
		DecodeUTF8.string(s)
	end
	def test_utf8_count
		inout = [
			1, 0x00,
			1, 0x0a,
			1, 0x7f,
			2, 0x80,
			2, 0x16d,
			2, 0x7ff,
			3, 0x800,
			3, 0xffff,
			4, 0x10000,
			4, 0x1fffff,
			5, 0x200000,
			5, 0x3ffffff,
			6, 0x4000000,
		]
		ok = true
		input, expected = inout.partition{|i| ok = !ok}
		output = input.map{|i| utf8_count(i)}
		assert_equal(expected, output)
	end
	def test_utf8_to_ucs4
		inout = [
			# 1 byte
			0x00000000, [0x00], 
			0x0000007f, [0x7f], 
			# 2 bytes
			0x00000080, [0xc0|0x02, 0x80|0x00], 
			0x000000a9, [0xc0|0x02, 0x80|0x29],  # copyright
			0x0000016d, [0xc0|0x05, 0x80|0x2d], 
			0x000007ff, [0xc0|0x1f, 0x80|0x3f], 
			# 3 bytes
			0x00000800, [0xe0|0x00, 0x80|0x20, 0x80|0x00], 
			0x0000ffff, [0xe0|0x0f, 0x80|0x3f, 0x80|0x3f] 
		]
		ok = true
		input, expected = inout.partition{|i| ok = !ok}
		output = input.map{|i| utf8_to_ucs4(i)}
		assert_equal(expected, output)
	end
	def assert_exception_array(exception, input)
		errors = []
		input.each_index{|i|
			begin
				begin
					data = input[i]
					yield(data)
					if data.size != 0
						raise <<MSG
length is wrong, utf8 didn't consume all bytes.
There is #{data.size} bytes left which hasn't been consumed." 
MSG
					end
					raise "no #{exception} exception were thrown"
				rescue exception
				end
			rescue => e
				errors << [i, input[i], e]
			end
		}
		assert_equal([], errors)
	end
	def test_uft8_to_ucs4_overlong
		input = [
			# 2 byte overlong form
			[0xc0, 0x8a],        # U+0000000a
			[0xc1, 0x80],        # U+00000040
			[0xc1, 0xbf],        # U+0000007f
			# 3 byte overlong form
			[0xe0, 0x80, 0x8a],  # U+0000000a
			[0xe0, 0x82, 0xa9],  # U+000000a9 copyright
			# 4 byte overlong form
			[0xe0, 0x80, 0x80, 0x8a], # U+0000000a
		]
		assert_exception_array(DecodeUTF8::Overlong, input) {|i|
			utf8_to_ucs4(i)
		}
	end
	def test_uft8_to_ucs4_malformed
		input = [
			# illegal as initial byte
			[0x80],
			[0x80|0x1a],
			[0x80|0x3f],
			# illegal; prohibited by spec
			[0xfe],
			[0xff],
			# other illegal combinations
			[0xc1, 0x10],
			[0xe3, 0x89, 0x10],
		]
		assert_exception_array(DecodeUTF8::Malformed, input) {|i|
			utf8_to_ucs4(i)
		}
	end
	def test_ucs4_to_utf8
		inout = [
			# 1 byte
			0x00000000, [0x00], 
			0x0000007f, [0x7f], 
			# 2 bytes
			0x00000080, [0xc0|0x02, 0x80|0x00], 
			0x000000a9, [0xc0|0x02, 0x80|0x29],  # copyright
			0x0000016d, [0xc0|0x05, 0x80|0x2d], 
			0x000007ff, [0xc0|0x1f, 0x80|0x3f], 
			# 3 bytes
			0x00000800, [0xe0|0x00, 0x80|0x20, 0x80|0x00], 
			0x0000ffff, [0xe0|0x0f, 0x80|0x3f, 0x80|0x3f] 
		]
		ok = false
		input, expected = inout.partition{|i| ok = !ok}
		output = input.map{|i| ucs4_to_utf8(i)}
		assert_equal(expected, output)
	end
	def test_encode_decode
		input = [
			0x0a,
			0x7f, 
			0x80, 
			0x7ff,
			0x800,
			0x10000
		]
		output = encode_utf8_decode(input)
		assert_equal(input, output)
	end
end

if $0 == __FILE__
	require 'test/unit/ui/console/testrunner'
	Test::Unit::UI::Console::TestRunner.run(TestConvert)
end
