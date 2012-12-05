require 'misc'

class DecodeUTF8
	class Overlong < StandardError; end
	class Malformed < StandardError; end
	class << self
		def slice_one_char(utf8_string)
			input = utf8_string
			value = input.shift
			return value if value < 0x80
			raise Malformed if ((value & 0xc0) != 0xc0)
			raise Malformed if value == 0xfe 
			raise Malformed if value == 0xff 
			# determine length of sequence
			bytes = 2 
			bit = 5
			until value[bit] == 0
				bit -= 1
				bytes += 1
			end
			# parse first byte of sequence
			res = value & (0xff >> (8 - bit))
			# parse following bytes in sequence
			input.slice!(0, bytes-1).each{|i| 
				raise Malformed if (i & 0xc0) != 0x80
				res = (res << 6) + (i & 0x3f) 
			}
			# reject overlong form
			raise Overlong if EncodeUTF8.count_bytes(res) != bytes
			res
		end
		def string(input)
			res = []
			until input.empty?
				res << slice_one_char(input)
			end
			res
		end
	end
end

class EncodeUTF8
	class << self
		def count_bytes(unicode_value)
			b = unicode_value.bits
			return 1 if b <= 7
			return 2 if b <= 11 
			return 3 if b <= 16 
			return 4 if b <= 21 
			return 5 if b <= 26 
			6
		end
		def one_char(input)
			bytes = count_bytes(input)
			return [input] if bytes == 1
			mask = (0xfe << (7 - bytes)) & 0xff
			res = []
			while bytes > 1
				res.unshift((input & 0x3f) | 0x80)
				input = input >> 6
				bytes -= 1
			end
			res.unshift mask | input
			res
		end
		def string(input)
			res = []
			input.each{|i| res += one_char(i)}
			res
		end
	end
end

class String
	def to_utf8
		# disassemble into array of fixnum
		ary = self.split(//).map{|char|char[0]}
		# convert
		res = EncodeUTF8.string(ary)
		# assemble into string
		res.map{|int|int.chr}.join
	end
end

if $0 == __FILE__
	text = "få rødgrød med flødeovertræk"
	p text
	p text.to_utf8
end
