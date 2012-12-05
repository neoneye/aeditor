# purpose:
# functional tests with a bunch of perl5 regexp exercises.

module MatchSequence
	def test_sequence1
		assert_regex(["a"], "a", "bab")
	end
	def test_sequence2
		assert_regex(nil, "a", "xyz")
	end
	def test_sequence3
		assert_regex(["ab"], "ab", "aabb")
	end
	def test_sequence4
		assert_regex(nil, "a.b", "0a\nb1")
	end
	def test_sequence5
		assert_regex(["a1b"], "a.b", "0a1b2")
	end
	def test_sequence6
		assert_regex(["a1b", "1"], "a(.)b", "0a1b2")
	end
end # module MatchSequence

module MatchRepeat
	# phase #1,  the simplest form of greedy-repeat  ( ... )*
	def test_repeat1
		assert_regex(["a1b2b", "1b2", "2"], "a((.)*)b", "0a1b2b3")
	end
	def test_repeat2
		assert_regex(["<a>1<b>"], "<.*>", "0<a>1<b>2") 
	end
	def test_repeat3
		# match zero times
		assert_regex(["abc"], "ab*bc", "xabcz")
	end
	def test_repeat4
		assert_regex(nil, "ab*bc", "xacz")
	end
	def test_repeat5
		# match zero times
		assert_regex(["xx"], "x.*x", "0xx1")
	end
	def test_repeat6
		assert_regex(["bc"], "bx*c", "abcd")
	end
	def test_repeat7
		assert_regex(["bxc"], "bx*c", "abxcd")
	end
	def test_repeat8
		assert_regex(["bxxc"], "bx*c", "abxxcd")
	end
	def test_repeat9
		assert_regex(["y", ""], "(x*)y", "y")
	end  
	def test_repeat10
		assert_regex(["z", "", nil], "((x)*y*)z", "z")
	end  
	def test_repeat11
		assert_regex(["abc-123"], ".*", "abc-123")
	end  
end # module MatchRepeat

module MatchRepeatSequence
	def test_repeat_seq1
		assert_regex(
			["a1b2c3b3cd5e6ee", "1b2c3", "3", "", "5e6e"], 
			"a(.*)b(.*)c(.*)d(.*)e", 
			"0a1b2c3b3cd5e6ee7")
	end
	def test_repeat_seq2
		# on EndOfInput we must restart
		assert_regex(["a1b2c3b4c", "1b2c3"], "a(.*)b.*c", "0a1b2c3b4c5")
	end
	def test_repeat_seq3
		assert_regex(["a1b2c3c", "2c3"], "a.*b(.*)c", "0a1b2c3c4")
	end
end # module MatchRepeatSequence

module MatchRepeatMinimum
	# phase #2,  match a minimum number of times  ( ... )+  ( ... ){42,}
	def test_repeat_min1_1
		assert_regex(["xbx"], "xb+x", "0xbx0")
	end
	def test_repeat_min1_2
		assert_regex(nil, "xb+x", "0xx0")
	end
	def test_repeat_min1_3
		assert_regex(nil, "bx+c", "abcd")
	end
	def test_repeat_min1_4 
		assert_regex(["bxc"], "bx+c", "abxcd")
	end
	def test_repeat_min1_5 
		assert_regex(nil, "bx+xc", "abxcd")
	end
	def test_repeat_min1_6 
		assert_regex(["bxxc"], "bx+xc", "abxxcd")
	end
	def test_repeat_min2_1
		assert_regex(["xbbx"], "xb{2,}x", "0xbbx0")
	end
	def test_repeat_min2_2
		assert_regex(nil, "xb{2,}x", "0xbx0")
	end
	def test_repeat_min2_3
		assert_regex(nil, "bx{2,}c", "abxcd")
	end
	def test_repeat_min2_4
		assert_regex(["bxxc"], "bx{2,}c", "abxxcd")
	end
	def test_repeat_min2_5
		assert_regex(["bxxxc"], "bx{2,}c", "abxxxcd")
	end
	def test_repeat_min2_6
		assert_regex(["bxxxcxc", "xxxcx"], "b(.{2,})c", "abxxxcxcd")
	end
end # module MatchRepeatMinimum

module MatchRepeatMaximum
	# phase #3,  match a minium+maximum number of times ( ... )?  ( ... ){3,7} ( ... ){42}
	def test_repeat_range1
		assert_regex(nil, "bx{1,4}c", "abcd")
	end
	def test_repeat_range2
		assert_regex(["bxc"], "bx{1,4}c", "abxcd")
	end
	def test_repeat_range3
		assert_regex(["bxxxxc"], "bx{1,4}c", "abxxxxcd")
	end
	def test_repeat_range4
		assert_regex(nil, "bx{1,4}c", "abxxxxxcd")
	end
	def test_repeat_range5
		assert_regex(nil, "bx{1,4}xc", "abxcd")
	end
	def test_repeat_range6
		assert_regex(nil, "(ab){2}", "0aba1")
	end
	def test_repeat_range7
		assert_regex(["abab", "ab"], "(ab){2}", "0abab1")
	end
	def test_repeat_range8
		assert_regex(["abab", "ab"], "(ab){2}", "0ababa1")
	end
	def test_repeat_range9
		assert_regex(["abab", "ab"], "(ab){2}", "0ababab1")
	end
	def test_repeat_range10
		assert_regex(["ab"], "ax?b", "0ab1")
	end
	def test_repeat_range11
		assert_regex(["axb"], "ax?b", "0axb1")
	end
	def test_repeat_range12
		assert_regex(nil, "ax?b", "0axxb1")
	end
	def test_repeat_range13
		assert_regex(["a1b2b", "1b2"], "a(.{2,3})b", "0a1b2b3b4")
	end
	def test_repeat_range14
		assert_regex(["bc"], "bx?c", "abcd")
	end
	def test_repeat_range15
		assert_regex(["bxc"], "bx?c", "abxcd")
	end
	def test_repeat_range16
		assert_regex(nil, "bx?c", "abxxcd")
	end
	def test_repeat_range17 
		assert_regex(nil, "bx{2}c", "abxcd")
	end
	def test_repeat_range18 
		assert_regex(["bxxc"], "bx{2,}c", "abxxcd")
	end
	def test_repeat_range19 
		assert_regex(nil, "bx{2}c", "abxxxcd")
	end
	def test_repeat_range20 
		assert_regex(["aaab", "a"], "(a){1,3}b", "aaaab")
	end
	def test_repeat_range21 
		assert_regex(["b"], "a?b", "0b1")
	end
	def test_repeat_range22
		assert_regex(["d"], "[:alpha:]{0,3}d", "123d")
	end
	def test_repeat_range_special1 
		# expected (min <= max), got (min > max)
		assert_regex_error("a{999,666}") 
	end
	def test_repeat_range_special2 
		# NOT premature end of input
		assert_regex(["a{3"], "a{3", "2a{34")  
	end
	def test_repeat_range_special3 
		# NOT neither min or max specified
		assert_regex(["a{,}b"], "a{,}b", "0a{,}b1")  
	end
	def test_repeat_range_special4 
		# NOT min expected, but got none
		assert_regex(["a{,3}b"], "a{,3}b", "0a{,3}b1",
			:oniguruma_output=>["b"]  # maybe bug in oniguruma?
		) 
	end
	def test_repeat_range_special5 
		# NOT either ',' or '}' expected, got 'x'
		assert_regex(["a{43x3}b"], "a{43x3}b", "a{43x3}b")  
	end
	def test_repeat_range_special6 
		# NOT premature end of input
		assert_regex(["a{43,333"], "a{43,333", "a{43,333")  
	end
	def test_repeat_range_special7 
		# NOT expected '}', got 'x'
		assert_regex(["a{43,333x"], "a{43,333x", "a{43,333x") 
	end
	def test_repeat_range_ignore1 
		# repeat zero times => ignore pattern
		assert_regex(nil, "ie{0}r", "wierd") 
	end
	def test_repeat_range_ignore2 
		# repeat zero times => ignore pattern
		assert_regex(["ir"], "ie{0}r", "mirror") 
	end
end # module MatchRepeatMaximum

module MatchRepeatLazyNested
	def test_repeat_lazy_nested1
		assert_regex(["ruby", "b", "b"], "r((u|b)*?)*?y", "ruby",
			:bug_gnu=>nil   # definitly a bug in GNU
		)
	end
	def test_repeat_lazy_nested2
		assert_regex(["aababz", "ab"], "(a*?b)*?z", "vaababzab")
	end
end # module MatchRepeatNestedLazy

module MatchRepeatNested
	def test_repeat_nested1 
		assert_regex(nil, "ax{2}*a", "0axxxa1")
	end
	def test_repeat_nested2 
		assert_regex(["axxxxa", "xxxx"], "a(x{2}*)a", "0axxxxa1")
	end
	def test_repeat_nested3 
		assert_regex(["axa"], "ax{1}+a", "0axa1")
	end
	def test_repeat_nested4 
		assert_regex(["aa"], "ax?{2}a", "0aa1")
	end
	def test_repeat_nested5 
		assert_regex(["axa"], "ax?{2}a", "0axa1")
	end
	def test_repeat_nested6 
		assert_regex(["axxa"], "ax?{2}a", "0axxa1")
	end
	def test_repeat_nested7 
		assert_regex(nil, "ax?{2}a", "0axxxa1")
	end
	def test_repeat_nested8 
		assert_regex(["axx"], "ax?{2}x", "0axx1")
	end
end # module MatchRepeatNested

