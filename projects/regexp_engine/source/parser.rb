require 'regexp/abstract_syntax'
require 'iterator'

# purpose:
# translate regex-string into abstract-syntax-tree
class Parser
	include RegexFactory
	include SymbolNames

	class RegexpIterator < Iterator::Collection
		# TODO: #current should raise 'premature end of regexp' 
		# by doing so, I can avoid doing it in the parser-code. simplification.

		def lookup(n)
			i = self.clone
			n.times {
				raise "premature end" unless i.has_next?
				i.next
			}
			raise "premature end" unless i.has_next?
			return i.current
		ensure
			i.close
		end
	end
	def initialize(regex, ignorecase=false, multiline=false, extended=false)
		@sequence = []     # current sequence (except last element)
		@last = nil        # last element in current sequence
		@alternations = [] # alternations to choose among
		@stack = []        # used for nested parentesis 
		@group_create_method = nil  # 'nil' should never be invoked

		# keep track of which options currently turned off/on
		@opt_ignorecase = ignorecase
		@opt_multiline = multiline
		@opt_extended = extended
		@alternation_options = [ignorecase, multiline, extended]
		@accessable_captures = []
		@number_of_captures = 0

		# iterate through the regex-input string
		begin
			stream = RegexpIterator.new(regex)
			while stream.has_next? 
				if @opt_extended and POSIX_SPACE.include?(stream.current)
					stream.next
					next
				end
				res = parse(stream)
				flush
				@last = res
			end
		ensure
			stream.close
		end
		unless @stack.empty?
			raise "missing close parentesis"
		end

		# everything went well, store result
		@expression = flush_alternations
		@input = regex
	end
	attr_reader :input, :expression
	def self.compile(regexp_string)
		Parser.new(regexp_string).expression  
	end
