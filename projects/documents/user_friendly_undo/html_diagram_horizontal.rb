require 'cgi-lib'
require 'html_diagram_vertical'

class Generator
	def initialize(a, b, c, d, extra=0)
		@divisions = [
			[[a, "buffer"], 
			[b, "view_left"]], 
			[[c, "view_right"], 
			[d, "buffer"]]]
		@sum = a + b + c + d
	end
	def build_sub(style, data)
		res = ""
		data.each{|i|
			res += CGI::tag("TD", {"CLASS"=>style}) { i }
		}
		res
	end
	def build
		celldata = (0..(@sum-1)).to_a.map {|i| i.to_s }
		leftright = []
		@divisions.each {|ary|
			res = ""
			ary.each {|sub| 
				length, style = sub
				res << build_sub(style, celldata.slice!(0, length)) 
			}
			res = CGI::tag("TR") { res }
			res = CGI::tag("TABLE", {"CLASS"=>"lksdjf"}) { res }
			res = CGI::tag("TD") { res }
			leftright << res
		}
		CGI::tag("TABLE", {"CLASS"=>"horzgen"}) { 
			cursor = CGI::tag("TD", {"CLASS"=>"cursor"}) { "" }
			CGI::tag("TR") { leftright.join(cursor) }
		}
	end
	def Generator.stylesheet
		<<STYLE
TABLE {
	border-spacing: 0px;
}
TD, TR {
	padding: 0px;
	margin: 0px;
}
TABLE.horzgen {
	border: 1px solid black;
}
TD.jframe {
	width: 10px;
	border-right: 1px solid black;
}
TD.jframe_descr {
	padding-left: 4px;
}
TD.buffer {
	text-align: center;
	padding: 3px;
	padding-left: 10px;
	padding-right: 10px;
	background: #a7a9c0;
	color: #227;
}
TD.cursor {
	border: 8px solid black;
	border-left: none;
	border-right: none;
	height: 42px;
	width: 5px;
	background: white;
	color: #559;
}
TD.view_left {
	text-align: center;
	padding: 3px;
	padding-left: 10px;
	padding-right: 10px;
	background: white;
	color: #558;
}
TD.view_right {
	text-align: center;
	padding: 3px;
	padding-left: 10px;
	padding-right: 10px;
	background: white;
	color: #558;
}
STYLE
	end
end

class SkeletonHorz
	def initialize(data)
		@frames = []
		@jframes = []
		return unless data
		ok = false
		f, jf = data.partition {|i| ok = !ok}
		state_id = 0
		@frames = f.map{|divisions| 
			diagram = gen_state(*divisions)
			frame = Frame.new("t#{state_id}", diagram)
			state_id += 1
			frame
		}
		state_id = 0
		@jframes = jf.map{|args| 
			args.unshift "t#{state_id}#{state_id+1}"
			jframe = JFrame.new(*args)
			state_id += 1
			jframe 
		}
	end
	def gen_state(a, b, c, d, extra=nil)
		Generator.new(a, b, c, d, extra).build
	end
	def gen_state_table
		rows_frames = @frames.map {|i|
		 	cols = CGI::tag("TH") { i.title } + 
		 	CGI::tag("TD", {"COLSPAN"=>"2"}) { i.image } 
		 	CGI::tag("TR") { cols }
		}
		rows_join = @jframes.map {|i|
		 	cols = CGI::tag("TH") { i.title } + 
		 	CGI::tag("TD", {"CLASS"=>"jframe"}) { "&nbsp;" } +
		 	CGI::tag("TD", {"CLASS"=>"jframe_descr"}) { 
				i.operation + "<BR>" + i.text } 
		 	CGI::tag("TR") { cols }
		}
		rows_frames.zip(rows_join).join
	end
	def generate
		CGI::tag("TABLE") {
			gen_state_table
		}
	end
	def SkeletonHorz.build
		self.new.generate
	end
end

class TestHorz < SkeletonHorz
	def initialize
		data = [
			[1, 1, 1, 2],
			["scroll_right", <<"T01"],
a typical scroll right operation.
T01
			[2, 1, 1, 1],
			["undo (scroll_right)", <<"T02"],
everything will be restored, exactly as it were before.
T02
			[1, 1, 1, 2],
			["redo (scroll_right)", <<"T03"],
you will not be able to tell the difference, wheter scroll_right or redo occured.
T03
			[2, 1, 1, 1]
		]
		super(data)
	end
end

if $0 == __FILE__
	content = TestHorz.build
	body = CGI::tag("BODY") { content }
	head = CGI::tag("HEAD") { 
		CGI::tag("TITLE") { "test" } +
		CGI::tag("STYLE", {"TYPE"=>"text/css"}) { Generator.stylesheet } 
	}
	result = CGI::tag("HTML") { head + body }
	File.open("test.html", "w+") { |f| f.write result }
	puts "OK"
end
