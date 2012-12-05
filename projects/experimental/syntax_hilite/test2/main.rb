require 'iterator'

class Hash
	def store_keys(keys, value)
		keys.each {|key| self[key] = value }
	end
end

# comment
KEYWORDS = %w(alias and begin BEGIN break case class def) +
	%w(defined? do else elsif end END ensure for if loop) +
	%w(module next nil not or raise redo require rescue) +
	%w(retry return self super then true false undef) +
	%w(unless until yield when while)

hash = {}
hash.store_keys(KEYWORDS, 3)
$token2code = hash

token_pattern = '(?x) \s+ | \w+ | .'
$token_re = Regexp.new(token_pattern)


def lex(line_string)
	token_array = line_string.scan($token_re)
	tokens = token_array.create_iterator
	state = :normal
	color = 0
	colors = []
	while tokens.has_next?
		token = tokens.current
		case state
		when :normal
			color = $token2code[token]
			unless color
				case token
				when '\''
					state = :string1
					color = 2
				when '"'
					state = :string2
					color = 2
				when '#'
					state = :comment
					color = 1
				when ':'
					tokens.next
					color = 2
					if tokens.has_next?
						colors << color
						token = tokens.current
					end
				else
					color = 0
				end
			end
		when :comment
			color = 1
		when :string1
			color = 4
			case token
			when '\\'
				tokens.next
				if tokens.has_next?
					colors << color
					token = tokens.current
				end
			when "'"
				color = 2
				state = :normal
			end
		when :string2
			color = 4
			case token
			when '\\'
				tokens.next
				if tokens.has_next?
					colors << color
					token = tokens.current
				end
			when '"'
				color = 2
				state = :normal
			end
		end
		tokens.next
		colors << color
	end
	colors.zip(token_array)
end

# purpose:
# benchmark how fast we can do relexing
#100.times do
	lines = IO.readlines(__FILE__)

	lines.each do |line|
		p lex(line)
	end
#end

