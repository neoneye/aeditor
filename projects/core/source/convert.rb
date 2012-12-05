require 'aeditor/backend/buffer_objects'
require 'aeditor/backend/line_objects'
require 'aeditor/backend/ascii'

module Convert
	class CannotConvert < StandardError; end

	# Newline cannot be represented as a LineObjects
	# attempts to convert it should result in CannotConvert exception.
	def Convert.from_bufferobjs_into_lineobjs(bufobjs)
		bufobjs.collect do |bo|
			case bo
			when BufferObjects::Text
				case bo.ascii_value
				when Ascii::TAB
					LineObjects::Tab.new
				else
					LineObjects::Text.new(bo.ascii_value)
				end
			when BufferObjects::Fold
				LineObjects::Fold.new(
					bo.child_bufobjs,
					bo.title,
					bo.whole_line)
			when BufferObjects::Mark
				LineObjects::Mark.new(bo.text)
			else
				msg = <<MSG
bufobj2lineobj: 
don't know how to convert from \"#{bo.class.to_s}\" into a lineobject. 
MSG
				msg += bufobjs.class_inspect.map { |cnt|
					"   #{cnt}"
				}.join("\n")
				raise CannotConvert, msg
			end
		end
	end
	# VSpace cannot be represented as a BufferObjects
	# attempts to convert it should result in CannotConvert exception.
	def Convert.from_lineobjs_into_bufferobjs(lineobjs)
		lineobjs.collect do |lo|
			case lo
			when LineObjects::Text
				BufferObjects::Text.new(lo.ascii_value)
			when LineObjects::Tab
				BufferObjects::Text.new(Ascii::TAB)
			when LineObjects::Fold
				BufferObjects::Fold.new(
					lo.child_bufobjs,
					lo.title,
					lo.whole_line)
			when LineObjects::Mark
				BufferObjects::Mark.new(lo.text)
			else
				msg = <<MSG
lineobj2bufobj: 
don't know how to convert from \"#{lo.class.to_s}\" into a bufferobject. 
MSG
				msg += lineobjs.class_inspect.map { |cnt|
					"   #{cnt}"
				}.join("\n")
				raise CannotConvert, msg
			end
		end
	end
	def Convert::from_string_into_bufferobjs(string)
		res = []
		string.split(//).each do |char| 
			case char
			when "\n"
				res << BufferObjects::Newline.new 
			else
				res << BufferObjects::Text.new(char[0]) 
			end
		end
		res
	end
	def Convert::from_string_into_lineobjs(string)
		bo = Convert::from_string_into_bufferobjs(string)
		Convert::from_bufferobjs_into_lineobjs(bo)
	end
	# purpose:
	# removed *extra* info when the buffer is stored to disc
	def Convert::from_bufferobjs_into_filestring(bufobjs)
		str = ""
		bufobjs.collect do |bo|
			case bo
			when BufferObjects::Text
				str << bo.to_s
			when BufferObjects::Newline
				str << "\n"
			when BufferObjects::Fold
				str += Convert::from_bufferobjs_into_filestring(bo.child_bufobjs)
			when BufferObjects::Mark
				# ignore me
			else
				msg = <<MSG
bufobj2filestring: 
don't know how to convert from \"#{bo.class.to_s}\" into a filestring. 
MSG
				msg += bufobjs.class_inspect.map { |cnt|
					"   #{cnt}"
				}.join("\n")
				raise CannotConvert, msg
			end
		end
		str
	end
end
