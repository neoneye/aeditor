module SymbolNames
	CURLY_BEGIN = ?{
	CURLY_END = ?}
	PARA_BEGIN = ?(
	PARA_END = ?)
	BRACKET_BEGIN = ?[
	BRACKET_END = ?]
	LESS_THAN = ?<
	GREATER_THAN = ?>
	QUESTION_MARK = ??
	EXCLAMATION_MARK = ?!
	SPLAT = ?*
	PLUS = ?+
	MINUS = ?-
	UNDERSCORE = ?_
	COLON = ?:
	EQUAL = ?=
	SHARP = ?#
	PIPE = ?|
	COMMA = ?,
	DOT = ?.
	HAT = ?^
	DOLLAR = ?$
	AMBERSAND = ?&
	QUOTE = ?'
	BACK_QUOTE = ?`
	BACK_SLASH = '\\'[0]
	UPPER_A = ?A
	UPPER_B = ?B
	UPPER_D = ?D
	UPPER_F = ?F
	UPPER_S = ?S
	UPPER_W = ?W
	UPPER_Z = ?Z
	LOWER_A = ?a
	LOWER_B = ?b
	LOWER_D = ?d
	LOWER_F = ?f
	LOWER_I = ?i
	LOWER_M = ?m
	LOWER_N = ?n
	LOWER_S = ?s
	LOWER_W = ?w
	LOWER_X = ?x
	LOWER_Z = ?z
	DIGIT_0 = ?0
	DIGIT_1 = ?1
	DIGIT_7 = ?7
	DIGIT_9 = ?9
	BELL = 7
	TAB = 9
	NEWLINE = 10
	SPACE = 32

	RANGE_09 = (DIGIT_0..DIGIT_9)
	RANGE_az = (LOWER_A..LOWER_Z)
	RANGE_AZ = (UPPER_A..UPPER_Z)
	RANGE_af = (LOWER_A..LOWER_F)
	RANGE_AF = (UPPER_A..UPPER_F)

	POSIX_DIGIT = [RANGE_09]
	POSIX_LOWER = [RANGE_az]                       # TODO: diacritical
	POSIX_UPPER = [RANGE_AZ]                       # TODO: diacritical
	POSIX_ALNUM = [RANGE_09, RANGE_az, RANGE_AZ]   # TODO: diacritical
	POSIX_ALPHA = [RANGE_az, RANGE_AZ]             # TODO: diacritical
	POSIX_WORD  = [RANGE_09, RANGE_az, RANGE_AZ, UNDERSCORE]   # TODO: diacritical
	POSIX_BLANK = [TAB, SPACE]
	POSIX_CNTRL = [(0..31), 127]
	POSIX_GRAPH = [(33..126)]
	POSIX_PRINT = [(32..126)]
	POSIX_PUNCT = [(33..47), (58..64), (91..96), (123..126)] 
	POSIX_SPACE = (9..13).to_a + [32] 
	POSIX_XDIGIT = [RANGE_09, RANGE_af, RANGE_AF]

	# TODO: unicode: are they existing posix classes ?
end # module SymbolNames

module StringHelper
	def byte_swapcase(codepoint)
		raise TypeError unless codepoint.kind_of?(Integer)
		raise IndexError unless (0..255).member?(codepoint)
		codepoint.chr.swapcase[0]
	end
	def byte_from_letter(letter)
		raise TypeError unless letter.kind_of?(String)
		raise IndexError unless 1 == letter.size
		letter[0]
	end
end # module StringHelper

class RangeSet
	def self.mk_str(string_set, ignorecase)
		# TODO: unicode, must convert according to the current encoding, ascii, iso, utf8...
		# right now it only converts 8bits values... because that we want to be able
		# to deal with multiple encodings, then it make sense to let this be handled
		# in the parser.
		integer_set = string_set.map do |i|
			# deal with codepoints within charclasses
			if i.kind_of?(Range)
				Range.new(i.first[0], i.last[0])
			else
				i[0]
			end
		end
		mk_int(integer_set, ignorecase)
	end
	def self.mk_int(integer_set, ignorecase)
		return RangeSet.new(integer_set) unless ignorecase
		new_syms = integer_set.map do |i|
			# deal with codepoints within charclasses
			if i.kind_of?(Range)
				byte0 = i.first
				byte1 = i.last
				raise "not a byte" if byte0 > 255
				raise "not a byte" if byte1 > 255
				Range.new(byte0.chr.swapcase[0], byte1.chr.swapcase[0])
			else
				byte = i
				raise "not a byte" if byte > 255
				byte.chr.swapcase[0]
			end
		end
		RangeSet.new((integer_set + new_syms).uniq)
	end
	def initialize(codepoints)
		@codepoints = codepoints
		check_valid
	end
	attr_reader :codepoints
	def check_valid
		@codepoints.each do |cp|
			if cp.kind_of?(Range)
				cp1 = cp.first
				unless cp1.kind_of?(Integer)
					raise TypeError, "expected Integer, but got class=#{cp1.class} value=#{cp1.inspect}"
				end
				cp2 = cp.last
				unless cp2.kind_of?(Integer)
					raise TypeError, "expected Integer, but got class=#{cp2.class} value=#{cp2.inspect}"
				end
			else 
				unless cp.kind_of?(Integer)
					raise TypeError, "expected Integer, but got class=#{cp.class} value=#{cp.inspect}"
				end
			end
		end
	end
	def ==(other)
		return false if (self.class != other.class)
		a1, b1 = @codepoints.partition {|cp| cp.kind_of?(Range) }
		a2, b2 = other.codepoints.partition {|cp| cp.kind_of?(Range) }
		return false if (b1.sort != b2.sort)
		a1_ary = a1.map{|range| [range.first, range.last] }
		a2_ary = a2.map{|range| [range.first, range.last] }
		return false if (a1_ary.sort != a2_ary.sort)
		true
	end
	def format_codepoint(codepoint)
		return "\"#{codepoint.chr}\"" if (33..126).member?(codepoint)
		return "U-%04X" % codepoint if codepoint < 0x10000
		"U-%08X" % codepoint
	end
	def to_s
		res = []
		@codepoints.each do |i|
			if i.kind_of?(Range)
				res << (format_codepoint(i.first) + ".." + format_codepoint(i.last))
			else
				res << format_codepoint(i)
			end
		end
		return res[0] if res.size == 1
		'[' + res.join(', ') + ']'
	end
	def member?(codepoint)
		@codepoints.each do |cp|
			return true if cp.kind_of?(Range) and cp.include?(codepoint)
			return true if cp == codepoint
		end
		false
	end
end # class RangeSet
