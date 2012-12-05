=begin
interactive UTF-8/UTF-16 converter
http://www.fileformat.info/convert/text/utf2utf.htm

good overview of how UTF-16 works:
http://www.azillionmonkeys.com/qed/unicode.html

or read the RFC
ftp://ftp.rfc-editor.org/in-notes/rfc2781.txt
=end
require 'test/unit'
require 'iterator'

class TestDecodeUTF16 < Test::Unit::TestCase
	MALFORMED = Iterator::DecodeUTF16::Malformed
	def word2str(word)
		byte1 = word & 255
		byte0 = (word >> 8) & 255
		return byte0.chr + byte1.chr
	end
	def encode_codepoint(codepoint)
		if (0xd800..0xdfff).member?(codepoint)
			raise "invalid codepoint"
		end
		return word2str(codepoint) if codepoint < 0x10000
		codepoint -= 0x10000
		lo = codepoint & 0x3ff
		hi = codepoint >> 10
		word2str(hi+0xd800) + word2str(lo+0xdc00)
	end
	def encode(codepoints)
		codepoints.map{|cp| encode_codepoint(cp)}.join
	end
	def decode(str)
		byte_iterator = str.create_iterator
		i = Iterator::DecodeUTF16.mk_be(byte_iterator)
		result = nil
		begin
			result = i.to_a
		ensure
			i.close
			byte_iterator.close
		end
		result
	end
	def decode_le(str)
		byte_iterator = str.create_iterator
		i = Iterator::DecodeUTF16.mk_le(byte_iterator)
		result = nil
		begin
			result = i.to_a
		ensure
			i.close
			byte_iterator.close
		end
		result
	end
	MAPPING_BE = [
		[0x007a, "\x00\x7a"],
		[0x6c34, "\x6c\x34"],
		[0xd7ff, "\xd7\xff"],
		# d800..dfff is used for surrogates
		[0xe000, "\xe0\x00"],
		[0xfeff, "\xfe\xff"],
		[0xfffe, "\xff\xfe"],
		# pairs uses the range d800..dfff
		[0x10000, "\xd8\x00\xdc\x00"],
		[0x10001, "\xd8\x00\xdc\x01"],
		[0x1d11e, "\xd8\x34\xdd\x1e"],
		[0x10fffd, "\xdb\xff\xdf\xfd"],
	]
	def self.calc_mapping_le
		codepoints, strings = MAPPING_BE.transpose
		#p strings
		strings.map!{|s| s.unpack('n*').pack('v*') }
		#p strings
		[codepoints, strings].transpose
	end
	MAPPING_LE = calc_mapping_le
	def test_encode_be1
		input, expected = MAPPING_BE.transpose
		actual = encode(input)
		assert_equal(expected.join, actual)
	end
	def test_forward_be_normal1
		expected, input = MAPPING_BE.transpose
		actual = input.map{|str| decode(str)[0] }
		assert_equal(expected, actual)
	end
	def test_forward_be_normal2
		expected, input = MAPPING_BE.transpose
		actual = decode(input.join)
		assert_equal(expected, actual)
	end
	def test_forward_le_normal1
		expected, input = MAPPING_LE.transpose
		actual = decode_le(input.join)
		assert_equal(expected, actual)
	end
	def test_forward_malformed1
		str = "\x00\x42" +        # this is valid
			"\xd8\x00\xdb\x00" +  # malformed
			"\x00\x42"            # this is valid
		e = assert_raise(MALFORMED) { decode(str) }
		assert_match('byte-offset=4', e.message)
		assert_match('previous word (d800) is incomplete', e.message)  
	end
	def test_forward_malformed2
		str = "\x00\x42" +        # this is valid
			"\xd8\x00\xe0\x00" +  # malformed
			"\x00\x42"            # this is valid
		e = assert_raise(MALFORMED) { decode(str) }
		assert_match('byte-offset=4', e.message)
		assert_match('previous word (d800) is incomplete', e.message)  
	end
	def test_forward_malformed3
		str = "\x00\x42" +        # this is valid
			"\xdc\x00" +          # malformed first-byte of pair
			"\x00\x42"            # this is valid
		e = assert_raise(MALFORMED) { decode(str) }
		assert_match('byte-offset=2', e.message)
		assert_match('illegal UTF-16 word (dc00)', e.message)
	end
	def forward_measure_width(string)
		byte_iterator = string.create_iterator
		iterator = Iterator::DecodeUTF16.mk_be(byte_iterator)
		widths = []
		while iterator.has_next?
			old = byte_iterator.position
			iterator.next
			widths << byte_iterator.position - old
		end
		widths
	end
	def forward_measure_position(string)
		byte_iterator = string.create_iterator
		iterator = Iterator::DecodeUTF16.mk_be(byte_iterator)
		positions = [iterator.position]
		while iterator.has_next?
			old = byte_iterator.position
			iterator.next
			positions.push(iterator.position)
		end
		positions
	end
	def test_forward_width1
		str = 
			"\x00\x42" +          # this is valid
			"\xdc\x00" +          # malformed high-byte of pair
			"\xd8\x00" +          # high-byte of pair.. but missing low byte
			"\x00\x42" +          # this is valid
			"\xd8\x00" +          # high-byte of pair.. but malformed low byte 
			"\xdb\x00" +          # malformed high-byte of pair 
			"\x00\x42" +          # this is valid
			"\xd8\x00\xdc\x00"    # this is valid 
		widths = forward_measure_width(str)
		assert_equal([2, 2, 2, 2, 2, 2, 2, 4], widths)
		positions = forward_measure_position(str)
		assert_equal((0..8).to_a, positions)
	end
	def backward_measure_width(string)
		byte_iterator = string.create_iterator
		iterator = Iterator::DecodeUTF16.mk_be(byte_iterator).last
		widths = []
		while iterator.has_prev?
			old = byte_iterator.position
			iterator.prev
			widths.unshift(old - byte_iterator.position)
		end
		widths
	end
	def backward_measure_position(string)
		byte_iterator = string.create_iterator
		iterator = Iterator::DecodeUTF16.mk_be(byte_iterator).last
		positions = [iterator.position]
		while iterator.has_prev?
			iterator.prev
			positions.unshift(iterator.position)
		end
		positions
	end
	def test_backward_width1
		str = 
			"\x00\x42" +          # this is valid
			"\xdc\x00" +          # malformed high-byte of pair
			"\xd8\x00" +          # high-byte of pair.. but missing low byte
			"\x00\x42" +          # this is valid
			"\xd8\x00" +          # high-byte of pair.. but malformed low byte 
			"\xdb\x00" +          # malformed high-byte of pair 
			"\x00\x42" +          # this is valid
			"\xd8\x00\xdc\x00"    # this is valid 
		widths = backward_measure_width(str)
		assert_equal([2, 2, 2, 2, 2, 2, 2, 4], widths)
		positions = backward_measure_position(str)
		assert_equal((0..8).to_a, positions)
	end
	def rev_decode(str)
		byte_iterator = str.create_iterator
		i = Iterator::DecodeUTF16.mk_be(byte_iterator).last
		result = []
		begin
			while i.has_prev?
				result.unshift(i.current_prev)
				i.prev
			end
		ensure
			i.close
			byte_iterator.close
		end
		result
	end
	def test_backward_normal1
		expected, input = MAPPING_BE.transpose
		actual = rev_decode(input.join)
		assert_equal(expected, actual)
	end
	def test_backward_malformed1
		str = "\x00\x42" +        # this is valid
			"\xd8\x00\xdb\x00" +  # malformed
			"\x00\x42"            # this is valid
		e = assert_raise(MALFORMED) { rev_decode(str) }
		assert_match('byte-offset=6', e.message)
		assert_match('previous word (db00) is incomplete', e.message)  
	end
	def test_backward_malformed2
		str = "\x00\x42" +        # this is valid
			"\xd8\x00\xe0\x00" +  # malformed
			"\x00\x42"            # this is valid
		e = assert_raise(MALFORMED) { rev_decode(str) }
		assert_match('byte-offset=4', e.message)
		assert_match('previous word (d800) is incomplete', e.message)  
	end
	def test_backward_malformed3
		str = "\x00\x42" +        # this is valid
			"\xdc\x00" +          # malformed first-byte of pair
			"\x00\x42"            # this is valid
		e = assert_raise(MALFORMED) { rev_decode(str) }
		assert_match('byte-offset=2', e.message)
		assert_match('illegal UTF-16 word (dc00)', e.message)
	end
	def test_clone1
		str = "\x00\x55" + 
			"\xd8\x00\xdc\x55" + 
			"\x99\x55" + 
			"\xdb\xff\xdf\xfd" +
			"\x42\x42"
		byte_iterator = str.create_iterator
		i = Iterator::DecodeUTF16.mk_be(byte_iterator).next(1)
		assert_equal(0x10055, i.current)
		assert_equal(1, i.position)
		i2 = i.clone.next(2)
		assert_equal(0x10fffd, i2.current)
		assert_equal(3, i2.position)
		# check harmless
		assert_equal(0x10055, i.current)
		assert_equal(1, i.position)
	end
	# TODO: little endian should work.. but more testing wouldn't hurt
	# TODO: invalid codepoints supplied to encode.. exercise the 0xd800..0xdfff range
	def test_encode_decode1
		codepoints = [
			0x0042,
			0x0666,
			0xd7ff,
			# d800..dfff is dedicated to surrogates
			0xe000,
			0x10000,
			0x100000,
			0x10ffff,
		]
		str = encode(codepoints)
		actual = decode(str)
		assert_equal(codepoints, actual)
	end
end

if $0 == __FILE__
	require 'test/unit/ui/console/testrunner'
	Test::Unit::UI::Console::TestRunner.run(TestDecodeUTF16)
end
