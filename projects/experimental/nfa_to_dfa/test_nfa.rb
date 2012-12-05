require 'test/unit'
require 'nfa'

class TestNfa < Test::Unit::TestCase
	def sym(*symbol)
		Match::Include.new(*symbol)
	end
	def sym_neg(*symbol)
		Match::Exclude.new(*symbol)
	end
	def setup
		# build the NFA shown on figure 2.5 
		# page 27, in 'Basics of Compiler Design'
		nfa_hash = {
			0 => [[nil, 4], [nil, 1]],  # start state
			1 => [[sym('a'), 2]],
			2 => [[sym('b'), 3]],
			3 => [],  # accepting
			4 => [[nil, 5], [nil, 6]],
			5 => [[sym('a'), 7]],
			6 => [[sym('b'), 7]],
			7 => [[nil, 0]]
		}
		@nfa = Nfa.new(nfa_hash)
	end
	def test_fixedpoint1
		assert_equal([0, 1, 4], @nfa.fixed_point_iteration([0]))
	end
	def test_fixedpoint2
		assert_equal([0, 1, 4, 5, 6], @nfa.fixed_point_iteration([0, 1, 4]))
	end
	def test_fixedpoint3
		assert_equal([0, 1, 4, 5, 6], @nfa.fixed_point_iteration([0, 1, 4, 5, 6]))
	end
	def test_e_closure1
		assert_equal([0, 1, 4, 5, 6], @nfa.e_closure([0]))
	end
	def test_alphabet
		assert_equal(['a', 'b'], @nfa.alphabet)
	end
	def test_accepting_states
		assert_equal([3], @nfa.accepting_states)
	end
	def test_move_s0_a
		# description of the #move operation, see page 34 in BoCD
		assert_equal([0, 1, 2, 4, 5, 6, 7], @nfa.move([0, 1, 4, 5, 6], 'a'))
	end
	def test_move_s0_b
		assert_equal([0, 1, 4, 5, 6, 7], @nfa.move([0, 1, 4, 5, 6], 'b'))
	end
	def test_move_s1_a
		assert_equal([0, 1, 2, 4, 5, 6, 7], @nfa.move([0, 1, 2, 4, 5, 6, 7], 'a'))
	end
	def test_move_s1_b
		assert_equal([0, 1, 3, 4, 5, 6, 7], @nfa.move([0, 1, 2, 4, 5, 6, 7], 'b'))
	end
	def test_move_s2_a
		assert_equal([0, 1, 2, 4, 5, 6, 7], @nfa.move([0, 1, 4, 5, 6, 7], 'a'))
	end
	def test_move_s2_b
		assert_equal([0, 1, 4, 5, 6, 7], @nfa.move([0, 1, 4, 5, 6, 7], 'b'))
	end
	def test_move_s3_a
		assert_equal([0, 1, 2, 4, 5, 6, 7], @nfa.move([0, 1, 3, 4, 5, 6, 7], 'a'))
	end
	def test_move_s3_b
		assert_equal([0, 1, 4, 5, 6, 7], @nfa.move([0, 1, 3, 4, 5, 6, 7], 'b'))
	end
	def test_build_dfa
		# see figure 2.7 at page 35 in BoCD
		next_state = [[1, 2], [1, 3], [1, 2], [1, 2]]
		assert_equal([next_state, ['a', 'b'], [3]], @nfa.build_dfa)
	end
	def test_exclude
		nfa_hash = {
			0 => [[sym('a'), 1]],
			1 => [[sym_neg('b'), 2]],  # ignore excluded symbols
			2 => [[sym('c'), 3]],
			3 => []
		}
		nfa = Nfa.new(nfa_hash)
		assert_equal([nil, 'a', 'b', 'c'], nfa.alphabet)
	end
	def test_merge_states   #  (ab)|(ac)
		# the two 'a' states will be merged in the DFA
		nfa_hash = {
			0 => [[nil, 3], [nil, 1]],  # start state
			1 => [[sym('a'), 2]],
			2 => [[sym('b'), 5]],
			3 => [[sym('a'), 4]],
			4 => [[sym('c'), 5]],
			5 => [[nil, 6]],
			6 => []
		}
		nfa = Nfa.new(nfa_hash)
		next_state = [
			[1, 2, 2],
			[2, 3, 3],
			[2, 2, 2],  # not necessary
			[2, 2, 2]
		]
		assert_equal([next_state, ['a', 'b', 'c'], [3]], nfa.build_dfa)
	end
	def test_merge_states_wild   #  ([^X]b)|([^X]c)
		# the two 'a' states will be merged in the DFA
		nfa_hash = {
			0 => [[nil, 3], [nil, 1]],  # start state
			1 => [[sym_neg('X'), 2]],
			2 => [[sym('b'), 5]],
			3 => [[sym_neg('X'), 4]],
			4 => [[sym('c'), 5]],
			5 => [[nil, 6]],
			6 => []
		}
		nfa = Nfa.new(nfa_hash)
		next_state = [
			[1, 2, 1, 1],
			[2, 2, 3, 3],
			[2, 2, 2, 2],  # not necessary
			[2, 2, 2, 2]
		]
		assert_equal([next_state, [nil, 'X', 'b', 'c'], [3]], nfa.build_dfa)
	end
end

if $0 == __FILE__
	require 'test/unit/ui/console/testrunner'
	Test::Unit::UI::Console::TestRunner.run(TestNfa)
end
