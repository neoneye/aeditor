require 'aeditor/backend/buffer_measure'

module LineObjects
	# base class for LineObject visitors, eg: render
	class Visitor
		def visit_object(lo)
		end
		def visit_text(lo)
		end
		def visit_tab(lo)
		end
		def visit_mark(lo)
		end
		def visit_vspace(lo)
		end
		def visit_fold(lo)
		end
	end
	class Object
		include MeasureMixins::Zero

		def to_s; "<object>" end
		def accept(visitor); visitor.visit_object(self) end
	end
	class Text < Object  
		include MeasureMixins::One
		def initialize(ascii_value)
			@ascii_value = ascii_value
		end
		attr_reader :ascii_value
		def to_s
			String.new << @ascii_value
		end
		def accept(visitor); visitor.visit_text(self) end
	end
	class Tab < Object
		include MeasureMixins::One
		def to_s; "\t" end
		def accept(visitor); visitor.visit_tab(self) end
	end
	class Mark < Object
		include MeasureMixins::Zero
		def initialize(text="?")
			@text = text
		end
		attr_reader :text
		def to_s; "<mark>" end
		def accept(visitor); visitor.visit_mark(self) end
	end
	class VSpace < Object
		include MeasureMixins::Zero
		def to_s; "<vspace>" end
		def accept(visitor); visitor.visit_vspace(self) end
	end
	class Fold < Object
		# issues:
		# * Even thought this is a LineObject, it must be
		#   initialized with BufferObjects.
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
		def accept(visitor); visitor.visit_fold(self) end
	end
end

class Line
	def initialize(lineobjs = [], newline = false)
		@lineobjs = lineobjs
		@newline = newline
	end
	attr_reader :newline, :lineobjs
	def set_data(lineobjs)
		@lineobjs = lineobjs
	end
	def set_newline(on_off)
		@newline = on_off
	end
	def Line.create(text = "none", newline = true)
		lineobjs = Convert::from_string_into_lineobjs(text)
		l = Line.new(lineobjs)
		l.set_newline(newline)
		l
	end
	def to_s
		lineobjs.to_s + ((newline) ? "<hard>" : "<soft>")
	end
end

class LineFold
	def initialize(bo, title)
		@buffer_objs = bo
		@title = title
	end
	attr_reader :buffer_objs, :title
end

module LineIndent
	def LineIndent.extract_indent(lineobjs)
		res = []
		lineobjs.each { |lo|
			case lo
			when LineObjects::Tab
				# nothing
			when LineObjects::Text
				if lo.ascii_value != 32
					break
				end
			else
				break
			end
			res << lo
		}
		res
	end
end

# purpose:
# container for Line's.. which measures the size of each line.
#
#
# issues:
# * line_add/line_sub is checking if the line is nil.. and bailout
#   if so... Instead of 'nil' there should be a LineNil class,
#   this would make it easier to render the Cell's.
class LineArray
	include Measure
	def initialize(lines = [])
		replace(lines)
	end
	attr_reader :data
	def replace(lines)
		init_measure
		@data = []
		lines.each do |line|
			push(line)
		end
	end
	def empty?
		@data.empty?
	end
	def size
		@data.size
	end
	def first
		@data.first
	end
	def last
		@data.last
	end
	def line_add(line)
		return unless line
		self.add(line.lineobjs)
		self.add([BufferObjects::Newline.new]) if line.newline
	end
	def line_sub(line)
		return unless line
		self.sub(line.lineobjs)
		self.sub([BufferObjects::Newline.new]) if line.newline
	end
	def push(line)
		@data.push(line)
		line_add(line)
	end
	def unshift(line)
		@data.unshift(line)
		line_add(line)
	end
	def pop
		line = @data.pop
		line_sub(line)
		line
	end
	def shift
		line = @data.shift
		line_sub(line)
		line
	end
	def to_s
		@data.join
	end
	def each
		@data.each do |line|
			yield(line)
		end
	end
end
