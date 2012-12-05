module RegexAbstractSyntax
	class Expression
		def inspect
			self.accept(RegexPrettyVisitor.new).join("\n")
		end
	end
	class Literal < Expression
		def initialize(text); @text = text end
		attr_reader :text
		def match(other); @text == other end
		def accept(visitor); visitor.visit_literal self end
		def ==(other); self.class == other.class and @text == other.text end
		def match_inspect; @text.inspect end
	end
	class Wildcard < Expression
		def initialize(symbols = nil)
			symbols ||= ["\n"]
			@symbols = symbols
		end
		attr_reader :symbols
		def match(other); not @symbols.include?(other) end
		def accept(visitor); visitor.visit_wildcard self end
		def ==(other); self.class == other.class and @symbols == other.symbols end
		def match_inspect; "NOT" + @symbols.inspect end
	end
	class Sequence < Expression
		def initialize(*exprs); @exprs = exprs end
		attr_reader :exprs
		def accept(visitor)
			visitor.visit_sequence self
		end
		def ==(other); self.class == other.class and @exprs == other.exprs end
	end
	class Alternation < Expression
		def initialize(*exprs); @exprs = exprs end
		attr_reader :exprs
		def accept(visitor)
			visitor.visit_alternation self
		end
		def ==(other); self.class == other.class and @exprs == other.exprs end
	end
	class Repeat < Expression
		def initialize(expr, min, max, lazy=false) 
			@expr, @lazy = expr, lazy 
			@min, @max = min, max
		end
		attr_reader :expr, :lazy, :min, :max
		def accept(visitor); visitor.visit_repeat self end
		def ==(other) 
			self.class == other.class and 
			@expr == other.expr and
			@lazy == other.lazy and
			@min == other.min and
			@max == other.max
		end
	end
	class Backreference < Expression
		def initialize(number); @number = number end
		attr_reader :number
		def accept(visitor); visitor.visit_backreference self end
		def ==(other); self.class == other.class and @number == other.number end
	end
	class Group < Expression
		def initialize(expr) 
			@expr = expr 
			@register = "unassigned register"
		end
		attr_reader :expr, :register
		def accept(visitor); visitor.visit_group self end
		def ==(other); self.class == other.class and @expr == other.expr end
		def set_register(reg); @register = reg end
	end
end

# purpose:
# populate abstract-tree with register id's
class AssignRegistersVisitor
	def initialize
		@register = 1
	end
	attr_reader :register
	def visit_literal(i); end
	def visit_wildcard(i); end
	def visit_sequence(i)
		i.exprs.each{|expr| expr.accept(self) }
	end
	def visit_alternation(i)
		i.exprs.each{|expr| expr.accept(self) }
	end
	def visit_repeat(i)
		i.expr.accept(self)
	end
	def visit_backreference(i); end
	def visit_group(i)
		i.set_register(@register)
		@register += 1
		i.expr.accept(self)
	end
end

class RegexPrettyVisitor
	def initialize
		@last = true
	end
	def format_leaf(text)
		["+-" + text]
	end
	def format_composite(text, children)
		pad = @last ? " " : "|"
		res = []
		children[0..-2].each{|child|
			@last = false
			res += child.accept(self)
		}
		@last = true
		res += children.last.accept(self)
		["+-" + text] + res.map{|s| pad + " " + s }
	end
	def visit_literal(i)
		format_leaf("Literal " + i.text.inspect)
	end
	def visit_wildcard(i)
		format_leaf("Wildcard " + i.symbols.map{|v|v.inspect}.join(", "))
	end
	def visit_sequence(i)
		format_composite("Sequence", i.exprs)
	end
	def visit_alternation(i)
		format_composite("Alternation", i.exprs)
	end
	def visit_repeat(i)
		kind = i.lazy ? "lazy" : "greedy"
		kind += "{#{i.min},#{i.max}}"
		format_composite("Repeat #{kind}", [i.expr])
	end
	def visit_backreference(i)
		format_leaf("Backref " + i.number.to_s)
	end
	def visit_group(i)
		format_composite("Group register=#{i.register} ", [i.expr])
	end
end

module RegexFactory
	class Error < StandardError; end
	class CannotRepeat < Error; end

	def mk_letter(letter)
		RegexAbstractSyntax::Literal.new(letter)
	end
	def mk_sequence(*exprs)
		RegexAbstractSyntax::Sequence.new(*exprs)
	end
	def mk_alternation(*exprs)
		RegexAbstractSyntax::Alternation.new(*exprs)
	end
	def mk_repeat(expr, min, max, lazy=false)
		if expr == nil
			raise CannotRepeat, "there is nothing to repeat"
		end
		RegexAbstractSyntax::Repeat.new(expr, min, max, lazy)
	end
	def mk_group(expr)
		RegexAbstractSyntax::Group.new(expr)
	end
	def mk_wild
		RegexAbstractSyntax::Wildcard.new
	end
	def mk_backref(number)
		RegexAbstractSyntax::Backreference.new(number)
	end
end # module RegexFactory

if $0 == __FILE__
	include RegexFactory
	x = mk_letter('X')
	y = mk_letter('Y')
	grp = mk_group(mk_alternation(x, y))
	rep = mk_repeat(mk_wild, 0, -1)
	p mk_sequence(grp, rep, mk_backref(1))
end
