class Composite
	def initialize(text)
		@text = text
		@left = nil
		@right = nil
	end
	attr_reader :text
	attr_accessor :left, :right
	def accept(visitor)
		visitor.visit_composite(self)
	end
end

class DumpVisitor
	def initialize
		@stack = []
	end
	def visit_composite(node)
		p node.text
		@stack << node.right if node.right
		@stack << node.left if node.left
		until @stack.empty?
			@stack.shift.accept(self)
		end
	end
end

=begin
class DetermineWidthVisitor
	def initialize
		@width = Hash.new
	end
	def visit_composite(node)
		p node.text
		@stack << node.right if node.right
		@stack << node.left if node.left
		until @stack.empty?
			@stack.shift.accept(self)
		end
	end
end
=end


def comp(text, right=nil, left=nil)
	composite = Composite.new(text)
	composite.left = left
	composite.right = right
	composite
end

tree = comp('2', 
	comp('3', comp('5'), comp('6')), 
	comp('4', comp('7'), comp('8'))
)

#p tree

#v = PrettyVisitor.new
v = DumpVisitor.new
tree.accept(v)




