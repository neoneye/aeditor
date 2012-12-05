require 'aeditor/backend/buffer_measure'
require 'aeditor/backend/exceptions'

# todo: is this class really necessary ?
class EditSize
	include Measure
	def initialize
		init_measure
	end
end

# purpose:
# this is the 'model' for the Edit class.
#
# it keeps track of:
# * which objects is *left* of the cursor
# * which objects is *right* of the cursor.
# * which object is *under* the cursor.
# 
# it measures different properties of these 
# objects: x-position, bytes, newlines.
#
# todo:
# * do unittesting of #right_bytes & #right_physical_lines.
# * specifying *width* as argument is ugly.
# * use the (old_x != new_x) instead of dirty(true)
class EditContainer
	class Error < StandardError; end
	class NotBegin < CommandHarmless; end
	class NotEnd < CommandHarmless; end

	def initialize
		# left
		@left    = Array.new
		@left_x  = Array.new
		@size_left = EditSize.new

		# current
		@current = nil
		@x = 0

		# right
		@right   = Array.new
		@size_right = EditSize.new

		# dirty-flags
		@content_changed = false
	end
	def left_bytes
		@size_left.bytes
	end
	def right_bytes
		n = (@current == nil) ? (0) : (@current.size_bytes)
		@size_right.bytes + n
	end
	def left_physical_lines
		@size_left.physical_lines
	end
	def right_physical_lines
		n = (@current == nil) ? (0) : (@current.size_physical_lines)
		@size_right.physical_lines + n
	end
	def dirty
		@content_changed = true
	end
	def clear_dirty
		@content_changed = false
	end
	def is_dirty
		@content_changed
	end
	def intern_push_left(obj, width) 
		@left.push(obj)
		@size_left.add([obj])
		@left_x.push(width)
		@x += width
	end
	def intern_pop_left
		raise NotBegin if @left.empty?
		width = @left_x.pop
		@x -= width
		obj = @left.pop
		@size_left.sub([obj])
		obj
	end
	def intern_push_right(obj)  
		@right.unshift(obj)
		@size_right.add([obj])
	end
	def intern_pop_right
		raise NotEnd if @right.empty?
		obj = @right.shift
		@size_right.sub([obj])
		obj
	end
	def zap_right
		res = @right
		@right = []
		@size_right.init_measure
		res
	end
	def zap_left
		res = @left
		@left = []
		@left_x = []
		@size_left.init_measure
		@x = 0
		res
	end

	def set_current(obj)
		@current = obj
		dirty
	end
	def get_current
		@current
	end

	def push_left(obj)
		w = measure_width(@x, obj)
		intern_push_left(obj, w)
		dirty if w > 0
	end
	def pop_left
		w = @left_x.last
		obj = intern_pop_left
		dirty if w > 0
		obj
	end
	def push_right(obj)
		intern_push_right(obj)
		dirty
	end
	def pop_right
		obj = intern_pop_right
		dirty
		obj
	end
	def left2right
		raise Error if @current != nil
		obj = intern_pop_left
		intern_push_right(obj)
	end
	def measure_width(x, obj)
		1
	end
	# overload this method in order to get rid of "width"
	# find editor.. measure width instead.
	def right2left  
		raise Error if @current != nil
		obj = intern_pop_right
		w = measure_width(@x, obj)
		intern_push_left(obj, w) 
	end
	def left2current
		obj = intern_pop_left
		dirty if (@current != nil)
		@current = obj
	end
	def right2current
		obj = intern_pop_right
		dirty if (@current != nil)
		@current = obj
	end
	# overload this method in order to get rid of "width"
	# find editor.. measure width instead.
	def current2left
		w = measure_width(@x, @current)
		intern_push_left(@current, w)
		@current = nil
	end
	def current2right
		intern_push_right(@current)
		@current = nil
	end
	def move_home_internal(content)
		@right = content
		@left = []
		@left_x = []
		@current = nil
		@x = 0
		@size_left.init_measure
		@size_right.init_measure
		@size_right.add(@right)
		# todo: dirty everything is not efficient, perhaps fix ? 
		#dirty
	end
	def reset
		move_home_internal([])
	end
end
