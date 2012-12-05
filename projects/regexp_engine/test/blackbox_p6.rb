# purpose:
# functional tests with a bunch of perl6 regexp exercises.

module MatchAnchors
	# ^   string begin
	# $   string end
	# ^^  line begin
	# $$  line end
	def test_anchor_string_begin1
		assert_regex(["a1"], "^ a .", "a1\na2")
	end
	def test_anchor_string_begin2
		assert_regex(nil, "^ a .", "x1\na2")
	end
	def test_anchor_string_end1
		assert_regex(["a2"], "a . $", "a1\na2")
	end
	def test_anchor_string_end2
		assert_regex(nil, "a . $", "a1\nx2")
	end
	def test_anchor_line_begin1
		assert_regex(["a1"], "^^ a .", "a1\na2")
	end
	def test_anchor_line_begin2
		assert_regex(["a2"], "^^ a .", "x1\na2")
	end
	def test_anchor_line_end1
		assert_regex(["a1"], "a . $$", "a1\na2")
	end
	def test_anchor_line_end2
		assert_regex(["a2"], "a . $$", "x1\na2")
	end
end # module MatchAnchors

module MatchWhitespace
	# '\N' match anything except newline
	# '\T' match anything except tab
	# '\ ' match whitespace literal
	# '\s' match whitespace generic
	# '\h' match whitespace horizontal
	# '\v' match whitespace vertical
	# <sp> match whitespace explicit
	def test_match_whitespace_literal1
		assert_regex(["a a"], 'a \  a', "xa ax")
	end
	def test_match_whitespace_literal2
		assert_regex(nil, 'a \  a', "xa\tax")
	end
	def test_match_whitespace_literal3
		assert_regex(["a a"], "a <' '> a", "xa\ta ax")
	end
	def test_match_whitespace_generic1
		assert_regex(["a \t a"], 'a \s+ a', "xa \t ax")
	end
	def test_match_whitespace_horizontal1
		assert_regex(["a \t a"], 'a \h+ a', "xa \t ax")
	end
	def test_match_whitespace_horizontal2
		# verticaltab = "\v",  formfeed = "\f"
		assert_regex(nil, 'a \h+ a', "xa\v\fax")
	end
	def test_match_whitespace_vertical1
		# \r is considered vertical even though it theoretically moves the carriage sideways.
		assert_regex(["a\ra"], 'a \v+ a', "xa\rax")
	end
	def test_match_whitespace_vertical2
		assert_regex(nil, 'a \v+ a', "xa ax")
	end
	def test_match_whitespace_explicit1
		assert_regex(["a a"], 'a <sp> a', "xa\ta ax")
	end
	def test_match_whitespace_implicit1
		# TODO: don't understand this.. I guess ':w' is an option
		assert_regex(["a a"], ':w a a', "xa\ta ax")
	end
	def test_match_whitespace_hex1
		assert_regex([" y"], '\x20 .', "x y z")
	end
	def test_match_whitespace_hex2
		assert_regex([" 0"], '\x[20]0', "x y 0 z")
	end
	def test_match_whitespace_octal1
		assert_regex([" y"], '\040 .', "x y z")
	end
	def test_match_whitespace_octal2
		assert_regex([" 0"], '\0[40]0', "x y 0 x")
	end
	def test_invmatch_newline1
		assert_regex(["axa"], "a \N a", "a\naxa")
	end
	def test_invmatch_tab1
		assert_regex(["axa"], "a \T a", "a\taxa")
	end
	def test_invmatch_whitespace_hex1
		assert_regex(["bb"], '\X20 b', "ru bby")
	end
end # module MatchWhitespace

