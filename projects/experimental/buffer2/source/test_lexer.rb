require 'aeditor/common_test'
require 'aeditor/lexer'

class TestLexerText < Test::Unit::TestCase
	include LexerText
	def format(text)
		lexer = Lexer.new
		lexer.set_states([])  # there are no states in plaintext files
		lexer.set_result([])
		lexer.lex_line(text)
		lexer.result
	end
	def test_format_normal1
		expected = [
			['hell', :text],
			["\t\t", :tab],
			["o world\n   ", :text]
		]
		assert_equal(expected, format("hell\t\to world\n   "))
	end
end

module HelpTestLexer
	def mk_lexer
		raise "class must overload me"
	end
	def tok(string)
		lexer = mk_lexer
		lexer.tokenize(string).transpose
	end
	def lex(text, states=nil)
		lexer = mk_lexer
		lexer.set_states(states||[])
		lexer.set_result([])
		lexer.lex_line(text)
		lexer.result.transpose
	end
	def prop(states, text)
		lexer = mk_lexer
		lexer.set_states(states.map{|i| i.clone})
		lexer.set_result([])
		lexer.lex_line(text)
		lexer.states
	end
	def eol(states, text)
		lexer = mk_lexer
		lexer.set_states(states.map{|i| i.clone})
		lexer.set_result([])
		lexer.lex_line(text)
		lexer.result_endofline
	end
	def eol2(text, states=nil)
		eol(states||[], text)
	end
end # module HelpTestLexer

