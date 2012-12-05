require 'misc'
require 'test/unit'

class TestMisc < Test::Unit::TestCase
	def test_fixnum_bits
		inout = [
			0, 0x00,
			4, 0x0a,
			7, 0x7f,
			8, 0x80,
			9, 0x100,
		]
		ok = true
		input, expected = inout.partition{|i| ok = !ok}
		output = input.map{|i| i.bits}
		assert_equal(expected, output)
	end
end

if $0 == __FILE__
	require 'test/unit/ui/console/testrunner'
	Test::Unit::UI::Console::TestRunner.run(TestMisc)
end
