require 'common'

class TestScanner < Common::TestCase
	def test_input_reverse
		string_ary = "string".split(//)
		iterator = string_ary.create_iterator
		input = InputIterator.new(iterator)
		assert_equal(0, input.position)
		assert_equal(nil, input.last_value)
		assert_equal('s', input.current)
		input.next(2)
		assert_equal(2, input.position)
		assert_equal('t', input.last_value)
		assert_equal('r', input.current)
		rev_input = input.reverse
		assert_equal(2, rev_input.position)
		assert_equal('r', rev_input.last_value)
		assert_equal('t', rev_input.current)
		rev_input2 = rev_input.clone.next
		assert_equal(1, rev_input2.position)
		assert_equal('t', rev_input2.last_value)
		assert_equal('s', rev_input2.current)
		# see if original iterators are unharmed
		assert_equal(2, rev_input.position)
		assert_equal('r', rev_input.last_value)
		assert_equal('t', rev_input.current)
		assert_equal(2, input.position)
		assert_equal('t', input.last_value)
		assert_equal('r', input.current)
	end
end

TestScanner.run if $0 == __FILE__
