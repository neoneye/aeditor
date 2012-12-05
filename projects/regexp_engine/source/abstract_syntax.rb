require 'regexp/misc'

module RegexAbstractSyntax
	class Expression
		def inspect
			self.accept(RegexPrettyVisitor.new).join("\n")
		end
	end
	class Literal < Expression
		def initialize(set); @set = set end
		attr_reader :set
		def match(other); @set.member?(other) end
		def accept(visitor); visitor.visit_literal self end
		def ==(other); self.class == other.class and @set == other.set end
		def match_inspect; @set.to_s end
	end
	class Wildcard < Expression
		def initialize(set); @set = set end
		attr_reader :set
		def match(other); not @set.member?(other) end
		def accept(visitor); visitor.visit_wildcard self end
		def ==(other); self.class == other.class and @set == other.set end
		def match_inspect; @set.to_s end
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
		# ignorecase are absurd, but can happen
		# for instance /(ab)((?i)\1)/.match("abAb") -> true
		def initialize(number, ignorecase) 
			@number = number 
			@ignorecase = ignorecase
		end
		attr_reader :number, :ignorecase
		def accept(visitor); visitor.visit_backreference self end
		def ==(other); self.class == other.class and @number == other.number end
	end
	class Group < Expression
		NORMAL=0
		LOOKAHEAD_POSITIVE=1
		LOOKAHEAD_NEGATIVE=2
		LOOKBEHIND_POSITIVE=3
		LOOKBEHIND_NEGATIVE=4
		PURE=5
		ATOMIC=6
		def initialize(group_type, expr) 
			@group_type = group_type
			@expr = expr 
			@register = "unassigned register"
		end
		attr_reader :expr, :register, :group_type

		def accept(visitor); visitor.visit_group self end
		def ==(other) 
			self.class == other.class and 
			@expr == other.expr and
			@group_type == other.group_type
		end
		def set_register(reg); @register = reg end
		def self.mk_group(expr)
			self.new(NORMAL, expr)
		end
		def self.mk_lookahead(expr)
			self.new(LOOKAHEAD_POSITIVE, expr)
		end
		def self.mk_lookahead_negative(expr)
			self.new(LOOKAHEAD_NEGATIVE, expr)
		end
		def self.mk_lookbehind(expr)
			self.new(LOOKBEHIND_POSITIVE, expr)
		end
		def self.mk_lookbehind_negative(expr)
			self.new(LOOKBEHIND_NEGATIVE, expr)
		end
		def self.mk_pure(expr)
			self.new(PURE, expr)
		end
		def self.mk_atomic(expr)
			self.new(ATOMIC, expr)
		end
	end
	class Anchor < Expression
		def initialize(anchor_type) 
			@anchor_type = anchor_type
		end
		attr_reader :anchor_type
		def accept(visitor); visitor.visit_anchor self end
		def ==(other); self.class == other.class and @anchor_type == other.anchor_type end
		def self.mk_begin; self.new(:line_begin) end
		def self.mk_end; self.new(:line_end) end
		def self.mk_string_begin; self.new(:string_begin) end
		def self.mk_string_end; self.new(:string_end) end
		def self.mk_string_end_excl; self.new(:string_end2) end
		def self.mk_word_boundary; self.new(:word_boundary) end
		def self.mk_nonword_boundary; self.new(:nonword_boundary) end
	end

	class CodeBlock < Expression
		def initialize(code) 
			@src = code
			#fix me
			#meed better way to create Proc object
			#and way to access captured subgroups
			@code = eval "proc {#{code}}"
		end
		attr_reader :code, :src
		def match(other)
			raise "Calling match on abstract class"
		end
		def accept(visitor); visitor.visit_codeblock self end
		def ==(other); self.class == other.class and @src == other.src end
		def match_inspect 
			raise "Calling match_inspect on abstract class"
		end
		def self.mk_code_assertion(code)
			CodeAssertion.new(code)
		end
		def self.mk_closure(code)
			Closure.new(code)
		end
		def self.mk_regexp_assertion(code)
			RegexpAssertion.new(code)
		end
	end

	class CodeAssertion < CodeBlock
		def match(other)
			@code.call(other)
		end
		def match_inspect 
			"<(#@src)>"
		end
	end

	class Closure < CodeBlock
		def match(other)
			begin
				@code.call(other)
				return true
			rescue
				return false;
			end
		end
		def match_inspect 
			"{#@src}"
		end
	end

	class RegexpAssertion < CodeBlock
		def match(other)
			regexp = @code.call()
			#parse returned regexp
			#match against other
		end
		def match_inspect 
			"<{#@src}>"
		end
	end
end # module RegexAbstractSyntax

