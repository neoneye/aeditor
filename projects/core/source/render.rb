require 'aeditor/backend/line_objects'
require 'aeditor/backend/cell'
require 'aeditor/backend/ascii'

# purpose:
# translate line_objects into cell objects (ready to be displayed).
#
# todo:
# * at some time, this class must be splitted up
#   into multiple plugable rendering strategies.
class Render
	class RenderVisitor
		def initialize
			@tab_size = 8
			@tab_glyph_last = Ascii::SPACE
			@tab_glyph_fill = Ascii::SPACE
			#@tab_glyph_last = "."[0]
			#@tab_glyph_fill = "_"[0]
			@mark_glyph_left = "["[0]
			@mark_glyph_right = "]"[0]
			reset
			@color = Cell::TEXT
		end
		attr_accessor :tab_size
		attr_reader :result
		def output(str, color=nil)
			color ||= @color
			cells = str.split(//).map{|ascii|
				Cell.new(ascii[0], color)
			}
			@result += cells
		end
		def reset
			@result = []
		end
		def visit_object(lo)
		end
		def visit_text(lo)
			output(lo.ascii_value.chr, Cell::TEXT)
		end
		def visit_tab(lo)
			indent = @tab_size - (@result.size % @tab_size)
			fill = @tab_glyph_fill.chr * (indent-1)
			fill += @tab_glyph_last.chr
			output(fill, Cell::TAB)
		end
		def visit_mark(lo)
			str = @mark_glyph_left.chr + lo.text + @mark_glyph_right.chr
			output(str, Cell::ERROR)
		end
		def visit_vspace(lo)
		end
		def visit_fold(lo)
			if lo.whole_line
				str = "== #{lo.hidden_lines} == #{lo.title} =="
				# todo: pad with '=' so we fit to width of window
			else
				str = lo.title
			end
			output(str, Cell::ERROR)
		end
	end
	def initialize
		@render_visitor = RenderVisitor.new
	end
	def set_tabsize(ts)
		@render_visitor.tab_size = ts
	end
	# functions:
	# * performs tab-expand.. translates TABS into spaces.
	def render(line_objs)
		@render_visitor.reset
		line_objs.each {|lo| lo.accept(@render_visitor) }
		@render_visitor.result
	end
	# issues:
	# * does not perform tab-expand.. this is up to yourself.
	def Render::from_string_into_cells(string, color=Cell::TEXT)
		string.split(//).collect do |char| 
			Cell.new(char[0], color) 
		end
	end
	def Render.percent_to_string(current, total)
		raise if current > total or current < 0
		return "TOP" if current == 0
		return "BOT" if current == total
		"%%%02d" % (current * 100 / total)
	end
end

class String
	# issues:
	# * does not perform tab-expand.. this is up to yourself.
	def to_cells(color=Cell::TEXT)
		Render::from_string_into_cells(self, color)
	end
end
