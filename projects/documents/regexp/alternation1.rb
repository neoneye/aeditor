require 'regexp_senario'

class AlternationPattern1 < RegexpSenario
	def initialize
		super(
			"/a(b|c)d/.match(\"acd\")", 
			%w('a' ALT PAT 'b' /PAT) +
			%w(PAT 'c' /PAT /ALT 'd'), 
			"acd".split(//)
		)
	end
	def body
		[status(0, 0),
		match('a', "i+=1; r+=1"), 
		status(1, 1),
		reaction("r == AlternationOpen", "r=r.find(PatternOpen)+1; alt.push(i)"),
		status(1, 3, [[1, []]]),
		mismatch('c', 'b', "try next alternation, r=r.find(PatternOpen)+1; i=alt[-1]"),
		status(1, 6),
		match('c', "i+=1; r+=1"), 
		status(2, 7),
		reaction("r == PatternClose", "r=r.find(AlternationClose)+1; alt.pop"),
		status(2, 9, []),
		match('d', "i+=1; r+=1"), 
		status(3, 10),
		reaction("the end", "nothing more to do")]
	end
end

class AlternationPattern2 < RegexpSenario
	def initialize
		super(
			"/a(bc|bd)e/.match(\"abde\")", 
			%w('a' ALT PAT 'b' 'c' /PAT) +
			%w(PAT 'b' 'd' /PAT /ALT 'e'), 
			"abde".split(//)
		)
	end
	def body
		[status(0, 0),
		match('a', "i+=1; r+=1"), 
		status(1, 1),
		reaction("r == AlternationOpen", "r=r.find(PatternOpen)+1; alt.push(i)"),
		status(1, 3, [[1, []]]),
		match('b', "i+=1; r+=1"), 
		status(2, 4),
		mismatch('d', 'c', "try next alternation, r=r.find(PatternOpen)+1; i = alt[-1]"),
		status(1, 7),
		match('b', "i+=1; r+=1"), 
		status(2, 8),
		match('d', "i+=1; r+=1"), 
		status(3, 9),
		reaction("r == PatternClose", "r=r.find(AlternationClose)+1; alt.pop"),
		status(3, 11, []),
		match('e', "i+=1; r+=1"), 
		status(4, 12),
		reaction("the end", "nothing more to do")]
	end
end

class AlternationPattern3 < RegexpSenario
	def initialize
		super(
			"/a(bc|b(d|e))f/.match(\"abef\")", 
			%w('a' ALT PAT 'b' 'c' /PAT) +
			%w(PAT 'b') +
			%w(ALT PAT 'd' /PAT) +
			%w(PAT 'e' /PAT /ALT) +
			%w(/ALT 'e'), 
			"abef".split(//)
		)
	end
	def body
		[status(0, 0),
		match('a', "i+=1; r+=1"), 
		status(1, 1),
		reaction("r == AlternationOpen", "r=r.find(PatternOpen)+1; alt.push(i)"),
		status(1, 3, [[1, []]]),
		match('b', "i+=1; r+=1"), 
		status(2, 4),
		mismatch('e', 'c', "try next alternation, r=r.find(PatternOpen)+1; i = alt[-1]"),
		status(1, 7),
		match('b', "i+=1; r+=1"), 
		status(2, 8),
		reaction("r == AlternationOpen", "r=r.find(PatternOpen)+1; alt.push(i)"),
		status(2, 10, [[1, []], [2, []]]),
		mismatch('e', 'd', "try next alternation, r=r.find(PatternOpen)+1; i = alt[-1]"),
		status(2, 13),
		match('e', "i+=1; r+=1"), 
		status(3, 14),
		reaction("r == PatternClose", "r=r.find(AlternationClose)+1; alt.pop"),
		status(3, 16, [[1, []]]),
		reaction("r == AlternationClose", "r+=1; alt.pop"),
		status(3, 17, []),
		match('e', "i+=1; r+=1"), 
		status(4, 18),
		reaction("the end", "nothing more to do")]
	end
end

class AlternationPattern4 < RegexpSenario
	def initialize
		super(
			"/a(b*|bc)d/.match(\"abcd\")", 
			%w('a' ALT PAT REP 'b' /REP /PAT) +
			%w(PAT 'b' 'c' /PAT /ALT 'd'),
			"abcd".split(//)
		)
	end
	def body
		[status(0, 0),
		match('a', "i+=1; r+=1"), 
		status(1, 1),
		reaction("r == AlternationOpen", "r=r.find(PatternOpen)+1; alt.push(i)"),
		status(1, 3, [[1, []]]),
		reaction("r == RepeatOpen", "r=r.find(RepeatClose)+1"),
		status(1, 6, [[1, [[1, 4, 0, 0]]]]),
		# leasson: don't pop on alternationclose !!
		reaction("r == PatternClose", "r=r.find(AlternationClose)+1"),
		status(1, 12),
		mismatch('b', 'd', "restart at the repeat point; repeat-count+=1"),
		status(1, 4, [[1, [[1, 4, 1, 0]]]]),  
		match('b', "i+=1; r+=1"), 
		status(2, 5),
		reaction("r == RepeatClose", "stack[-1].cnt += 1; r+=1"),
		status(2, 6, [[1, [[1, 4, 1, 1]]]]),
		reaction("r == PatternClose", "r=r.find(AlternationClose)+1"),
		status(2, 12),
		mismatch('c', 'd', "restart at the repeat point; repeat-count+=1"),
		status(1, 4, [[1, [[1, 4, 2, 0]]]]), 
		match('b', "i+=1; r+=1"), 
		status(2, 5),
		reaction("r == RepeatClose", "stack[-1].cnt += 1; restart at repeat point"),
		status(2, 4, [[1, [[1, 4, 2, 1]]]]), 
		# leasson: pop off repeat
		mismatch('c', 'b', "stop (no more repeat is possible); pop off repeats; try next pattern"),
		status(1, 8, [[1, []]]),  
		match('b', "i+=1; r+=1"), 
		status(2, 9),  
		match('c', "i+=1; r+=1"), 
		status(3, 10),  
		reaction("r == PatternClose", "r=r.find(AlternationClose)+1; alt.pop"),
		status(3, 12, []),
		match('d', "i+=1; r+=1"), 
		status(4, 13),
		reaction("the end", "nothing more to do")]
	end
end

intro = <<INT
<H2>How to implement alternation?</H2>
<P>A stack of <TT>input-positions</TT> seems to be necessary, 
in order to deal with nested alternations. It seems to me
that either this <TT>alternation-stack</TT> has to be pushed on the
<TT>repeat-stack</TT> or perhaps the opposite way around.
</P>
<P>Conclusion: The <TT>repeat-stack</TT> must be pushed on 
the <TT>alternation-stack</TT>.. This way we can easily 
recover from a mismatch (flush eventual repeats from the
mismatching pattern) and proceede with next pattern.
</P>
<UL>
<LI>What if I mix Alternation and Repeat.. is the current
concept of 2 stacks sufficiently ?</LI>
<LI>If mismatch occur within a different scope, It can
be necessary to skip over multiple <TT>AlternationClose</TT> tags.
Construct a senario which demonstrates this.</LI>
</UL>
INT

alt = <<CHP
<H2>Alternation</H2>
<P>Note that parentesis is used, but not yielding any groups.
</P>
CHP

s1 = AlternationPattern1.new
s2 = AlternationPattern2.new
s3 = AlternationPattern3.new
s4 = AlternationPattern4.new
document = 
	intro + 
	alt + s1.build + s2.build + s3.build + s4.build 
document.html_save("alternation1", "Regexp with alternating patterns", s1.style)
