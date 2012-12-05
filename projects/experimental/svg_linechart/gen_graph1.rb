data = [
	['jan-04', 80, 67, 60],
	['feb-04', 77, 64, 55],
	['mar-04', 65, 50, 50],
	['apr-04', 64, 39, 45],
	['may-04', 59, 31, 40],
	['jun-04', 55, 24, 30],
	['jul-04', 53, 19, 20],
	['aug-04', 51, 17, 18],
	['sep-04', 49, 17, 17],
	['oct-04', 44, 17, 16],
	['nov-04', 40, 17, 15],
	['dec-04', 38, 14, 14]
]

xlabels, *all_values = data.transpose
ylabels = (0..10).to_a.map{|i| (i*10).to_s+'%'}.reverse
ymin = 0
ymax = 100

values = all_values[0]

ylabels[-1] = ''  # hide first label


require 'graphlib'
include Graphlib


lw = 30
width = 300
lh = 50
height = 300

Padding = Struct.new(:left, :right, :top, :bottom)
grid_padding = Padding.new(3, 3, 3, 3)


extra_left = -11
extra_right = -11

xs_grid = Helper.create_pieces(
	lw+grid_padding.left-extra_left, 
	lw+width-grid_padding.right+extra_right, 
	xlabels.size)
ys_grid = Helper.create_pieces(
	grid_padding.top, 
	height-grid_padding.bottom, 
	ylabels.size)
ys_graphs = all_values.map do |vals|
  Helper.normalize_values(ymin, ymax, height, vals).map do |rv|
  	height-rv
  end
end

paths = []

# defs

filter = <<FILTER
<defs>
<filter id="FilterValues" filterUnits="userSpaceOnUse" x="0" y="0" width="100%" height="100%">
  <feGaussianBlur in="SourceAlpha" stdDeviation="2" result="blur"/>
</filter>
</defs>
FILTER

paths << filter

grid = SVG::Grid.new(xs_grid, ys_grid)
paths << grid.to_s

# begin filter
paths << '<g filter="url(#FilterValues)">'

# make values
colors = %w(#eaa #b0b0ff #9e9)
cl = SVG::ChartLine.new(xs_grid)
ys_graphs.each_with_index do |ys_value, index|
	cl.push(ys_value, colors[index%colors.size], 2)
end
paths << cl.to_s

# end filter
paths << '</g>'

# make values (again)
paths << cl.to_s

# make labels along x-axis
triplet = []
xs_grid.each_with_index{|x, i| triplet << [x, height, xlabels[i]] }
labels_vert = SVG::LabelsVert.new(triplet)
paths << labels_vert.to_s

# make labels along y-axis
triplet = []
ys_grid.each_with_index{|y, i| triplet << [lw-extra_left, y+3, ylabels[i]] }
labels_horz = SVG::LabelsHorz.new(triplet)
paths << labels_horz.to_s

# make document
doc = SVG::Document.new
doc.x2 = lw + width
doc.y1 = -7
doc.y2 = lh + height
doc.content = paths.join
puts doc.to_s
