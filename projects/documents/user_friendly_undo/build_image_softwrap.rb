class BuildImageSoftwrap
	def initialize(data, filename)
		@data = data
		@filename = filename
	end
	def BuildImageSoftwrap.build(data, filename)
		BuildImageSoftwrap.new(data, filename).generate
	end
	def generate
		require 'RMagick'

		vx, vy, vw, vh = @data[1]

		# measure the size of the image required
		nx = @data[2].inject(0) {|a,b| [a,b.size].max}
		ny = @data[2].size
		inside = 0
		@data[2].each{|line|
			n, t = 0, 0
			line.split(//).each {|i|
				if i == " "
					t += 1
				else
					n += t + 1
					t = 0
				end
			}
			inside = [inside, n].max
		}
		#p inside

		w, h = 24, 28                     
		font_screw1 = h / 2 + 6
		font_screw2 = h / 2 + 9
		canvas = Magick::ImageList.new
		sizex = [nx, vx+vw].max
		sizey = [ny, vy+vh].max
		canvas.new_image(sizex*w, sizey*h) { self.background_color = "#ffffff" }
		gc = Magick::Draw.new

		# physical buffer
		gc.fill '#8080a0'
		gc.stroke '#707070'
		gc.stroke_width 1.0
		#gc.roundrectangle(0, 0, nx*w-1, ny*h-1, 7, 7)
		y = 0
		@data[2].each{|line|
			gc.roundrectangle(0, y*h, line.size*w-1, (y+1)*h-1, 7, 7)
			y += 1
		}

		## cell indexes
		gc.pointsize 20
		gc.gravity = Magick::CenterGravity
		gc.fill 'black'
		gc.stroke 'black'
		gc.font_weight 'normal'
		gc.text_align(Magick::CenterAlign)
		x, y = 0, 0
		current_letter = " "
		@data[2].each{|line|
			line.split(//).each {|i|
				text = (i == " ") ? ("_") : (i)
				if (x == @data[0][0]) and (y == @data[0][1])
					current_letter = text
				else
					gc.text(x*w + w/2, y*h + font_screw1, "'#{text}'") 
				end
				x += 1
			}
			y += 1
			x = 0
		}

		## visible area
		gc.opacity 0.5
		gc.fill 'grey'
		gc.stroke 'black'
		gc.stroke_width 2.0
		vx *= w
		vw *= w
		vy *= h
		vh *= h
		gc.rectangle(vx, vy, vx+vw-1, vy+vh-1)

		# background current glyph
		gc.opacity 1.0
		gc.fill '#90ff90'
		gc.stroke '#50b050'
		gc.stroke_width 0
		x, y = @data[0]
		x *= w
		y *= h
		gc.rectangle(x, y, x+w-1, y+h-1)

		# current glyph
		gc.fill 'grey'
		gc.opacity 1.0
		gc.pointsize 28
		gc.stroke 'black'
		gc.stroke_width 1.5
		gc.font_weight 'bold'
		gc.text_align(Magick::CenterAlign)
		gc.text(@data[0][0]*w + w/2, @data[0][1]*h + font_screw2, "'#{current_letter}'") 
		#puts "\n"+gc
		gc.draw(canvas)
		canvas.write(@filename)
	end
end

if $0 == __FILE__
	BuildImageSoftwrap.build(
		[[3, 1], [0, 0, 4, 4], ["ab ", "c ", "de  ", "f"]],
		'/home/neoneye/web/test.png'
	)
end
