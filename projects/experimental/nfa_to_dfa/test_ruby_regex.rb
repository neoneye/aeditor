require 'test/unit'
require 'match_mixins'

# purpose:
# exercise Ruby's native regex support
#
# hopefully one day I will be able to
# overload Ruby's regex routines with
# my own, and make all these tests pass OK.
#
# todo:
# rubicon/language/regexp.test contains also many
# interesting patterns.
class TestRubyRegex < Test::Unit::TestCase
	def assert_regex(expected, regex, input, debug=false, message=nil)
		actual = ""
		begin
			m = Regexp.new(regex).match(input)
			if m == nil
				actual = nil
			else
				actual = m.to_a
			end
		rescue => e
			actual = e
		end
		full_message = build_message(message, <<EOT, expected, actual)
<?> expected but was
<?>.
EOT
		assert_block(full_message) { expected == actual }
	end
	def test_escape_string_begin1
		assert_match(/\Aab/, "abcd")
	end
	def test_escape_string_begin1
		assert_no_match(/\Aab/, "a\nabcd")
	end
	def test_escape_string_end1
		assert_match(/cd\z/, "abcd")
	end
	def test_escape_string_end2
		assert_no_match(/cd\z/, "abcd\n")
	end
	def test_escape_string_end_excl_newline1
		assert_match(/cd\Z/, "abcd\n")
	end
	def test_escape_string_end_excl_newline2
		assert_no_match(/cd\Z/, "abcd\nd")
	end
	def test_escape_word_boundary1
		assert_match(/b\b/, "ab cd")
	end
	def test_escape_word_boundary2
		assert_no_match(/b\b/, "abc d")
	end
	def test_escape_nonword_boundary1
		assert_no_match(/b\B/, "ab cd")
	end
	def test_escape_nonword_boundary2
		assert_match(/b\B/, "abc d")
	end
	def xtest_escape_leftword_boundary1
		assert_match(/\<b/, "a bcb")
	end
	def xtest_escape_leftword_boundary2
		assert_match(/\<b/, "ab cb")
	end
	def test_escape_hex1
		assert_match(/b\x20c/, "ab cd")
	end
	def test_escape_octal1
		assert_match(/b\040c/, "ab cd")
	end
	def test_escape_digit1
		assert_match(/b\dc/, "ab3cd")
	end
	def test_escape_nondigit1
		assert_no_match(/b\Dc/, "ab3cd")
	end
	def test_escape_whitespace1
		assert_match(/b\sc/, "ab cd")
	end
	def test_escape_nonwhitespace1
		assert_no_match(/b\Sc/, "ab cd")
	end
	def test_escape_word1
		assert_match(/b\wc/, "abxcd")
	end
	def test_escape_nonword1
		assert_no_match(/b\Wc/, "abxcd")
	end

	def test_occur_zero_or_more1
		assert_match(/bx*c/, "abcd")
	end
	def test_occur_zero_or_more2
		assert_match(/bx*c/, "abxcd")
	end
	def test_occur_zero_or_more2
		assert_match(/bx*c/, "abxxcd")
	end
	def test_occur_zero_or_one1
		assert_match(/bx?c/, "abcd")
	end
	def test_occur_zero_or_one2
		assert_match(/bx?c/, "abxcd")
	end
	def test_occur_zero_or_one3
		assert_no_match(/bx?c/, "abxxcd")
	end
	def test_occur_one_or_more1
		assert_no_match(/bx+c/, "abcd")
	end
	def test_occur_one_or_more2
		assert_match(/bx+c/, "abxcd")
	end
	def test_occur_one_or_more3
		assert_no_match(/bx+xc/, "abxcd")
	end
	def test_occur_one_or_more4
		assert_match(/bx+xc/, "abxxcd")
	end
	def xtest_illegal_range1
		input = [
			"a{3",        # premature end of input
			"a{,}b",      # neither min or max specified
			"a{,3}b",     # min expected, but got none
			"a{43x3}b",   # either ',' or '}' expected, got 'x'
			"a{43,333",   # premature end of input
			"a{43,333x",  # expected '}', got 'x'
			"a{999,666}"  # expected (min <= max), got (min > max)
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
	def test_occur_range1
		assert_no_match(/bx{1,4}c/, "abcd")
	end
	def test_occur_range2
		assert_match(/bx{1,4}c/, "abxcd")
	end
	def test_occur_range3
		assert_match(/bx{1,4}c/, "abxxxxcd")
	end
	def test_occur_range4
		assert_no_match(/bx{1,4}c/, "abxxxxxcd")
	end
	def test_occur_range5
		assert_no_match(/bx{1,4}xc/, "abxcd")
	end
	def test_occur_least_greedy1
		assert_no_match(/bx{2,}c/, "abxcd")
	end
	def test_occur_least_greedy2
		assert_match(/bx{2,}c/, "abxxcd")
	end
	def test_occur_least_greedy3
		assert_match(/bx{2,}c/, "abxxxcd")
	end
	def test_occur_least_greedy4
		assert_equal(["bxxxcxc", "xxxcx"], /b(.{2,})c/.match("abxxxcxcd").to_a)
	end
	def test_occur_least_lazy1
		assert_no_match(/b(.{2,}?)c/, "abxcd")
	end
	def test_occur_least_lazy2
		assert_match(/b(.{2,}?)c/, "abxxcd")
	end
	def test_occur_least_lazy3
		assert_equal(["bxxxc", "xxx"], /b(.{2,}?)c/.match("abxxxcxcd").to_a)
	end
	def test_occur_exact1
		assert_no_match(/bx{2}c/, "abxcd")
	end
	def test_occur_exact2
		assert_match(/bx{2,}c/, "abxxcd")
	end
	def test_occur_exact3
		assert_no_match(/bx{2}c/, "abxxxcd")
	end
	def test_occur_exact_repeat1
		assert_no_match(/ax{2}*a/, "0axxxa1")
	end
	def test_occur_exact_repeat2
		assert_equal(["axxxxa", "xxxx"], /a(x{2}*)a/.match("0axxxxa1").to_a)
	end
	def xtest_occur_max1
		assert_match(/bx{,2}c/, "abcd")
	end
	def xtest_occur_max2
		assert_match(/bx{,2}c/, "abxxcd")
	end
	def xtest_occur_max3
		assert_no_match(/bx{,2}c/, "abxxxcd")
	end
	def test_alter_simple1
		assert_match(/bc|bxc/, "abcd")
	end
	def test_alter_simple2
		assert_match(/bc|bxc/, "abxcd")
	end
	def test_alter_simple3
		assert_no_match(/bc|bxc/, "abxxcd")
	end
	def test_alter_simple4
		# left most longest: This is an excelent example that the
		# left most pattern in an alternation has higher priority
		assert_equal(["abab", "ab", nil], /(a.)+|(.b)+/.match("abab").to_a)
	end
	def test_alter_simple5
		# scanning stops when there is a pattern that matches.. 
		# in this case the first 'short' pattern matches
		assert_equal(["ab"], /ab|aba/.match("abax").to_a)
	end
	def test_alter_group_lastmatch1
		# the last matched element of the alternation
		# ends up in as group[1] = 'b'.
		assert_equal(["0abb1", "b"], /0(a|b)+1/.match("xx0abb1yy").to_a)
	end
	def test_alter_group_lastmatch2
		# the last matched element of the alternation
		# ends up in as group[1] = 'a'.
		assert_equal(["0bba1", "a"], /0(a|b)+1/.match("xx0bba1yy").to_a)
	end
	def test_alter_complex1
		# see if the repeat-stack gets flushed, when the
		# first alternation pattern fails.
		assert_equal(["abcd", "bc"], /a(b*|bc)d/.match("0abcd1").to_a)
	end
	def test_character_class1
		assert_match(/b[x-z]c/, "abxcd")
	end
	def test_character_class2
		assert_match(/b[x-z]c/, "abycd")
	end
	def test_character_class_neg1
		assert_no_match(/b[^xyX-Z]c/, "abycd")
	end
	def test_character_class_neg2
		assert_no_match(/b[^xyX-Z]c/, "abZcd")
	end
	def test_character_class_neg3
		assert_match(/b[^xyX-Z]c/, "abzcd")
	end
	def test_lookahead_equal1
		assert_match(/ab(?=cd)/, "abcd")
	end
	def test_lookahead_equal2
		assert_no_match(/ab(?=cd)/, "abxcd")
	end
	def test_lookahead_equal3
		assert_equal(["abb"], /ab*(?=bb)/.match("abbbbd").to_a)
	end
	def test_lookahead_distinct1
		assert_no_match(/ab(?!cd)/, "abcd")
	end
	def test_lookahead_distinct2
		assert_match(/ab(?!cd)/, "abxcd")
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
	def test_ruby_ignorecase_a1
		assert_match(/b((?i)x)/, "abxcd")
	end
	def test_ruby_ignorecase_a2
		assert_match(/b((?i)x)/, "abXcd")
	end
	def test_ruby_ignorecase_a3
		assert_no_match(/b((?i)x)/, "abcd")
	end
	def test_ruby_ignorecase_b1
		assert_match(/b(?i:x)/, "abxcd")
	end
	def test_ruby_ignorecase_b2
		assert_match(/b(?i:x)/, "abXcd")
	end
	def test_ruby_ignorecase_b3
		assert_no_match(/b(?i:x)/, "abcd")
	end
	def test_posix_comment1
		assert_match(/ab(?#yy)cd/, "abcd")
	end
	def test_posix_comment2
		assert_no_match(/ab(?#yy)cd/, "abxcd")
	end
	def test_wildcard_lazy1
		m = /<.+?>/.match("0<a>1<b>2")
		res = [m.pre_match, m.post_match]
		assert_equal(["0", "1<b>2"], res)
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
	def test_option_ignorecase1
		assert_match(/bx*c/i, "AbXxXxCd")
	end
	def test_option_multiline1
		assert_match(/ab.*cd/m, "ab\ncd")
	end
	def test_option_extended1
		# ignoring space
		assert_match(/b c/x, "abcd")
	end
	def test_option_extended2
		# ignoring newline+tabs
		assert_match(/b 
			c/x, "abcd")
	end
	def test_option_extended3
		# ignoring newline
		re = Regexp.new("b\nc", Regexp::EXTENDED)
		assert_match(re, "abcd")
	end
	def test_option_extended4
		# does not ignore newline... makes no sense?
		assert_no_match(/b\nc/x, "abcd")
	end
	def test_posix_character_class_digit1
		# alnum, alpha, blank, cntrl, digit, graph, 
		# lower, print, punct, space, upper, xdigit 
		assert_match(/b[[:digit:]]c/, "ab3cd")
	end
	def test_posix_character_class_digit2
		assert_no_match(/b[[:digit:]]c/, "abxcd")
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
	def test_special_backslash1
		assert_match(/b\\c/, "ab\\cd")
	end
	def test_special_period1
		assert_match(/b\.c/, "ab.cd")
	end
	def test_special_star1
		assert_match(/b\*c/, "ab*cd")
	end
	def test_special_circumflex1
		assert_match(/b\^c/, "ab^cd")
	end
	def test_special_brackets1
		m = /\[(.*)\]/.match("a[bc]d")
		assert_equal("bc", m[1])
	end
	def test_special_curleys1
		m = /\{(.*)\}/.match("a{bc}d")
		assert_equal("bc", m[1])
	end
	def test_special_parantesis1
		m = /\((.*)\)/.match("a(bc)d")
		assert_equal("bc", m[1])
	end

	include MatchAlternation
	include MatchAlternation2
	include MatchBackref
	include MatchDifficult  
	include MatchMeta
	include MatchRepeat
	include MatchRepeat2
	include MatchSequence  
	# todo:
	# * precedens between different operators
	# * any illegal regex constructions?
	# * more exercising of grouping.. and backrefs
	# * utf8 matching \udeadbeef
	# * What if I specify a different 'lang' option (n, e, s, u)
	# * operator (?m)  multiline 
	# * operator (?x)  extended
	#
	# not-possible:
	# * lookbehind 
	# * max number of occurences
	# * conditionals
	# * I cannot find POSIXLINE in 're.c'.. maybe no longer existent?
	# * match beginning of word operator \<
	# * match end of word operator \>
end

if $0 == __FILE__
	require 'test/unit/ui/console/testrunner'
	Test::Unit::UI::Console::TestRunner.run(TestRubyRegex)
end
