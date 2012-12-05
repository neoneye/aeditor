require 'test/unit'
require 'aeditor/string'

class TestString < Test::Unit::TestCase
	def test_expand_tabs1
		str = "\ta\tab\tabc\tabcd\tx"
		e1 = "\ta\tab\tabc\tabcd\tx" 
		e2 = "\t\ta\tab\t\tabc\tabcd\t\tx"
		e3 = "\t\t\ta\t\tab\tabc\t\t\tabcd\t\tx"
		e4 = "\t\t\t\ta\t\t\tab\t\tabc\tabcd\t\t\t\tx"
		assert_equal(e1, str.expand_tabs(1))
		assert_equal(e2, str.expand_tabs(2))
		assert_equal(e3, str.expand_tabs(3))
		assert_equal(e4, str.expand_tabs(4))
	end
	def forward1(str)
		str.paren_forward
	end
	def backward1(str)
		str.paren_backward
	end
	def test_paren_forward1
		assert_equal(nil, forward1(")("))
		assert_equal(nil, forward1("("))
		assert_equal(nil, forward1(")"))
		assert_equal(nil, forward1(")()"))
		assert_equal(nil, forward1("(()"))
	end
	def test_paren_forward2
		assert_equal([1, 0], forward1("()"))
		assert_equal([4, 0], forward1("abc()"))
		assert_equal([3, 0], forward1("(())"))
		assert_equal([5, 0], forward1("(()())"))
		assert_equal([1, 0], forward1("()())"))
	end
	def forward2(str)
		str.paren_forward(0, %w([ ]))
	end
	def test_paren_forward3
		assert_equal([1, 0], forward2("[]"))
		assert_equal([4, 0], forward2("abc[]def"))
		assert_equal([3, 0], forward2("[()]"))
		assert_equal([5, 0], forward2("[()()]"))
		assert_equal([2, 0], forward2("[(])"))
	end
	def generic_paren_forward(
		balance, input, exp_location, exp_indexes=nil)
		input_str = input.inspect
		str = input.shift
		indexes = []
		location = str.paren_forward(balance) do |index|
			indexes << index
			input.shift
		end
		assert_equal(exp_location, location, 
			"location problem  input=#{input_str}")
		return unless exp_indexes
		assert_equal(exp_indexes, indexes,
			"index problem  input=#{input_str}")
	end
	def test_paren_forward11
		generic_paren_forward(0, ['ab(', 'cd)'],
			[2, 1], [1])
		generic_paren_forward(0, ['a(b(x)c', '(y)', '(z))'],
			[3, 2], [1, 2])
		generic_paren_forward(0, ['', 'abc'],
			nil, [])
		generic_paren_forward(0, ['(a)b', ''],
			[2, 0], [])
	end
	def test_paren_forward12
		generic_paren_forward(1, ['ab(', 'cd)ef)g'],
			[5, 1], [1])
		generic_paren_forward(1, ['ab', 'cd)ef)g'],
			[2, 1], [1])
		generic_paren_forward(1, ['', 'x)y'],
			[1, 1], [1])
		generic_paren_forward(1, ['(cd)efg', 'x)y'],
			[1, 1], [1])
	end
	def test_paren_backward1
		assert_equal(nil, backward1(")("))
		assert_equal(nil, backward1("("))
		assert_equal(nil, backward1(")"))
		assert_equal(nil, backward1("()("))
		assert_equal(nil, backward1("())"))
	end
	def test_paren_backward2
		assert_equal([0, 0], backward1("()"))
		assert_equal([3, 0], backward1("abc()"))
		assert_equal([0, 0], backward1("(())"))
		assert_equal([0, 0], backward1("(()())"))
		assert_equal([3, 0], backward1("(()()"))
	end
	def backward2(str)
		str.paren_backward(0, %w([ ]))
	end
	def test_paren_backward3
		assert_equal([0, 0], backward2("[]"))
		assert_equal([3, 0], backward2("abc[]def"))
		assert_equal([0, 0], backward2("[()]"))
		assert_equal([0, 0], backward2("[()()]"))
		assert_equal([1, 0], backward2("([)]"))
	end
	def generic_paren_backward(
		balance, input, exp_location, exp_indexes=nil)
		input_str = input.inspect
		str = input.pop
		indexes = []
		location = str.paren_backward(balance) do |index|
			indexes << index
			input.pop
		end
		assert_equal(exp_location, location, 
			"location problem  input=#{input_str}")
		return unless exp_indexes
		assert_equal(exp_indexes, indexes,
			"index problem  input=#{input_str}")
	end
	def test_paren_backward11
		generic_paren_backward(0, ['ab(', 'cd)'], 
			[2, -1], [-1])
		generic_paren_backward(0, ['a(b(x)c', '(y)', '(z))'], 
			[1, -2], [-1, -2])
		generic_paren_backward(0, ['', 'abc'], 
			nil, [])
	end
	def test_paren_backward12
		generic_paren_backward(1, ['ab(', 'cd'], 
			[2, -1], [-1])
	end
	def generic_test_bracket_matcher(str, inpos, outpos)
		res = inpos.map {|p| str.match_bracket(p) }
		xs = res.map do |i|
			next nil unless i
			i[1] # extract x component
		end
		assert_equal(outpos, xs, str)
	end
	def test_bracket_matcher01
		generic_test_bracket_matcher(
			"ab(cd)ef",
			[0, 1, 2, 3, 4, 5, 6, 7],
			[5, 5, 5, 2, 2, 2, 2, 2]
		)
	end
	def test_bracket_matcher02
		generic_test_bracket_matcher(
			"a(b(c)d(e)e)f",
			[ 0,  1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12],
			[11, 11, 5, 5, 3, 3, 9, 9, 7, 7,  1,  1,  1]
		)
	end
	def test_bracket_matcher03
		generic_test_bracket_matcher(
			"abc", [0, 1, 2, 3], [nil, nil, nil, nil])
	end
	def test_bracket_matcher04
		generic_test_bracket_matcher(
			"a(b", [0, 1, 2, 3], [nil, nil, nil, nil])
	end
	def test_bracket_matcher05
		generic_test_bracket_matcher(
			"(a(b)c)", [0, 1, 2, 3, 4, 5, 6], [6, 4, 4, 2, 2, 0, 0])
	end
	def test_bracket_matcher06
		generic_test_bracket_matcher(
			")a)b(c(", [0, 1, 2, 3, 4, 5, 6], [nil]*7)
	end
	def xtest_bracket_matcher07 # TODO:
		generic_test_bracket_matcher(
			"a(b[c)d]e", (0..9).to_a, [5, 5, 7, 7, 1, 1, 3, 3, 3, 3])
	end
	def test_bracket_matcher11
		str = ["ab(#cd", "42", ")"]
		inpos = [0, 1, 2, 3, 4, 5, 6]
		res = inpos.map do |p|
			str[0].match_bracket(p) do |y|
				raise y.to_s if y <= 0
				next nil if y >= str.size
				str[y]
			end
		end
		expected = [[2, 0]] * 7
		assert_equal(expected, res, str.inspect)
	end
	def test_bracket_matcher12
		str = ["ab(#cd", "42", "99)#xy"]
		inpos = [0, 1, 2, 3, 4, 5, 6]
		res = inpos.map do |p|
			str[2].match_bracket(p) do |y|
				iy = -y
				raise y.to_s if iy <= 0
				next nil if iy >= str.size
				str[2-iy]
			end
		end
		expected = [[-2, 2]]*7
		assert_equal(expected, res, str.inspect)
	end
	def test_bracket_matcher13
		str = ["(", "a)b(c()d"]
		inpos = [0, 1, 2, 3, 4, 5, 6, 7, 8]
		res = inpos.map do |p|
			#puts "- - - - -"
			#puts "input pos=#{p} str=#{str[1].inspect}"
			str[1].match_bracket(p) do |y|
				#puts "callback y=#{y}"
				iy = -y
				raise y.to_s if iy == 0  # both less and greater than is ok
				next nil if iy >= str.size
				str[1-iy]
			end
		end
		# NOTE: apparently VIM doesn't do anything in the
		# last 4 cases.. (im mimicing VIM's behavier)
		# maybe it would be best if I didn't mimiced these 4 cases?
		expected = [[-1, 0], [-1, 0], nil, nil, 
			[0, 6], [0, 6], [0, 5], [0, 5], [0, 5]]
		assert_equal(expected, res, str.inspect)
	end
end