# purpose:
# populate abstract-tree with register id's
class AssignRegistersVisitor
	def initialize
		@register = 0
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
		if i.group_type == RegexAbstractSyntax::Group::NORMAL
			i.set_register(@register)
			@register += 1
		end
		i.expr.accept(self)
	end
	def visit_anchor(i); end
	def visit_codeblock(i); end
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
		if children.size > 0
			children[0..-2].each{|child|
				@last = false
				res += child.accept(self)
			}
			@last = true
			res += children.last.accept(self)
		end
		["+-" + text] + res.map{|s| pad + " " + s }
	end
	def visit_literal(i)
		format_leaf("Inside set=" + i.match_inspect)
	end
	def visit_wildcard(i)
		format_leaf("Outside set=" + i.match_inspect)
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
		str = case i.group_type
		when RegexAbstractSyntax::Group::NORMAL
			"Group capture=#{i.register}"
		when RegexAbstractSyntax::Group::LOOKAHEAD_POSITIVE
			"Lookahead positive"
		when RegexAbstractSyntax::Group::LOOKAHEAD_NEGATIVE
			"Lookahead negative"
		when RegexAbstractSyntax::Group::LOOKBEHIND_POSITIVE
			"Lookbehind positive"
		when RegexAbstractSyntax::Group::LOOKBEHIND_NEGATIVE
			"Lookbehind negative"
		when RegexAbstractSyntax::Group::PURE
			"Group non-capturing"
		when RegexAbstractSyntax::Group::ATOMIC
			"Atomic Group"
		else
			raise "unknown group"
		end
		format_composite(str, [i.expr])
	end
	def visit_anchor(i)
		name = i.anchor_type.to_s
		format_leaf("Anchor #{name}")
	end
end

module RegexFactory
	include RegexAbstractSyntax

	class Error < StandardError; end
	class CannotRepeat < Error; end

	def mk_letter2(letter, ignorecase=false)
		mk_charclass2([letter], ignorecase)
	end
	def mk_charclass2(codepoints, ignorecase=false)
		set = RangeSet.mk_int(codepoints, ignorecase)
		Literal.new(set)
	end
	def mk_charclass_inverse2(codepoints, ignorecase=false)
		set = RangeSet.mk_int(codepoints, ignorecase)
		Wildcard.new(set)
	end
	def mk_letter(letter, ignorecase=false)
		mk_charclass([letter], ignorecase)
	end
	def mk_wide(codepoint)
		set = RangeSet.new([codepoint])
		Literal.new(set)
	end
	def mk_charclass(charinfo, ignorecase=false)
		set = RangeSet.mk_str(charinfo, ignorecase)
		Literal.new(set)
	end
	def mk_charclass_inverse(charinfo, ignorecase=false)
		set = RangeSet.mk_str(charinfo, ignorecase)
		Wildcard.new(set)
	end
	def mk_sequence(*exprs)
		Sequence.new(*exprs)
	end
	def mk_alternation(*exprs)
		Alternation.new(*exprs)
	end
	def mk_repeat(expr, min, max, lazy=false)
		if expr == nil
			raise CannotRepeat, "there is nothing to repeat"
		end
		Repeat.new(expr, min, max, lazy)
	end
	def mk_group(expr)
		Group.mk_group(expr)
	end
	def mk_wild(multiline=false)
		codepoints = multiline ? [] : [SymbolNames::NEWLINE]
		set = RangeSet.new(codepoints)
		Wildcard.new(set)
	end
	def mk_backref(number, ignorecase=false)
		Backreference.new(number, ignorecase)
	end
	def mk_anchor_begin
		Anchor.mk_begin
	end
	def mk_anchor_end
		Anchor.mk_end
	end
	def mk_anchor_string_begin
		Anchor.mk_string_begin
	end
	def mk_anchor_string_end
		Anchor.mk_string_end
	end
	def mk_anchor_string_end_excl
		Anchor.mk_string_end_excl
	end
	def mk_anchor_word_boundary
		Anchor.mk_word_boundary
	end
	def mk_anchor_nonword_boundary
		Anchor.mk_nonword_boundary
	end
	def mk_lookahead(expr)
		Group.mk_lookahead(expr)
	end
	def mk_lookahead_negative(expr)
		Group.mk_lookahead_negative(expr)
	end
	def mk_lookbehind(expr)
		Group.mk_lookbehind(expr)
	end
	def mk_lookbehind_negative(expr)
		Group.mk_lookbehind_negative(expr)
	end
	def mk_group_pure(expr)
		Group.mk_pure(expr)
	end
	def mk_atomic_group(expr)
		Group.mk_atomic(expr)
	end
	def mk_code_assertion(code)
		CodeBlock.mk_code_assertion(code)
	end
	def mk_closure(code)
		CodeBlock.mk_closure(code)
	end
	def mk_regexp_assertion(code)
		CodeBlock.mk_regexp_assertion(code)
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
