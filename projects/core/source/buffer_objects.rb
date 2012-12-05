require 'aeditor/backend/buffer_measure'
require 'aeditor/backend/misc'

module BufferObjects
	class Object
		include MeasureMixins::Zero
		def to_s
			"<Object>"
		end
	end
	class Text < Object
		include MeasureMixins::One
		def initialize(ascii_value)
			@ascii_value = ascii_value
		end
		def to_s
			String.new << @ascii_value
		end
		attr_reader :ascii_value
	end
	class Newline < Object
		include MeasureMixins::Newline
		def to_s
			"\n"
		end
	end
	class Mark < Object
		include MeasureMixins::Zero
		def initialize(text="?")
			@text = text
		end
		attr_reader :text
		def to_s; "<mark>" end
	end
	class Fold < Object
		def initialize(child_bufobjs, title, whole_line)
			@child_bufobjs = child_bufobjs
			@bytes, phys, vis = Measure::count(child_bufobjs)
			@newlines = phys
			@hidden_lines = vis
			@title = title
			@whole_line = whole_line
		end
		attr_reader :child_bufobjs, :bytes, :newlines, :title, :whole_line
		attr_reader :hidden_lines
		def size_bytes; @bytes end
		def size_visible_lines 
			(@whole_line) ? (1) : (0)
		end
		def size_physical_lines; @newlines end
		def to_s; "<fold>" end
	end
end

# purpose:
#
# constraints:
# * only initialize with buffer_objects
class BufferObjectArray
	include Measure
	def initialize(objs = [])
		replace(objs)
	end
	attr_reader :data
	def replace(objs)
		@data = objs
		init_measure
		self.add(objs)
	end
	def empty?
		@data.empty?
	end
	def size
		@data.size
	end
	def line_push(objs, newline)
		@data.push(*objs)
		self.add(objs)
		if newline != nil
			@data.push(newline)
			self.add([newline])
		end
	end
	def line_pop
		newline = nil
		if @data.last.kind_of?(BufferObjects::Newline)
			newline = @data.pop
			self.sub([newline])
		end
		objs = @data.pop_until(BufferObjects::Newline)
		self.sub(objs)
		[objs, newline]
	end
	def line_unshift(objs, newline)
		if newline != nil
			@data.unshift(newline)
			self.add([newline])
		end
		@data.unshift(*objs)
		self.add(objs)
	end
	def line_shift
		objs = @data.shift_until(BufferObjects::Newline)
		self.sub(objs)
		newline = nil
		if @data.first.kind_of?(BufferObjects::Newline)
			newline = @data.shift
			self.sub([newline])
		end
		[objs, newline]
	end
	def to_s
		@data.to_s
	end
end
