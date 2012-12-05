require 'aeditor/backend/control'
require 'aeditor/backend/view'
require 'aeditor/backend/cellarea'
require 'aeditor/backend/buffer'
require 'aeditor/backend/convert'

# purpose:
# build a fake environment, suitable for unittesting.
module FakeSetup
	class FakeControl < Control
		def initialize
			b = Buffer.new
			class << b
				attr_reader :line_top, :line_bottom, :data_top, :data_bottom
			end
			c = Cellarea.new
			v = View.new(b, c)
			super(b, v)
		end
		def setup(total, y, top, bottom)
			str = (0..(total-1)).to_a.map{|i| i.to_s }.join("\n")
			bo = Convert::from_string_into_bufferobjs(str)
			m = Buffer::Memento::All.new(0, y, bo, Buffer::Blocking.new)
			@buffer.set_memento(m)
			@buffer.resize_topbottom(top, bottom)
		end
		def status
			[
				@buffer.position_visible_lines, 
				@buffer.line_top.size,
				@buffer.line_bottom.size
			]
		end
		def total
			@buffer.total_visible_lines
		end
		def execute(symbol)
			command = send(symbol)
			super(command)
		end
		def undo
			execute_undo
		end
		def redo
			execute_redo
		end
		def height(top, bottom)
			@buffer.resize_topbottom(top, bottom)
		end
		def dump
			bo = @buffer.create_memento.bufobjs
			Convert::from_bufferobjs_into_filestring(bo)
		end
	end # class FakeControl
end # module FakeSetup
