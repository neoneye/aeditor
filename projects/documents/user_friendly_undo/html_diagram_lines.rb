require 'cgi-lib'

class Skeleton
	def initialize(data=nil)
		@width = data[0]
		@x = data[1][0]
		@y = data[1][1]
		@lines = data[2]
		print "parsing input data ... "
		$stdout.flush
		raise "cursor x must be within view" if @x >= @width
		raise "cursor y must be within view" if @y > @lines.size
		build_optional_table
		validate_optional_table
		w = measure_width_of_optional_table
		@lines = strings_to_arrays(@lines)
		@op_lines = strings_to_arrays(@op_lines)
		nil_pad_arrays(@lines, @width)
		nil_pad_arrays(@op_lines, w)
		msg = "width of optional table = #{w}"
		if w == 0
			msg += " (NO optional table)"
			@op_lines = nil
		end
		puts "OK"
		p @lines
		p @op_lines
		puts msg
	end
	def nil_pad_arrays(ary, width)
		ary.each{|i|
			raise "too many elements" if i.size > width
			(width - i.size).times { i << nil }
		}
	end
	def strings_to_arrays(ary)
		ary.map{|i|i.split(//)}
	end
	def build_optional_table
		@op_lines = @lines.map{|line|
			if line.size > @width
				res = line.slice!(@width, line.size-1)
			else
				res = "" 
			end
			res
		}
	end
	def measure_width_of_optional_table
		@op_lines.map{|i|i.size}.max
	end
	def validate_optional_table
		@op_lines.each{|line|
			line.split(//).each{|s|
				i = s[0]
				if (i != 9) and (i != 32)
					raise <<MSG
non-space found in optional-table 
data were: #{i} (#{s.class}),  expected either 9 or 32
MSG
				end
			}
		}
		# Optional table is fine
	end
	def Skeleton.build
		i = self.new
		i.create
	end
	def Skeleton.style
		<<MSG
TABLE {
	font-family: monospaced;
	font-weight: bold;
	text-align: center;
	border: none;
	border-spacing: 0px;
	cell-spacing: 0px;
	padding: 0px;
	margin: 0px;
	clear: both;
}
TABLE > TABLE.left {
	border-left: black 4px solid;
}
TABLE > TABLE.right {
	border-right: black 4px solid;
}
TR {
	border-spacing: 0px;
	padding: 0px;
	margin: 0px;
	clear: both;
}
TD {
	border-spacing: 0px;
	border: #111 1px solid;
	padding: 2px;
	margin: 0px;
	clear: both;
	background: white;
}
TD > TD.space {
	color: white;
}
TD > TD.rspace {
	background: #ccc;
	color: #ccc;
}
TD > TD.empty {
/*	background: transparant;*/
	background: #78c;
	color: #78c;
	border: #78c 1px solid;
}
TD.nest {
	border: #111 0px solid;
	padding: 0px;
	margin: 0px;
	clear: both;
}
MSG
	end
	def cgi_table(attr=nil)
		attr ||= {}
		attr["CELLSPACING"] = "0"
		CGI::tag("TABLE", attr) { yield }
	end
	def html_table(lines, space=nil, table_attr=nil)
		rows = lines.map{|line|
			cells = line.map{|cell|
				attr = {}
				# hack: Internet Explorer 5.0 fuckups width 
				# of cell if we use plain space.
				unless cell
					cell = "_"
					attr["CLASS"] = "empty"
				end
				if cell == 32.chr
					cell = "_" 
					attr["CLASS"] = space || "space"
				end
				CGI::tag("TD", attr) { cell }
			}
			CGI::tag("TR") { cells.join }
		}
		cgi_table(table_attr) { rows.join }
	end
	def html_composite_table
		style = (@op_lines) ? {} : {"CLASS"=>"right"}
		tab = html_table(@lines, "space", style)
		return tab if @op_lines == nil
		otab = html_table(@op_lines, "rspace", {"CLASS"=>"left"})
		cells = [tab, otab].map{|cell| 
			CGI::tag("TD", {"CLASS"=>"nest"}) { cell } 
		}
		row = CGI::tag("TR") { cells.join }
		cgi_table { row }
	end
	def create
		html_composite_table
	end
end

class Test < Skeleton
	def initialize
		data = [4, [2, 0], ["abc   ", "d e ", "f"]]
		#data = [4, [2, 0], ["abc ", "d e ", "f"]]
		#data = [5, [2, 0], ["abc ", "d e ", "f"]]
		super(data)
	end
end

if $0 == __FILE__
	style = CGI::tag("STYLE", {"TYPE"=>"text/css"}) { Test.style }
	title = CGI::tag("TITLE") { "Softwrap in action" }
	head = CGI::tag("HEAD") { title + style }
	body = CGI::tag("BODY") { Test.build }
	html = CGI::tag("HTML") { head + body }
	File.open("test.html", "w+") { |f| f.write(html) }
	puts "done"
end
