module Graphlib

module Helper

def create_pieces(x1, x2, divisions)
	pieces = []
	length = x2 - x1
	divisions.times do |i|
		pieces << (length * i).to_f / (divisions-1) + x1
	end
	pieces
end

def normalize_values(x1, x2, window_size, values)
	values.map do |v|
		((v - x1) * window_size).to_f / (x2 - x1).to_f
	end
end

extend(self)
end # module Helper

module SVG

class Document
  def initialize
    @content = ''
    @x1 = 0
    @y1 = 0
    @x2 = 1000
    @y2 = 1000
  end
  attr_accessor :content, :x1, :y1, :x2, :y2
  def to_s
		<<TEMPLATE
<?xml version="1.0" standalone="yes"?>
<!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.0//EN" 
  "http://www.w3.org/TR/2001/REC-SVG-20010904/DTD/svg10.dtd">
<svg width="100%" height="100%" viewBox="#{@x1} #{@y1} #{@x2} #{@y2}">
#{@content}
</svg>
TEMPLATE
  end
end # class Document

class Grid
	def initialize(xs, ys)
		@xs = xs
		@ys = ys
	end
	# make y grid (horizontal lines)
	def build_grid_y(x1, x2, ys_grid)
		paths = ys_grid.map do |y|
			str =	"%1.2f %1.2f L %1.2f %1.2f" % [x1, y, x2, y]
			'<path d="M ' + str + '"/>'
		end
		paths
	end
	# make x grid (vertical lines)
	def build_grid_x(y1, y2, xs_grid)
		paths = xs_grid.map do |x|
			str =	"%1.2f %1.2f L %1.2f %1.2f" % [x, y1, x, y2]
			'<path d="M ' + str + '"/>'
		end
		paths
	end
	def to_s
		str = '<g style="fill:none;stroke:grey;stroke-width:1">'
		str << build_grid_y(@xs[0], @xs[-1], @ys).join
		str << build_grid_x(@ys[0], @ys[-1], @xs).join
		str << '</g>'
		str
	end
end # class Grid

class LabelsHorz
	def initialize(x_y_text)
		@triplet = x_y_text
	end
	def to_s
		str = '<g style="font-family:Verdana;' +
			'font-size:10;fill:black;' +
			'text-anchor:end">'
		@triplet.each do |(x, y, label)|
			position = 'x="%1.2f" y="%1.2f"' % [x, y]
			str << "<text #{position}>#{label}</text>"
		end
		str << '</g>'
		str
	end
end # class LabelsHorz

class LabelsVert
	def initialize(x_y_text)
		@triplet = x_y_text
	end
	def to_s
		str = '<g style="font-family:Verdana;' +
			'font-size:10;fill:black;' +
			'writing-mode:tb;' +
			'text-anchor:end">'
		@triplet.each do |(x, y, label)|
			text = "<text>#{label}</text>"
			rotate = 'rotate(180)'
			transl = 'translate(%1.2f,%1.2f)' % [x, y]
			str << "<g transform=\"#{transl} #{rotate}\">#{text}</g>"
		end
		str << '</g>'
		str
	end
end # class LabelsVert


class ChartLine
	def initialize(xs)
		@xs = xs
		@graphs = []
	end
	def push(ys, color, width)
		stroke = 'stroke:' + color
		style = "style=\"fill:none;#{stroke};stroke-width:#{width}\""
		@graphs << [ys, style]
	end
	def to_s
		result = ''
		@graphs.each do |(ys, style)|
			points = @xs.zip(ys).map do |x, y|
				"%1.2f %1.2f" % [x, y]
			end
			result << '<path ' + style + 
				' d="M ' + points.join(' L ') + '"/>'
		end
		result
	end
end # class ChartLine

end # module SVG

end # module Graphlib