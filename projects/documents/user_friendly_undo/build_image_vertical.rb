class BuildImageVertical
	def initialize(data, filename)
		@data = data
		@filename = filename
	end
	def BuildImageVertical.build(data, filename)
		BuildImageVertical.new(data, filename).generate
	end
	def generate
		require 'RMagick'

		# measure number of cells the image is heigh
		n = @data.inject(1) {|a,b| a+b}
		buffer_n = @data[0..3].inject(1) {|a,b| a+b}
		current = @data[0..1].inject(0){|i,j|i+j}

		w, h = 24, 28
		font_screw1 = h/2 + 5
		font_screw2 = h/2 + 7
		canvas = Magick::ImageList.new
		canvas.new_image(w, h*n) { self.background_color = "#ffffff" }
		gc = Magick::Draw.new

		# physical buffer
		gc.fill '#8080a0'
		gc.stroke '#707070'
		gc.stroke_width 1.0
		gc.roundrectangle(0, 0, w-1, h*buffer_n-1, 7, 7)

		# cell indexes
		gc.pointsize 20
		gc.gravity = Magick::CenterGravity
		gc.fill 'black'
		gc.stroke 'black'
		gc.font_weight 'normal'
		gc.text_align(Magick::CenterAlign)
		n.times {|i| 
			next if i == current
			gc.text(w/2, i*h + font_screw1, "'#{i.to_s}'") 
		}

		# visible area
		gc.opacity 0.5
		gc.fill 'grey'
		gc.stroke 'black'
		gc.stroke_width 2.0
		a = @data[0] * h
		c = (@data[4] != nil) ? (@data[4]) : (0)
		b = @data[0..2].inject(c+1){|i,j| i+j} * h
		gc.rectangle(0, a, w-1, b-1)

		# current line
		gc.fill 'grey'
		gc.opacity 1.0
		gc.pointsize 28
		gc.stroke 'black'
		gc.font_weight 'bold'
		gc.text_align(Magick::CenterAlign)
		gc.text(w/2, current*h + font_screw2, "'#{current.to_s}'")

		gc.draw(canvas)
		canvas.write(@filename)
	end
end                   

if $0 == __FILE__
	BuildImageVertical.build(
[2, 3, 2, 3],
#[2, 1, 2, 0, 1],
'/home/neoneye/web/test.png')
end
