require 'regexp_senario'

class RepeatShortPattern1 < RegexpSenario
	def initialize
		super(
			"/ab*ba/.match(\"aa\")", 
			%w('a' REP 'b' /REP 'b' 'a'), 
			"aa".split(//)
		)
	end
	def body
		[status(0, 0),
		match('a', "i+=1; r+=1"), 
		status(1, 1),
		reaction("r == RepeatOpen", "r=r.find(RepeatClose)+1"),
		status(1, 4, [[0, [[1, 2, 0, 0]]]]),
		mismatch('a', 'b', "restart at the repeat point; repeat-count+=1"),
		status(1, 2, [[0, [[1, 2, 1, 0]]]]),
		mismatch('a', 'b', "stop (no more repeat is possible)") ]
	end
end

class RepeatShortPattern2 < RegexpSenario
	def initialize
		super(
			"/ab*ba/.match(\"aba\")", 
			%w('a' REP 'b' /REP 'b' 'a'), 
			"aba".split(//)
		)
	end
	def body
		[status(0, 0),
		match('a', "i+=1; r+=1"), 
		status(1, 1),
		reaction("r == RepeatOpen", "r=r.find(RepeatClose)+1"),
		status(1, 4, [[0, [[1, 2, 0, 0]]]]),
		match('b', "i+=1; r+=1"), 
		status(2, 5),
		match('a', "i+=1; r+=1"), 
		status(3, 6),  # the end
		reaction("the end", "restart at the repeat point; repeat-count+=1"),
		status(1, 2, [[0, [[1, 2, 1, 0]]]]),
		match('b', "i+=1; r+=1"), 
		status(2, 3, [[0, [[1, 2, 1, 1]]]]),
		reaction("ignore repeat-close", "r+=1"),
		status(2, 4),
		mismatch('a', 'b', "restart at the repeat point; repeat-count+=1"),
		status(2, 2, [[0, [[1, 2, 2, 0]]]]),
		mismatch('a', 'b', "stop (no more repeat is possible)") ]
	end
end

class RepeatShortPattern3 < RegexpSenario
	def initialize
		super(
			"/ab*ba/.match(\"abba\")", 
			%w('a' REP 'b' /REP 'b' 'a'), 
			"abba".split(//)
		)
	end
	def body
		[status(0, 0),
		match('a', "i+=1; r+=1"), 
		status(1, 1),
		reaction("r == RepeatOpen", "r=r.find(RepeatClose)+1"),
		status(1, 4, [[0, [[1, 2, 0, 0]]]]),
		match('b', "i+=1; r+=1"), 
		status(2, 5),
		mismatch('a', 'b', "restart at the repeat point; repeat-count+=1"),
		status(1, 2, [[0, [[1, 2, 1, 0]]]]),  
		match('b', "i+=1; r+=1"), 
		status(2, 3, [[0, [[1, 2, 1, 1]]]]),
		reaction("ignore repeat-close", "r+=1"),
		status(2, 4),
		match('b', "i+=1; r+=1"), 
		status(3, 5),
		match('a', "i+=1; r+=1"), 
		status(4, 6),
		reaction("the end", "restart at the repeat point; repeat-count+=1"),
		status(1, 2, [[0, [[1, 2, 2, 0]]]]),  
		match('b', "i+=1; r=execute repeat pattern again"), 
		status(2, 2, [[0, [[1, 2, 2, 1]]]]),
		match('b', "i+=1; r+=1 (done with repeating)"), 
		status(3, 3, [[0, [[1, 2, 2, 2]]]]),
		reaction("ignore repeat-close", "r+=1"),
		status(3, 4),
		mismatch('a', 'b', "stop (no more repeat is possible)") ]
	end
end

class RepeatLongPattern1 < RegexpSenario
	def initialize
		super(
			"/(ab)*a/.match(\"aba\")", 
			%w(REP 'a' 'b' /REP 'a'), 
			"aba".split(//)
		)
	end
	def body
		[status(0, 0),
		reaction("r == RepeatOpen", "r=r.find(RepeatClose)+1"),
		status(0, 4, [[0, [[0, 1, 0, 0]]]]),
		match('a', "i+=1; r+=1"), 
		status(1, 5),
		reaction("the end", "restart at the repeat point; repeat-count+=1"),
		status(0, 1, [[0, [[0, 1, 1, 0]]]]),
		match('a', "i+=1; r+=1"), 
		status(1, 2),
		match('b', "i+=1; r+=1"), 
		status(2, 3),
		reaction("ignore repeat-close", "r+=1"),
		status(2, 4, [[0, [[0, 1, 1, 1]]]]),
		match('a', "i+=1; r+=1"), 
		status(3, 5),
		reaction("the end", "restart at the repeat point; repeat-count+=1"),
		status(0, 1, [[0, [[0, 1, 2, 0]]]]),  
		match('a', "i+=1; r+=1"), 
		status(1, 2),
		match('b', "i+=1; r+=1"), 
		status(2, 3),
		reaction("r == RepeatClose", "restart at repeat pattern"),
		status(2, 1, [[0, [[0, 1, 2, 1]]]]),
		match('a', "i+=1; r+=1"), 
		status(3, 2),
		reaction("the end", "stop (no more repeat is possible)") ]
	end
end

class RepeatWildPattern1 < RegexpSenario
	def initialize
		super(
			"/.*a.*b/.match(\"abab\")", 
			%w(REP Any /REP 'a') +
			%w(REP Any /REP 'b'), 
			"abab".split(//)
		)
	end
	def body
		[status(0, 0),
		reaction("r == RepeatOpen", "r=r.find(RepeatClose)+1"),
		status(0, 3, [[0, [[0, 1, 0, 0]]]]),
		match('a', "i+=1; r+=1"), 
		status(1, 4),
		reaction("r == RepeatOpen", "r=r.find(RepeatClose)+1"),
		status(1, 7, [[0, [[0, 1, 0, 0], [1, 5, 0, 0]]]]),
		match('b', "i+=1; r+=1"), 
		status(2, 8),
		reaction("the end", "restart at the repeat point; repeat-count+=1"),
		status(1, 5, [[0, [[0, 1, 0, 0], [1, 5, 1, 0]]]]),
		match('.', "i+=1; r+=1"), 
		status(2, 6),
		reaction("ignore repeat-close", "r+=1"),
		status(2, 7, [[0, [[0, 1, 0, 0], [1, 5, 1, 1]]]]),
		mismatch('a', 'b', "restart at the repeat point; repeat-count+=1"),
		status(1, 5, [[0, [[0, 1, 0, 0], [1, 5, 2, 0]]]]),
		match('.', "i+=1; r=repeat-point"), 
		status(2, 5, [[0, [[0, 1, 0, 0], [1, 5, 2, 1]]]]),
		match('.', "i+=1; done repeating, r+=1"), 
		status(3, 6, [[0, [[0, 1, 0, 0], [1, 5, 2, 2]]]]),
		reaction("ignore repeat-close", "r+=1"),
		status(3, 7),
		match('b', "i+=1; r+=1"), 
		status(4, 8),
		reaction("the end", "not possible to match more with this " +
			"repeat, thus pop repeat element and restart; repeat-count+=1"),
		status(0, 1, [[0, [[0, 1, 1, 0]]]]),
		match('.', "i+=1; done repeating, r+=1"), 
		status(1, 2),
		reaction("ignore repeat-close", "r+=1"),
		status(1, 3, [[0, [[0, 1, 1, 1]]]]),
		mismatch('b', 'a', "restart at the repeat point; repeat-count+=1"),
		status(0, 1, [[0, [[0, 1, 2, 0]]]]),
		match('.', "i+=1; keep repeating"), 
		status(1, 1, [[0, [[0, 1, 2, 1]]]]),
		match('.', "i+=1; done repeating, r+=1"), 
		status(2, 2, [[0, [[0, 1, 2, 2]]]]),
		reaction("ignore repeat-close", "r+=1"),
		status(2, 3),
		match('a', "i+=1; r+=1"), 
		status(3, 4),
		reaction("r == RepeatOpen", "r=r.find(RepeatClose)+1"),
		status(3, 7, [[0, [[0, 1, 2, 0], [3, 5, 0, 0]]]]),
		match('b', "i+=1; r+=1"), 
		status(4, 8),
		reaction("the end", "restart at the repeat point; repeat-count+=1"),
		status(3, 5, [[0, [[0, 1, 2, 0], [3, 5, 1, 0]]]]),
		match('.', "i+=1; r+=1"), 
		status(4, 6, [[0, [[0, 1, 2, 0], [3, 5, 1, 1]]]]),
		reaction("the end", "pop repeat element; repeat-count+=1"),
		status(0, 1, [[0, [[0, 1, 3, 0]]]]),
		match('.', "i+=1; keep repeating"), 
		status(1, 1, [[0, [[0, 1, 3, 1]]]]),
		match('.', "i+=1; keep repeating"), 
		status(2, 1, [[0, [[0, 1, 3, 2]]]]),
		match('.', "i+=1; done repeating, r+=1"), 
		status(3, 2, [[0, [[0, 1, 3, 3]]]]),
		reaction("ignore repeat-close", "r+=1"),
		status(3, 3),
		mismatch('b', 'a', "stop (no more repeat is possible)")]
	end
end

class RepeatWildPattern2 < RegexpSenario
	def initialize
		super(
			"/x((.)*)*x/.match(\"0x1x2x3\")", 
			%w('x' REP GRP REP GRP Any /GRP /REP /GRP /REP 'x'),
			"0x1x2x3".split(//)
		)
	end
	def body
		[status(0, 0),
		mismatch('0', 'x', "try match i+=1"),
		status(1, 0),
		match('x', "i+=1; r+=1"), 
		status(2, 1),
		reaction("r == RepeatOpen", "r=r.find(RepeatClose)+1"),
		status(2, 10, [[0, [[2, 2, 0, 0]]]]),
		mismatch('1', 'x', "repeat-count+=1, restart"),
		status(2, 2, [[0, [[2, 2, 1, 0]]]]),
		reaction("r == GroupOpen", "r+=1"),
		status(2, 3),
		reaction("r == RepeatOpen", "r=r.find(RepeatClose)+1"),
		status(2, 8, [[0, [[2, 2, 1, 0], [2, 4, 0, 0]]]]),
		reaction("r == GroupClose", "r+=1"),
		status(2, 9),
		reaction("r == RepeatClose", "r+=1"),
		status(2, 10),
		mismatch('1', 'x', "repeat-count+=1, restart"),
		status(2, 4, [[0, [[2, 2, 1, 0], [2, 4, 1, 0]]]]),
		reaction("r == GroupOpen", "r+=1"),
		status(2, 5),
		match('.', "i+=1; r+=1"), 
		status(2, 6),
		reaction("r == GroupClose", "r+=1"),
		status(2, 7),
		reaction("r == RepeatClose", "done, repeating, r+=1"),
		status(2, 8, [[0, [[2, 2, 1, 0], [2, 4, 1, 1]]]]),
		reaction("r == GroupClose", "r+=1"),
		status(2, 9),
		reaction("r == RepeatClose", "done, repeating, r+=1"),
		status(2, 10),  # TODO:  should REP#0 increment ?
		# TODO: finish test-run
		mismatch('b', 'a', "stop (no more repeat is possible)")]
	end
end

intro = <<INT
<H2>How to implement repeat?</H2>
<P>A pattern can be matched a minimum+maximum number of times,
where maximum can be infinite, for instance:
The <QUOTE>STAR</QUOTE> operator goes from zero to infinite.
</P>
<P>Left-most-longest.
</P>
INT

short = <<CHP
<H2>A Short Repeating Pattern</H2>
<P>The <TT>/ab*ba/</TT> is an interesting pattern which is 
very inefficient, but demonstrates perfectly the problems of 
finding longest match. It could be optimized to 
<TT>/abb*a/</TT> and would then be much more efficient. 
</P>
CHP

long = <<CHP
<H2>A Longer Repeating Pattern</H2>
<P>TODO
</P>
CHP

wild = <<CHP
<H2>Two repeating patterns with wildcards!</H2>
<P>TODO
</P>
CHP

s1 = RepeatShortPattern1.new
s2 = RepeatShortPattern2.new
s3 = RepeatShortPattern3.new
l1 = RepeatLongPattern1.new  
w1 = RepeatWildPattern1.new
w2 = RepeatWildPattern2.new
document = 
	intro + 
	short + s1.build + s2.build + s3.build + 
	long + l1.build +
	wild + w1.build + w2.build
document.html_save("repeat1", "Regexp with repeating patterns", s1.style)
