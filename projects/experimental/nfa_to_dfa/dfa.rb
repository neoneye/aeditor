# purpose:
# Deterministec Finite Automata
#
# constraints:
# *  initial state must be 0.
# *  a 'nil' in alphabet means wildcard.
class Dfa
	def initialize(next_state, alphabet, accepting_states)
		@next_state = next_state
		@alphabet = alphabet
		@accepting_states = accepting_states
	end
	attr_reader :next_state, :alphabet, :accepting_states
	def Dfa.build_from_hash(dfa_hash, accepting_states)
		# build alphabet
		syms = []
		dfa_hash.each{|k, v| v.each{|sym, dst| syms << sym } }
		alphabet = syms.compact.uniq.sort

		# build next_state array
		ary = []
		dfa_hash.each{|k, v|
			dests = {}
			v.each{|sym, dst| dests[sym] = dst}
			row = alphabet.map{|i| dests[i]}
			ary[k] = row
		}
		Dfa.new(ary, alphabet, accepting_states)
	end
	def minimize
		Dfa.build_from_hash(*DfaMini.build(self))
	end
	def alphabet_hash
		res = {}
		@alphabet.each_with_index{|sym, i| 
			unless sym
				res.default = i
			else
				res[sym] = i
			end
		}
		res
	end
end

# purpose:
# do minimization of a DFA
#
# functions:
# * uses a naive algorithm, worst-case = O(n^2).
#   The routine is descriped in BoCD at page 38.
#   There exists other algoriths which has O(n*log(n)).
#
# issues:
# * [input] avoid dead-states.
# * [input] avoid undefined transistions.
class DfaMini
	def initialize(dfa)
		g1 = dfa.accepting_states
		g2 = []
		@next_state = dfa.next_state
		@next_state.each_with_index{|state, i|
			next if g1.include?(i)
			ok = false
			state.each{|x| ok = true if x != nil}
			g2 << i if ok
		}
		@groups = [g1.sort, g2.sort]
		@pos = 0
	end
	attr_reader :groups, :pos
	def DfaMini.build(dfa)
		i = DfaMini.new(dfa)
		i.calculate
		# I cannot build the new DFA, even though
		# I have calculated the result, which
		# states that will survive. What I don't 
		# understand is where do I get the
		# state transition information for those
		# new states ?  BoCD does'nt say anything
		# about this. 
		# TODO: build transition hash.
		[{}, []]
	end
	def calculate
		until @pos >= @groups.size
			group = @groups[@pos]
			if group.empty?
				@pos += 1
				next 
			end
			table = build_consistency_table(group)
			extra_groups = DfaMini.split(table)
			if extra_groups.size > 1
				@groups[@pos] = []
				@groups += extra_groups
				@pos = 0
			else
				@pos += 1
			end
		end
	end
	def result
		res = []
		@groups.each_with_index{|group, i|
			res << i unless group.empty?
		}
		res
	end
	def DfaMini.split(table)
		on_new = proc {|h, k| h[k] = []}
		reverse_table = Hash.new(&on_new)
		table.each{|k, v| reverse_table[v] << k }
		res = []
		reverse_table.each{|k, v| res << v.sort }
		res.sort{|x,y| y.size <=> x.size }
	end
	def build_consistency_table(states)
		table = {}
		states.each{|src|
			table[src] = @next_state[src].map{|dest| 
				# find out which marked/unmarked group 'dest' belong to
				group = nil
				@groups.each_with_index{|g, i|
					group = i if g.include?(dest)
				}
				group 
			}
		}
		table
	end
end
