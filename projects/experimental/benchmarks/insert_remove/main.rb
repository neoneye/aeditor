def make_reports(bm, max, n)
	pos = []
	max.times do
		pos << rand(max)
	end
	
	bm.report("insert max=#{max} n=#{n}") do
		str = 'x' * max
		n.times do
			s = str.clone
			pos.each { |i| s.insert(i, 'X') }
		end
	end
	bm.report("remove max=#{max} n=#{n}") do
		str = 'xy' * max
		n.times do
			s = str.clone
			pos.each { |i| s.slice!(i, 1) }
		end
	end
end

require 'benchmark'
Benchmark.bm do |x|
	make_reports(x, 2 << 7, 4000)
	make_reports(x, 2 << 10, 400)
	make_reports(x, 2 << 14, 4)
	make_reports(x, 2 << 15, 1)
end