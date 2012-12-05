# links:
# interactive utf8 decoder
# http://software.hixie.ch/utilities/cgi/unicode-decoder/utf8-decoder

require 'test/unit'
require 'iterator'

class TestDecodeUTF8 < Test::Unit::TestCase
	OVERLONG = Iterator::DecodeUTF8::Overlong
	MALFORMED = Iterator::DecodeUTF8::Malformed
	def forward_from_utf8(utf8_string)
		iterator = Iterator::DecodeUTF8.new(utf8_string.create_iterator)
		result = []
		while iterator.has_next?
			result << iterator.current
			iterator.next
		end
		result
	end
	def test_forward_normal1
		pairs = [
			# 1 byte
			[0x00, "\x00"], 
			[0x7f, "\x7f"], 
			# 2 bytes
			[0x80, "\xc2\x80"], 
			[0xa9, "\xc2\xa9"],
			[0x16d, "\xc5\xad"], 
			[0x391, "\xce\x91"],
			[0x7ff, "\xdf\xbf"],
			# 3 bytes
			[0x800, "\xe0\xa0\x80"], 
			[0x2262, "\xe2\x89\xa2"],
			[0xd55c, "\xed\x95\x9c"],
			[0xffff, "\xef\xbf\xbf"],
			# 4 bytes
			[0x10000, "\xf0\x90\x80\x80"], 
			[0x233B4, "\xf0\xa3\x8e\xb4"],
			[0x10ffff, "\xf4\x8f\xbf\xbf"] 
		]
		expected, input = pairs.transpose
		actual = forward_from_utf8(input.join) 
		assert_equal(expected, actual)
	end
	def test_forward_overlong1
		str = 'abcd' +    # 4 bytes of 7bits ascii
			"\xc1\xbf" +  # overlong form of "\x7f"
			'xyz'         # 3 bytes of 7bits ascii
		e = assert_raises(OVERLONG) { forward_from_utf8(str) }
		assert_match('byte-offset=4', e.message)
	end
	def test_forward_malformed1
		str = 'abcde' +   # 5 bytes of 7bits ascii
			"\xff" +      # this byte is not allowed to occur in utf8
			'xy'          # 2 bytes of 7bits ascii
		e = assert_raises(MALFORMED) { forward_from_utf8(str) }
		assert_match('byte-offset=5', e.message)
		assert_match('not a valid UTF8 byte', e.message)
	end
	def test_forward_malformed2
		str = 'abcdef' +  # 6 bytes of 7bits ascii
			"\xfe" +      # this byte is not allowed to occur in utf8
			'xyz'         # 3 bytes of 7bits ascii
		e = assert_raises(MALFORMED) { forward_from_utf8(str) }
		assert_match('byte-offset=6', e.message)
		assert_match('not a valid UTF8 byte', e.message)
	end
	def test_forward_malformed3
		str = 'abc' +     # 3 bytes of 7bits ascii
			"\x80" +      # this is not a valid utf8 first-byte
			"\x80" +      # this is not a valid utf8 first-byte
			'xyzw'        # 4 bytes of 7bits ascii
		e = assert_raises(MALFORMED) { forward_from_utf8(str) }
		assert_match('byte-offset=3', e.message)
		assert_match('unexpected continuation byte', e.message)
	end
	def test_forward_malformed4
		str = 'abc' +     # 3 bytes of 7bits ascii
			"\xc2\x7f" +  # previous sequence is incomplete
			'xyz'         # 3 bytes of 7bits ascii
		e = assert_raises(MALFORMED) { forward_from_utf8(str) }
		assert_match('byte-offset=4', e.message)
		assert_match('previous multibyte sequence is incomplete', e.message)
	end
	def test_forward_malformed5
		str = 'abc' +     # 3 bytes of 7bits ascii
			"\xc2\xcf" +  # second byte is not a continuation byte
			'xyz'         # 3 bytes of 7bits ascii
		e = assert_raises(MALFORMED) { forward_from_utf8(str) }
		assert_match('byte-offset=4', e.message)
		assert_match('previous multibyte sequence is incomplete', e.message)
	end
	def test_forward_malformed6
		str = 'abc' +     # 3 bytes of 7bits ascii
			"\xfe\xa0\x80\x80\x80\x80\x80" +  # 7 bytes values are now allowed
			'xyz'         # 3 bytes of 7bits ascii
		e = assert_raises(MALFORMED) { forward_from_utf8(str) }
		assert_match('byte-offset=3', e.message)
		assert_match('not a valid UTF8 byte', e.message)
	end
	def test_correctness1
		delta = [19, 53, 79]
		ary = []
		last = 0
		1000.times do |i|
			ary << last
			last += delta[i%3]
		end
		assert_equal(ary, forward_from_utf8(ary.pack('U*')), 'forward is broken')
		assert_equal(ary, backward_from_utf8(ary.pack('U*')), 'backward is broken')
	end
	def measure_byte_width_forward(utf8_string)
		byte_iterator = utf8_string.create_iterator
		iterator = Iterator::DecodeUTF8.new(byte_iterator)
		widths = []
		while iterator.has_next?
			old = byte_iterator.position
			iterator.next
			widths << byte_iterator.position - old
		end
		widths
	end
	def measure_byte_width_backward(utf8_string)
		byte_iterator = utf8_string.create_iterator
		iterator = Iterator::DecodeUTF8.new(byte_iterator)
		iterator.last
		widths = []
		while iterator.has_prev?
			old = byte_iterator.position
			iterator.prev
			widths.unshift(old - byte_iterator.position)
		end
		widths
	end
	def assert_byte_width(expected, utf8_string)
		assert_equal(expected, measure_byte_width_forward(utf8_string), '#next is broken')
		assert_equal(expected, measure_byte_width_backward(utf8_string), '#prev is broken')
	end
	def test_nextprev_normal1
		str = "abcd"
		assert_byte_width([1, 1, 1, 1], str)
	end
	def test_nextprev_normal2
		str = "a\xce\x91\xed\x95\x9cbc\xf0\xa3\x8e\xb4d"
		assert_byte_width([1, 2, 3, 1, 1, 4, 1], str)
	end
	def test_nextprev_malformed1
		str = "ab\xfec"   # fe is invalid
		assert_byte_width([1, 1, 1, 1], str)
	end
	def test_nextprev_malformed2
		str = "ab\xffc"   # ff is invalid
		assert_byte_width([1, 1, 1, 1], str)
	end
	def test_nextprev_malformed3
		str = "ab\x80c"   # 80 is invalid
		assert_byte_width([1, 1, 1, 1], str)
	end
	def test_nextprev_malformed4
		str = 'ab' +
			"\xf0\xa3\x8e" + # "\xf0\xa3\x8e\xb4" where the last byte is missing
			"\xf0\xa3\x8e" + # "\xf0\xa3\x8e\xb4" where the last byte is missing
			'cd'  
		assert_byte_width([1, 1, 3, 3, 1, 1], str)
	end
	def test_nextprev_malformed5
		str = 'ab' +
			"\xf0\xa3\x8e" # "\xf0\xa3\x8e\xb4" where the 
			# last byte is missing because of end of file
		assert_byte_width([1, 1, 3], str)
	end
	def test_nextprev_overlong1
		str = 'ab' +
			"\xc1\xbf" + # is overlong
			'cd'  
		assert_byte_width([1, 1, 2, 1, 1], str)
	end
	def measure_positions_forward(utf8_string)
		iterator = Iterator::DecodeUTF8.new(utf8_string.create_iterator)
		positions = []
		positions << iterator.position
		while iterator.has_next?
			iterator.next
			positions << iterator.position
		end
		positions
	end
	def measure_positions_backward(utf8_string)
		iterator = Iterator::DecodeUTF8.new(utf8_string.create_iterator)
		iterator.last
		positions = []
		positions.unshift(iterator.position)
		while iterator.has_prev?
			iterator.prev
			positions.unshift(iterator.position)
		end
		positions
	end
	def assert_positions(expected, utf8_string)
		assert_equal(expected, measure_positions_forward(utf8_string), 'forward is broken')
		assert_equal(expected, measure_positions_backward(utf8_string), 'backward is broken')
	end
	def test_position_normal1
		str = [1000, 9000, 5000, 40, 40000, 100100].pack('U*')
		assert_byte_width([2, 3, 3, 1, 3, 4], str)
		assert_positions((0..6).to_a, str)
	end
	def test_position_malformed1
		str = [1024, 4096].pack('U*') + 
			"\xff" +   # malformed first byte
			[80000, 150150].pack('U*') +
			"\xfe" +   # malformed first byte
			[5000, 12345].pack('U*') +
			"\xf0\xa3\x8e" + # "\xf0\xa3\x8e\xb4" where the last byte is missing
			[666, 256*256].pack('U*') +
			"\xc1\xbf" +  # overlong form of "\x7f"
			[256, 999].pack('U*')
		assert_byte_width([2, 3, 1, 4, 4, 1, 3, 3, 3, 2, 4, 2, 2, 2], str)
		assert_positions((0..14).to_a, str)
	end
	def test_position_malformed2
		str = "ab" +
			"\xff" + # malformed first byte
			"\x80" + # invalid continuation byte
			"\x80" + # invalid continuation byte  
			"ab"
		assert_byte_width([1, 1, 1, 1, 1, 1, 1], str)
		assert_positions((0..7).to_a, str)
	end
	def test_position_malformed3
		str = "ab" +
			"\xef\x80" + # missing last byte
			"\xc0" +     # missing last byte
			"ab"
		assert_byte_width([1, 1, 2, 1, 1, 1], str)
		assert_positions((0..6).to_a, str)
	end
	def test_position_malformed4
		str = "\x80" +   # invalid continuation byte
			"a" +
			"\x80" +     # invalid continuation byte
			"a"
		assert_byte_width([1, 1, 1, 1], str)
		assert_positions((0..4).to_a, str)
	end
	def test_position_malformed5
		str = "\xf7" +   # missing continuation bytes
			"a" +
			"\x80" +     # invalid continuation byte
			"a"
		assert_byte_width([1, 1, 1, 1], str)
		assert_positions((0..4).to_a, str)
	end
	def test_position_malformed6
		str = "a" +
			"\x80" +  # invalid continuation byte
			"\x80" +  # invalid continuation byte
			"\x80" +  # invalid continuation byte
			"\x80" +  # invalid continuation byte
			"\x80" +  # invalid continuation byte
			"\x80" +  # invalid continuation byte
			"a"
		assert_byte_width([1, 1, 1, 1, 1, 1, 1, 1], str)
		assert_positions((0..8).to_a, str)
	end
	def test_clone1
		str = [1024, 4096, 999, 60000, 42].pack('U*')
		iterator = Iterator::DecodeUTF8.new(str.create_iterator)
		iterator.next(2)
		assert_equal(999, iterator.current)
		assert_equal(2, iterator.position)
		i2 = iterator.clone.next
		assert_equal(60000, i2.current)
		assert_equal(3, i2.position)
		# check that clone were harmless
		assert_equal(999, iterator.current)
		assert_equal(2, iterator.position)
	end
	def test_first_last1
		str = [1024, 4096, 999, 60000, 42].pack('U*')
		iterator = Iterator::DecodeUTF8.new(str.create_iterator)
		iterator.next(2)
		assert_equal(999, iterator.current)
		assert_equal(2, iterator.position)
		iterator.first
		assert_equal(1024, iterator.current)
		assert_equal(0, iterator.position)
		iterator.last
		assert_equal(5, iterator.position)
		e = assert_raise(RuntimeError) { iterator.current }
		assert_match('end', e.message)
	end
	def backward_from_utf8(utf8_string)
		iterator = Iterator::DecodeUTF8.new(utf8_string.create_iterator)
		iterator.last
		result = []
		while iterator.has_prev?
			result.unshift(iterator.current_prev)
			iterator.prev
		end
		result
	end
	def test_backward_normal1
		ary = [1024, 4096, 999, 60000, 42]
		str = ary.pack('U*')
		assert_equal(ary, backward_from_utf8(str))
	end
	def test_backward_overlong1
		str = 'abcd' +    # 4 bytes of 7bits ascii
			"\xc1\xbf" +  # overlong form of "\x7f"
			'xyz'         # 3 bytes of 7bits ascii
		e = assert_raises(OVERLONG) { backward_from_utf8(str) }
		assert_match('byte-offset=4', e.message)
	end
	def test_backward_malformed1
		str = 'abcde' +   # 5 bytes of 7bits ascii
			"\xff" +      # this byte is not allowed to occur in utf8
			'xy'          # 2 bytes of 7bits ascii
		e = assert_raises(MALFORMED) { backward_from_utf8(str) }
		assert_match('byte-offset=5', e.message)
		assert_match('not a valid UTF8 byte', e.message)
	end
	def test_backward_malformed2
		str = 'abcdef' +  # 6 bytes of 7bits ascii
			"\xfe" +      # this byte is not allowed to occur in utf8
			'xyz'         # 3 bytes of 7bits ascii
		e = assert_raises(MALFORMED) { backward_from_utf8(str) }
		assert_match('byte-offset=6', e.message)
		assert_match('not a valid UTF8 byte', e.message)
	end
	def test_backward_malformed3
		str = 'abc' +     # 3 bytes of 7bits ascii
			"\x80" +      # this is not a valid utf8 first-byte
			"\x80" +      # this is not a valid utf8 first-byte
			'xyzw'        # 4 bytes of 7bits ascii
		e = assert_raises(MALFORMED) { backward_from_utf8(str) }
		assert_match('byte-offset=4', e.message)
		assert_match('unexpected continuation byte', e.message)
	end
	def test_backward_malformed4
		str = 'abc' +     # 3 bytes of 7bits ascii
			"\xc2\x7f" +  # second byte doesn't have 10 as the most significant bits.
			'xyz'         # 3 bytes of 7bits ascii
		e = assert_raises(MALFORMED) { backward_from_utf8(str) }
		assert_match('byte-offset=4', e.message)
		assert_match('previous multibyte sequence is incomplete', e.message)
	end
	def test_backward_malformed5
		str = 'abc' +     # 3 bytes of 7bits ascii
			"\xfe\xa0\x80\x80\x80\x80\x80" +  # 7 bytes values are now allowed
			'xyz'         # 3 bytes of 7bits ascii
		e = assert_raises(MALFORMED) { backward_from_utf8(str) }
		assert_match('byte-offset=9', e.message)
		assert_match('unexpected continuation byte', e.message)
	end
	def test_backward_malformed5a
		str = 'abc' +     # 3 bytes of 7bits ascii
			"\xfe\xa0\x80\x80\x80\x80" +  # 6 bytes values are now allowed
			'xyz'         # 3 bytes of 7bits ascii
		e = assert_raises(MALFORMED) { backward_from_utf8(str) }
		assert_match('byte-offset=8', e.message)
		assert_match('unexpected continuation byte', e.message)
	end
	def test_first
		str = "abc"  
		bytei = str.create_iterator
		i = Iterator::DecodeUTF8.new(bytei).next
		assert_equal(1, i.position)
		assert_equal(1, bytei.position)
		assert_equal(i, i.first)   # ensure #first returns self
		assert_equal(0, i.position)
		assert_equal(0, bytei.position)
	end
	def test_last
		str = "abc"
		bytei = str.create_iterator
		i = Iterator::DecodeUTF8.new(bytei)
		assert_equal(0, i.position)
		assert_equal(0, bytei.position)
		assert_equal(i, i.last)    # ensure #last returns self 
		assert_equal(3, i.position)
		assert_equal(3, bytei.position)
	end
end

if $0 == __FILE__
	require 'test/unit/ui/console/testrunner'
	Test::Unit::UI::Console::TestRunner.run(TestDecodeUTF8)
end
