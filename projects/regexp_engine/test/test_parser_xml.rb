require 'common'
#require 'regexp/parser_xml'

class XTestParserXml < Common::TestCase
	include RegexFactory
	def compile(regex)
		ParserXml.new(regex).expression
	end
	def assert_parse(expected, input)
		assert_equal(expected, compile(input))
	end
	def test_sequence_any1
		exp = mk_sequence(
			mk_letter('a'), 
			mk_letter('b'), 
			mk_letter('c'), 
			mk_letter('d')
		)
		assert_parse(exp, "abc\n \td")
	end
	def test_sequence_any2
		exp = mk_sequence(
			mk_letter('a'), 
			mk_wild, 
			mk_letter('b')
		)
		assert_equal(exp, "a<wild />b")
	end
	#debug :test_sequence_any2
	#undef test_sequence_any2
=begin
	xmlstring = <<-EOXML
	<regexp>
	  <wordboundary />
	  he
	  <quantifier minimum="2">l</quantifier>
	  o
	  <wordboundary />
	</regexp>
	EOXML 
=end
end

XTestParserXml.run if $0 == __FILE__