module MatchRepeatNested2
	def test_repeat_nested9 
		assert_regex(["a1b2ba3b", "a3b"], "(a.*b){2}", "0a1b2ba3b4")
	end
	def test_repeat_nested10
		assert_regex(["x1x2x", "1x2", "2"], "x((.)*)*x", "0x1x2x3",
			:oniguruma_output=>["x1x2x", "", "2"]  # nested quantifiers differs
		)
	end
	def test_repeat_nested11 
		assert_regex(["x1x2x3x", "1x2x3", "1x2", "2"], "x(((.)*)x.*)*x", "0x1x2x3x4")
	end
	def test_repeat_nested12
		assert_regex(["x1y2y3z4z", "1y2", "3z4"], "x(.*)*y(.*)*z", "0x1y2y3z4z5",
			:oniguruma_output=>["x1y2y3z4z", "", ""]  # nested quantifiers differ
		)
	end
	def test_repeat_nested13 
		assert_regex(["a1b2ba3b4b", "a3b4b"], "(a.*b){2}", "0a1b2ba3b4b5")
	end
	def test_repeat_nested14
		assert_regex(["abababab", "ab"], "(a.*b){3}", "0abababab1")
	end
	def test_repeat_nested15
		# notice that register#2 doesn't get cleared,
		# it must contain the last matched value.
		assert_regex(["ababxx", "x", "ab"], "((ab)*x)+", "0ababxx1")
	end
	def test_repeat_nested16 
		assert_regex(["a1ba2ba3b", "a3b"], "(a.*?b)*", "a1ba2ba3b4b5")
	end
	def test_repeat_nested17 
		assert_regex(["aaaaaaaa", "aaaa", "aa"], "((a{2}){2}){2}", "0aaaaaaaa1")
	end
	def test_repeat_nested18 
		assert_regex(nil, "((a{2}){2}){2}", "0aaaaaaa1")
	end
end # module MatchRepeatNested2

module MatchRepeatNested3
	def test_repeat_nested21
		assert_regex(["aabaaab", "aaab"], "(a*b)+", "xaabaaabx")
	end
	def test_repeat_nested22
		assert_regex(["", nil], "(a*b)*", "xaabaaabx")
	end
	def test_repeat_nested22a
		assert_regex(["aabaaab", "aaab"], "(a*b)*", "aabaaabx")
	end
	def test_repeat_nested23
		assert_regex(["", nil], "(a?b)?", "xbabx")
	end
	def test_repeat_nested23a
		assert_regex(["b", "b"], "(a?b)?", "babx")
	end
	def test_repeat_nested23b
		assert_regex(["ab", "ab"], "(a?b)?", "abx")
	end
	def test_repeat_nested24
		assert_regex(["", ""], "(g*|o*)+", "EL google")
	end
	def test_repeat_nested25
		# worstcase = 3 levels of nesting
		assert_regex(["axzxbxccx", "cc"], "(?:(a|b|c+)?z?x)*", "axzxbxccx0")
	end
	def test_repeat_nested26
		assert_regex(["aza", "", "z"], "a(?:(z?)(z+))*a", "aza")
	end
	def test_repeat_nested27
		assert_regex(["azza", "z", "z"], "a(?:(z?)(z+))*a", "azza")
	end
	def test_repeat_nested28
		assert_regex(["azzza", "z", "zz"], "a(?:(z?)(z+))*a", "azzza")
	end
	def test_repeat_nested29
		assert_regex(["foobar", "o"], "((?:foob)?o?(?:fo)?)*bar", "xfoobarx",
			:oniguruma_output=>["foobar", ""]  # don't know why
		)
	end
	def test_repeat_nested30
		assert_regex(["aaabbb", "bbb", "bbb"], "(a|(a*b*))*", "aaabbb",
			:oniguruma_output=>["aaabbb", "", ""]  # don't know why
		)
	end
end # module MatchRepeatNested3

module MatchRepeatLazy
	def test_repeat_lazy1
		assert_regex(["a1b2b3c", "1", "2b3"], "a(.*?)b(.*?)c", "0a1b2b3c4")
	end
	def test_repeat_lazy2
		assert_regex(["<a>"], "<.+?>", "0<a>1<b>2")
	end
	def test_repeat_lazy3
		assert_regex(nil, "b(.{2,}?)c", "abxcd")
	end
	def test_repeat_lazy4
		assert_regex(["bxxc", "xx"], "b(.{2,}?)c", "abxxcd")
	end
	def test_repeat_lazy5
		assert_regex(["bxxxc", "xxx"], "b(.{2,}?)c", "abxxxcxcd")
	end
	def test_repeat_lazy6
		assert_regex(["aa", ""], "a(a??)a", "0aaa1")
	end
	def test_repeat_lazy7
		assert_regex(nil, "a.{0,2}?a", "0aXXXa0")
	end
	def test_repeat_lazy8
		assert_regex(["aXXa"], "a.{0,2}?a", "0aXXa0")
	end
end # module MatchRepeatLazy

module MatchVerbose
	def test_verbose_alt_rep1
		assert_regex(["foobar", "o"], "(foob|fo|o)*bar", "xfoobarx")
	end
	def test_verbose_alt_rep2
		assert_regex(["bcac", "ac", "a", "c"], "((a|b)(c|d))*", "bcacao")
	end
	def test_verbose_repeat1
		assert_regex(["a1b2c3b4c5c", "4c5"], "a.*b(.*)c", "xa1b2c3b4c5cx")
	end
	def test_verbose_repeat2
		assert_regex(["aabbccdd", "ab", "c", "d"], "a(.*)b(.*)c(.*)d", "xaabbccddx")
	end
	def test_verbose_repeat3
		assert_regex(["aaxxbcd", "axx", "", ""], "a(.*)b(.*)c(.*)d", "xaaxxbcdx")
	end
	def test_verbose_repeat4
		assert_regex(["abc", "", ""], "a(.*)b(.*)c", "abc")
	end
end # module MatchVerbose

module MatchAlternation
	def test_alternation1
		assert_regex(["ab"], "ab|ac", "0ab1")
	end
	def test_alternation2
		assert_regex(["ac"], "ab|ac", "0ac1")
	end
	def test_alternation3
		assert_regex(nil, "ab|ac", "0a1c2")
	end
	def test_alternation4
		assert_regex(["aaab", "aa"], "a(aa|ab)b", "0aaab1")
	end
	def test_alternation5
		assert_regex(["aabb", "ab"], "a(aa|ab)b", "0aabb1")
	end
	def test_alternation6
		assert_regex(nil, "a(aa|ab)b", "0aaaa1")
	end
	def test_alternation7
		assert_regex(["abdf", "bd", "d"], "a(b(c|d)|e)f", "0abdf1")
	end
	def test_alternation8
		# if this fails, then its because we 
		# does'nt keep track of the depth of tags.
		assert_regex(["aef", "e", nil], "a(b(c|d)|e)f", "0aef1")
	end
	def test_alternation9
		# alternation must scan until mismatch, so
		# that it can discard 'aa'
		assert_regex(["aaa", "a"], "(aa|a)aa", "0aaa1")
	end
	def test_alternation10
		assert_regex(nil, "x(a(aa|a)|a)ax", "xax")
	end
	def test_alternation11
		# register #2 = nil, is cumbersome to implement
		# it requires that we do a deep-clone of the registers
		# everytime we try out a alternation-pattern!
		assert_regex(["xaax", "a", nil], "x(a(aa|a)|a)ax", "xaax")
	end
	def test_alternation12
		assert_regex(["xaaax", "aa", "a"], "x(a(aa|a)|a)ax", "xaaax")
	end
	def test_alternation13
		assert_regex(["xaaaax", "aaa", "aa"], "x(a(aa|a)|a)ax", "xaaaax")
	end
	def test_alternation14
		assert_regex(nil, "x(a(aa|a)|a)ax", "xaaaaax")
	end
	def test_alternation15
		assert_regex(["aa", "a"], "(aa|ab|a|b)a", "xaax")
	end
	def test_alternation16
		assert_regex(["af", nil, "f"], "a(b|c)|ad|a(e|f|g)", "xafx")
	end
end # module MatchAlternation

module MatchAlternation2
	def test_nested_group1
		assert_regex(["0bxb1", "bxb", "x"], "0(a|b(x|y)b|c)1", "3210bxb12")
	end
	def test_nested_group2
		assert_regex(["0byb1", "byb", "y"], "0(a|b(x|y)b|c)1", "3210byb12")
	end
	def test_nested_group3
		assert_regex(["0a1", "a", nil], "0(a|b(x|y)b|c)1", "3210a12")
	end
	def test_nested_group4
		assert_regex(["0c1", "c", nil], "0(a|b(x|y)b|c)1", "3210c12")
	end
	def test_nested_group5
		assert_regex(nil, "0(a|b(x|y)b|c)1", "3210axc12")
	end
	def test_alternating_priority1
		assert_regex(["a", ""], "a(|b)", "xabx")
	end
	def test_alternating_priority2
		assert_regex(["ab", "b"], "a(b|)", "xabx")
	end
	def test_alternating_priority3
		assert_regex(["ab", "b"], "a(b|bx)", "yabxy")
	end
	def test_alternating_priority4
		assert_regex(["abx", "bx"], "a(bx|b)", "yabxy")
	end
	def test_alternating_group1
		assert_regex(["ab", "ab", nil], "(ab)|(cd)", "0ab1")
	end
	def test_alternating_group2
		assert_regex(["cd", nil, "cd"], "(ab)|(cd)", "0cd1")
	end
	def test_alternating_group3
		assert_regex(nil, "(ab)|(cd)", "0ad1")
	end  
end # module MatchAlternation2