module MatchMisc
	# { ... }   code assertion
	# $string   literal
	# <n,m>     repeat-range
	# $1..$9    backref
	# <! .. >   negate assertion
	def test_option_exteded1
		assert_regex(["aa"], "a \n a", "baab")
	end
	def test_dollar_literal1
		# TODO: don't understand this.. I guess dollar isn't endofstring here (dual meaning?)
		assert_regex(["axy"], "a $xy", "baaxyb")
	end
	def test_code1
		# TODO: fill in some code
		# <name>
		# <Other::name>
		# <$var>
		# <*builtinrule>
		# <{ ... }>
		# <( ... )>
		# <name(expr)>
		# .pos are the current input-position
		assert_regex(["aa"], "a { p 'hello' } a", "abaaba")
	end
	def test_match_alpha1
		assert_regex(["aia"], "a <alpha> a", "la1aial")
	end
	def test_match_digit1
		assert_regex(["a1a"], "a <digit> a", "laia1al")
	end
	def test_match_alphadigit1
		assert_regex(["ai1a"], "a <<alpha><digit>>+ a", "la-ai1a=al")
	end
	def test_match_class1
		assert_regex(["ruby"], "r <[ub]>+ y", "perl ruby lisp")
	end
	def test_match_class2
		assert_regex(["rbuy"], "r <[ub]>+ y", "prel rbuy lsip")
	end
	# TODO: exercise indirect repeat count <$n,$m>  
	def test_repeat_range1
		assert_regex(nil, "u b<2,3> y", "arubyr")
	end
	def test_repeat_range2
		assert_regex(["rubby"], "u b<2,3> y", "arubbyr")
	end
	def test_repeat_range3
		assert_regex(["rubbby"], "u b<2,3> y", "arubbbyr")
	end
	def test_repeat_range4
		assert_regex(nil, "u b<2,3> y", "arubbbbyr")
	end
	def test_repeat_range5
		assert_regex(["rubby"], "u b<2> y", "arubbyr")
	end
	def test_repeat_range6
		assert_regex(nil, "u b<2> y", "arubyr")
	end
	def test_repeat_range7
		assert_regex(["rubby"], "u b<2,> y", "arubbyr")
	end
	def test_repeat_range8
		assert_regex(["rubbbby"], "u b<2,> y", "arubbbbyr")
	end
	# TODO: exercise backtracking control (colon)
	# TODO: bind name to atom   name := pattern
	# TODO: the :c points at last position
	# TODO: match literal with \q[string]
	# TODO: <english>  <danish> 
	# TODO: property
	# TODO: level of unicode support,  :u0 :u1 :u2 :u3 ...  control behavier of <dot>
	# TODO: p5 compatibility with perl5 modifier
	# TODO: epsilon transistions is no longer allowed in alternations.. use <null> or <prior>
	# TODO: positive lookahead  <after ...>
	# TODO: negative lookahead  <!after ...>
	# TODO: positive lookbehind <before ...>
	# TODO: negative lookbehind <!before ...>
	# TODO: no backtracking     [ ... ]:   
	# TODO: commit              ::    or   <commit>
	# TODO: colons              :::   or   ::::  
	# TODO: conditionals        [ cond :: yes | no ]
	# TODO: <self> token
	def test_option_ignorecase1
		assert_regex(["latex"], ":i LaTeX", "alatexas")
	end
	def test_option_ignorecase2
		assert_regex(["lOHi"], ":ignorecase lo HI", "hellOHiHey")
	end
	def test_option_ignorecase3
		assert_regex(["Ruby"], "[:i r] uby", "CsharpThruByeWelcomeRuby")
	end
	def test_negate_assertion_whitespace1
		assert_regex(["ala"], "a <!sp> a", "a ala")
	end
	def test_negate_assertion_range1
		assert_regex(["axa"], "a x<!2,3> a", "axxaxala")
	end
	def test_negate_assertion_range2
		assert_regex(["axxxxa"], "a x<!2,3> a", "axxxaxxxxala")
	end
	def test_backref1
		assert_regex(["-a-", "-"], "(.) a $1", "<a-a-a>")
	end
	def test_match_alarm1
		assert_regex(["a\aa"], 'a \c[BEL] a', "a<a\aa>a")
	end
	def test_invmatch_alarm1
		assert_regex(["a<a"], 'a \C[BEL] a', "a<a\aa>a")
	end
	def test_null_assertion1
		assert_regex(["yz"], '[y|<null>]z', "xyz")
	end
	def test_null_assertion2
		assert_regex(["z"], '[<null>|y]z', "xyz")
	end
	def test_null_assertion3
		assert_regex(["xyz"], 'x[<null>|y]z', "xyz")
	end
	def test_set_aritmetic1
		assert_regex(["xbx"], "x <<digig>+<alpha>-<['a']>> x", "xax-xbx")
	end
	def test_capture_string1
		# TODO: check that the string named 'name' contains ' xb'
		assert_regex([" xb"], '$name := (\s* \S*)', "xa xb xc")
	end
	def test_capture_hash1
		# TODO: check that the hash named 'name' contains {'x'=>'a', 'y'=>'b', 'z'=>'c'}
		assert_regex(["x a y b z c"], '%name := [ (\S+)\: \s* (.*) ]*', "x a y b z c")
	end
	def test_empty_choice1
		# empty alternations is not allowed, use <null> instead
		assert_regexp_fail('a|b|')
	end
	def test_token_fail1
		assert_regexp(nil, 'ab<fail>', "xabx")
	end
	def test_interpolate_array_as_alternation1
		ary = %w(aa bb cc)
		assert_regex(["aaccbbcc"], "@ary+", "xaxaaccbbccx")
	end
	def test_token_dot1
		assert_regex(["xax"], "x <dot> x", "yaxaxbx")
	end
	def test_token_lt1
		assert_regex(["x<x"], "x <lt> x", "yax<x>x")
	end
	def test_token_gt1
		assert_regex(["x>x"], "x <gt> x", "yax<x>x")
	end
end # module MatchMisc
