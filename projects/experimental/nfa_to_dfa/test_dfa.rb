require 'test/unit'
require 'dfa'

class TestDfa < Test::Unit::TestCase
	def setup
		# see figure 2.8 at page 37 in BoCD
		dfa_hash = {
			0 => [['a', 1]],
			1 => [['a', 4], ['b', 2]],
			2 => [['a', 3], ['b', 5]],
			3 => [['b', 1]],
			4 => [['a', 6], ['b', 5]],
			5 => [['a', 7], ['b', 2]],
			6 => [['a', 5]],
			7 => [['a', 0], ['b', 5]]
		}
		accepting = [0, 6]
		@dfa = Dfa.build_from_hash(dfa_hash, accepting)
	end
	def test_alphabet
		assert_equal(['a', 'b'], @dfa.alphabet)
	end
	def xtest_minimize
		# TODO: implement DfaMini#build
		# see figure 2.9 at page 39 in BoCD
		dfa_hash = {
			0 => [['a', 1]],
			1 => [['a', 4], ['b', 2]],
			2 => [['a', 3], ['b', 1]],
			3 => [['b', 1]],
			4 => [['a', 0], ['b', 1]]
		}
		exp = Dfa.build_from_hash(dfa_hash, [0])
		assert_equal(exp, @dfa.minimize)
	end
	def test_dfamini_initial_groups1
		exp = [[0, 6], [1, 2, 3, 4, 5, 7]]
		mini = DfaMini.new(@dfa)
		assert_equal(exp, mini.groups)
	end
	def test_dfamini_consistency1
		exp = {
			0 => [1, nil],
			6 => [1, nil]
		}
		mini = DfaMini.new(@dfa)
		hash = mini.build_consistency_table(mini.groups[0])
		assert_equal(exp, hash)
	end
	def test_dfamini_consistency2
		exp = {
			1 => [1, 1],
			2 => [1, 1],
			3 => [nil, 1],
			4 => [0, 1],
			5 => [1, 1],
			7 => [0, 1]
		}
		mini = DfaMini.new(@dfa)
		hash = mini.build_consistency_table(mini.groups[1])
		assert_equal(exp, hash)
	end
	def test_dfamini_split1
		table = {
			0 => [1, nil],
			6 => [1, nil],
		}
		res = DfaMini.split(table)
		assert_equal([[0, 6]], res)
	end
	def test_dfamini_split2
		table = {
			1 => [1, 1],
			2 => [1, 1],
			3 => [nil, 1],
			4 => [0, 1],
			5 => [1, 1],
			7 => [0, 1]
		}
		res = DfaMini.split(table)
		assert_equal([[1, 2, 5], [4, 7], [3]], res)
	end
	def test_dfamini_calculate
		mini = DfaMini.new(@dfa)
		mini.calculate
		res = mini.result
		assert_equal([0, 3, 4, 5, 6], res)
	end
	def test_next_state_table
		exp = [[1, nil], [4, 2], [3, 5], [nil, 1],
			[6, 5], [7, 2], [5, nil], [0, 5]]
		res = @dfa.next_state
		assert_equal(exp, res)
	end
	def test_alphabet2index_normal
		exp = {'a'=>0, 'b'=>1}
		res = @dfa.alphabet_hash
		assert_equal(exp, res)
	end
	def test_alphabet2index_wild
		dfa = Dfa.new([], [nil, 'a', 'b'], [5])
		exp = {'a'=>1, 'b'=>2}
		exp.default = 0
		res = dfa.alphabet_hash
		assert_equal(exp, res)
	end
end

if $0 == __FILE__
	require 'test/unit/ui/console/testrunner'
	Test::Unit::UI::Console::TestRunner.run(TestDfa)
end
