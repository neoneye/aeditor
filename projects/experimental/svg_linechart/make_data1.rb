data = [
	['4000x256', 38964, 59277],
	['400x2048', 51757, 68481],
	['4x32768', 279235, 299072],
	['1x65536', 994873, 962829]
]

xlabels, *all_values = data.transpose
ymin = 0
ymax = 1000000
#ylabels = (0..10).to_a.map{|i| (i*10).to_s+'%'}.reverse
ylabels = (0..10).to_a.map{|i| ((i*(ymax-ymin)/10)+ymin).to_s }.reverse

values = all_values[0]

ylabels[-1] = ''  # hide first label

lw = 50
width = 300
lh = 70
height = 300


require 'gen_graph1'