module MatchAlternation3
	def test_alter_simple1
		assert_regex(["bc"], "bc|bxc", "abcd")
	end
	def test_alter_simple2
		assert_regex(["bxc"], "bc|bxc", "abxcd")
	end
	def test_alter_simple3
		assert_regex(nil, "bc|bxc", "abxxcd")
	end
	def test_alter_simple4
		# left most longest: This is an excelent example that the
		# left most pattern in an alternation has higher priority
		assert_regex(["abab", "ab", nil], "(a.)+|(.b)+", "abab")
	end
	def test_alter_simple5
		# scanning stops when there is a pattern that matches.. 
		# in this case the first 'short' pattern matches
		assert_regex(["ab"], "ab|aba", "abax")
	end
	def test_alter_group_lastmatch1
		# the last matched element of the alternation
		# ends up in as group[1] = 'b'.
		assert_regex(["0abb1", "b"], "0(a|b)+1", "xx0abb1yy")
	end
	def test_alter_group_lastmatch2
		# the last matched element of the alternation
		# ends up in as group[1] = 'a'.
		assert_regex(["0bba1", "a"], "0(a|b)+1", "xx0bba1yy")
	end
	def test_alter_complex1
		# see if the repeat-stack gets flushed, when the
		# first alternation pattern fails.
		assert_regex(["abcd", "bc"], "a(b*|bc)d", "0abcd1")
	end
	def test_alter_complex2
		assert_regex(["xAxBxBxAxC", "xA"], "(xA|xB)*xC", "CxAxBxBxAxC")
	end
end # module MatchAlternation3

module MatchEmpty
	def test_empty1
		assert_regex(["", ""], "()?", "abc")
	end
	def test_empty2
		assert_regex(["a", ""], "a(c|)", "abc")
	end
	def test_empty3
		assert_regex([""], "b*", "abc")
	end
	def test_empty4
		assert_regex(["", ""], "()*", "abc")
	end
	def test_empty5
		assert_regex(["", nil], "()*?", "abc")
	end
end # module MatchEmpty

module MatchCharclass
	def test_charclass1
		assert_regex(["aDbEcF"], "[a-cD-F]+", "0aDbEcF1")
	end
	def test_charclass2
		assert_regex(["aDcF"], "[acDF]+", "0EaDcFb1")
	end
	def test_charclass3
		# its not a range; its sequence ['A', '-']
		assert_regex(["-A"], "[A-]+", "0-A1")
	end
	def test_charclass4
		# its not a range; its sequence ['-', '^']
		assert_regex(["^-^"], "[-^]+", "0^-^1")
	end
	def test_charclass5
		assert_regex(["--"], "[-]+", "0--1")
	end
	def test_charclass6
		assert_regex(["^^"], '[\^]+', "0^^1")
	end
	def test_charclass7
		assert_regex(["[["], '[\[]+', "0[[1")
	end
	def test_charclass8
		assert_regex(["]]"], '[\]]+', "0]]1")
	end
	def test_charclass9
		# alnum, alpha, blank, cntrl, digit, graph, 
		# lower, print, punct, space, upper, xdigit 
		assert_regex(["b3c"], "b[[:digit:]]c", "ab3cd")
	end
	def test_charclass10
		assert_regex(nil, "b[[:digit:]]c", "abxcd")
	end
	def test_charclass11
		assert_regex([".[:"], "[.[:]+", "a].[:d",
			:rubywarn=>"character class has `\\[' without escape")
	end
	def test_charclass12
		assert_regex(["123"], '[\d]+', "a123d")
	end
	def test_charclass13
		# Absurd to use inverse inside regexp, ([[:digit:]]|[^[:space:]])
		assert_regex(["a1b2"], '[\d\S]+', " a1b2 3d")
	end
	def test_charclass14
		# Absurd to use inverse inside regexp, [[:space:]]
		assert_regex([" "], '[^\S]+', "Wa1b2 3d")
	end
	def test_charclass15
		assert_regex(["a"], '[\s\S]', "a b")
	end
	def test_charclass16
		assert_regex(["a"], '[\S\s]', "a b")
	end
	def test_charclass17
		assert_regex(["a"], '[^\S\s]', "a b",
			:oniguruma_output=>nil,
			:bug_gnu=>nil
		)
	end
	def test_charclass18
		assert_regex(["a"], '[^\s\S]', "a b",
			:oniguruma_output=>nil,
			:bug_gnu=>nil
		)
	end
	def test_charclass_octal1
		assert_regex(["bc"], '[^\040]{2,}', " a bc ")
	end
	def test_charclass_octal2
		assert_regex(["  "], '[\040]{2,}', " a  b")
	end
	def test_charclass_octal3
		assert_regex(["a\001", "a"], '(.)[\1]', " a\001b")
	end
	def test_charclass_octal4
		assert_regex(["\335\335"], '[\735]{2,}', " a\335\335b")
	end
	def test_charclass_octal5
		assert_regex(["\337\335\336"], '[\735-\737]{2,}', " a\337\335\336b")
	end
	def test_charclass_octal6
		assert_regex(["\337\335\336"], '[\735-\337]{2,}', " a\337\335\336b")
	end
	def test_charclass_octal7
		assert_regex(["\337\335\336"], '[\335-\337]{2,}', " a\337\335\336b")
	end
	def test_charclass_hex1
		assert_regex(["bc"], '[^\x20]{2,}', " a bc ")
	end
	def test_charclass_hex2
		assert_regex(["  "], '[\x20]{2,}', " a  b")
	end
	def test_charclass_hex3
		assert_regex(["abc"], '[a-\x63]{3,}', "cxx a\x62c a")
	end
	def test_charclass_escape1
		assert_regex(["\nan\n\a"], '[a\nn\a]{5,}', "\ann a\n\na \nan\n\a")
	end
	def test_charclass_escape2
		assert_regex(["\xa\x9\x8\x7"], '[\a-\n]{2,}', "ab\000\xa\x9\x8\x7\000ab")
	end
	def test_charclass_illegal1
		assert_regex_error("[Z-A]")
	end
	def test_charclass_illegal2
		assert_regex_error("[^]")
	end
	def test_charclass_illegal3
		assert_regex_error("[]")
	end
	def test_charclass_illegal4
		assert_regex_error("[+")
	end
	def test_charclass_illegal5
		assert_regex_error("[[:xxx:]]")
	end
	def test_charclass_illegal6
		assert_regex_error("[[::]]+")
	end
	def test_charclass_illegal7
		assert_regex_error("[[:digit:]-[:word:]]+")
	end
	def test_charclass_neg1
		assert_regex(nil, "b[^xyX-Z]c", "abycd")
	end
	def test_charclass_neg2
		assert_regex(nil, "b[^xyX-Z]c", "abZcd")
	end
	def test_charclass_neg3
		assert_regex(["bzc"], "b[^xyX-Z]c", "abzcd")
	end
	def test_charclass_neg4
		assert_regex(["abc"], "[^-]+", "--abc--")
	end
	def test_charclass_neg5
		# its not a range; its a sequence
		# 0x2d=>'-', 0x2E=>'.', 0x30=>'0' 
		assert_regex(["a.b"], "[^-0]+", "0-a.b-0")
	end
	def test_charclass_neg6
		assert_regex(["abc"], "[^[:digit:]]+", "0abc1")
	end
	def test_charclass_neg7
		assert_regex(["abc"], "[[:^digit:]]+", "0abc1")
	end
	def test_charclass_neg8
		assert_regex(["666"], "[[:^alpha:]]+", "alpha666alpha")
	end
	def test_charclass_posix_digit1
		assert_regex(["0739"], '\d+', "a0739d")
	end
	def test_charclass_posix_nondigit1
		assert_regex(["abc"], '\D+', "0abc1")
	end
	def test_charclass_posix_whitespace1
		assert_regex(["b c"], 'b\sc', "ab cd")
	end
	def test_charclass_posix_nonwhitespace1
		assert_regex(["ab"], '\S+', "  ab  ")
	end
	def test_charclass_posix_word1
		assert_regex(["copy_left3"], '\w+', "#copy_left3(a, b)")
	end
	def test_charclass_posix_nonword1
		assert_regex(["%(.="], '\W+', "a_b%(.=cd")
	end
end # module MatchCharclass

module MatchCharclassWarn
	def test_charclass_warn1
		assert_regex(["abc-e"], "[a-c-e]+", "0abc-ed1", 
			:rubywarn=>"character class has `-' without escape")
	end
	def test_charclass_warn2
		assert_regex(["abc-efg"], "[a-c-e-g]+", "0abc-efgd1", 
			:rubywarn=>"character class has `-' without escape")
	end
	def test_charclass_warn3
		assert_regex(["[["], "[[]+", "0[[1", 
			:rubywarn=>"character class has `\\[' without escape")
	end
	def test_charclass_warn4
		# 0x29=>')', 0x2d=>'-', 0x2E=>'.', 0x30=>'0' 
		# notice that '.' is excluded
		assert_regex(["+-0"], "[)--0]+", "a+-0.b", 
			:rubywarn=>"character class has `-' without escape")
	end
	def test_charclass_warn5
		# ']' are within the character range!!!  wierd
		# I expect it to fail, the same way as /[]/ does
		# I consider this as a BUG in GNU's regex engine.
		assert_regex(["]"], "[]]+", "a]e", 
			:rubywarn=>"character class has `\\]' without escape")
	end
	def test_charclass_warn6
		# ']' are within the character range ('['..'_').
		assert_regex(["]"], '[[-_]+', "a]e", 
			:rubywarn=>"character class has `\\[' without escape")
	end
	def test_charclass_warn7
		# 'Z' are within the character range ('Y'..'[').
		assert_regex(["Z"], '[Y-[]+', "aZe", 
			:rubywarn=>"character class has `\\[' without escape")
	end
end # module MatchCharclassWarn

