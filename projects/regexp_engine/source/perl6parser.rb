require 'regexp/abstract_syntax'
require 'iterator'
require 'regexp/parser'
require "regexp/misc"

# purpose:
# translate a perl6 style regex-string into abstract-syntax-tree
class Perl6Parser < Parser
	include SymbolNames
	#include Debuggable
	def initialize(regex, ignorecase=false, multiline=false, extended=true)
                super(regex, ignorecase, multiline, extended)
        end

private
	def parse(stream)
		symbol = nil
		if @opt_extended 
			loop do
				if stream.has_next? == false
					raise "premature end of regexp"
				end
				symbol = stream.current
				stream.next
				break unless POSIX_SPACE.include?(symbol)
			end
		else
			symbol = stream.current
			stream.next
		end

		res = mk_letter(symbol, @opt_ignorecase)

		case symbol
		when '<' 
		        res = parse_assertion(res, stream)
                when '{'
                        res = parse_closure(res, stream)
		when '+', '*', '?'  # repeat (lazy/greedy)
			lazy = false
			if stream.has_next? and stream.current == '?'
				lazy = true 
				stream.next
			end
			min = (symbol == '+') ? 1 : 0
			max = (symbol == '?') ? 1 : -1
			res = mk_repeat(@last, min, max, lazy)
			@last = nil
		when '(', '['  # parantesis-begin
			ignorecase = nil
			multiline = nil
			extended = nil
			meth = :mk_group
                        
                        if(symbol == '[')
                                meth = :mk_group_pure
                        end
			flush
			@stack << [
				@sequence, 
				@alternations, 
				@group_create_method,
				@opt_ignorecase,
				@opt_multiline,
				@opt_extended
			]
			@sequence = []
			@last = nil
			@alternations = []
			@group_create_method = meth
			@alternation_options = [@opt_ignorecase, @opt_multiline, @opt_extended]

			res = nil
			@opt_ignorecase = ignorecase if ignorecase != nil
			@opt_multiline  = multiline  if multiline  != nil
			@opt_extended   = extended   if extended   != nil
		when ')', ']'  # parantesis-end
			if @stack.empty?
				raise "missing open parentesis"
			end
                        if( (@group_create_method == :mk_group_pure && symbol == ')') ||
                            (@group_create_method == :mk_group && symbol == ']') )
                                raise "mismatched brackets"
                        end

			# create that kind of group we detected in 'parentesis-begin'
			res = method(@group_create_method).call(flush_alternations)
			(	@sequence, 
				@alternations, 
				@group_create_method,
				@opt_ignorecase,
				@opt_multiline,
				@opt_extended    ) = @stack.pop
			@last = nil
		when '|'  # alternation
			@opt_ignorecase, @opt_multiline, @opt_extended = @alternation_options
			@alternations << mk_expr
			@sequence = []
			@last = nil
			res = nil
		when '.'  # any
			res = mk_wild(@opt_multiline)
		when '^' # anchor-begin
			res = mk_anchor_begin
		when '$' # anchor-end
			res = mk_anchor_end
		when '\\' # escape
			if stream.has_next? == false
				raise "premature end of regexp, nothing to escape"
			end
			symbol1 = stream.current
			stream.next
			case symbol1
			when '1'..'9' # backreference
				res = mk_backref(symbol1.to_i, @opt_ignorecase)
			when 'b'  # anchor word boundary
				res = mk_anchor_word_boundary
			when 'B'  # anchor non-word boundary
				res = mk_anchor_nonword_boundary
			when 'A'  # anchor string begin
				res = mk_anchor_string_begin
			when 'z'  # anchor string end
				res = mk_anchor_string_end
			when 'Z'  # anchor string end excl
				res = mk_anchor_string_end_excl
			when 'd'  # [:digit:]
				res = mk_charclass(POSIX_DIGIT, @opt_ignorecase)
			when 'D'  # ^[:digit:]
				res = mk_charclass_inverse(POSIX_DIGIT, @opt_ignorecase)
			when 's'  # [:space:]
				res = mk_charclass(POSIX_SPACE, @opt_ignorecase)
			when 'S'  # ^[:space:]
				res = mk_charclass_inverse(POSIX_SPACE, @opt_ignorecase)
			when 'w'  # [:word:]
				res = mk_charclass(POSIX_WORD, @opt_ignorecase)
			when 'W'  # ^[:word:]
				res = mk_charclass_inverse(POSIX_WORD, @opt_ignorecase)
			else # escaped symbol
				res = mk_letter(symbol1, @opt_ignorecase)
			end
		end
		res
	end

	# deal with <[abcA-Z]>
	def parse_charclass(stream, inverse = false)
		symbols = []
		inverse_symbols = []
		if stream.has_next? == false
			raise "premature end of character class"
		end
		if stream.current == '^'
			inverse = true
			stream.next
		end

		loop do
			if stream.has_next? == false
				raise "premature end of character class"
			end
			symbol = stream.current
			stream.next
			break if symbol == ']'

			if stream.has_next? == false
				raise "premature end of character class"
			end
			if symbol == '\\'
				symbol = stream.current
				stream.next
				case symbol
				when 'd'
					symbols << POSIX_DIGIT
				when 'w'
					symbols << POSIX_WORD
				when 's'
					symbols << POSIX_SPACE
				when 'D'
					inverse_symbols << POSIX_DIGIT
				when 'W'
					inverse_symbols << POSIX_WORD
				when 'S'
					inverse_symbols << POSIX_SPACE
				else
					symbols <<  symbol
				end
				next
			end

			if symbol == '[' and stream.current == ':'
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
					symbols << parse_charclass_posix(stream)
					next
				rescue Bailout
				end
			end

			as_range = false
			if symbol == '-'
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
				if stream.has_next? and stream.current == ']'
					next_is_valid = false
				end
				if next_is_valid and (symbols.size > 0) and symbols.last.kind_of?(Array)
					raise "charclass cannot be used in ranges"
				end
				as_range = (prev_is_valid and next_is_valid)
			end
			if as_range
				symbol = stream.current
				stream.next
				if symbol == '\\'
					symbol = stream.lookup(0)
				end
				if symbols[-1] > symbol
					raise "charclass: negative ranges are not allowed"
				end
				symbols[-1] = symbols[-1]..symbol # match range
			else
				symbols << symbol # match literal
			end
		end

		next_symbol = stream.current

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
		#tmp.next
		name = ""
		ok = false
		8.times do |i|
			if tmp.has_next? == false
				raise "premature end of character class"
			end
			sym = tmp.current 
			if sym == '>'
				#puts "found #{name}"
				ok = true
				#tmp.next
				break
			end
			tmp.next
			name += sym
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
		return sym_ary
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
			when "i"
				ignorecase = true
			when "m"
				multiline = true
			when "x"
				extended = true
			when "-"
				if stream.has_next? == false
					raise "premature end of regexp"
				end
				symbol2 = stream.current
				stream.next
				case symbol2
				when "i"
					ignorecase = false
				when "m"
					multiline = false
				when "x"
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
		min_s = ""
		s = ""
		loop do 
			if stream.has_next? == false
				#raise "range: premature end of string" 
				return nil
			end
			s = stream.current 
			stream.next
			break if (s < '0') or (s > '9')
			min_s += s
		end
		if min_s == ""
			#raise "range: no minimum value specified" 
			return nil
		end
		min = min_s.to_i
		max = min
		if s == '>'
			# nothing
		elsif s != ','
			#raise "range: expected either '>' or ','"
			return nil
		else
			max_s = ""
			loop do 
				if stream.has_next? == false
					#raise "range: premature end of string" 
					return nil
				end
				s = stream.current
				stream.next
				break if (s < '0') or (s > '9')
				max_s += s
			end
			if s != ">"
				#raise "range: expected '>'" 
				return nil
			end
			if max_s == ""
				max = -1
			else
				max = max_s.to_i
				raise "range: expected (min <= max), but got (min > max)" if min > max
			end
		end
                puts "range = #{min} - #{max}"
		[min, max]
	end

        #parse an assertion <...>
	def parse_assertion(res, stream, negative = false)
		assertion = []
	        next_symbol = stream.current

                if(next_symbol == "!")
                        negative = true
                        stream.next
                end

	        loop do
		        next_symbol = stream.current

			case next_symbol
		        when '>' # end the assertion
			     stream.next
			     break
                        when '"', "'" # literal string
                             end_symbol = next_symbol
                             stream.next
                             chars = []
                             loop do
                                     symbol = stream.current
				     puts symbol
                                     stream.next
                                     break if symbol == end_symbol
                                     chars << mk_letter(symbol)
                             end
			     assertion = [mk_sequence(*chars)]		     
			when ' '
			     stream.next
			     next
			when '0'..'9' # repeat range (lazy/greedy)
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
				if stream.has_next? and stream.current == '?'
				        lazy = true 
					stream.next
				end
                                unless negative
				        assertion << mk_repeat(@last, min, max, lazy)
                                else
                                        if min == 0
    				                assertion << mk_repeat(@last, max + 1, -1, lazy)
                                        else
                   			        assertion << mk_alternation(mk_repeat(@last, 0, min-1, lazy), mk_repeat(@last, max+1, -1, lazy))

                                        end
                                end
				@last = nil
				break
			when '('  # code assertion
                             stream.next
                             src = ""
                             loop do
                                     symbol = stream.current
                                     stream.next
                                     break if symbol == ")"
                                     src << symbol
                             end
			     assertion = [mk_code_assertion(src)]
			when '<'  # sub assertion
			     stream.next
			     assertion << parse_assertion(res, stream, negative)                    
		        when '-'  # negative character class
			     stream.next
			     negative = true
		        when '+'  # postive character class
			     stream.next
			     negative = false
		        when '['  # character class
			    stream.next
			    symbols, inverse_symbols = parse_charclass(stream, negative)
			    a = symbols.empty? ? 0 : 1
			    b = inverse_symbols.empty? ? 0 : 2
			    case a+b
			    when 1
				 assertion << mk_charclass(symbols, @opt_ignorecase)
			    when 2
				 assertion << mk_charclass_inverse(inverse_symbols, @opt_ignorecase)
			    when 3
				 assertion << mk_alternation(
			           mk_charclass(symbols, @opt_ignorecase),
			           mk_charclass_inverse(inverse_symbols, @opt_ignorecase)
				 )
		            else
				raise "empty character class"
			    end
		        else # named character class
			   # posix character class found, we push its
			   # array on the symbol list. Observe that we
			   # don't concat it to the symbol list!!!
			   # this is because we don't want people to be
			   # able to do /<vowels>-z/,  assuming
			   # that :vowels: are [aeiouy].. that expression
			   # should yield in the end an expression which
			   # says ['a', 'e', 'i', 'o', 'u', 'y', '-', 'z']
			   # NOT ['a', 'e', 'i', 'o', 'u', 'y'..'z'] !!!
			   begin
				symbols = parse_charclass_posix(stream)
				assertion << mk_charclass(symbols, @opt_ignorecase);
				next
			   rescue Bailout
			   end
		      end
		end      

		if(assertion.length == 1)
		        res = assertion[0]
		else
			assertion = assertion.collect {|item| item.symbols[0]}
			res = mk_charclass(assertion)
		end

		res
	end
        #parse a closure object {...}
        #the match failes if the closure raise an exception
        #/a{raise if false}/ matches
        #/a{raise if true}/ doesn't
        def parse_closure(res, stream)
                src = ""
                loop do
                        symbol = stream.current
                        stream.next
                        break if symbol == "}"
                        src << symbol
                end
                mk_closure(src)
        end
end


if $0 == __FILE__
	# USAGE:
	#
	# server> ruby [-d] regexp/perl6parser.rb "a(a|b|c)+" "daccbad"
	# d<<accba>>d
	# ["accba", "a"]
	# server>
	#
        require "regexp"
	$debug = $DEBUG # -d enables debugging
	regexp = NewRegexp.new(ARGV[0] || "((ab)*x)+", Perl6Parser)
	result = regexp.match(ARGV[1] || "0ababxx1")
	if result
		puts result.pre_match + "<<" + result.to_s + ">>" + result.post_match
		p result.to_a
	else
		puts "Mismatch Error: regexp does not match string."
	end
end