class TestLexerCplusplus < Test::Unit::TestCase
	include LexerCplusplus
	include HelpTestLexer
	def mk_lexer
		Lexer.new
	end
	COMMENT = State::Comment
	PREPROC = State::Preprocessor
	ASSEMBLER = State::Assembler
	def test_tokenize_number1
		bad, good = tok('123+0.5+6+12.34')
		assert_equal(%w|123 + 0.5 + 6 + 12.34|, good)
		assert_equal([nil]*7, bad)
	end
	def test_tokenize_number2
		bad, good = tok("0xD0ce,0XBABE2+34ab5z_z;")
		assert_equal(%w|0xD0ce , 0XBABE2 +| + [nil, ';'], good)
		assert_equal([nil, nil, nil, nil, '34ab5z_z', nil], bad)
	end
	def test_tokenize_identifier
		bad, good = tok("sum=__a2+a-b_2*_3;")
		assert_equal(%w|sum = __a2 + a - b_2 * _3 ;|, good)
		assert_equal([nil]*10, bad)
	end
	def test_tokenize_comment
		bad, good = tok("run();//hi")
		assert_equal(%w|run ( ) ; //hi|, good)
		assert_equal([nil]*5, bad)
	end
	def test_tokenize_string1
		bad, good = tok('printf("%s %s", "\\"a", "\\\\");')
		assert_equal(%w|printf ( "%s\ %s" , \  "\\"a" , \  "\\\\" ) ;|, good)
		assert_equal([nil]*11, bad)
	end
	def test_tokenize_string2
		bad, good = tok('s="hello;')
		assert_equal(['s', '=', nil], good)
		assert_equal([nil, nil, '"hello;'], bad)
	end
	def test_tokenize_char1
		bad, good = tok("'a', '\\n', '\\\\'")
		assert_equal(%w|'a' , \  '\\n' , \  '\\\\'|, good)
		assert_equal([nil]*7, bad)
	end
	def test_tokenize_char2
		bad, good = tok("'a','bad','c'")
		assert_equal(["'a'", ',', nil, ',', "'c'"], good)
		assert_equal([nil, nil, "'bad'", nil, nil], bad)
	end
	def test_tokenize_char3
		bad, good = tok("'a','','b'")
		assert_equal(["'a'", ',', nil, ',', "'b'"], good)
		assert_equal([nil, nil, "''", nil, nil], bad)
	end
	def test_tokenize_char4
		bad, good = tok("'a', 'whos bad")
		assert_equal(["'a'", ',', ' ', nil], good)
		assert_equal([nil, nil, nil, "'whos bad"], bad)
	end
	def test_tokenize_preprocessor
		bad, good = tok("#define max(a, b) \\")
		assert_equal(["#define max(a, b) \\"], good)
		assert_equal([nil], bad)
	end
	def test_lex1
		tokens, states = lex("ab+c*9.9")
		assert_equal(%w|ab + c * 9.9|, tokens)
		assert_equal([:ident, :punct, :ident, :punct, :number], states)
	end
	def test_lex2
		tokens, states = lex("'a', '', 'b'")
		assert_equal(%w|'a' , \  '' , \  'b'|, tokens)
		assert_equal([:string, :punct, :space, :bad, 
			:punct, :space, :string], states)
	end
	def test_lex3
		tokens, states = lex('const int x=9')
		assert_equal(%w|const \  int \  x = 9|, tokens)
		assert_equal([:keyword, :space, :keyword, 
			:space, :ident, :punct, :number], states)
	end
	def test_lex4
		tokens, states = lex("doom << 42; // o\tk")
		assert_equal(%W|doom \  < < \  42 ; \  //\ o \t k|, tokens)
		assert_equal([:ident, :space, :punct, :punct,
			:space, :number, :punct, :space, :comment,
			:comment_tab, :comment], states)
	end
	def test_lex5
		tokens, states = lex("\ttest(); /*x*/ test();")
		assert_equal(%W|\t test ( ) ; \  /*x*/ \  test ( ) ;|, tokens)
		assert_equal([:tab, :ident, :punct, :punct, :punct,
			:space, :mcomment, :space, :ident, :punct, 
			:punct, :punct], states)
	end
	def test_lex6
		tokens, states = lex('  #  define ZETA 42')
		assert_equal(%w|\ \  #\ \ define\ ZETA\ 42|, tokens)
		assert_equal([:space, :preproc], states)
	end
	def test_lex7
		tokens, states = lex("\"\\t-\\n-\t\"")
		assert_equal(%W|" \\t - \\n - \t "|, tokens)
		assert_equal([:string, :string1, :string, 
			:string1, :string, :string1, :string], states)
	end
	def test_lex8
		tokens, states = lex("\t\tblah blah", [COMMENT.new])
		assert_equal(%W|\t\t blah\ blah|, tokens)
		assert_equal([:mcomment_tab, :mcomment], states)
	end
	def test_lex9
		tokens, states = lex("\t\tblah */ #endif", [COMMENT.new])
		assert_equal(%W|\t\t blah\ */ \  #endif|, tokens)
		assert_equal([:mcomment_tab, :mcomment, :space, :preproc], states)
	end
	def test_lex10
		tokens, states = lex("stop( /*\tm\te")
		assert_equal(%W|stop ( \  /* \t m \t e|, tokens)
		assert_equal([:ident, :punct, :space, :mcomment, 
			:mcomment_tab, :mcomment, :mcomment_tab, :mcomment], states)
	end
	def test_lex11
		tokens, states = lex("do /*\t*/ {")
		assert_equal(%W|do \  /* \t */ \  {|, tokens)
		assert_equal([:keyword, :space, :mcomment, 
			:mcomment_tab, :mcomment, :space, :punct], states)
	end
	def test_lex12
		tokens, states = lex("#\tdefine\tx(y)\\")
		assert_equal(%W|# \t define \t x(y)\\|, tokens)
		assert_equal([:preproc, :preproc_tab, :preproc, :preproc_tab,
			:preproc], states)
	end
	def test_lex13
		tokens, states = lex("#define\t\tx 42")
		assert_equal(%W|#define \t\t x\ 42|, tokens)
		assert_equal([:preproc, :preproc_tab, :preproc], states)
	end
	def test_lex14
		tokens, states = lex("\t\tx=0;\ty=0;\\", [PREPROC.new])
		assert_equal(%W|\t\t x=0; \t y=0;\\|, tokens)
		assert_equal([:preproc_tab, :preproc, :preproc_tab,
			:preproc], states)
	end
	def test_lex15
		tokens, states = lex("\t\tZAP", [PREPROC.new])
		assert_equal(%W|\t\t ZAP|, tokens)
		assert_equal([:preproc_tab, :preproc], states)
	end
	def test_lex16
		tokens, states = lex("\t\tmov al, 1", [ASSEMBLER.new])
		assert_equal(%W|\t\t mov\ al,\ 1|, tokens)
		assert_equal([:assembler_tab, :assembler], states)
	end
	def test_lex17
		tokens, states = lex("\t\t} MACRO", [ASSEMBLER.new])
		assert_equal(%W|\t\t } \  MACRO|, tokens)
		assert_equal([:assembler_tab, :assembler,
			:space, :ident], states)
	end
	def test_lex18
		tokens, states = lex("\tasm{\tnop")
		assert_equal(%W|\t asm{ \t nop|, tokens)
		assert_equal([:tab, :assembler, :assembler_tab,
			:assembler], states)
	end
	def test_propagate_comment1
		stack = prop([], '"normal" /* comment')
		assert_equal([COMMENT.new], stack)
	end
	def test_propagate_comment2
		stack = prop([], 's=\'im bad /* comment')
		assert_equal([COMMENT.new], stack)
	end
	def test_propagate_comment3
		stack = prop([], '"normal" /* comment */ "normal"')
		assert_equal([], stack)
	end
	def test_propagate_comment4
		stack = prop([COMMENT.new], 'comment */ "normal"')
		assert_equal([], stack)
	end
	def test_propagate_preprocessor1
		stack = prop([], '#define RESET(x) \\')
		assert_equal([PREPROC.new], stack)
	end
	def test_propagate_preprocessor2
		stack = prop([PREPROC.new], 'x++; \\')
		assert_equal([PREPROC.new], stack)
	end
	def test_propagate_preprocessor3
		stack = prop([PREPROC.new], 'y--;')
		assert_equal([], stack)
	end
	def test_propagate_assembler1
		stack = prop([], '__asm {')
		assert_equal([ASSEMBLER.new], stack)
	end
	def test_propagate_assembler2
		stack = prop([ASSEMBLER.new], '}')
		assert_equal([], stack)
	end
	def test_endofline_comment1
		expected = :comment_end
		assert_equal(expected, eol([], "abc + def; // comment"))
		assert_equal(expected, eol([], "cout << 42; // comment\n"))
	end
	def test_endofline_mcomment1
		expected = :mcomment_end
		assert_equal(expected, eol([], "\"normal\"; /* comment"))
		assert_equal(expected, eol([], "\"normal\"; /* comment\n"))
	end
	def test_endofline_mcomment2
		expected = :mcomment_end
		stack = [COMMENT.new]
		assert_equal(expected, eol(stack, "blah * blah"))
	end
	def test_endofline_mcomment3
		expected = nil
		stack = [COMMENT.new]
		assert_equal(expected, eol(stack, "blah */ code"))
	end
	def test_endofline_preprocessor1
		expected = :preproc_end
		stack = [PREPROC.new]
		assert_equal(expected, eol(stack, "\tab = 0; \\"))
	end
	def test_endofline_preprocessor2
		expected = nil
		stack = [PREPROC.new]
		assert_equal(expected, eol(stack, "\tab = 0;"))
	end
	def test_endofline_assembler1
		expected = :assembler_end
		stack = [ASSEMBLER.new]
		assert_equal(expected, eol(stack, "\txor\teax, eax"))
	end
end # class TestLexerCplusplus

class TestLexerRuby < Test::Unit::TestCase
	include LexerRuby
	include HelpTestLexer
	HEREDOC = State::Heredoc
	COMMENT = State::Comment
	ENDOFFILE = State::Endoffile
	LITERAL = State::Literal
	STRING = State::String
	def mk_lexer
		Lexer.new
	end
	def test_tokenize_number1
		bad, good = tok('123+0.5+6+12.34')
		assert_equal(%w|123 + 0.5 + 6 + 12.34|, good)
		assert_equal([nil]*7, bad)
	end
	def test_tokenize_number2
		bad, good = tok('0xa_F3,1_2.3_4,0b01_10')
		assert_equal(%w|0xa_F3 , 1_2.3_4 , 0b01_10|, good)
		assert_equal([nil]*5, bad)
	end
	def test_tokenize_number3
		bad, good = tok('?a,??.to_s,?bad')
		assert_equal(%w|?a , ?? .to_s ,|+[nil], good)
		assert_equal([nil, nil, nil, nil, nil, '?bad'], bad)
	end
	def test_tokenize_identifier1
		bad, good = tok("sum=__a2+a-b_2*_1")
		assert_equal(%w|sum = __a2 + a - b_2 * _1|, good)
		assert_equal([nil]*9, bad)
	end
	def test_tokenize_identifier2
		bad, good = tok("$dbg=@val-@@zz")
		assert_equal(%w|$dbg = @val - @@zz|, good)
		assert_equal([nil]*5, bad)
	end
	def test_tokenize_identifier3
		bad, good = tok("@@n.zap! if empty?")
		assert_equal(%w|@@n .zap! \  if \  empty?|, good)
		assert_equal([nil]*6, bad)
	end
	def test_tokenize_identifier_number1
		bad, good = tok("try 4u=666")
		assert_equal(['try', ' ', nil, '=', '666'], good)
		assert_equal([nil, nil, '4u', nil, nil], bad)
	end
	def test_tokenize_comment1
		bad, good = tok("code # comment ## more")
		assert_equal(%w(code \  #\ comment\ ##\ more), good)
		assert_equal([nil]*3, bad)
	end
	def test_tokenize_comment2
		bad, good = tok("code#comment\n ")
		assert_equal(%W(code #comment\n\ ), good)
		assert_equal([nil]*2, bad)
	end
	def test_tokenize_heredoc1
		bad, good = tok("<<A,<<-B.zap!,<<'C'")
		assert_equal(%w(<<A , <<-B .zap! , <<'C'), good)
		assert_equal([nil]*6, bad)
	end
	def test_tokenize_symbol1
		bad, good = tok(":dk,:2u,:c3")
		assert_equal([':dk', ',', nil, ',', ':c3'], good)
		assert_equal([nil, nil, ':2u', nil, nil], bad)
	end
	def test_tokenize_string1
		bad, good = tok('"\t#{code}\n"+\'#{}\'')
		assert_equal(['"\t#{code}\n"', '+', '\'#{}\''], good)
		assert_equal([nil]*3, bad)
	end
	def test_tokenize_string2
		bad, good = tok('"\\",","\\\\","\\n"')
		assert_equal(%w("\\"," , "\\\\" , "\\n"), good)
		assert_equal([nil]*5, bad)
	end
	def test_tokenize_string3
		bad, good = tok("'ab\\''+'\\\\'+\"cd\\\"\"")
		assert_equal(%w('ab\\'' + '\\\\' + "cd\\""), good)
		assert_equal([nil]*5, bad)
	end
	def test_tokenize_string4
		bad, good = tok("puts('abc")
		assert_equal(%W|puts ( 'abc|, good)
		assert_equal([nil]*3, bad)
	end
	def test_tokenize_regexp1
		bad, good = tok("/ab\\/c\\Sd/.kcode /ab")
		assert_equal(%w(/ab\\/c\\Sd/.kcode\ /ab), good)
		assert_equal([nil], bad)
	end
	def test_tokenize_regexp2
		bad, good = tok("//u,//s,/x/5in")
		assert_equal(%w(//u,//s,/x/5in), good)
		assert_equal([nil], bad)
	end
	def test_tokenize_regexp3
		bad, good = tok("re=/(.(.)")
		assert_equal(%w|re = /(.(.)|, good)
		assert_equal([nil]*3, bad)
	end
	def test_tokenize_method1
		bad, good = tok("12.a_b.c1d.e3f")
		assert_equal(%w(12 .a_b .c1d .e3f), good)
		assert_equal([nil]*4, bad)
	end
	def test_tokenize_literal1
		# literals requires counting.. (recursion)
		bad, good = tok("['a'],%W[b c]#comment")
		assert_equal(%w([ 'a' ] , %W[b\ c]#comment), good)
		assert_equal([nil]*5, bad)
	end
	def test_tokenize_endoffile1
		bad, good = tok("\t__END__ #oops")
		assert_equal(["\t", "__END__ #oops"], good)
		assert_equal([nil]*2, bad)
	end
	def test_lexer_normal1
		tokens, states = lex("abc += ?x # comment\n ")
		assert_equal(%W|abc \  += \  ?x \  #\ comment \n\ |, tokens)
		assert_equal([:ident, :space, :punct, :space,
			:number, :space, :comment, :comment_end], states)	
		assert_equal(:comment_end, eol2("abc += ?x # comment\n "))
	end
	def test_lexer_normal2
		tokens, states = lex("\t@@doom2 \"z\".hey")
		assert_equal(["\t", '@@doom2', ' ', '"z"', '.hey'], tokens)
		assert_equal([:tab, :cvar, :space, :string, :dot], states)
	end
	def test_lexer_normal3
		tokens, states = lex("@a(<<'HERE'.zz,:xyz)")
		assert_equal(['@a', '(', '<<\'HERE\'', '.zz', 
			',', ':xyz', ')'], tokens)
		assert_equal([:ivar, :punct, :heredoc, :dot, 
			:punct, :symbol, :punct], states)
	end
	def test_lexer_normal4
		tokens, states = lex('/\\\\/u.match(s) if true')
		assert_equal(%W(/ \\\\ /u .match ( s ) \  if \  true), tokens)
		assert_equal([:regexp, :regexp1, :regexp, :dot, :punct, 
			:ident, :punct, :space, :keyword, :space, :keyword], states)
	end
	def test_lexer_normal5
		tokens, states = lex('$s.scan(/\t/3Z)')
		assert_equal(%w($s .scan ( / \t / 3Z )), tokens)
		assert_equal([:gvar, :dot, :punct, :regexp, 
			:regexp1, :regexp, :bad, :punct], states)
	end
	def test_lexer_normal6
		tokens, states = lex('ab __END__cd')
		# TODO: __END__cd is actually a identifier.. fixme
		assert_equal(%w(ab \  __END__cd), tokens)
		assert_equal([:ident, :space, :bad], states)
	end
	def test_lexer_normal7
		tokens, states = lex(' __END__')
		assert_equal(%w(\  __END__), tokens)
		assert_equal([:space, :bad], states)
	end
	def test_lexer_normal8
		tokens, states = lex('$ ab="cd')
		assert_equal(%w($ \  ab = "cd), tokens)
		assert_equal([:bad, :space, :ident, :punct, :string], states)
	end
	def test_lexer_normal9
		tokens, states = lex("output=`ls`#com\tment")
		assert_equal(%W(output = `ls` #com \t ment), tokens)
		assert_equal([:ident, :punct, :execute, :comment,
			:comment_tab, :comment], states)
	end
	def test_lexer_normal10
		tokens, states = lex("$..to_s+$0+$:aa")
		assert_equal(%W($. .to_s + $0 + $:aa), tokens)
		assert_equal([:gvar, :dot, :punct, :gvar, :punct, :bad], states)
	end
	def test_lexer_normal11
		tokens, states = lex("M::C.x")
		assert_equal(%W(M :: C .x), tokens)
		assert_equal([:ident, :punct, :ident, :dot], states)
	end
	def test_lexer_bad1
		tokens, states = lex("1..2,3...4,5....6")
		assert_equal(%W(1 .. 2 , 3 ... 4 , 5 .... 6), tokens)
		assert_equal([:number, :punct, :number, :punct,
			:number, :punct, :number, :punct,
			:number, :bad, :number], states)
	end
	def test_lexer_bad2
		tokens, states = lex("@ok,@@ok,@@@bad,@@@@bad")
		assert_equal(%W(@ok , @@ok , @@@bad , @@@@bad), tokens)
		assert_equal([:ivar, :punct, :cvar, :punct,
			:bad, :punct, :bad], states)
	end
	def test_lexer_bad3
		tokens, states = lex("a::b,c:::d")
		assert_equal(%W(a :: b , c ::: d), tokens)
		assert_equal([:ident, :punct, :ident, :punct, 
			:ident, :bad, :ident], states)
	end
	def test_lexer_normal_literal1
		tokens, states = lex("%w(a),%{b},%Q<c>,%q[d]")
		assert_equal(%w|%w(a) , %{b} , %Q<c> , %q[d]|, tokens)
		assert_equal([:literal, :punct, :literal, :punct,
			:literal, :punct, :literal], states)
	end
	def test_lexer_normal_literal2
		tokens, states = lex("ok(%w(a(b)c),3)")
		assert_equal(%w|ok ( %w(a(b)c) , 3 )|, tokens)
		assert_equal([:ident, :punct, :literal, :punct, 
			:number, :punct], states)
	end
	def test_lexer_normal_literal3
		tokens, states = lex("ok(%Q<a<<>b<>>c>,3)")
		assert_equal(%w|ok ( %Q<a<<>b<>>c> , 3 )|, tokens)
		assert_equal([:ident, :punct, :literal, :punct, 
			:number, :punct], states)
	end
	def test_lexer_normal_literal4
		tokens, states = lex("%{a\\}b{c}d}.reverse")
		assert_equal(%w|%{a \\} b{c}d} .reverse|, tokens)
		assert_equal([:literal, :literal1, :literal, :dot], states)
	end
	def test_lexer_normal_literal5
		tokens, states = lex("%|a\\|b|+%-\\\\-#hi")
		assert_equal(%w(%|a \\| b| + %- \\\\ - #hi), tokens)
		assert_equal([:literal, :literal1, :literal, :punct, 
			:literal, :literal1, :literal, :comment], states)
	end
	def test_lexer_literal_end1
		tokens, states = lex("b)c).reverse", [LITERAL.new('q', '(', 2)])
		assert_equal(%w|b)c) .reverse|, tokens)
		assert_equal([:literal, :dot], states)
	end
	def test_lexer_literal_end2
		tokens, states = lex("b)\\|c|.reverse", [LITERAL.new('q', '|', 1)])
		assert_equal(%w[b) \\| c| .reverse], tokens)
		assert_equal([:literal, :literal1, :literal, :dot], states)
	end
	def test_lexer_literal_decoration1
		tokens, states = lex("%|1\t2\\|3\\n4|")
		assert_equal(%W(%|1 \t 2 \\| 3 \\n 4|), tokens)
		assert_equal([:literal, :literal_tab, :literal,
			:literal1, :literal, :literal1, :literal], states)
	end
	def test_lexer_literal_decoration2
		tokens, states = lex("%q|1\t2\\|3\\n4\\ 5|")
		assert_equal(%W(%q|1 \t 2 \\| 3\\n4\\\ 5|), tokens)
		assert_equal([:literal, :literal_tab, :literal,
			:literal1, :literal], states)
	end
	def test_lexer_literal_decoration3
		tokens, states = lex("%w|1\t2\\|3\\n4\\ 5|")
		assert_equal(%W(%w|1 \t 2 \\| 3\\n4 \\\  5|), tokens)
		assert_equal([:literal, :literal_tab, :literal,
			:literal1, :literal, :literal1, :literal], states)
	end
	def test_lexer_literal_decoration4
		tokens, states = lex("%w|1\t2\\|3")
		assert_equal(%W(%w|1 \t 2 \\| 3), tokens)
		assert_equal([:literal, :literal_tab, :literal,
			:literal1, :literal], states)
	end
	def test_lexer_literal_decoration5
		tokens, states = lex("%q(1\t2\\t3\\(4\\)5)")
		assert_equal(%W|%q(1 \t 2\\t3 \\( 4 \\) 5)|, tokens)
		assert_equal([:literal, :literal_tab, :literal,
			:literal1, :literal, :literal1, :literal], states)
	end
	def test_lexer_literal_decoration6
		tokens, states = lex("%w{\t1\\)2\\{3")
		assert_equal(%W|%w{ \t 1\\)2 \\{ 3|, tokens)
		assert_equal([:literal, :literal_tab, :literal,
			:literal1, :literal], states)
	end
	def test_lexer_literal_decoration7
		tokens, states = lex("\t1\\)2\\{3", [LITERAL.new('q', '{', 2)])
		assert_equal(%W|\t 1\\)2 \\{ 3|, tokens)
		assert_equal([:literal_tab, :literal, 
			:literal1, :literal], states)
	end
	def test_lexer_literal_decoration8
		tokens, states = lex("\t1\\)2\\{3|.dot", [LITERAL.new('W', '|', 2)])
		assert_equal(%W<\t 1 \\) 2 \\{ 3| .dot>, tokens)
		assert_equal([:literal_tab, :literal, 
			:literal1, :literal, :literal1, :literal, :dot], states)
	end
	def xtest_lexer_normal_modulo1  # TODO: ambiguity literal/modulo
		tokens, states = lex("'%i'%123")
		assert_equal(%w('%i' % 123), tokens)
		assert_equal([:string, :punct, :number], states)
	end
	def test_lexer_string_end1
		tokens, states = lex("ab'.upcase", [STRING.new('\'')])
		assert_equal(%w(ab' .upcase), tokens)
		assert_equal([:string, :dot], states)
	end
	def test_lexer_string_decoration1
		tokens, states = lex("\"\t1\\t2\\n3\#{42}\"")
		assert_equal(%W(" \t 1 \\t 2 \\n 3 \#{42} "), tokens)
		assert_equal([:string, :string_tab, :string, :string1, 
			:string, :string1, :string, :string1, :string], states)
	end
	def test_lexer_string_decoration2
		tokens, states = lex("'\t1\\t2\\n3\\\\4\\\'5\#{42}'")
		assert_equal(%W(' \t 1\\t2\\n3 \\\\ 4 \\' 5\#{42}'), tokens)
		assert_equal([:string, :string_tab, :string, 
			:string1, :string, :string1, :string], states)
	end
	def test_lexer_string_decoration3
		tokens, states = lex("str='\t1\\\\2")
		assert_equal(%W(str = ' \t 1 \\\\ 2), tokens)
		assert_equal([:ident, :punct, :string, :string_tab, :string, 
			:string1, :string], states)
	end
	def test_lexer_string_decoration4
		tokens, states = lex("\t1\\\\2\\''.reverse", [STRING.new('\'')])
		assert_equal(%W(\t 1 \\\\ 2 \\' ' .reverse), tokens)
		assert_equal([:string_tab, :string, :string1, 
			:string, :string1, :string, :dot], states)
	end
	def test_lexer_string_decoration5
		tokens, states = lex("1\t2\\\\t3\\n4\\'5\\t6", [STRING.new('\'')])
		assert_equal(%W(1 \t 2 \\\\ t3\\n4 \\' 5\\t6), tokens)
		assert_equal([:string, :string_tab, :string, 
			:string1, :string, :string1, :string], states)
	end
	def test_lexer_string_decoration6
		tokens, states = lex("1\t2\\\\t3\\n4\\'5\\t6", [STRING.new('"')])
		assert_equal(%W(1 \t 2 \\\\ t3 \\n 4 \\' 5 \\t 6), tokens)
		assert_equal([:string, :string_tab, :string, :string1, 
			:string, :string1, :string, :string1, :string,
			:string1, :string], states)
	end
	def test_lexer_execute_end1
		tokens, states = lex("ab`.upcase", [STRING.new('`')])
		assert_equal(%w(ab` .upcase), tokens)
		assert_equal([:execute, :dot], states)
	end
	def test_lexer_regexp_begin1
		tokens, states = lex("re=/a\tb\\/x")
		assert_equal(%W(re = /a \t b \\/ x), tokens)
		assert_equal([:ident, :punct, :regexp, :regexp_tab, :regexp,
			:regexp1, :regexp], states)
	end
	def test_lexer_regexp_middle1
		tokens, states = lex("a.*\tb\\tc", [STRING.new('/')])
		assert_equal(%W(a.* \t b \\t c), tokens)
		assert_equal([:regexp, :regexp_tab, :regexp,
			:regexp1, :regexp], states)
	end
	def test_lexer_regexp_end1
		tokens, states = lex("\t) \\s(?!z)/xm).to_a", [STRING.new('/')])
		assert_equal(%W|\t )\  \\s (?!z)/xm ) .to_a|, tokens)
		assert_equal([:regexp_tab, :regexp, :regexp1, :regexp, 
			:punct, :dot], states)
	end
	def test_lexer_regexp_end2
		tokens, states = lex(")\\/(?!z)/XM).to_a", [STRING.new('/')])
		assert_equal(%W|) \\/ (?!z)/ XM ) .to_a|, tokens)
		assert_equal([:regexp, :regexp1, :regexp, :bad, 
			:punct, :dot], states)
	end
	def test_lexer_comment_begin1
		tokens, states = lex("=begin\tte \t\txt")
		assert_equal(%W|=begin \t te\  \t\t xt|, tokens)
		assert_equal([:mcomment, :mcomment_tab, :mcomment, :mcomment_tab,
			:mcomment], states)
	end
	def test_lexer_comment_middle1
		tokens, states = lex("\tcom\t\tment", [COMMENT.new])
		assert_equal(%W|\t com \t\t ment|, tokens)
		assert_equal([:mcomment_tab, :mcomment, :mcomment_tab,
			:mcomment], states)
	end
	def test_lexer_comment_end1
		tokens, states = lex("=end\tte \t\txt", [COMMENT.new])
		assert_equal(%W|=end \t te\  \t\t xt|, tokens)
		assert_equal([:mcomment, :mcomment_tab, :mcomment, :mcomment_tab,
			:mcomment], states)
	end
	def test_lexer_heredoc_middle1
		tokens, states = lex("1\t2\\n3\#{42}4", 
			[HEREDOC.new('EOHTML', false, true)])
		assert_equal(%W|1 \t 2 \\n 3 \#{42} 4|, tokens)
		assert_equal([:heredoc, :heredoc_tab, :heredoc, :heredoc1,
			:heredoc, :heredoc1, :heredoc], states)
	end
	def test_lexer_heredoc_middle2
		tokens, states = lex("1\t2\\n3\#{42}4", 
			[HEREDOC.new('EOHTML', false, false)])
		assert_equal(%W|1 \t 2\\n3\#{42}4|, tokens)
		assert_equal([:heredoc, :heredoc_tab, :heredoc], states)
	end
	def test_lexer_endoffile_decoration1
		tokens, states = lex("\tthe\t\tend", [ENDOFFILE.new])
		assert_equal(%W|\t the \t\t end|, tokens)
		assert_equal([:endoffile_tab, :endoffile, :endoffile_tab,
			:endoffile], states)
	end
	def test_ambiguity_division_regexp1
		tokens, states = lex("a=2 \t/3")
		assert_equal(%W|a = 2 \  \t / 3|, tokens)
		assert_equal([:ident, :punct, :number, :space,
			:tab, :punct, :number], states)
	end
	def test_ambiguity_division_regexp2
		tokens, states = lex("ident/ident")
		assert_equal(%W|ident / ident|, tokens)
		assert_equal([:ident, :punct, :ident], states)
	end
	def test_ambiguity_division_regexp3
		tokens, states = lex("values[3]/value")
		assert_equal(%W|values [ 3 ] / value|, tokens)
		assert_equal([:ident, :punct, :number, :punct, 
			:punct, :ident], states)
	end
	def test_ambiguity_division_regexp4
		tokens, states = lex("log(3)/value")
		assert_equal(%W|log ( 3 ) / value|, tokens)
		assert_equal([:ident, :punct, :number, :punct, 
			:punct, :ident], states)
	end
	def test_ambiguity_division_regexp5
		tokens, states = lex("3.xx/value")
		assert_equal(%W|3 .xx / value|, tokens)
		assert_equal([:number, :dot, :punct, :ident], states)
	end
	def test_ambiguity_division_regexp6
		tokens, states = lex("@xx/value")
		assert_equal(%W|@xx / value|, tokens)
		assert_equal([:ivar, :punct, :ident], states)
	end
	def test_ambiguity_division_regexp7
		tokens, states = lex("@@xx/$value")
		assert_equal(%W|@@xx / $value|, tokens)
		assert_equal([:cvar, :punct, :gvar], states)
	end
	def test_ambiguity_division_regexp8
		tokens, states = lex("$./9.0")
		assert_equal(%W|$. / 9.0|, tokens)
		assert_equal([:gvar, :punct, :number], states)
	end
	def test_ambiguity_division_regexp9
		tokens, states = lex("def /(val)")
		assert_equal(%W|def \  / ( val )|, tokens)
		assert_equal([:keyword, :space, :punct, 
			:punct, :ident, :punct], states)
	end
	def test_ambiguity_division_regexp10
		tokens, states = lex("when /val/")
		assert_equal(%W|when \  /val/|, tokens)
		assert_equal([:keyword, :space, :regexp], states)
	end
	def test_ambiguity_modulo_literal1
		tokens, states = lex("x=3%2")
		assert_equal(%W|x = 3 % 2|, tokens)
		assert_equal([:ident, :punct, :number, :punct, :number], states)
	end
	def test_ambiguity_modulo_literal2
		tokens, states = lex('x="a%ib"%2')
		assert_equal(%W|x = "a%ib" % 2|, tokens)
		assert_equal([:ident, :punct, :string, :punct, :number], states)
	end
	def test_ambiguity_modulo_literal3
		tokens, states = lex('x=value%2')
		assert_equal(%W|x = value % 2|, tokens)
		assert_equal([:ident, :punct, :ident, :punct, :number], states)
	end
	def test_ambiguity_modulo_literal4
		tokens, states = lex('x=fib(17)%4')
		assert_equal(%W|x = fib ( 17 ) % 4|, tokens)
		assert_equal([:ident, :punct, :ident, :punct, 
			:number, :punct, :punct, :number], states)
	end
	def test_ambiguity_modulo_literal5
		tokens, states = lex('x=ary[y]%4')
		assert_equal(%W|x = ary [ y ] % 4|, tokens)
		assert_equal([:ident, :punct, :ident, :punct, 
			:ident, :punct, :punct, :number], states)
	end
	def test_ambiguity_modulo_literal6
		tokens, states = lex('x=y.dot%4')
		assert_equal(%W|x = y .dot % 4|, tokens)
		assert_equal([:ident, :punct, :ident, :dot,
			:punct, :number], states)
	end
	def test_ambiguity_modulo_literal7
		tokens, states = lex('x=%(%s)%"a"')
		assert_equal(%W|x = %(%s) % "a"|, tokens)
		assert_equal([:ident, :punct, :literal, :punct, :string], states)
	end
	def test_ambiguity_modulo_literal8
		tokens, states = lex('@a%2,@@b%2,$c%2')
		assert_equal(%W|@a % 2 , @@b % 2 , $c % 2|, tokens)
		assert_equal([:ivar, :punct, :number, :punct, 
			:cvar, :punct, :number, :punct,
			:gvar, :punct, :number], states)
	end
	def test_ambiguity_modulo_literal9
		tokens, states = lex('eval%{code')
		assert_equal(%W|eval %{code|, tokens)
		assert_equal([:ident, :literal], states)
	end
	def test_ambiguity_modulo_literal10
		tokens, states = lex('val%(2)')
		assert_equal(%W|val % ( 2 )|, tokens)
		assert_equal([:ident, :punct, :punct, :number, :punct], states)
	end
	def test_ambiguity_modulo_literal11
		tokens, states = lex('"%i%i"%[1,2]')
		assert_equal(%W|"%i%i" % [ 1 , 2 ]|, tokens)
		assert_equal([:string, :punct, :punct, :number, :punct,
			:number, :punct], states)
	end
	def test_ambiguity_modulo_literal12
		tokens, states = lex('func%w[1]')
		assert_equal(%W|func %w[1]|, tokens)
		assert_equal([:ident, :literal], states)
	end
	def xtest_ambiguity_questionmark_conditional1
=begin TODO: problem
a cond?if:else can span over multiple lines
I am clueless how to provide good support of
this construction?
=end
		tokens, states = lex('(a==b)?x:y')
		assert_equal(%W|( a = = b ) ? x : y|, tokens)
		assert_equal([:punct, :ident, :punct, :punct, :ident, :punct,
			:punct, :ident, :punct, :ident], states)
	end
	def test_ambiguity_questionmark_conditional2
		tokens, states = lex('(a==b) ? x : y')
		assert_equal(%W|( a == b ) \  ? \  x \  : \  y|, tokens)
		assert_equal([:punct, :ident, :punct,
			:ident, :punct, :space, :punct, :space, :ident, 
			:space, :punct, :space, :ident], states)
	end
	def test_propagate_normal_to_heredoc1
		stack = prop([], "y = <<EOHTML.upcase")
		assert_equal([HEREDOC.new('EOHTML', false)], stack)
	end
	def test_propagate_normal_to_heredoc2
		stack = prop([], "puts <<-eoruby.gsub(/x/,'y')")
		assert_equal([HEREDOC.new('eoruby', true)], stack)
	end
	def test_propagate_normal_to_heredoc3
    stack = prop([], "ary = [<<A, <<-B]\n")
    assert_equal([HEREDOC.new('A', false), 
			HEREDOC.new('B', true)], stack)
	end
	def test_propagate_normal_to_heredoc5
		stack = prop([], "ary = [<<'A', <<-\"B\"]\n")
		assert_equal([HEREDOC.new('A', false, false), 
			HEREDOC.new('B', true, true)], stack)
	end
	def test_propagate_heredoc_to_heredoc1
		stack = [HEREDOC.new('EOHTML', false)]
		expected = stack
		assert_equal(expected, prop(stack, "x += 3\n"))
		assert_equal(expected, prop(stack, "EOIGNORE\n"))
		assert_equal(expected, prop(stack, "EOHTML \n"))
		assert_equal(expected, prop(stack, "LEOHTML\n"))
		assert_equal(expected, prop(stack, "eohtml\n"))
		assert_equal(expected, prop(stack, "\t EOHTML\n"))
	end
	def test_propagate_heredoc_end1
		stack = [HEREDOC.new('EOHTML', false)]
		expected = []
		assert_equal(expected, prop(stack, "EOHTML\n"))
		assert_not_equal(expected, prop(stack, " \tEOHTML\n"))
	end
	def test_propagate_heredoc_end2
		stack = [HEREDOC.new('eoxml', false)]
		expected = []
		assert_equal(expected, prop(stack, "eoxml\n"))
	end
	def test_propagate_heredoc_end3
		stack = [HEREDOC.new('DATA', true)]
		expected = []
		assert_equal(expected, prop(stack, "DATA\n"))
		assert_equal(expected, prop(stack, "\t \t  DATA\n"))
		assert_equal(expected, prop(stack, "DATA\n  ")) # tailspace
	end
	def test_propagate_heredoc_end4
		stack = [HEREDOC.new('A', false), HEREDOC.new('B', true),
			HEREDOC.new('C', true)]
		expected = [HEREDOC.new('B', true), HEREDOC.new('C', true)]
		assert_equal(expected, prop(stack, "A\n"))
	end
	def test_propagate_comment_begin1
		assert_equal([COMMENT.new], prop([], "=begin\n"))
		assert_equal([COMMENT.new], prop([], "=begin hi\n"))
		assert_equal([COMMENT.new], prop([], "=begin endofline"))
	end
	def test_propagate_comment_begin2
		assert_equal([], prop([], "\t =begin\n"))
		assert_equal([], prop([], "=beginx\n"))
		assert_equal([], prop([], "=begin<\n"))
	end
	def test_propagate_comment_end1
		assert_equal([], prop([COMMENT.new], "=end\n"))
		assert_equal([], prop([COMMENT.new], "=end p 42\n"))
	end
	def test_propagate_comment_end2
		assert_equal([COMMENT.new], prop([COMMENT.new], "\t =end\n"))
		assert_equal([COMMENT.new], prop([COMMENT.new], "=end<\n"))
		assert_equal([COMMENT.new], prop([COMMENT.new], "=endx\n"))
	end
	def test_propagate_endoffile_begin1
		assert_equal([ENDOFFILE.new], prop([], "__END__\n"))
	end
	def test_propagate_literal_begin1
		stack = prop([], "42,%w(a(\n")
		assert_equal([LITERAL.new('w', '(', 2)], stack) 
	end
	def test_propagate_literal_begin2
		stack = prop([], "42,%w|abc")
		assert_equal([LITERAL.new('w', '|', 1)], stack) 
	end
	def test_propagate_literal_middle1
		stack = prop([LITERAL.new('q', '(', 2)], "b)c\n")
		assert_equal([LITERAL.new('q', '(', 1)], stack) 
	end
	def test_propagate_literal_middle2
		stack = prop([LITERAL.new('x', '(', 2)], "ab(c")
		assert_equal([LITERAL.new('x', '(', 3)], stack) 
	end
	def test_propagate_literal_middle3
		stack = prop([LITERAL.new('w', '(', 2)], "a(b)c")
		assert_equal([LITERAL.new('w', '(', 2)], stack) 
	end
	def test_propagate_literal_middle4
		stack = prop([LITERAL.new('Q', '(', 2)], "a)b(c")
		assert_equal([LITERAL.new('Q', '(', 2)], stack) 
	end
	def test_propagate_literal_end1
		stack = prop([LITERAL.new('W', '(', 2)], "b)c)\n")
		assert_equal([], stack) 
	end
	def test_propagate_literal_end2
		stack = prop([LITERAL.new('Q', '(', 2)], "b)c) + %w{\\{d{e{\n")
		assert_equal([LITERAL.new('w', '{', 3)], stack) 
	end
	def test_propagate_string_begin1
		stack = prop([], "puts('42,%w(a(\n")
		assert_equal([STRING.new("'")], stack) 
	end
	def test_propagate_string_begin2
		stack = prop([], "puts(\"42,%w(\\\"a(\n")
		assert_equal([STRING.new("\"")], stack) 
	end
	def test_propagate_string_end1
		stack = prop([STRING.new("'")], "bla'.reverse")
		assert_equal([], stack) 
	end
	def test_propagate_string_end2
		stack = prop([STRING.new("'")], "b\\'la'.reverse")
		assert_equal([], stack) 
	end
	def test_propagate_string_end3
		stack = prop([STRING.new("'")], "single' + \"double")
		assert_equal([STRING.new("\"")], stack) 
	end
	def test_propagate_regexp_begin1
		stack = prop([], "re=/(?:")
		assert_equal([STRING.new("/")], stack) 
	end
	def test_propagate_regexp_begin2
		stack = prop([], "re=/(?:\\/")
		assert_equal([STRING.new("/")], stack) 
	end
	def test_propagate_regexp_end1
		# NOTE: regexp are suppose to eat until /x 
		stack = prop([STRING.new("/")], "x*)(.)x/x; p re.source")
		assert_equal([], stack) 
	end
end # class TestLexerRuby






