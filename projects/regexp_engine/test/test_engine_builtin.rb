# purpose:
# exercise Ruby's native regex support
#
# hopefully one day I will be able to
# overload Ruby's regex routines with
# my own, and make all these tests pass OK.
#
require 'common'
require 'blackbox_p5'
require 'blackbox_rubicon'

module EngineGnu
	# * precedens between different operators
	# * any illegal regex constructions?
	# * more exercising of grouping.. and backrefs
	# * utf8 matching \udeadbeef
	# * What if I specify a different 'lang' option (n, e, s, u)
	# * \G, anchor pointing at last position
	#
	# not-possible:
	# * lookbehind 
	# * max number of occurences
	# * named backreferences
	# * conditionals
	# * I cannot find POSIXLINE in 're.c'.. maybe no longer existent?
	# * match beginning of word operator \<
	# * match end of word operator \>
	def self.included(parent)
		parent.class_eval %{
			undef test_escape_hex8
			undef test_escape_hex9
			undef test_charclass_neg7
			undef test_charclass_neg8
			undef test_charclass_octal6
			undef test_endless_eternal1  # infinite loop
		}
	end
end # module EngineGnu

module EngineOniguruma
	include MatchLookbehindPositive
	undef test_lookbehind_positive_with_quantifier1
	undef test_lookbehind_positive_with_quantifier2
	undef test_lookbehind_positive_right_most_longest1
	undef test_lookbehind_positive_right_most_longest2
	undef test_lookbehind_positive_with_lookahead1
	undef test_lookbehind_positive_with_lookbehind3
	undef test_lookbehind_positive_with_backref1
	undef test_lookbehind_positive_with_capture1
	undef test_lookbehind_positive_with_capture2
	include MatchLookbehindNegative
	undef test_lookbehind_negative4
	undef test_lookbehind_negative5
	undef test_lookbehind_negative6
	undef test_lookbehind_negative7
	include PossessiveQuantifiers
	include MatchEncodingUTF8Codepoints
	include MatchEncodingUTF8Malformed
	undef test_utf8_hex3  # UTF-8 within charclass-ranges causes trouble
	undef test_utf8_find_malform1  # no clue why Oniguruma doesn't like it?
	def rubicon_skip?(lineno)
		# in case of oniguruma, we should skip these tests
		[
		# option has different scope
		269,
		351, 
		
		# nested quantifiers differ
		129, 
		132, 133, 
		147, 
		150, 
		520, 521, 522, 
		524, 525, 
		562, 563, 564, 565, 566, 
		568, 569, 570, 571, 572,
		579, 580, 581, 
		594, 
		639,
		645, 

		# nested quantifiers which doesn't return anything (same behavier as perl5.8)
		146, 
		149, 
		567, 
		593, 
		638,  

		# backref
		907, 

		# premature end   
		366, 367, 
		382, 
		772, 773, 
		786,
		820,
		866,
		
		# target of operator is invalid  
		1024
		].member?(lineno)
	end
	def self.included(parent)
		parent.class_eval %{
			undef test_not_supported_operations
			undef test_illegal_misc1 
			undef test_charclass_warn7
			undef test_charclass_warn6
			undef test_charclass_warn5
			undef test_charclass_warn4
			undef test_charclass_warn3
			undef test_charclass_warn2
			undef test_charclass_warn1
			undef test_charclass_octal4
			undef test_charclass_octal5
			undef test_charclass_octal6
			undef test_endless_eternal1  # infinite loop
			undef test_endless_lookahead_negative1     # target of operator is invalid  
			undef test_endless_lookahead_positive1     # target of operator is invalid  
			undef test_endless_anchor_boundarynonword1 # target of operator is invalid 
			undef test_endless_anchor_end1  # target of operator is invalid
			undef test_anchor_end6          # target of operator is invalid 
			undef test_charclass11          # premature end of regexp
			undef test_escape_octal4        # too big backref number.. probably bug in oniguruma?
			undef test_escape_octal5        # too big backref number.. probably bug in oniguruma?
			undef test_backref_octal6       # too big backref number.. probably bug in oniguruma? 
		}
	end
end # module EngineOniguruma

class XTestEngineBuiltin < Common::TestCase
	ENGINE = ("B" == /(?i)a|b/.match("0Ba1").to_s) ? :oniguruma : :gnu
	def assert_regex(expected, regex, input, options={})
		check_options_regexp(options)
		case ENGINE
		when :gnu
			expected = options[:bug_gnu] if options.has_key?(:bug_gnu)
		when :oniguruma
			expected = options[:oniguruma_output] if options.has_key?(:oniguruma_output) 
		else
			raise "unknown engine"
		end
		warn_str = options[:rubywarn]
		message = nil
		actual = ""
		if options[:encoding] == :UTF8
			$KCODE = 'U'
		else
			$KCODE = 'A'
		end
		begin
			re = nil
			str = capture_stderr { re = Regexp.new(regex) }
			if warn_str
				if Regexp.new(warn_str).match(str) == nil
					raise "expect warning:\n#{warn_str}\nbut got warning:\n#{str}"
				end
			else
				if str != ""
					raise "did not expect warning, but got:\n#{str}"
				end
			end
			m = re.match(input)
			if m == nil
				actual = nil
			else
				actual = m.to_a
			end
		rescue RegexpError => e
			actual = e
		end
		full_message = build_message(message, <<EOT, expected, actual)
<?> expected but was
<?>.
EOT
		assert_block(full_message) { expected == actual }
	end
	def assert_regex_error(regex, message=nil)
		actual = ""
		ok = false
		begin
			r = Regexp.new(regex)
			actual = r.source
		rescue RegexpError => e
			ok = true
			actual = e
		end
		expected = "compile error"
		full_message = build_message(message, <<EOT, expected, actual)