module MatchBackref
	def test_backref1
		assert_regex(["YbcY", "Y"], '(Y|X).*\1', "aYbcYd")
	end
	def test_backref2
		assert_regex(["XbcX", "X"], '(Y|X).*\1', "aXbcXd")
	end
	def test_backref3
		assert_regex(nil, '(Y|X).*\1', "aYbcXd")
	end
	def test_backref4
		assert_regex(nil, '(Y|X).*\1', "abcd")
	end
	def test_backref5
		assert_regex(["a", ""], '(?:\1a|())*', "abc",
			:bug_gnu=>["", nil]
		)
	end
	def test_backref_octal1
		assert_regex(["xx"] + (["x"]*10), '((((((((((x))))))))))\10', "axxa")
	end
	def test_backref_octal2
		assert_regex(["x\010"], 'x\10', "ax\010a")
	end
	def test_backref_octal3
		#  left-most \10 is interpreted as octal
		# right-most \10 is interpreted as backref
		assert_regex(["\010xx"] + (["x"]*10), '\10((((((((((x))))))))))\10', "a\010xxa")
	end
	def test_backref_octal4
		assert_regex(["\017xx"] + (["x"]*17), '\17'+('('*17)+'x'+(')'*17)+'\17', "a\017xxa")
	end
	def test_backref_octal5
		assert_regex(["\0019xx"] + (["x"]*19), '\19'+('('*19)+'x'+(')'*19)+'\19', "a\0019xxa")
	end
	def test_backref_octal6
		assert_regex(["\0242"], '\4242', "x\0242x")
	end
	def test_backref_octal7
		assert_regex(nil, '(\1)', "a")
	end
	def test_backref_octal8
		assert_regex(["\001", "\001"], '(\1)', "a\001a",
			:oniguruma_output=>nil,
			:bug_gnu=>nil
		)
	end
	def test_backref_octal9
		#   (   (   x   )   \2#backref   \1#octal   )   \1#backref
		assert_regex(["xx\001xx\001", "xx\001", "x"], '((x)\2\1)\1', "axx\001xx\001a",
			:oniguruma_output=>nil,
			:bug_gnu=>nil
		)
	end
	def test_backref_none1
		assert_regex(["x", "x"], '(x)|\1', "abxcd")
	end
	def test_backref_none2
		assert_regex(nil, '(x)|\1', "abcd")
	end
	def test_backref_special1
		assert_regex(nil, 'x(a+)\1x', "xax")
	end
	def test_backref_special2
		assert_regex(["xaax", "a"], 'x(a+)\1x', "xaax")
	end
	def test_backref_special3
		assert_regex(nil, 'x(a+)\1x', "xaaax")
	end
	def test_backref_special4
		assert_regex(["xaaaax", "aa"], 'x(a+)\1x', "xaaaax")
	end
end # module MatchBackref

module MatchAnchor
	# There exists these forms of anchors
	# ^      beginning of line
	# $      end of line
	# \A     beginning of string
	# \z     end of string
	# \Z     end of string (excl newline)
	# \b     word boundary
	# \B     non-word boundary
	def test_anchor_begin1
		assert_regex(["ab"], "^ab", "a\nabcd")
	end
	def test_anchor_begin2
		assert_regex(nil, "^ab", "a\nxabcd")
	end
	def test_anchor_begin3
		assert_regex(["ab"], "^ab", "ab\nacd")
	end
	def test_anchor_end1
		assert_regex(["cd"], "cd$", "a\nbcd\ne")
	end
	def test_anchor_end2
		assert_regex(nil, "cd$", "a\nbcdx\ne")
	end
	def test_anchor_end3
		assert_regex(["cd"], "cd$", "a\nbcdx\necd")
	end
	def test_anchor_end4
		assert_regex([""], "$", "")
	end
	def test_anchor_end6
		# absurd that this are possible!
		assert_regex(nil, "x$+", "xy")
	end
	def test_anchor_string_begin1
		assert_regex(["ab"], '\Aab', "abcd")
	end
	def test_anchor_string_begin2
		assert_regex(nil, '\Aab', "a\nabcd")
	end
	def test_anchor_string_end1
		assert_regex(["cd"], 'cd\z', "abcd")
	end
	def test_anchor_string_end2
		assert_regex(nil, 'cd\z', "abcd\n")
	end
	def test_anchor_string_end_excl_newline1
		assert_regex(["cd"], 'cd\Z', "abcd\n")
	end
	def test_anchor_string_end_excl_newline2
		assert_regex(nil, 'cd\Z', "abcd\nd")
	end
	def test_anchor_string_end_excl_newline3
		assert_regex(["cd"], 'cd\Z', "abcd")
	end
	def test_anchor_string_end_excl_newline4
		assert_regex(nil, 'cd\Z', "abcdx")
	end
	def test_anchor_word_boundary1
		assert_regex(["b"], 'b\b', "ab cd")
	end
	def test_anchor_word_boundary2
		assert_regex(nil, 'b\b', "abc d")
	end
	def test_anchor_word_boundary3
		assert_regex(["c"], '\bc', "ab cd")
	end
	def test_anchor_word_boundary4
		assert_regex(["cx"], '\bc.', "ab_cd5cDc\"cxy")
	end
	def test_anchor_nonword_boundary1
		assert_regex(nil, 'b\B', "ab cd")
	end
	def test_anchor_nonword_boundary2
		assert_regex(["b"], 'b\B', "abc d")
	end
	def test_anchor_nonword_boundary3
		assert_regex(nil, '\Bb', "a bcd")
	end
end # module MatchAnchor

module MatchOptionIgnorecase
	# There are these forms of Ignorecase
	# (?i)pattern     ignorecase=true
	# (?i:pattern)    ignorecase=true
	# (?-i)pattern    ignorecase=false
	# (?-i:pattern)   ignorecase=false
	def test_ignorecase_a1
		assert_regex(["bx", "x"], "b((?i)x)", "abxcd")
	end
	def test_ignorecase_a2
		assert_regex(["bX", "X"], "b((?i)x)", "abXcd")
	end
	def test_ignorecase_a3
		assert_regex(nil, "b((?i)x)", "abcd")
	end
	def test_ignorecase_a4
		assert_regex(["Xc", "X"], "((?i)x)c", "abXcd")
	end
	def test_ignorecase_a5
		assert_regex(nil, "((?i)x)c", "abXCd")
	end
	def test_ignorecase_a6
		# absurd, ignorecase of a backreference.
		assert_regex(["abAb", "ab", "Ab"], '(ab)((?i)\1)', "abAb")
	end
	def test_ignorecase_a7
		assert_regex(["abcdabcd", "abcd"], '(a(?:b(?i)c)d)\1', "0abcdabcd1")
	end
	def test_ignorecase_a8
		assert_regex(["abCdabCd", "abCd"], '(a(?:b(?i)c)d)\1', "0abCdabCd1")
	end
	def test_ignorecase_a9
		assert_regex(nil, '(a(?:b(?i)c)d)\1', "0abCdabcd1")
	end
	def test_ignorecase_a10
		assert_regex(nil, '(a(?:b(?i)c)d)\1', "0abcdabCd1")
	end
	def test_ignorecase_a11
		assert_regex(nil, '(a(?:b(?i)c)d)\1', "0aBcdaBcd1")
	end
	def test_ignorecase_b1
		assert_regex(["bx"], "b(?i:x)", "abxcd")
	end
	def test_ignorecase_b2
		assert_regex(["bX"], "b(?i:x)", "abXcd")
	end
	def test_ignorecase_b3
		assert_regex(nil, "b(?i:x)", "abcd")
	end
	def test_ignorecase_b4
		assert_regex(["bx"], "b(?i:[x-z])", "abxcd")
	end
	def test_ignorecase_b5
		assert_regex(["bX"], "b(?i:[x-z])", "abXcd")
	end
	def test_ignorecase_b6
		assert_regex(nil, "b(?i:[^x-z])", "abxcd")
	end
	def test_ignorecase_b7
		assert_regex(nil, "b(?i:[^x-z])", "abXcd")
	end
	def test_ignorecase_c1
		assert_regex(["Bx"], "(?i)b(?-i)x", "aBxd")
	end
	def test_ignorecase_c2
		assert_regex(nil, "(?i)b(?-i)x", "aBXd")
	end
	def test_ignorecase_d1
		assert_regex(["xB"], "(?i:(?-i:x)b)", "axBd")
	end
	def test_ignorecase_d2
		assert_regex(nil, "(?i:(?-i:x)b)", "aXBd")
	end
	def test_ignorecase_alternation1
		assert_regex(["a"], "(?i)a|b", "0Ba1",
			:oniguruma_output=>["B"]  # scope for options differ in oniguruma
		)
	end
	def test_ignorecase_special1
		# first enable, then disable ignorecase
		assert_regex(["a"], "(?i-i:a)+", "0Aa1")
	end
end # module MatchOptionIgnorecase

module MatchOptionMultiline
	def test_multiline_a1
		assert_regex(["a1a2\n3a4a"], "a(?m:.*)a", "0a1a2\n3a4a5")
	end
	def test_multiline_b1
		assert_regex(["a1\na2a"], "a(?m).*a(?-m).*a", "0a1\na2a\n3a4")
	end
	def test_multiline_alternation1
		assert_regex(["b"], "(?m)a.*a|b", "0ba\na1")
	end
	def test_multiline_alternation2
		assert_regex(["bab"], "(?m)a.*a|b.*b", "0bab\nab1",
			:oniguruma_output=>["bab\nab"]  # scope for options differ in oniguruma
		)
	end
	def test_multiline_special1
		# first enable, then disable multiline
		assert_regex(["a3a"], "a(?m-m:.*)a", "0a1\n2a3a4")
	end
end # module MatchOptionMultiline

module MatchOptionExtended
	def test_extended1
		assert_regex(["bc"], "(?x)b \n\tc", "abcd")
	end
	def test_extended2
		assert_regex(["bcb c"], "(?x)b c(?-x)b c", "abcbcb cb cd")
	end
	def test_extended3
		# space between atom and repeat
		assert_regex(["a123b"], "(?x)\ta .\n+b", "0a123b4")
	end
	def test_extended4
		# space within charclass are interpreted as space
		assert_regex(["Ba bB"], "(?x)B[a b]+B", "Ba bBabB")
	end
	def test_extended5
		# space within parentesis are interpreted as space
		assert_regex(["xxxx"], "(?x)(?: x x )+", "0xxxx1")
	end
	def test_extended6
		assert_regex(["GoOoOgL", "oOoO"], "(?x)  G (o O(?-x)oO) g L", "GoOoOgLe")
	end
	def test_extended7
		assert_regex(nil, "(?x)  G (o O(?-x)o O) g L", "GoOoOgLe")
	end
	def test_extended8
		assert_regex(["xx"], "(?x) x + \n", "0,xx'xx1")
	end
	def test_extended_illegal1
		# spaces are not allowed within (? kind of patterns.
		assert_regex_error("(?x)\ta\n( ? - x)test")
	end
