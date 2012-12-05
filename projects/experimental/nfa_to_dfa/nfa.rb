require 'match_symbol'

# purpose:
# Non-deterministic Finite Automata
#
# constraints:
# * wildcards; there can maximum be one MatchExclusive
#   per state. It does'nt make sense to have more.
# * nfa_hash[0] must be the starting state
# * nfa_hash[x] = [] identifies an accepting state
# * nfa_hash[source] = [[symbol, dest], ...]
# * if symbol == nil then its an epsilon transition
class Nfa
	def initialize(nfa_hash)
		@nfa_hash = nfa_hash

		# build alphabet
		symbols = []
		wild = []
		@nfa_hash.each{|k, v| 
			v.each{|match, dst| 
				next unless match
				symbols |= match.symbols
				wild |= [nil] if match.kind_of?(Match::Exclude) 
			} 
		}
		@alphabet = wild + symbols.sort

		# identify accepting_states
		res = []
		@nfa_hash.each{|k, v| res << k if v.empty? }
		@astates = res.uniq.sort
	end
	attr_reader :nfa_hash, :alphabet
	def accepting_states; @astates end
	def ==(other)
		nfa_hash == other.nfa_hash
	end
	def fixed_point_iteration(states)
		res = []
		states.each{|src|
			@nfa_hash[src].each{|sym, dst|
				res << dst if sym == nil  # epsilon transition
			}
		}
		(res | states).uniq.sort
	end
	def e_closure(states)
		# iterate until reaching a fixed-point
		#
		# A set is _closed_ under an operation if,
		# whenever the operation is applied to 
		# members of the set, the result is also a 
		# member of the set.
		#
		# the fixed_point_iteration method is
		# distributive:  F(X u Y) = F(X) u F(Y)
		# knowing this we can optimize this routine
		# so we only do fixed_point_iteration on
		# the newly arrived elements.  see the: 
		# work-list algorithm on page 32 in BoCD
		last = []
		until last == states 
			last = states
			states = fixed_point_iteration(states)
		end
		states
	end
	def move(states, symbol)
		res = []
		states.each{|src|
			@nfa_hash[src].each{|match, dst| 
				next if match == nil
				next unless match.is_member?(symbol)
				res << dst 
			}
		}
		e_closure(res)
	end
	def build_dfa    # see page 33 in BoCD
		current = [e_closure([0])]  # initial state = 0
		pos = 0
		next_state = []
		alphabet = @alphabet
		# subset construction
		while pos < current.size
			next_state[pos] = alphabet.map{|symbol|
				dests = move(current[pos], symbol)
				current << dests unless current.include?(dests)
				current.index(dests)
			}
			pos += 1
		end
		# identify accepting states in DFA
		astates = []
		current.each_with_index{|states, i| 
			astates << i unless (@astates & states).empty? 
		}
		[next_state, alphabet, astates]
	end
end
