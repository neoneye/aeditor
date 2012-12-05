require 'test/unit'
require 'common'
require 'regexp/perl6parser'

class XTestPerl6Parser < Test::Unit::TestCase
	include RegexFactory
	def compile(regex)
		Perl6Parser.new(regex.split(//)).expression
	end
	def test_sequence_any1
		exp = mk_sequence(mk_letter('a'), mk_wild, mk_letter('b'))
		i = compile("a.b")
		assert_equal(exp, i)
	end
	def test_sequence_group1
		grp = mk_group(mk_repeat(mk_wild, 0, -1))
		exp = mk_sequence(mk_letter('a'), grp, mk_letter('b'))
		i = compile("a(.*)b")
		assert_equal(exp, i)
	end
	def test_repeat_normal1
		rep = mk_repeat(mk_wild, 0, -1)
		exp = mk_sequence(mk_letter('a'), rep, mk_letter('b'))
		i = compile("a.*b")
		assert_equal(exp, i)
	end
	def test_repeat_normal2
		rep = mk_repeat(mk_wild, 1, -1)
		exp = mk_sequence(mk_letter('a'), rep, mk_letter('b'))
		i = compile("a.+b")
		assert_equal(exp, i)
	end
	def test_repeat_range1
		rep = mk_repeat(mk_wild, 22, 55)
		exp = mk_sequence(mk_letter('a'), rep, mk_letter('b'))
		i = compile("a.<22,55>b")
		assert_equal(exp, i)
	end
	def test_repeat_range2
		rep = mk_repeat(mk_wild, 4, 4, true)
		exp = mk_sequence(mk_letter('a'), rep, mk_letter('b'))
		i = compile("a.<4>?b")
		assert_equal(exp, i)
	end
	def test_repeat_range3
		rep = mk_repeat(mk_wild, 4, -1)
		exp = mk_sequence(mk_letter('a'), rep, mk_letter('b'))
		i = compile("a.<4,>b")
		assert_equal(exp, i)
	end
	def test_repeat_range4
		rep = mk_repeat(mk_wild, 4, -1, true)
		exp = mk_sequence(mk_letter('a'), rep, mk_letter('b'))
		i = compile("a.<4,>?b")
		assert_equal(exp, i)
	end
	def test_repeat_range5
		rep = mk_repeat(mk_wild, 0, 1)
		exp = mk_sequence(mk_letter('a'), rep, mk_letter('b'))
		i = compile("a.?b")
		assert_equal(exp, i)
	end
        def test_negative_repeat_range1
		rep = mk_repeat(mk_letter('x'), 5, -1)
		exp = mk_sequence(mk_letter('a'), rep, mk_letter('b'))
		i = compile("ax<!0,4>b")
		assert_equal(exp, i)
        end
        def test_negative_repeat_range2
		rep = mk_alternation(mk_repeat(mk_letter('x'), 0, 2),mk_repeat(mk_letter('x'), 5, -1))
		exp = mk_sequence(mk_letter('a'), rep, mk_letter('b'))
		i = compile("ax<!3,4>b")
		assert_equal(exp, i)
        end
	def test_repeat_range_illegal1
		input = [
			"a<999,666>"  # expected (min <= max), got (min > max)
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
	def test_repeat_group1
		seq = mk_sequence(mk_letter('a'), mk_letter('b'))
		exp = mk_sequence(mk_repeat(mk_group(seq), 0, -1), mk_letter('a'))
		i = compile("(ab)*a")
		assert_equal(exp, i)
	end
	def test_repeat_lazy1
		rep = mk_repeat(mk_wild, 0, -1, true)
		exp = mk_sequence(mk_letter('a'), rep, mk_letter('b'))
		i = compile("a.*?b")
		assert_equal(exp, i)
	end
	def test_group_missing_open_parentesis1
		assert_raises(RuntimeError) { compile(")") }
	end
	def test_group_missing_close_parentesis1
		assert_raises(RuntimeError) { compile("(") }
	end
	def test_alternation_normal1
		exp = mk_alternation(mk_letter('a'), mk_letter('b'))
		i = compile("a|b")
		assert_equal(exp, i)
	end
	def test_alternation_normal2
		seq1 = mk_sequence(mk_letter('a'), mk_letter('b'))
		seq2 = mk_sequence(mk_letter('c'), mk_letter('d'))
		exp = mk_alternation(seq1, seq2)
		i = compile("ab|cd")
		assert_equal(exp, i)
	end
	def test_alternation_group1
		alt = mk_alternation(mk_letter('x'), mk_letter('y'))
		exp = mk_sequence(mk_letter('a'), mk_group(alt), mk_letter('b'))
		i = compile("a(x|y)b")
		assert_equal(exp, i)
	end
	def test_alternation_group_nested1
		alt1 = mk_alternation(mk_letter('x'), mk_letter('y'))
		seq1 = mk_sequence(mk_letter('b'), mk_group(alt1), mk_letter('c'))
		alt2 = mk_alternation(mk_letter('a'), seq1, mk_letter('d'))
		exp = mk_sequence(mk_letter('0'), mk_group(alt2), mk_letter('1'))
		i = compile("0(a|b(x|y)c|d)1")
		assert_equal(exp, i)
	end
	def test_escape_backref1
		grp = mk_group(mk_alternation(mk_letter('X'), mk_letter('Y')))
		exp = mk_sequence(grp, mk_repeat(mk_wild, 0, -1), mk_backref(1))
		i = compile('(X|Y).*\1')
		assert_equal(exp, i)
	end
	def test_escape_repeat1
		exp = mk_sequence(mk_letter("a"), mk_letter('*'), mk_letter("b"))
		i = compile('a\*b')
		assert_equal(exp, i)
	end
	def test_escape_any1
		exp = mk_sequence(mk_letter("a"), mk_letter('.'), mk_letter("b"))
		i = compile('a\.b')
		assert_equal(exp, i)
	end
	def test_escape_slash1
		exp = mk_sequence(mk_letter("a"), mk_letter('\\'), mk_letter("b"))
		i = compile('a\\\\b')
		assert_equal(exp, i)
	end
	def test_escape_illegal1
		assert_raises(RuntimeError) { compile('ab\\') }
	end

	def test_character_class1
		exp = mk_sequence(mk_letter('a'), mk_charclass(['f', 'g', 'h']), mk_letter('b'))
		i = compile("a<[fgh]>b")
		assert_equal(exp, i)
	end
	def test_character_class2
		exp = mk_sequence(mk_letter('a'), mk_charclass(['c'..'m']), mk_letter('b'))
		i = compile("a<[c-m]>b")
		assert_equal(exp, i)
	end
	def test_character_class3
		exp = mk_sequence(
			mk_letter('a'), 
			mk_charclass(['a', 'e', 'A'..'Z', 'i', 'o', '0'..'9', 'u', 'y']), 
			mk_letter('b')
		)
		i = compile("a<[aeA-Zio0-9uy]>b")
		assert_equal(exp, i)
	end
	def test_character_class4
		exp = mk_sequence(mk_letter('a'), mk_charclass_inverse(['c'..'m']), mk_letter('b'))
		i = compile("a<-[c-m]>b")
		assert_equal(exp, i)
	end
	def test_character_class5
		exp = mk_sequence(mk_charclass(['0'..'9']), mk_letter('b'))
		i = compile("<digit>b")
		assert_equal(exp, i)
	end
	def xtest_character_class6
		exp = mk_sequence(mk_charclass(['0'..'9', '2'..'9']), mk_letter('b'))
		i = compile("<<digit> [2-9]>b")
		assert_equal(exp, i)
	end
	def test_abbreviated_character_class1
		exp = mk_sequence(mk_charclass(['0'..'9']), mk_letter('b'))
		i = compile('\db')
		assert_equal(exp, i)
	end
	def test_abbreviated_character_class2
		exp = mk_sequence(mk_charclass_inverse(['0'..'9']), mk_letter('b'))
		i = compile('\Db')
		assert_equal(exp, i)
	end
	def test_anchors1
		exp = mk_sequence(mk_anchor_begin, mk_letter('b'))
		i = compile('^b')
		assert_equal(exp, i)
	end
	def test_anchors2
		exp = mk_sequence(mk_letter('b'), mk_anchor_end)
		i = compile('b$')
		assert_equal(exp, i)
	end
	def test_anchors3
		exp = mk_sequence(mk_anchor_string_begin, mk_letter('b'), mk_anchor_string_end)
		i = compile('\Ab\z')
		assert_equal(exp, i)
	end
	def test_anchors4
		exp = mk_sequence(mk_anchor_word_boundary, mk_letter('b'), mk_anchor_nonword_boundary)
		i = compile('\bb\B')
		assert_equal(exp, i)
	end
	def test_group_pure1
		seq = mk_sequence(mk_letter('x'), mk_letter('y'))
		exp = mk_sequence(mk_letter('a'), mk_group_pure(seq))
		i = compile("a[xy]")
		assert_equal(exp, i)
	end
        def test_mismatched_brackets1
                assert_raises(RuntimeError) { compile("a[bc)d") }
        end
        def test_mismatched_brackets2
                assert_raises(RuntimeError) { compile("a(bc]d")}
        end
        def test_nested_group1
		seq = mk_sequence(mk_letter('c'), mk_letter('d'))
		exp = mk_group(mk_sequence(mk_letter('a'), mk_letter('b'), mk_group(seq), mk_letter('e'), mk_letter('f')))
                i = compile("(ab(cd)ef)")
                assert_equal(exp, i)
        end
        def test_nested_group2
		seq = mk_sequence(mk_letter('c'), mk_letter('d'))
		exp = mk_group(mk_sequence(mk_letter('a'), mk_letter('b'), mk_group_pure(seq), mk_letter('e'), mk_letter('f')))
                i = compile("(ab[cd]ef)")
                assert_equal(exp, i)
        end
        def test_code_assertion
                assertion = mk_code_assertion("$1 < 256")
                exp = mk_sequence(mk_group(mk_repeat(mk_charclass(['0'..'9']), 0, 3)), assertion)
                i = compile("(<digit><0,3>)<($1 < 256)>")
                assert_equal(exp, i)
        end                                            

        #debug :test_code_assertion
end


if $0 == __FILE__
	require 'test/unit/ui/console/testrunner'
	Test::Unit::UI::Console::TestRunner.run(XTestPerl6Parser)
end