end # module MatchOptionExtended

module MatchParentesis
	def test_para_posix_comment1
		assert_regex(["abcd"], "ab(?#yy)cd", "abcd")
	end
	def test_para_posix_comment2
		assert_regex(nil, "ab(?#yy)cd", "abxcd")
	end
	def test_para_posix_comment3
		assert_regex(["ab"], "a(?#)b", "0ab1")
	end
	def test_para_pure_group1
		# the \1 backref should point at 'x'
		assert_regex(["bxcdx", "x"], '(?:b)(x).*\1', "abxcdxe")
	end
	def test_para_pure_group2
		# the \1 backref does NOT point at 'b'
		assert_regex(nil, '(?:b)(x).*\1', "abxcdbe")
	end
	def test_para_pure_group3
		# nested parentesis are not affected by the pure group.
		assert_regex(["abc", "a"], '(?:(a)b)c', "0abc1")
	end
	def test_para_pure_group4
		# repeat of a pure-group, can be useful.
		assert_regex(["abbc"], "a(?:b)*c", "0abbc1")
	end
end # module MatchParentesis

module MatchLookahead
	def test_lookahead_positive1
		assert_regex(["ab"], "ab(?=cd)", "abcd")
	end
	def test_lookahead_positive2
		assert_regex(nil, "ab(?=cd)", "abxcd")
	end
	def test_lookahead_positive3
		assert_regex(["abb"], "ab*(?=bb)", "abbbbd")
	end
	def test_lookahead_positive4
		# nested parentesis are not affected by lookahead
		assert_regex(["a", "c"], "a(?=b(c))", "0abc1")
	end
	def test_lookahead_positive5
		# there can be text after the lookahead
		assert_regex(["ab"], "a(?=b|c)(?=c|b)b", "0ab1")
	end
	def test_lookahead_positive6
		assert_regex(["x2"], "x.(?=!.*a)", "0x1x2!3a4a5")
	end
	def test_lookahead_positive7
		assert_regex(["abab", "ab", "ab"], "((?=(.b){2,})a.)*", "ababab")
	end
	def test_lookahead_negative1
		assert_regex(nil, "ab(?!cd)", "abcd")
	end
	def test_lookahead_negative2
		assert_regex(["ab"], "ab(?!cd)", "abxcd")
	end
	def test_lookahead_negative3
		# register[1] will always be nil, no matter the input
		assert_regex(["a", nil], "a(?!b(c))", "0abd1")
	end
	def test_lookahead_negative4
		assert_regex(["x="], "x.(?!=)", "0xx=xx0")
	end
	def test_lookahead_negative5
		assert_regex(["foo", "ba"], "foo(?!(..)r)", "0foobaz0",
			:bug_gnu=>["foo", nil],
			:oniguruma_output=>["foo", nil]  # I suspect this is a bug in oniguruma
		)
	end
	def test_lookahead_negative6
		assert_regex(["foo", nil], "foo(?!(..)r)", "0foo\nar0")
	end
	def test_lookahead_negative7
		# TODO: what is the desired behavier here?
		assert_regex(["foo", "baz0"], "foo(?!(.*)r)", "0foobaz0",
			:bug_gnu=>["foo", nil],
			:oniguruma_output=>["foo", nil]
		)
	end
end # module MatchLookahead

module MatchEndlessLoop
	def test_endless_posixcomment1
		assert_regex(["ab"], "a(?#x)+?b", "0ab1")
	end
	def test_endless_lookahead_positive1
		assert_regex(["ab"], "a(?=b1)+b", "0ab1")
	end
	def test_endless_lookahead_negative1
		assert_regex(["ab"], "a(?!b2)+b", "0ab1")
	end
	def test_endless_empty1
		assert_regex(["", ""], "()*", "abc")
	end
	def test_endless_empty2
		assert_regex(["", ""], "()+", "abc")
	end
	def test_endless_empty3
		assert_regex(["", ""], "(){2,}", "abc")
	end
	def test_endless_empty4
		assert_regex(["", ""], "(){3,}", "abc")
	end
	def test_endless_empty5
		assert_regex(["ab"], "a(?:)+b", "0ab1")
	end
	def test_endless_empty6
		assert_regex(["", ""], "(){2,}?", "abc")
	end
	def test_endless_alternation1
		assert_regex(["aaa", "a"], "a(a|)*", "aaabbb",
			:oniguruma_output=>["aaa", ""]
		)
	end
	def test_endless_alternation2
		assert_regex(["ab", ""], "a(|)*b", "aaabbb",
			:bug_gnu=>["ab", nil]   # definitly a bug in GNU
		)
	end
	def test_endless_alternation3
		assert_regex(["ab", ""], "a(|||)*b", "aaabbb",
			:bug_gnu=>["ab", nil]   # definitly a bug in GNU
		)
	end
	def test_endless_alternation4
		assert_regex(["aabb", "ab"], "a(|ab)*b", "aaabbb",
			:oniguruma_output=>["aabb", ""]
		)
	end
	def test_endless_anchor_boundarynonword1
		assert_regex(["ab"], "a(?:\\B)+b", "abc")
	end
	def test_endless_anchor_end1
		# absurd case, GNU regexp should say that there
		# are no previous pattern which to repeat.
		# But it doesn't.
		assert_regex(["ab"], "ab$+", "ab")
	end
	def test_endless_anchor_end2
		assert_regex(["a", nil], "a(b|$)*", "aab\nx")
	end
	def test_endless_anchor_end3
		assert_regex(["ab", "b"], "a(b|$)+", "aab\nx",
			:oniguruma_output=>["ab", ""]
		)
	end
	def test_endless_anchor_begin2
		assert_regex(["ab", "a"], "(^|a)*b", "xab\naab\nx")
	end
	def test_endless_anchor_begin3
		assert_regex(["aab", "a"], "(^|a)*b", "xa\naab\nx")
	end
	def test_endless_keep_subcapture1
		assert_regex(["xyz", "y"], "x(y?)*z", "xyz",
			:oniguruma_output=>["xyz", ""]
		)
	end
	def test_endless_keep_subcapture2
		assert_regex(["xyz", "y"], "x(y{0,2})*z", "xyz",
			:oniguruma_output=>["xyz", ""]
		)
	end
	def test_endless_keep_subcapture3
		assert_regex(["xy", "y"], "x(.*(?=z))*", "xyz",
			:bug_gnu=>["xy", ""],
			:oniguruma_output=>["xy", ""]
		)
	end
	def test_endless_keep_subcapture4
		assert_regex(["xyy", "yy"], "x(y*)*", "xyyz",
			:bug_gnu=>["xyy", ""],
			:oniguruma_output=>["xyy", ""]
		)
	end
	def test_endless_eternal1
		assert_regex(nil, 
			'<(?:[^">]+|"[^"]*")+>', 
			'<META http-equiv="Content-Type content="text/html; charset=iso-8859-1">'
		)
	end
end # module MatchEndlessLoop

module MatchLookbehindPositive
	def test_lookbehind_positive1
		assert_regex(["bar"], "(?<=foo)bar", "0foobar0")
	end
	def test_lookbehind_positive2
		assert_regex(nil, "(?<=foo)bar", "0bar0")
	end
	def test_lookbehind_positive3
		assert_regex(["lo"], "(?<=l)l.", "hello")
	end
	def test_lookbehind_positive4
		assert_regex(["gol", "l"], "g(?<=a(l)g)o.", "goa algol goto")
	end
	def test_lookbehind_positive5
		assert_regex(["gol", "alg"], "g(?<=eg|(alg))o.", "goa algol lego egon goto")
	end
	def test_lookbehind_positive6
		assert_regex(["gon", nil], "g(?<=eg|(alg))o.", "goa egon lego algol goto")
	end
	def test_lookbehind_positive7
		assert_regex(nil, "g(?<=eg|(alg))o.", "goa goto gosub lego")
	end
	def test_lookbehind_positive8
		assert_regex(nil, "bar(?<=f(..)bar)", "0eoobar0")
	end
	def test_lookbehind_positive9
		assert_regex(["bar", "oo"], "bar(?<=f(..)bar)", "0foobar0")
	end
	def test_lookbehind_positive10
		assert_regex(["bar", "o", "e"], "bar(?<=f(.)(.)bar)", "0foebar0")
	end
	def test_lookbehind_positive11
		assert_regex(["gol", nil, "al", "g"], "g(?<=(e)g|(al)(g))o.", "goa algol lego egon goto")
	end
	def test_lookbehind_positive12
		assert_regex(["gon", "e", nil, nil], "g(?<=(e)g|(al)(g))o.", "goa egon lego algol goto")
	end
	def test_lookbehind_positive13
		assert_regex(["xa9x%%", "x%%"], '((?<=[a-z].)x..)+', '%%xa9xa9x%%x%%')
	end
	def test_lookbehind_positive_with_quantifier1
		assert_regex(["gol", "a al"], "g(?<=(a.*)g)o.", "goa algol goto")
	end
	def test_lookbehind_positive_with_quantifier2
		assert_regex(["cdx", "zab"], "c(?<=(.*)c)d.", "zabcdx-abxcdefz")
	end
	def test_lookbehind_positive_right_most_longest1
		# left-most-longest tells us that the output must be ["cde", "bcxa", "x"]
		# however in lookbehind the left-most-longest rule is inversed
		# so its the right-most-longest
		# TODO: left-most-longest would be nice
		assert_regex(["cde", "", "cxabx"], "c(?<=a(.*)b(.*)c)d.", "zabcxabxcdefz")
	end
	def test_lookbehind_positive_right_most_longest2
		# TODO: left-most-longest would be nice
		assert_regex(["cxdefd", "cxa", "x", "xdef"], "c(?<=a(.*)b(.*)c)(.*)d", "zacxabxcxdefdz")
	end
	def test_lookbehind_positive_with_lookahead1
		assert_regex(["got"], "g(?<=(?=g.t)g)o.", "goa gosub gone goto gov")
	end
	def test_lookbehind_positive_with_lookbehind1
		assert_regex(["gon"], "g(?<=(?<=e)g)o.", "goa gosub egon gov")
	end
	def test_lookbehind_positive_with_lookbehind2
		assert_regex(["gon", "e"], "g(?<=(?<=(e))g)o.", "goa gosub egon gov")
	end
	def test_lookbehind_positive_with_lookbehind3
		assert_regex(["gol"], "g(?<=l.(?<!le)g)o.", "goa gosub egon lego logol gov")
	end
	def test_lookbehind_positive_with_backref1
		assert_regex(["some", "b"], '(?<=<(\w+)>.*?</\1>)some', "zz<b>x</b>somezz")
	end
	def test_lookbehind_positive_with_capture1
		# lets do a backref to that subcapture inside lookbehind
		assert_regex([">x</b>some", "b"], '>(?<=<(\w+)>).*?</\1>some', "zz<b>x</b>somezz")
	end
	def test_lookbehind_positive_with_capture2
		# lets do a backref to that subcapture inside lookbehind
		assert_regex(["</b>some", "b"], '<(?<=<(\w+)>.*?<)/\1>some', "zz<b>x</b>somezz")
	end
