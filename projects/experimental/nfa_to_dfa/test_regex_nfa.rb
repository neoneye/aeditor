require 'test/unit'
require 'abstract_syntax'

class XTestRegexNfa < Test::Unit::TestCase
	include RegexFactory
	def sym(*symbol)
		Match::Include.new(*symbol)
	end
	def sym_neg(*symbol)
		Match::Exclude.new(*symbol)
	end
	def test_one_letter
		nfa = mk_letter('a').nfa_hash
		exp = {0=>[[sym('a'), 1000]], 1000=>[]}
		assert_equal(exp, nfa)
	end
	def test_sequence
		a = mk_letter('a')
		b = mk_letter('b')
		nfa = mk_sequence(a, b).nfa_hash
		exp = {0=>[[sym('a'), 1]], 1=>[[sym('b'), 1000]], 1000=>[]}
		assert_equal(exp, nfa)
	end
	def test_alternation
		a = mk_letter('a')
		b = mk_letter('b')
		nfa = mk_alternation(a, b).nfa_hash
		exp = {0=>[[nil, 1], [nil, 2]], 1=>[[sym('a'), 3]], 
			2=>[[sym('b'), 3]], 3=>[[nil, 1000]], 1000=>[]}
		assert_equal(exp, nfa)
	end
	def test_repeat
		a = mk_letter('a')
		nfa = mk_repeat(a).nfa_hash
		exp = {0=>[[nil, 1], [nil, 1000]], 1=>[[sym('a'), 0]], 1000=>[]}
		assert_equal(exp, nfa)
	end
	def test_wild
		# a.b
		a = mk_letter('a')
		wild = mk_wild
		b = mk_letter('b')
		seq = mk_sequence(wild, b)
		nfa = mk_sequence(a, seq).nfa_hash
		exp = {0=>[[sym('a'), 1]], 1=>[[sym_neg("\n"), 2]], 
			2=>[[sym('b'), 1000]], 1000=>[]}
		assert_equal(exp, nfa)
	end
end

if $0 == __FILE__
	require 'test/unit/ui/console/testrunner'
	Test::Unit::UI::Console::TestRunner.run(TestRegexNfa)
end
