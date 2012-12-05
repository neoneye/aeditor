require 'aeditor/backend/convert'
require 'aeditor/backend/buffer_objects'
require 'aeditor/backend/misc'
require 'aeditor/backend/exceptions'

# 
module BufferLine
	#class IntegrityError < StandardError; end
	def line_import_top
		raise BufferTop if @data_top.empty?
		#if @data_top.last.kind_of?(BufferObjects::Newline) == false
		#	raise IntegrityError 
		#end
		bo, nl = @data_top.line_pop
		lo = Convert::from_bufferobjs_into_lineobjs(bo)
		Line.new(lo, (nl != nil))
	end
private
	def line_import_bottom
		raise BufferBottom if @data_bottom.empty?
		# note: integrity error cannot occur here.. 
		bo, nl = @data_bottom.line_shift
		lo = Convert::from_bufferobjs_into_lineobjs(bo)
		Line.new(lo, (nl != nil))
	end
public
	def line_export_top(line)
		bo = Convert::from_lineobjs_into_bufferobjs(line.lineobjs)
		nl = (line.newline) ? BufferObjects::Newline.new : nil
		@data_top.line_push(bo, nl)
	end
	def line_export_bottom(line)
		return if line == nil   # discard empty lines
		bo = Convert::from_lineobjs_into_bufferobjs(line.lineobjs)
		nl = (line.newline) ? BufferObjects::Newline.new : nil
		@data_bottom.line_unshift(bo, nl)
	end
	def import_top
		@line_top.unshift(line_import_top)
	end
	def import_bottom(allow_empty_lines=true)
		begin
			line = line_import_bottom
		rescue BufferBottom
			if bottom_newline?
				line = Line.new([], false)
			else
				raise unless allow_empty_lines 
				line = nil
			end
		end
		@line_bottom.push(line)
		line
	end
	def export_top
		raise CannotExport if @line_top.empty?
		line_export_top(@line_top.shift)
	end
	def export_bottom
		raise CannotExport if @line_bottom.empty?
		line_export_bottom(@line_bottom.pop)
	end
	def top_empty?
		@data_top.empty?
	end
	def bottom_empty?
		@data_bottom.empty?
	end
	# purpose:
	# #import_bottom invokes this method in order
	# to determine wheter the last-line in the view
	# is terminated with newline.
    #
	# template method:
	# in order to use this mixin, you must
	# overload this function.
	#
	# should scan locate the last element in @line_bottom
	# and return its status.
	# if @line_bottom is empty, then status of @edit.newline
	def bottom_newline?
		true
	end
end
