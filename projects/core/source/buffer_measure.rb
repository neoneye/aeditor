# purpose:
# measure size (bytes, lines) for bufferobjs and lineobjs.
#
# issues:
# * 'physical_lines' is the number of 'physical-newline-characters' 
#   which has been encountered. Wordwrapped lines does NOT
#   count here, because its using soft-newlines!
#   A collapsed fold can contain several newlines.
#
# * 'visible_lines' is the number of lines you can see.
#   A buffer containing 9 'visible_lines', spans 10 lines.
#   This is because we count the number of linebreaks!
#
# * 'bytes' is the amount of storage space it takes up. 
module Measure
	def init_measure
		@bytes = 0
		@visible_lines = 0
		@physical_lines = 0
	end
	attr_reader :bytes, :visible_lines, :physical_lines
	def add(objs)
		objs.each do |obj|
			@bytes += obj.size_bytes
			@physical_lines += obj.size_physical_lines
			@visible_lines += obj.size_visible_lines
		end
	end
	def sub(objs)
		objs.each do |obj|
			@bytes -= obj.size_bytes
			@physical_lines -= obj.size_physical_lines
			@visible_lines -= obj.size_visible_lines
		end
	end
	# bytes, physical, visible = Measure.count(objs)
	# bytes, physical = Measure.count(objs)
	# bytes, = Measure.count(objs)
	def Measure.count(objs)
		x = ""
		x.extend Measure
		x.init_measure
		x.add(objs)
		[x.bytes, x.physical_lines, x.visible_lines]
	end
end

module MeasureMixins
	module Zero
		def size_bytes; 0 end
		def size_visible_lines; 0 end
		def size_physical_lines; 0 end
	end
	module One
		def size_bytes; 1 end
		def size_visible_lines; 0 end
		def size_physical_lines; 0 end
	end
	module Newline
		def size_bytes; 1 end
		def size_visible_lines; 1 end
		def size_physical_lines; 1 end
	end
end