end # module MatchLookbehindPositive

module MatchLookbehindNegative
	def test_lookbehind_negative1
		assert_regex(nil, "(?<!foo)bar", "0foobar0")
	end
	def test_lookbehind_negative2
		assert_regex(["bar"], "(?<!foo)bar", "0bar0")
	end
	def test_lookbehind_negative3
		assert_regex(["lo"], "(?<!e)l.", "hello")
	end
	def test_lookbehind_negative4
		assert_regex(nil, "bar(?<!f(..)bar)", "0foobar0")
	end
	def test_lookbehind_negative5
		assert_regex(["bar", "oo"], "bar(?<!f(..)bar)", "0eoobar0")
	end
	def test_lookbehind_negative6
		assert_regex(["bar", "\no"], "bar(?<!f(..)bar)", "0f\nobar0")
	end
	def test_lookbehind_negative7
		assert_regex(["bar", "0eoo"], "bar(?<!f(.*)bar)", "0eoobar0")
	end
end # module MatchLookbehindNegative

module MatchAtomicGrouping
	def test_atomic_grouping1
		assert_regex(["oobar", "o"], "(?>(foob|fo|o)*)bar", "xfoobarx")
	end
	def test_atomic_grouping2
		assert_regex(nil, "(?>\\d+)4", "x1234x")
	end
	def test_atomic_grouping2a
		assert_regex(["1234"], "(?>\\d+)", "x1234x")
	end
	def test_atomic_grouping3
		assert_regex(
			["abc,def,ghi,klm", "klm"], 
			"^(?>(?:.*?,){3})([[:alpha:]]*?(?=,))", 
			"abc,def,ghi,klm,nop,qrs"
		)
	end
	def test_atomic_grouping4
		assert_regex(
			nil,
			"^(?>(?:.*?,){3})([[:alpha:]]*?(?=,))", 
			"abc,def,ghi,klm"  # we left out comma
		)
	end
	def test_atomic_grouping5
		assert_regex(
			nil,
			"^(?>(?:.*?,){3})([[:alpha:]]*?(?=,))", 
			"abc,def,ghi,666,klm,nop,qrs"  # we don't give it alpha
		)
	end
end # module MatchAtomicGrouping

module PossessiveQuantifiers
	def test_possessive1
		assert_regex(nil, "\\d*+4", "x1234x")
	end
	def test_possessive2
		assert_regex(["1234"], "\\d*+", "x1234x",
			:oniguruma_output=>[""]  # See corresponding test in atomic group module
		)
	end
	def test_possessive3
		assert_regex(["123A"], "\\d*+A", "x123Ax")
	end
end # module PossessiveQuantifiers

module MatchEscape
	def test_escape_backslash1
		assert_regex(["b\\c"], "b\\\\c", "ab\\cd")
	end
	def test_escape_backslash2
		assert_regex(["bc"], "b\\\\*c", "abcd")
	end
	def test_escape_period1
		assert_regex(["b.c"], "b\\.c", "ab.cd")
	end
	def test_escape_period2
		assert_regex(["b.\\c"], "b\\..c", "ab.\\cd")
	end
	def test_escape_star1
		assert_regex(["b*c"], "b\\*c", "ab*cd")
	end
	def test_escape_star2
		assert_regex(["bc"], "b\\**c", "abcd")
	end
	def test_escape_star3
		assert_regex(["b*c"], "b\\**c", "ab*cd")
	end
	def test_escape_plus1
		assert_regex(["b+c"], "b\\+c", "ab+cd")
	end
	def test_escape_circumflex1
		assert_regex(["b^c"], "b\\^c", "ab^cd")
	end
	def test_escape_brackets1
		assert_regex(["[bc]"], "\\[.*\\]", "a[bc]d")
	end
	def test_escape_curleys1
		assert_regex(["{bc}"], "\\{.*\\}", "a{bc}d")
	end
	def test_escape_parantesis1
		assert_regex(["(bc)"], "\\(.*\\)", "a(bc)d")
	end
	def test_escape_hex1
		assert_regex(["b c"], 'b\x20c', "ab cd")
	end
	def test_escape_hex2
		assert_regex(nil, 'b\x020c', "ab cd")
	end
	def test_escape_hex3
		assert_regex(["b\0020c"], 'b\x020c', "ab\0020cd")
	end
	def test_escape_hex4
		assert_regex(nil, 'b\x0020c', "ab cd")
	end
	def test_escape_hex5
		assert_regex(["b\00020c"], 'b\x0020c', "ab\00020cd")
	end
	def test_escape_hex6
		assert_regex(["b\054"], 'b\x2c', "ab\054d")
	end
	def test_escape_hex6a
		assert_regex(["b\054"], 'b\x2C', "ab\054d")
	end
	def test_escape_hex7
		assert_regex(["b\002z"], 'b\x2z', "ab\002zd")
	end
	def test_escape_hex8
		assert_regex(["b\000z"], 'b\xz', "ab\000zd")
	end
	def test_escape_hex9
		assert_regex(nil, 'b\xz', "abxzd")
	end
	def test_escape_octal1
		assert_regex(["b c"], 'b\040c', "ab cd")
	end
	def test_escape_octal2
		assert_regex(["b\100c"], 'b\100c', "ab\100cd")
	end
	def test_escape_octal3
		assert_regex(["b\377c"], 'b\377c', "ab\377cd")
	end
	def test_escape_octal4
		assert_regex(["b\3777c"], 'b\3777c', "ab\3777cd")
	end
	def test_escape_octal5
		assert_regex(["b\3778c"], 'b\3778c', "ab\3778cd")
	end
	def test_escape_octal6
		assert_regex(["b\077c"], 'b\77c', "ab\077cd")
	end
	def test_escape_octal7
		# octal is apparently % 256
		assert_regex(["b\377c"], 'b\777c', "ab\377cd")
	end
	def test_escape_octal8
		assert_regex(["b\077" + "8c"], 'b\778c', "ab\077" + "8cd")
	end
	def test_escape_octal9
		assert_regex(["b\007c"], 'b\07c', "ab\007cd")
	end
	def test_escape_octal10
		# \1 .. \9 are backreferences
		# \0 is octal
		assert_regex(["b\000c"], 'b\0c', "ab\000cd")
	end
end # module MatchEscape

module MatchAdvancedRandom
	# exercise both alternation-stack and repeat-stacks
	def test_difficult1
		assert_regex(["abbxxc", "b", "xx"], "a(bx|b*)b(x*)c", "abbxxc")
	end
	def test_difficult2
		assert_regex(["abcdx", "d"], "a(b|c|d)*x", "0abcdx1")
	end
	def test_difficult3
		assert_regex([" moon is made of "], '\s.*\s', "The moon is made of cheese")
	end
	def test_difficult4
		assert_regex([" moon "], '\s.*?\s', "The moon is made of cheese")
	end
	def test_difficult5
		assert_regex(["oo"], '[aeiou]{2,99}', "The moon is made of cheese")
	end
	def test_difficult6
		assert_regex(
			[
				"http://hidden.neoneye.dk:8080/very/secret.html",
				"http", 
				"hidden.neoneye.dk", 
				":8080", 
				"/very/secret.html"
			],
			'(\w+):\/\/([^/:]+)(:\d*)?([^# ]*)', 
			"http://hidden.neoneye.dk:8080/very/secret.html"
		)
	end
	def test_difficult7
		# Rubicon, line #389
		assert_regex(
			[
				"d:usr/home/none/sub1/", 
				"none/"
			], 
			'([^/]*/)*sub1/', 
			"d:usr/home/none/sub1/sub2"
		)
	end
	def test_difficult8
		# Rubicon, line #678
		assert_regex(
			["effgz", "effgz", nil],
			'(bc+d$|ef*g.|h?i(j|k))',
			"reffgz"
		)
	end
end # module MatchAdvancedRandom

