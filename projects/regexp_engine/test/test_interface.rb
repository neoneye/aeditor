require 'common'
require 'regexp/interface'

class TestInterface < Common::TestCase
	def test_gsub_harmless1
		str = 'ababab'
		re = NewRegexp.new('ba')
		assert_equal('aBABAb', str.gsub5(re, 'BA'))
		assert_equal('ababab', str, 'gsub wasn\'t harmless')
	end
	def test_gsub_harmless2
		str = 'ababab'
		retval = str.gsub5('ba') { |m| m.to_s.upcase }
		assert_equal('aBABAb', retval)
		assert_equal('ababab', str, 'gsub wasn\'t harmless')
	end
	def test_gsub_destructive1
		str = 'ababab'
		assert_equal('aBABAb', str.gsub5!('ba', 'BA'))
		assert_not_equal('ababab', 'gsub wasn\'t destructive')
	end
	def test_sub_harmless1
		str = 'ababab'
		retval = str.sub5('ba') { |m| m.to_s.upcase }
		assert_equal('aBAbab', retval)
		assert_equal('ababab', str, 'sub wasn\'t harmless')
	end
	def test_sub_destructive1
		str = 'ababab'
		assert_equal('aBAbab', str.sub5!('ba', 'BA'))
		assert_not_equal('ababab', 'sub wasn\'t destructive')
	end
	def test_split1
		str = 'ab-ab-ab'
		assert_equal(['ab', 'ab-ab'], str.split5('-', 2))
		assert_equal('ab-ab-ab', str, 'split wasn\'t harmless')
	end
	def test_scan1
		str = 'ab-ab-ab'
		re = NewRegexp.new('ab')
		assert_equal(['ab', 'ab', 'ab'], str.scan5(re))
		assert_equal('ab-ab-ab', str, 'scan wasn\'t harmless')
	end
	def test_scan2
		str = 'ab-ab-ab'
		ary = []
		pattern = %w(a b)
		retval = str.scan5(pattern) {|m| ary << m.to_s }
		assert_equal(['ab', 'ab', 'ab'], ary)
		assert_equal('ab-ab-ab', retval)
	end
	def test_match1
		str = 'ab-ab-ab'
		m = str.match5('[^-]*')
		assert_equal('ab', m.to_s)
		assert_equal('ab-ab-ab', str, 'match wasn\'t harmless')
	end
end

TestInterface.run if $0 == __FILE__
