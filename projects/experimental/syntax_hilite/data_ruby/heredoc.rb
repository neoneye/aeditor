ok = 42

text = <<EOHTML
heredoc line 1  'ignore'
heredoc line 2  "ignore"
heredoc line 3  #{ok+3}
EOHTML

begin
	process = <<-'EODATA'
	heredoc line 1  'ignore'
	heredoc line 2  "ignore"
	heredoc line 3  #{ignore+3}
	EODATA
end

array = %w(a b c) + [1, 2, 3]

p(<<A + <<"B" + <<-C).gsub("\t", '\\')) # fun with heredoc
im heredoc (a)
A
	im heredoc (b)
	can		you		see		tabs?
B
		im heredoc (c)
		C

=begin
multiline comment line 1
multiline comment line 2
=end
$debug = true  # globals are bad bad!

# fun with strings
string = 'ab' + "cd" + %|efg\|| + :hij.to_s
string += "\narray=#{array.inspect} array.size=#{array.size}"
string += "\nfilename=" + $0

__END__
end data line 1
end data line 2