module MatchAdvancedIprange
	NUMBER_0_255 = "[01]?\\d\\d?|2[0-4]\\d|25[0-5]"
	IPRANGE = "^(?:#{NUMBER_0_255})$"
	def test_iprange_ok1
		assert_regex(["1"], IPRANGE, "1")
	end
	def test_iprange_ok2
		assert_regex(["01"], IPRANGE, "01")
	end
	def test_iprange_ok3
		assert_regex(["42"], IPRANGE, "42")
	end
	def test_iprange_ok4
		assert_regex(["042"], IPRANGE, "042")
	end
	def test_iprange_ok5
		assert_regex(["192"], IPRANGE, "192")
	end
	def test_iprange_ok6
		assert_regex(["255"], IPRANGE, "255")
	end
	def test_iprange_max1
		assert_regex(nil, IPRANGE, "256")
	end
	def test_iprange_max2
		assert_regex(nil, IPRANGE, "265")
	end
	def test_iprange_max3
		assert_regex(nil, IPRANGE, "355")
	end
	def test_iprange_max4
		# is 4 digits allowed in ipadresses?
		assert_regex(nil, IPRANGE, "0355")
	end
end # module MatchAdvancedIprange

module MatchAdvancedPalindrome
	PALINDROME =<<'EOPALIN'
(?x)(?i)\b
	(?:(\S)                (?:\s|\p)*
		(?:\S|(\S)         (?:\s|\p)*
			(?:\S|(\S)     (?:\s|\p)* 
				(?:\S|(\S) (?:\s|\p)* 
				\4)?       (?:\s|\p)* 
			\3)?           (?:\s|\p)*
		\2)?               (?:\s|\p)*
	\1)
\b
EOPALIN
	def test_palindrome_bad1
		# I don't consider words with length=1 being a palindrome
		assert_regex(nil, PALINDROME, "x")
	end
	def test_palindrome_bad2
		# string length is too long.
		assert_regex(nil, PALINDROME, "satan oscilate my metalic sonatas")
	end
	def test_palindrome_ok1
		assert_regex(["xX", "x", nil, nil, nil], PALINDROME, "09afAF xX 2")
	end
	def test_palindrome_ok2
		assert_regex(["666", "6", nil, nil, nil], PALINDROME, "-0.5 + 666 = 0.5 * 1331")
	end
	def test_palindrome_ok3
		assert_regex(["Abba", "A", "b", nil, nil], PALINDROME, "Money*3 by Abba is too commercial")
	end
	def test_palindrome_ok4
		assert_regex(["level", "l", "e", nil, nil], PALINDROME, "One level below the surface")
	end
	def test_palindrome_ok5
		assert_regex(["sub, BUS", "s", "u", "b", nil], PALINDROME, "sub, BUS")
	end
	def test_palindrome_ok6
		assert_regex(["a Toyota", "a", "T", "o", nil], PALINDROME, "Win a Toyota")
	end
end # module MatchAdvancedPalindrome

module MatchEncodingUTF8Codepoints
	def test_utf8_codepoint1
		# search for U+82 codepoint. The first \x82 you see in the input
		# is a part of another code-point, so it should be skipped.
		# The right-most multibyte sequence \xc2\x82 corresponds to U+82.
		assert_regex(["b\xc2\x82c"], 
			'.\x{82}.', 
			"a\xca\x82b\xc2\x82c",
			:encoding => :UTF8
		)
	end
	def test_utf8_codepoint2
		assert_regex(["a\xf3\x8e\x8e\x8ec"], '\w+', "%a\xf3\x8e\x8e\x8ec%", :encoding => :UTF8)
	end
	def test_utf8_codepoint3
		assert_regex(
			["\xc2\x81\xc4\x80"], 
			'[\x{81}-\x{100}]+', 
			"%a\xc2\x80" +  # less than U+81
			"\xc2\x81" +
			"\xc4\x80" + 
			"\xc4\x81b%",  # greater than U+100
			:encoding => :UTF8
		)
	end
	def test_utf8_codepoint4
		assert_regex(
			["\xc8\x80\xc8\x80"],
			'(?<=[\x{80}-\x{100}])\x{200}.', 
			"\xc3\x8f\xc3\x8f\xc8\x80\xc8\x80",
			:encoding => :UTF8
		)
	end
	def test_utf8_codepoint5
		assert_regex(
			["x\xe2\xbf\xbf9x%%", "x%%"], 
			'((?<=[\x{80}-\x{4000}].)x..)+', 
			"%%x\xc3\x8f9x\xe2\xbf\xbf9x%%x%%",
			:encoding => :UTF8
		)
	end
end # module MatchEncodingUTF8Codepoints

module MatchEncodingUTF8Malformed
	# Beware '\x{82}' is different from '\x82' 
	# The first is refering to codepoint U+82.
	# The last is refering to an malformed UTF-8 char
	# which only consists of one byte = 0x82.
	def test_utf8_hex1
		# search for U+82 codepoint. The first \x82 you see in the input
		# is a part of another code-point, so it should be skipped.
		# The right-most multibyte sequence \xc2\x82 corresponds to U+82.
		assert_regex(["b\xc2\x82c"], 
			'.\x82.',   # invalid continuation byte in regexp
			"a\xca\x82b\xc2\x82c",
			:encoding => :UTF8,
			:oniguruma_output=>nil  # maybe bug in oniguruma?
		)
	end
	def test_utf8_hex2
		# search for U+82 codepoint. The first \x82 you see in the input
		# is a part of another code-point, so it should be skipped.
		# The right-most multibyte sequence \xc2\x82 corresponds to U+82.
		assert_regex(["b\xc2\x82c"], 
			".\xc2\x82.",   # invalid continuation byte in regexp
			"a\xca\x82b\xc2\x82c",
			:encoding => :UTF8
		)
	end
	def test_utf8_hex3
		# search for U+82 codepoint. The first \x82 you see in the input
		# is a part of another code-point, so it should be skipped.
		# The right-most multibyte sequence \xc2\x82 corresponds to U+82.
		assert_regex(["b\xc2\x82c"], 
			".\xc2[\x81-\x83].",   # invalid continuation byte in regexp
			"a\xca\x82b\xc2\x82c",
			:encoding => :UTF8,
			:oniguruma_output=>nil  # maybe bug in oniguruma?
		)
	end
	def test_utf8_hex4
		assert_regex(["b\xc2\x82c"], 
			'.\xc2\x82.', 
			"a\xca\x82b\xc2\x82c",
			:encoding => :UTF8
		)
	end
	def test_utf8_codepoint_overlong1
		assert_regex(["b\xe0\xa0\xb4c"],
			'.\x{834}.', 
			"a" +
			"\xf0\x80\xa0\xb4" +  # this is overlong form of U+834
			"b" +
			"\xe0\xa0\xb4" +  # this is normal form of U+834
			"c",
			:encoding => :UTF8
		)
	end
	def test_utf8_malformed1
		# \xff and \xfe are both illegal UTF-8 codepoints
		assert_regex(["a"], '\w+', "%a\xffb\xfec%", :encoding => :UTF8,
			:oniguruma_output=>["a\xffb\xfec"]
		)
	end
	def test_utf8_malformed2
		# \xf3\x8e are an incomplete UTF-8 codepoint
		assert_regex(["a"], '\w+', "%a\xf3\x8ec%", :encoding => :UTF8,
			:oniguruma_output=>["a\xf3\x8ec%"]  # this looks like a bug to me
		)
	end
	def test_utf8_malformed3
		assert_regex(["b\xffc"], 
			'.\xff.',       # search for an invalid UTF-8 byte
			"a\xfeb\xffc",
			:encoding => :UTF8
		)
	end
	def test_utf8_malformed4
		assert_regex(["b\xf3\x8ec"], 
			'.\xf3\x8e.',   # search for an incomplete codepoint
			"a" + 
			"\xf3\x8e\x8e" +  # this is a valid codepoint.. so skip it
			"b" + 
			"\xf3\x8e" +   # this matches the incomplete codepoint we are looking fore
			"c",
			:encoding => :UTF8,
			:oniguruma_output=>["a\xf3\x8e\x8e"]  # this looks like a bug to me
		)
	end
	FIND_MALFORM_REGEXP = <<'EOM'
(?x) [\xc0-\xdf] (?![\x80-\xbf])
|    [\xe0-\xef] (?![\x80-\xbf]{2}) [\x80-\xbf]{0,1}
|    [\xf0-\xf7] (?![\x80-\xbf]{3}) [\x80-\xbf]{0,2}
|    [\xf8-\xfb] (?![\x80-\xbf]{4}) [\x80-\xbf]{0,3}
|    [\xfc-\xfd] (?![\x80-\xbf]{5}) [\x80-\xbf]{0,4}
|    [\xfe-\xff]
|    (?<![\xc0-\xfd]) [\x80-\xbf]
EOM
	def test_utf8_find_malform1
		assert_regex(["\xe5\x87"], 
			FIND_MALFORM_REGEXP,
			"ab\xe7\x83\x87cd\xe5\x87de",
			:encoding => :UTF8
		)
	end
end # module MatchEncodingUTF8Malformed

module MatchEncodingUTF16BECodepoints
	def test_utf16be_codepoint1
		assert_regex(["\xd9\x00\xdd\xdd\x00\x82\xda\xda\xdc\xdc"],
			'.\x{82}.', 
			"\x77\x77" +
			"\x90\x90" +
			"\xd9\x00\xdd\xdd" + # surrogate pair
			"\x00\x82" +
			"\xda\xda\xdc\xdc" + # surrogate pair
			"\xe0\xe0",
			:encoding => :UTF16BE
		)
	end
	def test_utf16be_codepoint2
		assert_regex(["\x30\x30\xda\x00\xde\x00\x90\x90"],
			'.\x{90200}.', 
			"\x77\x77" +
			"\x30\x30" +
			"\xda\x00\xde\x00" + # surrogate pair
			"\x90\x90" +
			"\xe0\xe0",
			:encoding => :UTF16BE
		)
	end
	def test_utf16be_codepoint3
		assert_regex(["\xff\xf0\xd8\x00\xdc\x00\xff\xfd\xd8\x00\xdc\x0f"],
			'[\x{fff0}-\x{1000f}]+', 
			"\x77\x77" +
			"\xff\xf0" +
			"\xd8\x00\xdc\x00" + # surrogate pair
			"\xff\xfd" +
			"\xd8\x00\xdc\x0f" + # surrogate pair
			"\xe0\xe0",
			:encoding => :UTF16BE
		)
	end