private
	def flush
		return unless @last
		@sequence << @last
		@last = nil
	end
	def mk_expr
		flush
		return @sequence[0] if @sequence.size == 1
		mk_sequence(*@sequence)
	end
	def flush_alternations
		expr = mk_expr
		return expr if @alternations.empty?
		alt = @alternations + [expr]
		@alternation = []
		@sequence = []
		@last = nil
		mk_alternation(*alt)
	end

	def self.build_hex2value_hash
		hash = Hash.new
		RANGE_09.each_with_index {|symbol, index| hash[symbol] = index }
		RANGE_AF.each_with_index {|symbol, index| hash[symbol] = index+10 } 
		RANGE_af.each_with_index {|symbol, index| hash[symbol] = index+10 } 
		hash
	end
	def self.build_octal2value_hash
		hash = Hash.new
		(DIGIT_0..DIGIT_7).each_with_index {|symbol, index| hash[symbol] = index } 
		hash
	end
	def self.build_decimal2value_hash
		hash = Hash.new
		RANGE_09.each_with_index {|symbol, index| hash[symbol] = index } 
		hash
	end
	def self.build_lower2ascii_hash
		hash = Hash.new
		RANGE_az.each_with_index {|symbol, index| hash[symbol] = ('a'[0] + index).chr } 
		hash
	end

	HEX2VALUE = build_hex2value_hash
	OCTAL2VALUE = build_octal2value_hash
	DECIMAL2VALUE = build_decimal2value_hash
	LOWER2ASCII = build_lower2ascii_hash


	def parse(stream)
		symbol = stream.current
		stream.next
		res = mk_letter2(symbol, @opt_ignorecase)
		case symbol
		when CURLY_BEGIN # repeat range (lazy/greedy)
			tmp = stream.clone
			begin
				minmax_ary = parse_range(tmp)
				return res if minmax_ary == nil
				stream.next while stream < tmp
			ensure
				tmp.close
			end
			min, max = minmax_ary
			lazy = false
			if stream.has_next? and stream.current == QUESTION_MARK
				lazy = true 
				stream.next
			end
			res = mk_repeat(@last, min, max, lazy)
			@last = nil
		when PLUS, SPLAT, QUESTION_MARK  # repeat (lazy/greedy)
			lazy = false
			if stream.has_next? and stream.current == QUESTION_MARK
				lazy = true 
				stream.next
			end
			min = (symbol == PLUS) ? 1 : 0
			max = (symbol == QUESTION_MARK) ? 1 : -1
			res = mk_repeat(@last, min, max, lazy)
			@last = nil
		when PARA_BEGIN  # parantesis-begin
			ignorecase = nil
			multiline = nil
			extended = nil
			meth = :mk_group
			# if '?' is present, then it is possible that we 
			# are dealing with a: pure-group, posix-comment,
			# lookahead-positive/negative.. etc.
			sym = nil
			if stream.has_next?
				sym = stream.current
			end
			if sym == QUESTION_MARK
				stream.next
				if stream.has_next?
					sym = stream.current
					case sym
					when COLON  # non-capturing group (?: ... )
						stream.next
						meth = :mk_group_pure
					when EQUAL  # lookahead positive (?= ... )
						stream.next
						meth = :mk_lookahead
					when EXCLAMATION_MARK  # lookahead negative (?! ... )
						stream.next
						meth = :mk_lookahead_negative
					when LESS_THAN  # lookbehind (?<= ... )  and (?<! ... )
						stream.next
						if stream.has_next? == false
							raise "premature end of regexp-lookbehind, " +
								"expected '=' or '!'"
						end
						sym = stream.current
						stream.next
						case sym
						when EQUAL
							meth = :mk_lookbehind
						when EXCLAMATION_MARK
							meth = :mk_lookbehind_negative
						else
							raise "unknown symbol '#{sym} encountered in " +
								"regexp-lookbehind, expected either '=' or '!'"
						end
					when GREATER_THAN  # atomic grouping
						stream.next
						meth = :mk_atomic_group
					when SHARP  # posix comment  (?# ... )
						stream.next
						meth = nil
						loop do 
							if stream.has_next? == false
								raise "premature end of regexp, " +
									"expected ')'"
							end
							sym = stream.current
							stream.next
							break if sym == PARA_END
						end
					when LOWER_I, LOWER_M, LOWER_X, MINUS
						(	last_symbol, 
							ignorecase,
							multiline,
							extended    )  = parse_options(stream)
						case last_symbol 
						when PARA_END
							meth = nil
						when COLON
							meth = :mk_group_pure
						else
							raise "expected either ')' or ':'"
						end
					else
						raise "group-begin: questionmark followed by " + 
							"an unknown symbol ('#{sym}')"
					end
				else
					raise "group-begin: questionmark not followed by " + 
						"anything.  A symbol were expected."
				end
			end
			if meth == :mk_group
				@number_of_captures += 1
			end
			if meth
				flush
				@stack << [
					@sequence, 
					@alternations, 
					@group_create_method,
					@opt_ignorecase,
					@opt_multiline,
					@opt_extended,
					@number_of_captures
				]
				@sequence = []
				@last = nil
				@alternations = []
				@group_create_method = meth
				@alternation_options = [@opt_ignorecase, @opt_multiline, @opt_extended]
			end
			res = nil
			@opt_ignorecase = ignorecase if ignorecase != nil
			@opt_multiline  = multiline  if multiline  != nil
			@opt_extended   = extended   if extended   != nil
		when PARA_END  # parantesis-end
			if @stack.empty?
				raise "missing open parentesis"
			end
			# create that kind of group we detected in 'parentesis-begin'
			is_group = (@group_create_method == :mk_group)
			res = method(@group_create_method).call(flush_alternations)
			capture_id = nil
			(	@sequence, 
				@alternations, 
				@group_create_method,
				@opt_ignorecase,
				@opt_multiline,
				@opt_extended,
				capture_id    ) = @stack.pop
			if is_group
				@accessable_captures << capture_id
			end
			@last = nil
		when PIPE  # alternation
			@opt_ignorecase, @opt_multiline, @opt_extended = @alternation_options
			@alternations << mk_expr
			@sequence = []
			@last = nil
			res = nil
		when BRACKET_BEGIN  # character class
			symbols, inverse_symbols = parse_charclass(stream)
			a = symbols.empty? ? 0 : 1
			b = inverse_symbols.empty? ? 0 : 2
			case a+b
			when 1
				res = mk_charclass2(symbols, @opt_ignorecase)
			when 2
				res = mk_charclass_inverse2(inverse_symbols, @opt_ignorecase)
			when 3
				res = mk_alternation(
					mk_charclass2(symbols, @opt_ignorecase),
					mk_charclass_inverse2(inverse_symbols, @opt_ignorecase)
				)
			else
				raise "empty character class"
			end
		when DOT  # any
			res = mk_wild(@opt_multiline)
		when HAT # anchor-begin
			res = mk_anchor_begin
		when DOLLAR # anchor-end
			res = mk_anchor_end
		when BACK_SLASH # escape
			if stream.has_next? == false
				raise "premature end of regexp, nothing to escape"
			end
			symbol1 = stream.current
			stream.next
			case symbol1
			when UPPER_A  # anchor string begin
				res = mk_anchor_string_begin
			when LOWER_A  # \a  bell
				res = mk_letter2(BELL, false)
			when UPPER_B  # anchor non-word boundary
				res = mk_anchor_nonword_boundary
			when LOWER_B  # anchor word boundary
				res = mk_anchor_word_boundary
			when UPPER_D  # ^[:digit:]
				res = mk_charclass_inverse2(POSIX_DIGIT, @opt_ignorecase)
			when LOWER_D  # [:digit:]
				res = mk_charclass2(POSIX_DIGIT, @opt_ignorecase)
			when LOWER_N  # \n  newline
				res = mk_letter2(NEWLINE, false)
			when UPPER_S  # ^[:space:]
				res = mk_charclass_inverse2(POSIX_SPACE, @opt_ignorecase)
			when LOWER_S  # [:space:]
				res = mk_charclass2(POSIX_SPACE, @opt_ignorecase)
			when UPPER_W  # ^[:word:]
				res = mk_charclass_inverse2(POSIX_WORD, @opt_ignorecase)
			when LOWER_W  # [:word:]
				res = mk_charclass2(POSIX_WORD, @opt_ignorecase)
			when LOWER_X  # hex value
				res = parse_wide_or_hex(stream)
			when UPPER_Z  # anchor string end excl
				res = mk_anchor_string_end_excl
			when LOWER_Z  # anchor string end
				res = mk_anchor_string_end
			when DIGIT_0  # octal  \000..\077
				res = mk_letter2(parse_octal(symbol1, stream), false)
			when DIGIT_1..DIGIT_9 # either backref or octal
				res = parse_backref_octal(symbol1, stream)
			else # escaped symbol
				res = mk_letter2(symbol1, @opt_ignorecase)
			end
		end
		res
	end

	class Bailout < StandardError; end

	# deal with [abcA-Z], [^symbols], [[:digit:][:punct:]] patterns
	def parse_charclass(stream)
		symbols = []
		inverse_symbols = []
		inverse = false
		if stream.has_next? == false
			raise "premature end of character class"
		end
		if stream.current == HAT
			inverse = true
			stream.next
		end
		loop do
			if stream.has_next? == false
				raise "premature end of character class"
			end
			symbol = stream.current
			stream.next
			break if symbol == BRACKET_END

			if stream.has_next? == false
				raise "premature end of character class"
			end
			if symbol == BACK_SLASH
				symbol = stream.current
				stream.next
				case symbol
				when LOWER_A
					symbols << BELL
				when UPPER_D
					inverse_symbols << POSIX_DIGIT
				when LOWER_D
					symbols << POSIX_DIGIT
				when UPPER_S
					inverse_symbols << POSIX_SPACE
				when LOWER_N
					symbols << NEWLINE
				when LOWER_S
					symbols << POSIX_SPACE
				when UPPER_W
					inverse_symbols << POSIX_WORD
				when LOWER_W
					symbols << POSIX_WORD
				when LOWER_X
					codepoint = parse_wide(stream)
					if codepoint
						symbols << codepoint
					else
						symbols << parse_hex(stream)
					end
				when RANGE_09
					symbols << parse_octal(symbol, stream)
				else
					symbols << symbol
				end
				next
			end

			if symbol == BRACKET_BEGIN and stream.current == COLON
				# posix character class found, we push its
				# array on the symbol list. Observe that we
				# don't concat it to the symbol list!!!
				# this is because we don't want people to be
				# able to do /[[:vowels:]]-z/,  assuming
				# that :vowels: are [aeiouy].. that expression
				# should yield in the end an expression which
				# says ['a', 'e', 'i', 'o', 'u', 'y', '-', 'z']
				# NOT ['a', 'e', 'i', 'o', 'u', 'y'..'z'] !!!
				begin
					inverse_posix, sym_ary = parse_charclass_posix(stream)
					if inverse_posix
						inverse_symbols += sym_ary
					else
						symbols += sym_ary
					end
					next
				rescue Bailout
				end
			end

			as_range = false
			if symbol == MINUS
				# determine if the '-' should be interpreted
				# either as a range or as a the '-' symbol
				prev_is_valid = true
				if symbols.empty? or 
					(symbols.size > 0 and 
						(symbols.last.kind_of?(Range) or 
						symbols.last.kind_of?(Array))
					)
					prev_is_valid = false
				end
				next_is_valid = true
				if stream.has_next? and stream.current == BRACKET_END
					next_is_valid = false
				end
				if next_is_valid and (symbols.size > 0) and symbols.last.kind_of?(Array)
					raise "charclass cannot be used in ranges"
				end
				as_range = (prev_is_valid and next_is_valid)
			end
			if as_range
				to_symbol = stream.current
				stream.next
				if to_symbol == BACK_SLASH
					sym = stream.current
					stream.next
					case sym
					when LOWER_A
						to_symbol = BELL
					when LOWER_N
						to_symbol = NEWLINE
					when RANGE_09
						to_symbol = parse_octal(sym, stream)
					when LOWER_X
						codepoint = parse_wide(stream)
						if codepoint
							to_symbol = codepoint
						else
							to_symbol = parse_hex(stream)
						end
					else
						to_symbol = sym
					end
				end
				from_symbol = symbols[-1]
				if to_symbol.class != from_symbol.class
					raise "charclass: cannot make range with 2 different classes"
				end
				if from_symbol > to_symbol
					raise "charclass: negative ranges are not allowed\n" +
						"from=#{from_symbol[0]}  to=#{to_symbol[0]}"
				end
				symbols[-1] = from_symbol..to_symbol # match range
			else
				symbols << symbol # match literal
			end
		end
		symbols.flatten!
		inverse_symbols.flatten!
		if inverse
			return [inverse_symbols, symbols]
		else
			return [symbols, inverse_symbols]
		end
	end

	def parse_charclass_posix(stream)
		tmp = stream.clone
		tmp.next
		inverse = false
		if tmp.has_next? and tmp.current == HAT
			inverse = true
			tmp.next
		end
		name = ""
		ok = false
		8.times do |i|
			if tmp.has_next? == false
				raise "premature end of character class"
			end
			codepoint = tmp.current 
			if codepoint == BRACKET_END
				raise Bailout, "did not expect ']' here"
			end
			tmp.next
			if codepoint == COLON
				if tmp.has_next? == false
					raise "premature end of character class"
				end
				if tmp.current != BRACKET_END
					raise Bailout, "expected ']'"
				end
				ok = true
				tmp.next
				break
			end
			ascii_letter = LOWER2ASCII[codepoint]
			unless ascii_letter
				raise "expected lowercase ascii letters inside character class"
			end
			name += ascii_letter
		end
		hash = {
			"alnum" => POSIX_ALNUM,
			"alpha" => POSIX_ALPHA,
			"blank" => POSIX_BLANK,
			"cntrl" => POSIX_CNTRL,
			"digit" => POSIX_DIGIT,
			"graph" => POSIX_GRAPH,
			"lower" => POSIX_LOWER,
			"print" => POSIX_PRINT,
			"punct" => POSIX_PUNCT,
			"space" => POSIX_SPACE,
			"upper" => POSIX_UPPER,
			"word"  => POSIX_WORD,
			"xdigit" => POSIX_XDIGIT
		}
		raise "syntax error in character class" if not ok
		sym_ary = hash[name]
		raise "unknown character class #{name}" if sym_ary == nil
		stream.next while stream < tmp
		return [inverse, sym_ary]
	ensure
		tmp.close
	end


	# deal with  (?i:pattern), (?m) or (?x-im:pattern)
	def parse_options(stream)
		ignorecase = nil
		multiline = nil
		extended = nil
		loop do
			if stream.has_next? == false
				raise "premature end of regexp"
			end
			symbol = stream.current
			stream.next
			case symbol
			when LOWER_I
				ignorecase = true
			when LOWER_M
				multiline = true
			when LOWER_X
				extended = true
			when MINUS
				if stream.has_next? == false
					raise "premature end of regexp"
				end
				symbol2 = stream.current
				stream.next
				case symbol2
				when LOWER_I
					ignorecase = false
				when LOWER_M
					multiline = false
				when LOWER_X
					extended = false
				else
					raise "expected eiter 'i' or 'm'"
				end
			else
				return [symbol, ignorecase, multiline, extended]
			end
		end
	end


	# deal with  {42,666}   {42,}  or  {42}
	def parse_range(stream)
		min = 0
		ok = false
		while stream.has_next?
			digit = DECIMAL2VALUE[stream.current]
			break unless digit
			ok = true
			stream.next
			min = (min*10) + digit
		end
		return nil unless ok
		return nil unless stream.has_next?
		s = stream.current
		stream.next
		return [min, min] if s == CURLY_END
		return nil if s != COMMA   # expected either '}' or ','
		max = 0
		infinite = true
		while stream.has_next?
			digit = DECIMAL2VALUE[stream.current]
			break unless digit
			infinite = false
			stream.next
			max = (max*10) + digit
		end
		return nil unless stream.has_next?
		return nil if stream.current != CURLY_END   # expected '}' 
		stream.next
		return [min, -1] if infinite
		raise "range: expected (min <= max), but got (min > max)" if min > max
		[min, max]
	end

	def parse_wide_or_hex(stream)
		codepoint = parse_wide(stream)
		return mk_wide(codepoint) if codepoint
		mk_letter2(parse_hex(stream), false) 
	end

	def parse_wide(stream)
		if stream.has_next? and stream.current != CURLY_BEGIN
			return nil
		end
		stream.next
		# deal with \x{42}    widehex
		code = 0
		9.times do
			unless stream.has_next?
				raise "premature end of regexp, expected '}'."
			end
			symbol = stream.current
			if symbol == CURLY_END
				stream.next
				return code  # success.. we got a widechar
			end
			val = HEX2VALUE[symbol]
			unless val 
				raise "unexpected symbol."
			end
			code = (code * 16) + val
			stream.next
		end
		raise "more than 32 bit value specified in widehex."
	end

	def parse_hex(stream)
		code = 0
		2.times do
			break unless stream.has_next?
			digit = HEX2VALUE[stream.current]
			break unless digit
			code = (code * 16) + digit
			stream.next
		end
		code
	end

	def parse_octal(symbol1, stream)
		code = OCTAL2VALUE[symbol1]
		oct_stream = stream.clone
		if code
			2.times do |i|
				break unless oct_stream.has_next?
				digit = OCTAL2VALUE[oct_stream.current]
				break unless digit
				code = (code * 8) + digit
				oct_stream.next
			end
		end
		stream.next while stream < oct_stream
		oct_stream.close
		(code % 256)   # octal numbers are just so fucked up.
	end

	def parse_backref_octal(symbol1, stream)
		# there is a lot of ambiguity between octal numbers and backrefs
		# this is the code for resolving it.. I may have to adjust it sligthly
		# For instance    /(?:\1a|())*/ ~= "abc"   is nasty
		# because the backref are refering to a capture which isn't
		# acessable yet. Solution could be to place a MaybeBackref node in the AST.

		# interpret as backref
		br_code = DECIMAL2VALUE[symbol1]
		br_stream = stream.clone
		while br_stream.has_next?
			digit = DECIMAL2VALUE[br_stream.current]
			break unless digit
			br_code = (br_code * 10) + digit
			br_stream.next
		end
		if @accessable_captures.member?(br_code)
			stream.next while stream < br_stream
			br_stream.close
			return mk_backref(br_code, @opt_ignorecase)
		end
		br_stream.close

		# interpret as octal
		symbol_oct = parse_octal(symbol1, stream)
		mk_letter2(symbol_oct, false) 
	end
end

if $0 == __FILE__
	p Parser.new("0(a|b|(xy)+)*?1").expression
end
