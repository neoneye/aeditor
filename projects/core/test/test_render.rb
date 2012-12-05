require 'aeditor/backend/render'
require 'aeditor/backend/convert'
require 'aeditor/backend/line_objects'
require 'common'

class FakeRender < Render
	def initialize
		super
		set_tabsize(4)
	end
end

class TestRender < Common::TestCase 
	# from cells, extract glyphs as a string
	def cells_glyphs2str(cells)
		#return cells.inspect
		cells.map{|cell| cell.glyph.chr}.join
	end
	def lineobjs2cells(line_objs)
		r = FakeRender.new
		r.render(line_objs)
	end
	def test_line2cell_tab1
		line_objs = [
			LineObjects::Text.new("a"[0]),
			LineObjects::Tab.new,
			LineObjects::Text.new("b"[0]),
			LineObjects::VSpace.new
		]
		cells = lineobjs2cells(line_objs)
		assert_equal("a   b", cells_glyphs2str(cells))
	end
	def test_line2cell_mark1
		line_objs = Convert::from_string_into_lineobjs("abcd")
		line_objs[2, 0] = LineObjects::Mark.new("hello")
		cells = lineobjs2cells(line_objs)
		assert_equal("ab[hello]cd", cells_glyphs2str(cells))
	end
	def test_line2cell_fold1 
		# a cell-fold which only spans few cells
		bo = Convert::from_string_into_bufferobjs(
			"{\n\te = wait_event();\n\tdispatch(e);\n}")
		line_objs = Convert::from_string_into_lineobjs("do  while(1);")
		line_objs[3, 0] = LineObjects::Fold.new(bo, "{3}", false)
		cells = lineobjs2cells(line_objs)
		assert_equal("do {3} while(1);", cells_glyphs2str(cells))
	end
	def test_line2cell_fold2 
		# a line-fold which occupies the whole line
		bo = Convert::from_string_into_bufferobjs(
			"#[ title\na\nb\nc\n#]\n")
		line_objs = [] << LineObjects::Fold.new(bo, "title", true)
		cells = lineobjs2cells(line_objs)
		assert_equal("== 5 == title ==", cells_glyphs2str(cells))
	end
	def test_string2cell_1
		cells = "abc".to_cells
		assert_equal("abc", cells_glyphs2str(cells))
	end
	def test_string2cell_2
		cells = "1\t2".to_cells
		# as you can see: no conversion of TAB occurs
		assert_equal("1\t2", cells_glyphs2str(cells))
	end
	def test_percent_minus1
		assert_raises(RuntimeError) {
			Render.percent_to_string(-1, 0)
		}
	end
	def test_percent0
		s = Render.percent_to_string(0, 0)
		assert_equal("TOP", s)
	end
	def test_percent1
		s = Render.percent_to_string(0, 1)
		assert_equal("TOP", s)
	end
	def test_percent2
		assert_raises(RuntimeError) {
			Render.percent_to_string(1, 0)
		}
	end
	def test_percent3
		s = Render.percent_to_string(1, 1)
		assert_equal("BOT", s)
	end
	def test_percent4
		s = Render.percent_to_string(1, 2)
		assert_equal("%50", s)
	end
	def test_percent5
		s = Render.percent_to_string(1, 3)
		assert_equal("%33", s)
	end
	def test_percent6
		s = Render.percent_to_string(3, 3)
		assert_equal("BOT", s)
	end
end

TestRender.run if $0 == __FILE__