end # module MatchEncodingUTF16BECodepoints

module MatchEncodingUTF16LECodepoints
	def test_utf16le_codepoint1
		assert_regex(["\x00\xd9\xdd\xdd\x82\x00\xda\xda\xdc\xdc"],
			'.\x{82}.', 
			"\x77\x77" +
			"\x90\x90" +
			"\x00\xd9\xdd\xdd" + # surrogate pair
			"\x82\x00" +
			"\xda\xda\xdc\xdc" + # surrogate pair
			"\xe0\xe0",
			:encoding => :UTF16LE
		)
	end
	def test_utf16le_codepoint2
		assert_regex(["\x30\x30\x00\xda\x00\xde\x90\x90"],
			'.\x{90200}.', 
			"\x77\x77" +
			"\x30\x30" +
			"\x00\xda\x00\xde" + # surrogate pair
			"\x90\x90" +
			"\xe0\xe0",
			:encoding => :UTF16LE
		)
	end
	def test_utf16le_codepoint3
		assert_regex(["\xf0\xff\x00\xd8\x00\xdc\xfd\xff\x00\xd8\x0f\xdc"],
			'[\x{fff0}-\x{1000f}]+', 
			"\x77\x77" +
			"\xf0\xff" +
			"\x00\xd8\x00\xdc" + # surrogate pair
			"\xfd\xff" +
			"\x00\xd8\x0f\xdc" + # surrogate pair
			"\xe0\xe0",
			:encoding => :UTF16LE
		)
	end
end # module MatchEncodingUTF16LECodepoints

module MatchGlobalSubstitute
	def test_gsub_normal1
		assert_gsub('xzxzx', 'z', 'xzxzx', 'z')
	end
	def test_gsub_normal2
		assert_gsub('xRubyxRubyx', 'Perl|Python', 'xPerlxPerlx', 'Ruby')
	end
	def test_gsub_captures1
		assert_gsub('1xzabab1xzab1xzxzab1', '((?:ab)+)((?:xz)+)', '1ababxz1abxz1abxzxz1', %q|\2\1|)
	end
	def test_gsub_captures2
		assert_gsub('1RxRxRx1', 'x(((((((((.)))))))))', '1xRxRxR1', %q|\9x|)
	end
	def test_gsub_captures3
		# capture 10 cannot be access in the replacement string
		assert_gsub('1x0xx0xx0x1', '(x)(((((((((.)))))))))', '1xRxRxR1', %q|\10\1|)
	end
	def test_gsub_captures4
		# capture 2 doesn't exist.. but yields nil
		assert_gsub('1<R><R><R>1', 'x(.)', '1xRxRxR1', %q|<\2\1>|)
	end
	def test_gsub_ampersand1
		assert_gsub('1<xR-xR><xR-xR><xR-xR>1', 'x(.)', '1xRxRxR1', %q|<\&-\&>|)
	end
	def test_gsub_prematch1
		assert_gsub('1<1><1xR><1xRxR>1', 'x(.)', '1xRxRxR1', %q|<\`>|)
	end
	def test_gsub_postmatch1
		assert_gsub('1<xRxR1><xR1><1>1', 'x(.)', '1xRxRxR1', %q|<\'>|)
	end
	def test_gsub_lastmatch1
		assert_gsub('1<a>1<b>1', 'x(.)(.)(.(.))', '1x___a1x___b1', %q|<\+>|)
	end
	def test_gsub_no_hex_escaping1
		assert_gsub('1<\x20>1<\x20>1', 'x.*?(?:a|b)', '1x___a1x___b1', %q|<\x20>|)
	end
	def test_gsub_block1
		assert_gsub('1ax1bx1', '\D+', '1xa1xb1') {|m| m[0].reverse }
	end
	def test_gsub_block2
		assert_gsub('11-314-61', '\D+', '1xa1xb1') {|m| "#{m.begin(0)}-#{m.end(0)}" }
	end
	def test_gsub_block3
		assert_gsub('1\+\&1\+\&1', '\D+', '1xa1xb1') {|m| %q|\+\&| }
	end
end # module MatchGlobalSubstitute

module MatchSplit
	def test_split_normal1minus
		assert_split(%w(a c), 'b', -1, 'abc')
	end
	def test_split_normal0
		assert_split(%w(a c), 'b', 0, 'abc')
	end
	def test_split_normal1
		assert_split(%w(1ab2cd3), '\D+', 1, '1ab2cd3')
	end
	def test_split_normal2
		assert_split(%w(1 2cd3), '\D+', 2, '1ab2cd3')
	end
	def test_split_normal3
		assert_split(%w(1 2 3), '\D+', 3, '1ab2cd3')
	end
	def test_split_normal4
		assert_split(%w(1 2 3), '\D+', nil, '1ab2cd3')
	end
	def test_split_normal5
		assert_split(%w(1 2), '\D+', nil, '1ab2cd')
	end
	def test_split_normal6
		assert_split([''] + %w(2 3), '\D+', nil, 'ab2cd3')
	end
	def test_split_normal7
		assert_split(["", "", "e"], '.{2}', nil, 'abcde')
	end
	def test_split_normal8
		assert_split(%w(a c), 'b', nil, 'abc')
	end
	def test_split_wipe1
		assert_split([], '.', nil, 'abc')
	end
	def test_split_wipe2
		assert_split([], '..', nil, 'abcd')
	end
	def test_split_wipe3
		assert_split(%w(a), '\B..', nil, 'abcde')
	end
	def test_split_no_wipe1
		# ary.last == empty-string, because of limit
		assert_split(['', '', '', ''], '.', 10, 'abc')
	end
	def test_split_no_wipe2
		# ary.last == empty-string, because of limit
		assert_split(['', '', ''], '..', 10, 'abcd')
	end
	def test_split_no_wipe3
		# ary.last == empty-string, because of limit
		assert_split(['', 'a', '', 'b', '', 'c', ''], '(.)', 10, 'abc')
	end
	def test_split_no_wipe4
		# ary.last == empty-string, because of limit
		assert_split(['', 'a', 'b', '', 'c', 'd', ''], '(.)(.)', 10, 'abcd')
	end
	def test_split_no_wipe5
		# no limit == no extra empty-string
		assert_split(['', 'a', '', 'b', '', 'c'], '(.)', nil, 'abc')
	end
	def test_split_no_wipe6
		# no limit == no extra empty-string
		assert_split(['', 'a', 'b', '', 'c', 'd'], '(.)(.)', nil, 'abcd')
	end
	def test_split_mismatch1
		assert_split(%w(1ab2cd3), 'z+', nil, '1ab2cd3')
	end
	def test_split_mismatch2
		assert_split(%w(1ab2cd3), 'z+', 2, '1ab2cd3')
	end
	def test_split_capture1
		assert_split(%w(1 ab 2 cd 3), '(\D+)', nil, '1ab2cd3')
	end
	def test_split_capture2
		assert_split(%w(1 ab 2cd3), '(\D+)', 2, '1ab2cd3')
	end
	def test_split_capture3
		assert_split(%w(1 ab b 2cd3), '((\D)+)', 2, '1ab2cd3')
	end
	def test_split_capture4
		assert_split([''] + %w(ab b 2cd3), '((\D)+)', 2, 'ab2cd3')
	end
	def test_split_capture5
		assert_split([''] + %w(a b 2cd3), '(\D)(\D)', 2, 'ab2cd3')
	end
end # module MatchSplit

module MatchScan
	def test_scan_normal1
		assert_scan(%w(ab cd), '\D+', '1ab2cd3')
	end
	def test_scan_normal2
		assert_scan(%w(a c), '[ac]', 'abc')
	end
	def test_scan_capture1
		assert_scan([%w(ab), %w(cd)], '(\D+)', '1ab2cd3')
	end
	def test_scan_capture2
		assert_scan([%w(ab b), %w(cd d)], '((\D)+)', '1ab2cd3')
	end
	def test_scan_capture3
		assert_scan([%w(a b), %w(c d)], '(\D)(\D)', '1ab2cd3')
	end
	def test_scan_mismatch1
		assert_scan([], 'z+', '1ab2cd3')
	end
	def test_scan_block1
		ary = []
		assert_scan('1ab2cd3', '\D+', '1ab2cd3') {|m| ary << m[0].reverse}
		assert_equal(%w(ba dc), ary)
	end
	def test_scan_block2
		ary = []
		assert_scan('1ab2cd3', 'z+', '1ab2cd3') {|m| ary << m[0].reverse}
		assert_equal([], ary)
	end
end # module MatchScan

module MatchLongScan
	def test_scan_long1
 		re = '([A-Z].+?(?<!([Mr|e\.g]))[.!?])'
		text = 'lorem ipsum' * 200
		a = 'ABCxyz.'
		b = 'ABCxyz!'
		c = 'ABCxyz?'
		text.insert(100, a)
		text.insert(600, b)
		text.insert(2100, c)                                 

		# TODO: the empty strings should NOT be present in this result
		assert_scan([[a, ''], [b, ''], [c, '']], re, text)

		# TODO: instead the result is supposed to be as the following
		#assert_scan([[a], [b], [c]], re, text)
	end
	def test_scan_long2
		re = '([A-Z].+?(?<!([Mr|e\.g]))[.!?])'
   		text = 'lorem ipsum' * 200
		a = 'ABC|!'
		text.insert(10, a)

		assert_scan([], re, text)
	end
end # 	module MatchLongScan
