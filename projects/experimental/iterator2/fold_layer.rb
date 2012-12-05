require 'iterator'

# a tree structure of the folds
class Node
	attr_reader :first, :last, :children
	def initialize(first, last, children)
		@first = first
		@last = last
		@children = children
	end
	def inspect
		res = @children.map{|i| i.inspect}.join("\n")
		res = res.split(/\n/).map{|i| "\n " + i}.join
		@first.position.to_s + ".." + @last.position.to_s + res
	end
end

# purpose:
# iterates through the visible lines
#
# this is useful when you move the
# cursor around, and when you have
# to scroll the view.
#
# todo:
# * the cloning of iterators is problematic, because
#   this class is usualy used in conjunction with
#   RobustArray.. Thus the number of observers will
#   grow steadily.  A detachment mechanism is necessary.
# * backwards iteration is necessary.
class ViewIterator < Iterator::Base
	def initialize(tree)
		super()
		@tree = tree
		first
	end
	def first
		@i = @tree.first.clone
		@c = @tree.children.create_iterator
		@c.first
	end
	def next
		@i.next
		return if @c.is_done?
		return if @i.position < @c.current.first.position
		@i = @c.current.last.clone
		@c.next
		@i.next
	end
	def is_done?
		@i.position > @tree.last.position
	end
	def current
		@i.current
	end
end
