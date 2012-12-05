require 'aeditor/backend/view'
require 'aeditor/backend/buffer'
require 'common'

class FakeViewCellarea
	def initialize(width, height)
		@width = width
		@height = height
		clear_events
	end
	def clear_events
		@events = []
	end
	attr_reader :events
	def getx; @width end

	def render_line(y, data)
		@events += [y, data]
	end
	def cursor_position(x, y)
		@events += [x, y]
	end
	def refresh
	end
end

class FakeViewBuffer
	def initialize(height)
		@position_x = 0
		@position_y = 0
		@height = height
		@blocking = Buffer::Blocking.new
	end
	attr_accessor :position_x, :position_y, :blocking
	def each_line
		@height.times do |i|
			yield(i)
		end
	end
	def edit_to_cells
		@position_y
	end
end

class FakeView < View
	def visible_part(data); data end
end

class TestView < Common::TestCase 
	def test_render_all1
		ca = FakeViewCellarea.new(4, 4)
		buf = FakeViewBuffer.new(4)
		view = FakeView.new(buf, ca)
		view.update(false, false, true)
		# test if update-all is actual occuring
		assert_equal(0, view.x)
		assert_equal(
			[
				# content of the 4 lines
				0, 0,
				1, 1,
				2, 2,
				3, 3,

				# cursor position within the view
				0, 0   
			], 
			ca.events
		)
	end
	def test_render_all2
		ca = FakeViewCellarea.new(4, 4)
		buf = FakeViewBuffer.new(4)
		view = FakeView.new(buf, ca)
		buf.position_x = 5
		# cursor moves outside the view => refocus view => render all
		view.update(true, false, false)
		# test if update-all is actual occuring
		assert_equal(2, view.x)
		assert_equal(
			[
				# content of the 4 lines
				0, 0,
				1, 1,
				2, 2,
				3, 3,

				# cursor position within the view
				3, 0   
			], 
			ca.events
		)
	end
	def test_render_line1
		ca = FakeViewCellarea.new(4, 4)
		buf = FakeViewBuffer.new(4)
		view = FakeView.new(buf, ca)
		buf.position_x = 2
		buf.position_y = 1
		view.update(false, true, false)
		# test if update-line is actual occuring
		assert_equal(0, view.x)
		assert_equal(
			[
				# content of current line
				1, 1,

				# cursor position within the view
				2, 1   
			], 
			ca.events
		)
	end
	def test_render_cursor1
		ca = FakeViewCellarea.new(4, 4)
		buf = FakeViewBuffer.new(4)
		view = FakeView.new(buf, ca)
		buf.position_x = 2
		buf.position_y = 1
		view.update(true, false, false)
		# test if update-cursor is actual occuring
		assert_equal(0, view.x)
		assert_equal([2, 1], ca.events)
	end
end

TestView.run if $0 == __FILE__