<?> expected but was
<?>.
EOT
		assert_block(full_message) { ok }
	end
	def assert_gsub(expected, regex, input, replace=nil, &block)
		message = nil
		actual = nil
		$KCODE = 'A'
		begin
			re = Regexp.new(regex)
			if block_given?
				actual = input.gsub(re) do |match0|
					matchdata = $~
					block.call(matchdata)
				end
			else
				actual = input.gsub(re, replace)
			end
		rescue RegexpError => e
			actual = e
		end
		full_message = build_message(message, <<EOT, expected, actual)
<?> expected but was
<?>.
EOT
		assert_block(full_message) { expected == actual }
	end
	def assert_scan(expected, regex, input, &block)
		message = nil
		actual = nil
		$KCODE = 'A'
		begin
			re = Regexp.new(regex)
			if block_given?
				actual = input.scan(re) do |match0|
					matchdata = $~
					block.call(matchdata)
				end
			else
				actual = input.scan(re)
			end
		rescue RegexpError => e
			actual = e
		end
		full_message = build_message(message, <<EOT, expected, actual)
<?> expected but was
<?>.
EOT
		assert_block(full_message) { expected == actual }
	end
	def assert_split(expected, regex, limit, input)
		message = nil
		actual = nil
		limit ||= 0
		$KCODE = 'A'
		begin
			re = Regexp.new(regex)
			actual = input.split(re, limit)
		rescue RegexpError => e
			actual = e
		end
		full_message = build_message(message, <<EOT, expected, actual)
<?> expected but was
<?>.
EOT
		assert_block(full_message) { expected == actual }
	end
	def xtest_escape_leftword_boundary1
		assert_match(/\<b/, "a bcb")
	end
	def xtest_escape_leftword_boundary2
		assert_match(/\<b/, "ab cb")
	end
	def test_not_supported_operations
		str = [
			"cd(?<=ab)",     # lookbehind 
			"b(?(?=x)x|y)c", # conditionals 
		]
		res = str.map{|s| 
			ok = false
			begin
				Regexp.new(s)
			rescue
				ok = true
			end
			ok
		}
		assert_equal([true] * str.size, res)
	end
	def test_wildcard_greedy1
		m = /<.+>/.match("0<a>1<b>2")
		res = [m.pre_match, m.post_match]
		assert_equal(["0", "2"], res)
	end
	def test_wildcard_greedy2
		m = /a.*b.*c/.match("0a1b2c3")
		res = [m.pre_match, m.post_match]
		assert_equal(["0", "3"], res)
	end
	def test_wildcard_greedy3
		m = /a.*b.*c/.match("0a1b2c3c4")
		res = [m.pre_match, m.post_match]
		assert_equal(["0", "4"], res)
	end
	def test_wildcard_greedy4
		m = /a.*b.*c/.match("0a1b2c3b4c5")
		res = [m.pre_match, m.post_match]
		assert_equal(["0", "5"], res)
	end
	def test_illegal_misc1
		input = [
			'a\\',
			")a",
			"a(",
			# no previous pattern to repeat
			"*a",
			"+a",
			"?a",
			"|*",
			"x?+",
			"x???+",
			"x?++",
			"x?+?+",
			# "x??+",   # doesn't raise any exception, wierd! inconsistent
			# "x??*?*", # ditto
			# "x*??",   # ditto
			"x(?#y\))z",  # escape ')' seems not to work?
			"x(?#yz",  # premature end of regexp
		]
		res = input.map{|str| 
			ok = false
			begin
				Regexp.new(str) 
			rescue RegexpError
				ok = true
			end
			ok
		}
		assert_equal([true] * input.size, res)
	end
	def xtest_warning_misc1
		input = [
			"]a",
		]
		res = input.map{|str| 
			# TODO: if any output to $stderr, then return true
			Regexp.new(str) 
			false
		}
		assert_equal([true] * input.size, res)
	end
	def test_special_curley_close1
		assert_match(/a}/, "0a}1")
	end

	include MatchAlternation
	include MatchAlternation2
	include MatchAlternation3
	include MatchBackref
	include MatchAnchor
	include MatchRepeat
	include MatchRepeatSequence 
	include MatchRepeatMinimum
	include MatchRepeatMaximum
	include MatchRepeatNested   
	include MatchRepeatNested2
	include MatchRepeatNested3
	include MatchRepeatLazyNested 
	include MatchRepeatLazy
	include MatchSequence  
	include MatchEmpty 
	include MatchCharclass      
	include MatchCharclassWarn
	include MatchOptionIgnorecase
	include MatchOptionMultiline
	include MatchOptionExtended
	include MatchParentesis
	include MatchLookahead
	include MatchEndlessLoop
	include MatchVerbose
	include MatchEscape  
	include MatchAtomicGrouping
	include MatchAdvancedRandom
	include MatchAdvancedIprange
	include MatchAdvancedPalindrome
	include MatchGlobalSubstitute
	include MatchScan
	include MatchSplit

	def execute_regex(pattern, subject)
		re = nil
		capture_stderr { re = Regexp.new(pattern, false) }
		match = re.match(subject)
		return nil unless match
		match.to_a
	end  
	include BlackboxRubicon

	case ENGINE
	when :gnu
		include EngineGnu
	when :oniguruma
		include EngineOniguruma
	else
		raise "unknown engine"
	end
end

XTestEngineBuiltin.run if $0 == __FILE__
