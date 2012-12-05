class MatchVisitor
	class Mismatch < StandardError; end
	class Done < StandardError; end
	def initialize(text, position=0)
		@input = text
		@pos = position
		@result = []
	end
	attr_reader :result
	def skip
		@pos += 1
		if @pos >= @input.size
			raise Done
		end
	end
	def visit_literal(i)
		if @input[@pos] != i.text
			raise Mismatch, "literal"
		end
		puts "Literal " + @pos.to_s
		skip
	end
	def visit_wildcard(i)
		if i.symbols.include?(@input[@pos]) != false
			raise Mismatch, "wildcard"
		end
		puts "Wild " + @pos.to_s
		skip
	end
	def visit_sequence(i)
		i.exprs.each{|e| e.accept(self) }
	end
	def visit_alternation(i)
		pos = @pos
		i.exprs.each{|e| 
			begin
				@pos = pos
				e.accept(self) 
				return
			rescue Mismatch
			end
		}
		raise Mismatch, "alternation"
	end
	def visit_repeat(i)
		# TODO: repeat is kinky because if we must
		# do some lookahead to see for instance
		# when we should stop parsing /a.*b/
		raise
	end
	def visit_backreference(i)
		raise
	end
	def visit_group(i)
		#pos = @pos
		i.expr.accept(self)
		#result[i.number] = @input[pos..@pos-1]
	end
end

# goal is to be compatible with Ruby/MatchData class
class RegexMatch
	def initialize(matches)
		@matches = matches
	end
	def to_s
		@matches.first
	end
	def [](index)
		@matches[index]
	end
	def to_a
		@matches
	end
end

class RegexEngine
	def initialize(expression)
		@expr = expression
	end
	def match(text)
		ary_text = text.split(//)
		ary_text.each_index{|index|
			v = MatchVisitor.new(ary_text, index)
			begin
				@expr.accept(v)
				return MatchData.new(v.result)
			rescue MatchVisitor::Done
				return MatchData.new(v.result)
			rescue MatchVisitor::Mismatch
			end
		}
		nil
	end
end

class RegexEngine2
	def initialize(expression)
		@expr = expression
	end
	def match(text)
		nfa = Nfa.new(@expr.nfa_hash)
		dfa = Dfa.new(*nfa.build_dfa)
		input = text.split(//)

		# identify possible beginning of match
		possible_start_places = []
		input.each_with_index do|char, index|
			symbol = dfa.alphabet_hash[char]
			next unless symbol
			next if dfa.alphabet_hash.default != nil and symbol == 0
			state = dfa.next_state[0][symbol]
			next if state == 0
			possible_start_places << index
		end

		# start scanning
		possible_start_places.each do|place|
			state = 0
			last = nil
			input[place..-1].each_with_index{|char, index|
				symbol = dfa.alphabet_hash[char]
				next_state = dfa.next_state[state][symbol]
				if dfa.accepting_states.include?(state)
					last = index
				end
				state = next_state
			}
			if last != nil
				return RegexMatch.new([input[place..last].to_s])
			end
		end
		nil
	end
end
