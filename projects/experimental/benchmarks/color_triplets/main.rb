def build_data
	colors = []
	(80*100).times do |i|
		r = i % 256
		g = 255 - r
		b = (r + g) / 2
		colors << [r, g, b]
	end
	colors
end
#p build_data


class Triplet
	def initialize(r, g, b)
		@r, @g, @b = r, g, b
	end
	attr_accessor :r, :g, :b
end




require 'benchmark'
n = 16
Benchmark.bm do |x|
  # the naive approach.. representing the triplet as an Array
	data1 = build_data
	x.report('array triplet') do 
		n.times do
			data1.each_index do |i|
				3.times do
					rgb = data1[i]
					r = rgb[0]
					b = rgb[1]
					g = rgb[2]
					rgb[0] = g
					rgb[1] = b
					rgb[2] = r
				end
			end
		end
	end
	# using a class
	data2 = build_data.map {|(r, g, b)| Triplet.new(r, g, b)}
	x.report('triplet class') do
		n.times do
			data2.each_index do |i|
				3.times do
					rgb = data2[i]
					r = rgb.r
					b = rgb.g
					g = rgb.b
					rgb.r = g
					rgb.g = b
					rgb.b = r
				end
			end
		end
	end
	# using 3 separate arrays
	data3r, data3g, data3b = build_data.transpose
	x.report('separate arrays') do
		n.times do
			data3r.each_index do |i|
				3.times do
					r = data3r[i]
					b = data3g[i]
					g = data3b[i]
					data3r[i] = g
					data3g[i] = b
					data3b[i] = r
				end
			end
		end
	end
	# use a 32bits value with 8bit components
	data4 = build_data.map{|(r, g, b)| ((r << 16)|(g << 8)|(b))}
	x.report('24bit value') do
		n.times do
			data4.each_index do |i|
				3.times do
					rgb = data4[i]
					r = (rgb >> 16) & 255
					b = (rgb >> 8) & 255
					g = rgb & 255
					data4[i] = ((g << 16)|(b << 8)|(r))
				end
			end
		end
	end
end