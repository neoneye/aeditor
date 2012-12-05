require 'match_symbol'

# purpose:
# from regex-syntax-tree build NFA (interpreter pattern) 
#    initial state = 0
#    final state = 1000
#
# issues:
# *  assumes that the number of NFA states
#    is less than 1000. If you need more
#    you will have to adjust Context#dest
#    to a more appropriate value.
class Regex2NfaVisitor
	def initialize
		on_new = proc {|h, k| h[k] = []}
		@states = Hash.new(&on_new)
		@n = 0
		@source = 0
		@dest = 1000
		@states[@dest] = []
	end
	attr_reader :states, :source, :dest
	def set_source(state)
		@source = state
	end
	def set_dest(state)
		@dest = state
	end
	def add_transition(src, sym, dst)
		match = Match::Include.new(sym)
		@states[src] << [match, dst]
	end
	def add_transition_epsilon(src, dst)
		@states[src] << [nil, dst]
	end
	def add_transition_exclude(src, syms, dst)
		match = Match::Exclude.new(*syms)
		@states[src] << [match, dst]
	end
	def create_state
		@n += 1
		@n
	end
	def result
		@states.default = nil   # because == operator also compares proc
		@states
	end

	def visit_literal(i)
		add_transition(@source, i.text, @dest)
	end
	def visit_wildcard(i)
		add_transition_exclude(@source, i.symbols, @dest) 
	end
	def visit_sequence(i)
		d = @dest
		s = create_state
		set_dest(s)
		i.expr1.accept(self)
		set_source(s)
		set_dest(d)
		i.expr2.accept(self)
	end
	def visit_alternation(i)
		s1 = create_state
		s2 = create_state
		d = create_state
		add_transition_epsilon(d, @dest) 
		set_dest(d)
		src = @source
		add_transition_epsilon(src, s1) 
		set_source(s1)
		i.expr1.accept(self)
		add_transition_epsilon(src, s2) 
		set_source(s2)
		i.expr2.accept(self)
	end
	def visit_repeat(i)
		s = create_state
		add_transition_epsilon(@source, s) 
		add_transition_epsilon(@source, @dest) 
		set_dest(@source)
		set_source(s)
		i.expr.accept(self)
		# TODO: how to make lazy ?
	end
	def visit_backreference(i)
		# TODO: how should I deal with backref ?
	end
	def visit_group(i)
		i.expr.accept(self)
	end
end
