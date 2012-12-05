require 'modul'

puts "begin"

test = Test::Test.new
=begin
I'm a comment
=end
3.times { |i|
	3.times { |j|
		# I'm a comment in an active area
		puts "abe #{i} #{j}"
	}
	if false
		# I'm a comment in an inactive area
		puts "should not happen"
	end
	puts "row"
}

puts test.value

puts "end"
