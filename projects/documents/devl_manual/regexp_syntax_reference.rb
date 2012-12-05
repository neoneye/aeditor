row = <<ROWEND
<row>
	<entry><literal>%</literal></entry>
	<entry>%</entry>
</row>
ROWEND

table = [
	["atom atom", "expr sequence."],
	["expr | expr", "alternation."],
	["atom?", "greedy repeat 0..1."],
	["atom*", "greedy repeat 0..infinity."],
	["atom+", "greedy repeat 1..infinity."],
	["atom{min,}", "greedy repeat min..infinity."],
	["atom{min,max}", "greedy repeat min..max."],
	["atom{min}", "greedy repeat min..min."],
	["atom??", "non-greedy repeat 0..1."],
	["atom*?", "non-greedy repeat 0..infinity."],
	["atom+?", "non-greedy repeat 1..infinity."],
	["atom{min,}?", "non-greedy repeat min..infinity."],
	["atom{min,max}?", "non-greedy repeat min..max."],
	["atom{min}?", "non-greedy repeat min..min."],
	["&bsol;1 .. &bsol;9", "backreference."],
	["( expr )", "group."],
	["(?: expr )", "pure group."],
	["(?= expr )", "positive look ahead."],
	["(?! expr )", "negative look ahead."],
	["(?# ... )", "posix comment."],
	["(?i: expr ), (?-i: expr )", "option-ignorecase=ON. option-ignorecase=OFF. " +
		"Besides i, there are also x=extended, and m=multiline."],
	["(?i), (?-i)", "alternative way to toggle options. ignorecase=ON. ignorecase=OFF."],
	["[ ... ]", "character class."],
	["[^ ... ]", "inverse character class."],
	[".", "match everything, except newline."],
	["&bsol;d", "match digit."],
	["&bsol;D", "match anything else than digit."],
	["&bsol;s", "match space."],
	["&bsol;S", "match anything else than space."],
	["&bsol;w", "match word."],
	["&bsol;W", "match anything else than word."],
	["^", "beginning of line."],
	["$", "end of line."],
	["&bsol;A", "beginning of string."],
	["&bsol;z", "end of string."],
	["&bsol;Z", "end of string, eventually exclude newline."],
	["&bsol;b", "boundary between word-blank."],
	["&bsol;B", "boundary between word-word or blank-blank."],
]

rows = table.map{|(title, desc)| row.sub("%", title).sub("%", desc) }
puts rows.join
