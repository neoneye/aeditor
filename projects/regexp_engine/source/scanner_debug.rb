class ScannerIntegrityDumpVisitor
	class IndexError < StandardError; end
	def initialize(index_stack)
		@result = ""
		@index_stack = index_stack
	end
	attr_reader :result
	def result_stripped
		@result.strip.squeeze(" ")
	end
	def visit_last(node)
		# nothing
	end
	def visit_match(node)
		@result << node.node.integrity_str
		node.succ.accept(self)
	end
	def visit_group(node)
		node.succ.accept(self)
	end
	def visit_alternation(node)
#		if @index_stack.empty?
#			raise IndexError, "stack underflow"
#		end
		#index = @index_stack.shift
		index = @index_stack.empty? ? 0 : @index_stack.shift
		if index >= node.patterns.size
			raise IndexError, "index out of range"
		end
		@result << " "
		node.patterns[index].accept(self)
		@result << " "
		node.succ.accept(self)
	end
	def visit_alternation_end(node) 
		# nothing
	end
	def visit_repeat(node)
		n = (node.min == 0) ? 0 : 1
		if @index_stack.empty? == false
			n = @index_stack.shift
		end
		n.times do
			@result << " "
			node.pattern.accept(self)
		end
		@result << " "
		node.succ.accept(self)
	end
	def visit_repeat_end(node)
		# nothing
	end
	def visit_backreference(node)
		@result << "<backref>"
		node.succ.accept(self)
	end
	def visit_lookahead(node)
		#@result << "<lookahead>"
		@result << " "
		n = 0
		if @index_stack.empty? == false
			n = @index_stack.shift
		end
		if n == 0
			node.pattern.accept(self)
		else
			node.succ.accept(self)
		end
	end
	def visit_anchor(node)
		@result << "<anchor>"
		node.succ.accept(self)
	end
end

module ScannerHierarchy
	class Base
		def integrity
			"not implemented"
		end
		def integrity2(index_stack)
			v = ScannerIntegrityDumpVisitor.new(index_stack.clone)
			begin
				self.accept(v)
				return v.result_stripped
			rescue ScannerIntegrityDumpVisitor::IndexError
				return v.result_stripped + "<indexerror>"
			end
		end
	end
end
