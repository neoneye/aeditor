require 'common'

class TestParser < Common::TestCase
	include RegexFactory
	def compile(regex)
		ast = Parser.compile(regex)
		ast.accept(AssignRegistersVisitor.new)
		ast
	end
	def assert_parser(expected, regexp)
		ast = compile(regexp)
		assert_equal(expected, ast)
	end
	def test_sequence_any1
		exp = mk_sequence(mk_letter('a'), mk_wild, mk_letter('b'))
		assert_parser(exp, 'a.b')
	end
	def test_sequence_group1
		grp = mk_group(mk_repeat(mk_wild, 0, -1))
		exp = mk_sequence(mk_letter('a'), grp, mk_letter('b'))
		assert_parser(exp, 'a(.*)b')
	end
	def test_repeat_normal1
		rep = mk_repeat(mk_wild, 0, -1)
		exp = mk_sequence(mk_letter('a'), rep, mk_letter('b'))
		assert_parser(exp, 'a.*b')
	end
	def test_repeat_normal2
		rep = mk_repeat(mk_wild, 1, -1)
		exp = mk_sequence(mk_letter('a'), rep, mk_letter('b'))
		assert_parser(exp, 'a.+b')
	end
	def test_repeat_range1
		rep = mk_repeat(mk_wild, 22, 55)
		exp = mk_sequence(mk_letter('a'), rep, mk_letter('b'))
		assert_parser(exp, 'a.{22,55}b')
	end
	def test_repeat_range2
		rep = mk_repeat(mk_wild, 4, 4, true)
		exp = mk_sequence(mk_letter('a'), rep, mk_letter('b'))
		assert_parser(exp, 'a.{4}?b')
	end
	def test_repeat_range3
		rep = mk_repeat(mk_wild, 4, -1)
		exp = mk_sequence(mk_letter('a'), rep, mk_letter('b'))
		assert_parser(exp, 'a.{4,}b')
	end
	def test_repeat_range4
		rep = mk_repeat(mk_wild, 4, -1, true)
		exp = mk_sequence(mk_letter('a'), rep, mk_letter('b'))
		assert_parser(exp, 'a.{4,}?b')
	end
	def test_repeat_range5
		rep = mk_repeat(mk_wild, 0, 1)
		exp = mk_sequence(mk_letter('a'), rep, mk_letter('b'))
		assert_parser(exp, 'a.?b')
	end
	def test_repeat_range_legal1
		# Apparently these constructions are perfectly legal
		input = [
			"a{3",        # premature end of input
			"a{,}b",      # neither min or max specified
			"a{,3}b",     # min expected, but got none
			"a{43x3}b",   # either ',' or '}' expected, got 'x'
			"a{43,333",   # premature end of input
			"a{43,333x",  # expected '}', got 'x'
		]
		res = input.map{|str| 
			ok = false
			begin
				compile(str) 
				ok = true
			rescue RuntimeError
			end
			ok
		}
		assert_equal([true] * input.size, res)
	end
	def test_repeat_range_illegal1
		input = [
			"a{999,666}"  # expected (min <= max), got (min > max)
		]
		res = input.map{|str| 
			ok = false
			begin
				compile(str) 
			rescue RuntimeError
				ok = true
			end
			ok
		}
		assert_equal([true] * input.size, res)
	end
	def test_repeat_illegal1
		input = [
			"*a",       # nothing to repeat
			"+a",       # nothing to repeat 
			#"?a",      # nothing to repeat 
			"a(*)b",    # nothing to repeat 
			"x|*",      # nothing to repeat 
		]
		res = input.map{|str| 
			ok = false
			begin
				compile(str) 
			rescue CannotRepeat
				ok = true
			end
			ok
		}
		assert_equal([true] * input.size, res)
	end
	def test_repeat_group1
		seq = mk_sequence(mk_letter('a'), mk_letter('b'))
		exp = mk_sequence(mk_repeat(mk_group(seq), 0, -1), mk_letter('a'))
		assert_parser(exp, '(ab)*a')
	end
	def test_repeat_lazy1
		rep = mk_repeat(mk_wild, 0, -1, true)
		exp = mk_sequence(mk_letter('a'), rep, mk_letter('b'))
		assert_parser(exp, 'a.*?b')
	end
	def test_group_missing_open_parentesis1
		assert_raises(RuntimeError) { compile(")") }
	end
	def test_group_missing_close_parentesis1
		assert_raises(RuntimeError) { compile("(") }
	end
	def test_alternation_normal1
		exp = mk_alternation(mk_letter('a'), mk_letter('b'))
		assert_parser(exp, 'a|b')
	end
	def test_alternation_normal2
		seq1 = mk_sequence(mk_letter('a'), mk_letter('b'))
		seq2 = mk_sequence(mk_letter('c'), mk_letter('d'))
		exp = mk_alternation(seq1, seq2)
		assert_parser(exp, 'ab|cd')
	end
	def test_alternation_group1
		alt = mk_alternation(mk_letter('x'), mk_letter('y'))
		exp = mk_sequence(mk_letter('a'), mk_group(alt), mk_letter('b'))
		assert_parser(exp, 'a(x|y)b')
	end
	def test_alternation_group2
		exp = mk_alternation(
			mk_letter('a'), 
			mk_letter('b'), 
			mk_sequence(mk_letter('x'), mk_letter('c')),
			mk_letter('d')
		)
		assert_parser(exp, 'a|b|xc|d')
	end
	def test_alternation_group_nested1
		alt1 = mk_alternation(mk_letter('x'), mk_letter('y'))
		seq1 = mk_sequence(mk_letter('b'), mk_group(alt1), mk_letter('c'))
		alt2 = mk_alternation(mk_letter('a'), seq1, mk_letter('d'))
		exp = mk_sequence(mk_letter('0'), mk_group(alt2), mk_letter('1'))
		assert_parser(exp, '0(a|b(x|y)c|d)1')
	end
	def test_escape_backref1
		grp = mk_group(mk_alternation(mk_letter('X'), mk_letter('Y')))
		exp = mk_sequence(grp, mk_repeat(mk_wild, 0, -1), mk_backref(1))
		assert_parser(exp, '(X|Y).*\1')
	end
	def test_escape_repeat1
		exp = mk_sequence(mk_letter("a"), mk_letter('*'), mk_letter("b"))
		assert_parser(exp, 'a\*b') 
	end
	def test_escape_any1
		exp = mk_sequence(mk_letter("a"), mk_letter('.'), mk_letter("b"))
		assert_parser(exp, 'a\.b') 
	end
	def test_escape_slash1
		exp = mk_sequence(mk_letter("a"), mk_letter('\\'), mk_letter("b"))
		assert_parser(exp, 'a\\\\b') 
	end
	def test_escape_illegal1
		assert_raises(RuntimeError) { compile('ab\\') }
	end
	def test_character_class1
		exp = mk_sequence(mk_letter('a'), mk_charclass(['f', 'g', 'h']), mk_letter('b'))
		assert_parser(exp, 'a[fgh]b') 
	end
	def test_character_class2
		exp = mk_sequence(mk_letter('a'), mk_charclass(['c'..'m']), mk_letter('b'))
		assert_parser(exp, 'a[c-m]b') 
	end
	def test_character_class3
		exp = mk_sequence(
			mk_letter('a'), 
			mk_charclass(['a', 'e', 'A'..'Z', 'i', 'o', '0'..'9', 'u', 'y']), 
			mk_letter('b')
		)
		assert_parser(exp, 'a[aeA-Zio0-9uy]b') 
	end
	def test_character_class4
		exp = mk_sequence(mk_letter('a'), mk_charclass_inverse(['c'..'m']), mk_letter('b'))
		assert_parser(exp, 'a[^c-m]b') 
	end
	def test_character_class5
		exp = mk_sequence(mk_charclass(['0'..'9']), mk_letter('b'))
		assert_parser(exp, '[[:digit:]]b') 
	end
	def test_character_class6
		exp = mk_sequence(mk_charclass(['0'..'9', '2'..'9']), mk_letter('b'))
		assert_parser(exp, '[[:digit:]2-9]b') 
	end
	def test_abbreviated_character_class1
		exp = mk_sequence(mk_charclass(['0'..'9']), mk_letter('b'))
		assert_parser(exp, '\db') 
	end
	def test_abbreviated_character_class2
		exp = mk_sequence(mk_charclass_inverse(['0'..'9']), mk_letter('b'))
		assert_parser(exp, '\Db') 
	end
	def test_anchors1
		exp = mk_sequence(mk_anchor_begin, mk_letter('b'))
		assert_parser(exp, '^b') 
	end
	def test_anchors2
		exp = mk_sequence(mk_letter('b'), mk_anchor_end)
		assert_parser(exp, 'b$') 
	end
	def test_anchors3
		exp = mk_sequence(mk_anchor_string_begin, mk_letter('b'), mk_anchor_string_end)
		assert_parser(exp, '\Ab\z')
	end
	def test_anchors4
		exp = mk_sequence(mk_anchor_word_boundary, mk_letter('b'), mk_anchor_nonword_boundary)
		assert_parser(exp, '\bb\B') 
	end
	def test_group_lookahead1
		seq = mk_sequence(mk_letter('x'), mk_letter('y'))
		exp = mk_sequence(mk_letter('a'), mk_lookahead(seq))
		assert_parser(exp, 'a(?=xy)') 
	end
	def test_group_lookahead2
		seq = mk_sequence(mk_letter('x'), mk_letter('y'))
		exp = mk_sequence(mk_letter('a'), mk_lookahead_negative(seq))
		assert_parser(exp, 'a(?!xy)') 
	end
	def test_group_lookbehind1
		seq = mk_sequence(mk_letter('x'), mk_letter('y'))
		exp = mk_sequence(mk_letter('a'), mk_lookbehind(seq))
		assert_parser(exp, 'a(?<=xy)') 
	end
	def test_group_lookbehind2
		seq = mk_sequence(mk_letter('x'), mk_letter('y'))
		exp = mk_sequence(mk_letter('a'), mk_lookbehind_negative(seq))
		assert_parser(exp, 'a(?<!xy)') 
	end
	def test_group_pure1
		seq = mk_sequence(mk_letter('x'), mk_letter('y'))
		exp = mk_sequence(mk_letter('a'), mk_group_pure(seq))
		assert_parser(exp, 'a(?:xy)') 
	end   
	def test_repeat_nested1
		repa = mk_repeat(mk_letter('a'), 0, -1)
		grp = mk_group(mk_group(repa))
		exp = mk_repeat(grp, 0, -1)
		assert_parser(exp, '((a*))*') 
	end    
	def test_repeat_nested2
		repa = mk_repeat(mk_group(mk_letter('a')), 0, -1)
		repb = mk_repeat(mk_group(mk_letter('b')), 0, -1)
		exp = mk_repeat(mk_group(mk_sequence(repa, repb)), 0, -1)
		assert_parser(exp, '((a)*(b)*)*') 
	end              
	def test_repeat_nested3
		grp1 = mk_group(mk_repeat(mk_letter('a'), 0, -1))
		grp2 = mk_group(mk_repeat(grp1, 0, -1))
		exp = mk_repeat(grp2, 0, -1)
		assert_parser(exp, '((a*)*)*')
	end                 
	def test_repeat_alternation1
		repa = mk_repeat(mk_letter('a'), 0, -1)
		repb = mk_repeat(mk_letter('b'), 0, -1)
		repc = mk_repeat(mk_letter('c'), 0, -1)
		alt = mk_group(mk_alternation(repa, repb, repc))
		exp = mk_sequence(mk_repeat(alt, 0, -1), mk_letter('d'))
		assert_parser(exp, '(a*|b*|c*)*d') 
	end                 
	def test_widehex1
		exp = mk_sequence(mk_letter('a'), mk_wide(0x9abc), mk_letter('b'))
		assert_parser(exp, 'a\x{9aBc}b') 
	end                 
	def test_widehex2
		exp = mk_charclass2([0x5ee..0xdad, 0xbabe])
		assert_parser(exp, '[\x{5EE}-\x{dad}\x{babe}]') 
	end                 
	def xtest_parse_UTF8_encoded_regexp1
		exp = mk_sequence(
			mk_repeat(mk_letter(0x5000), 0, -1), 
			mk_letter(0x7000), 
			mk_anchor_end
		)
		regexp = [0x5000, '*'[0], 0x7000, '$'[0]].pack('U*')
		assert_parser(exp, regexp) 
	end                 
end

TestParser.run if $0 == __FILE__
