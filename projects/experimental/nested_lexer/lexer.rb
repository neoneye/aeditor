module Lexer

class Base
	MODE_NORMAL = 0
	PREALLOC = 1000
	def initialize
		@tokens = Array.new(PREALLOC, 0)
		@token_count = 0
	end
	attr_reader :tokens, :token_count
	def tokenize(text, max_position=nil)
		@tokens[0] = text.size
		@token_count = 1
	end
end

end # module Lexer

module HTML

class Lexer < Lexer::Base
	def initialize
		super()
	end
	TOKENS = [
		# comments
		'<!--.*?-->',
		
		# embedded stuff
		%q{<script(?:\s+\w+=(?:"[^"]*"|'[^']*'))*\s*>.*?</script>},

		# entities
		'&[[:alpha:]]+;',
		'&#\d+;',

		# open tag with attributes
		%q{<\w+(?:\s+\w+=(?:"[^"]*"|'[^']*'))*\s*>},

		# catch all
		'<[^<>]+?>'
	]
	TOKENIZER = Regexp.new(
		TOKENS.join("|"), 
		Regexp::MULTILINE | (2 << 5)  # enable UTF-8 encoding
	)
	def tokenize(text, max_position=nil)
		max_position ||= text.size + 1
		i = 0
		result = @tokens
		last = 0
		text.scan(TOKENIZER) do
			p1 = $~.begin(0)
			break if p1 > max_position
			if p1 > last
				result[i] = p1 - last
				i += 1
			end
			p2 = $~.end(0)
			result[i] = p2 - p1
			i += 1
			last = p2
		end
		if last < text.size
			result[i] = text.size - last
			i += 1
		end
		@token_count = i
		result
	end
end # class Lexer

end # module HTML

if $0 == __FILE__
	if ARGV.size != 1
		raise "a file must be supplied"
	end
	filename = ARGV[0]
	lexer = nil
	case filename
	when /.htm/
		lexer = HTML::Lexer.new
	else
		raise "don't know how to process your file"
	end
	str = IO.read(filename)
	lexer.tokenize(str)
	pos = 0
	lexer.tokens.first(lexer.token_count).each_with_index do |token, i|
		t = str[pos, token]
		puts ("%5i " % i) + t.inspect[1..-2]
		pos += token
	end
end