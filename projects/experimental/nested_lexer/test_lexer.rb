require 'test/unit'
require 'lexer'

module DebugNodes

class Base
end

class Text < Base
	def initialize(text)
		super()
		@text = text
	end
	def to_s
		@text
	end
end

class Transition < Base
	def initialize(text)
		super()
		@text = text
	end
	def to_s
		@text
	end
end

class EndState < Base
	def initialize(state)
		super()
	end
	def to_s
		""
	end
end

end # module DebugNodes

class TestLexer < Test::Unit::TestCase
=begin
	include DebugNodes
	def setup
		@state = Lexer::Base::MODE_NORMAL
		@lexer = nil
		case @method_name
		when /parse_html/
			@lexer = HTML::Lexer.new
		when /parse_ruby/
			@lexer = nil
		else
			raise "error"
		end
	end
	def transition(text=nil)
		Transition.new(text || "")
	end
	def end_state(symbol)
		EndState.new(symbol)
	end
	def line(*params)
		params.map!{|s| s.kind_of?(String) ? Text.new(s) : s }
		params.each_with_index do |s, i|
 			next if s.kind_of?(Base)
 			raise "param ##{i}: expected Base but was #{s.class}." 
		end
		text = params.join
		raise "newline problem" unless text =~ /\A[^\n]*\n?\z/m
		#p text
		#@state = @lexer.parse(text, @state)
		#assert_equal((@state == 0) ? 0 : 1, state || 0)
	end
	def test_parse_ruby1
		line "p :begin\n"
		line "p <<A, <<B\n", end_state(:embed)
		line "im a\n", end_state(:embed)
		line "A\n", end_state(:embed)
		line "im b\n", end_state(:embed)
		line "B\n"
		line "p :end"
	end
	def test_parse_ruby2
		line "p :begin\n"
		line "p ", transition("%w{"), "abc\n", end_state(:embed)
		line "def ghi\n", end_state(:embed)
		line "jkl", transition("}"), ".reverse\n", end_state(:embed)
		line "p :end"
	end
	def test_parse_html1
		line "<html>\n"
		line "<script type=\"text/javascript\" language=\"JavaScript\">", transition, "\n", end_state(:embed)
		line "alert(\"hi\");\n", end_state(:embed)
		line transition, "</script>\n"
		line "</html>"
	end
	def test_parse_html2
		line "<html>\n"
		line "<b>Time = ", transition("<?"), "\n", end_state(:embed)
		line "puts Time.now\n", end_state(:embed)
		line transition("?>"), "</html>"
	end
=end
	def setup
		@lexer = nil
		@state = nil
		case @method_name
		when /html/
			@lexer = HTML::Lexer.new
		when /ruby/
			@lexer = nil
		else
			raise "error"
		end
	end
=begin
	def colorize(texts, colors)
		raise "size problem" if texts.size != colors.size
		exp_sizes = texts.map{|t| t.size}
		@lexer.colorize(texts.join)
		act_sizes = @lexer.fragments.first(colors.size)
		act_colors = @lexer.colors.first(colors.size)
		assert_equal(exp_sizes, act_sizes)
		assert_equal(colors, act_colors)
	end
	def test_colorize_html1
		colorize(
			%W(< html > \n), [:tag1, :keyword, :tag2, :nl])
	end
=end
	def tok(tokens)
		str = tokens.join
		str.unpack("U*")
		@lexer.tokenize(str)
		actual = @lexer.tokens.first(@lexer.token_count)
		assert_equal(tokens.map{|i| i.size}, actual)
	end
	def test_tokenize_html_tags1
		tok %W(<html> <body> hi </body> </html> \n)
	end
	def test_tokenize_html_tags2
		tok %W(<b> hi </b> <h1> xyz </h1> <tt> 42 </tt>)
	end
	def test_tokenize_html_attr1
		tok %W(<a\ href="a\ b\ c"> somewhere </a> \n)
	end
	def test_tokenize_html_attr2
		tok %W(<div\ id="x"\ class='y'> bla </div> \n)
	end
	def test_tokenize_html_attr3
		tok %W(<img\ width="42"\n\ \ height="666"> \n </img> \n)
	end
	def test_tokenize_html_comment1
		tok %W(before <!--\ hi\ im\ a\ comment\ --> after)
	end
	def test_tokenize_html_comment2
		tok %W(im1 <!--\ line1\ \n\ line2\ --> im2)
	end
	def test_tokenize_html_ssi1
		tok %W(abc <?\ puts\ 42\np\ "hi"\ ?> def)
	end
	def test_tokenize_html_script1
		ary = [
			'before',
			'<script type="text/javascript" language="JavaScript">' +
			'alert("hi");' +
			'</script>',
			'after'
		]
		tok ary
	end
	def test_tokenize_html_unicode1
		tok [(250..4000).to_a.pack("U*")]
	end
	def test_tokenize_html_unicode2
		illegal = "ab\x80\x80cd"
		e = assert_raise(ArgumentError) do
			tok [illegal]
		end
		assert_match(/UTF-8/, e.message)
	end
	def test_tokenize_html_entities1
		tok %W(&nbsp; a &#160; b &lt; c &euro; d &gt; e &yen; f &copy;)
	end
	def test_tokenize_html_doctype1
		ary = [
			'<?xml version="1.0" encoding="UTF-8"?>',
			'<!DOCTYPE html' +
				'PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"' +
    		'"http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">',
    	'<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">'
		]
		tok ary
	end
	def test_tokenize_html_max
		@lexer.tokenize("abc<b>def<tt>ghi</tt>jkl<b>mno", 14)
		assert_equal([3, 3, 3, 4, 17], @lexer.tokens.first(@lexer.token_count))
	end
end