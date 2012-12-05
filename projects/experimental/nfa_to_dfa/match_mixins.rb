# purpose:
# mixin's which exercises different aspects in the regex engine.

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
	def test_repeat1
		assert_regex(["a1b2b", "1b2", "2"], "a((.)*)b", "0a1b2b3")
	end
	def test_repeat2
		assert_regex(["a1b2c3c", "2c3"], "a.*b(.*)c", "0a1b2c3c4")
	end
	def test_repeat3
		assert_regex(["<a>1<b>"], "<.*>", "0<a>1<b>2") 
	end
	def test_repeat4
		# on EndOfInput we must restart
		assert_regex(["a1b2c3b4c", "1b2c3"], "a(.*)b.*c", "0a1b2c3b4c5")
	end
	def test_repeat5
		# match zero times
		assert_regex(["abc"], "ab*bc", "xabcz")
	end
	def test_repeat6
		assert_regex(nil, "ab*bc", "xacz")
	end
	def test_repeat7
		# This paticular case is very interesting because it
		# exercises the bailout mechanism, and the
		# cancelation of result mechanism.
		# 'x' REP _______________________ 'x' END
		#     GRP REP ___________ /GR nil
		#         GRP ANY /GR nil
		assert_regex(["x1x2x", "1x2", "2"], "x((.)*)*x", "0x1x2x3")
	end
	def test_repeat8 
		# 'x' REP ___________________________________________ 'x' END
		#     GRP GRP REP ___________ /GR 'x' REP ___ /GR nil
		#             GRP ANY /GR nil         ANY nil
		assert_regex(["x1x2x3x", "1x2x3", "1x2", "2"], "x(((.)*)x.*)*x", "0x1x2x3x4")
	end
end # module MatchRepeat

module MatchRepeat2
	def test_repeat_plus1
		# notice that register#2 doesn't get cleared,
		# it must contain the last matched value.
		assert_regex(["ababxx", "x", "ab"], "((ab)*x)+", "0ababxx1", true)
	end
end # module MatchRepeat2


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

module MatchDifficult
	# exercise both alternation-stack and repeat-stacks
	def test_repeat_alternation1
		assert_regex(["abbxxc", "b", "xx"], "a(bx|b*)b(x*)c", "abbxxc")
	end
	def test_repeat_alternation2
		assert_regex(["abcdx", "d"], "a(b|c|d)*x", "0abcdx1")
	end
end # module MatchDifficult

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
	def test_pure_group1
		# the \1 backref should point at 'x'
		assert_regex(["bxcdx", "x"], '(?:b)(x).*\1', "abxcdxe")
	end
	def test_pure_group2
		# the \1 backref does NOT point at 'b'
		assert_regex(nil, '(?:b)(x).*\1', "abxcdbe")
	end
end # module MatchBackref

module MatchMeta
	def test_meta_begin1
		assert_regex(["ab"], "^ab", "a\nabcd")
	end
	def test_meta_begin2
		assert_regex(nil, "^ab", "a\nxabcd")
	end
	def test_meta_end1
		assert_regex(["cd"], "cd$", "a\nbcd\ne")
	end
	def test_meta_end2
		assert_regex(nil, "cd$", "a\nbcdx\ne")
	end
end # module MatchMeta
