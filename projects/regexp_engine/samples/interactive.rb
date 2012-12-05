# PURPOSE:
#
#  try perl5 style regexp interactively.
#
#
#
# USAGE:
#
#  server> ruby interactive.rb "a(a|b|c)+" daccbad
#  d<<accba>>d
#  ["accba", "a"]
#  server>
#
require 'regexp'
#include AE
$debug = $DEBUG # -d enables debugging
if !ARGV[0]
	puts "Syntax is: interactive <regex> <string>"
	puts "defaulting to '((ab)*x)'+ for <regex>"
end
if !ARGV[1]
	puts "defaulting to '0ababxx1' for <string>"
end
puts

regexp = NewRegexp.new(ARGV[0] || "((ab)*x)+")
puts regexp.tree
result = regexp.match(ARGV[1] || "0ababxx1")
if result
	puts result.pre_match + "<<" + result.to_s + ">>" + result.post_match
	p result.to_a
else
	puts "NO MATCH: regexp does not match string."
end
