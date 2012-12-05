require 'misc'
require 'build_image_vertical'

class SenarioSkeleton < FrameSkeleton
	@@diagram_id = 0
	@@diagrams = {}
	def build_diagram(*divisions)
		diagram_file = @@diagrams[divisions]
		unless diagram_file
			diagram_file = "vert"+@@diagram_id.to_s+".png"
			@@diagram_id += 1
			BuildImageVertical.build(divisions, diagram_file)
			@@diagrams[divisions] = diagram_file 
			print "."
			$stdout.flush
		end
		CGI::tag("IMG", {"src"=>diagram_file})
	end
	def SenarioSkeleton.get_style
		style = <<CSS
TABLE {
	border-spacing: 0px;
}
TD, TR {
	padding: 0px;
	margin: 0px;
}
TABLE.state {
	border: 3px solid #111;
	border-spacing: 0px;
}
TABLE.state_bot {
	border: 3px solid #111;
	border-spacing: 0px;
	border-bottom: none;
}
TABLE.state_extra {
	border: 3px dotted #111;
	border-top: none;
	border-spacing: 0px;
}
TR.buf {
	background: #a7a9c0;
	color: #227;
}
TR.view {
	background: white;
	color: #558;
}
TR.cur {}
TR.cur TD {
	background: white;
	border-left: 8px solid black;
	border-right: 8px solid black;
}
TD.opera {
	text-align: center;
	padding-left: 10px;
	padding-right: 10px;
	border-bottom: 1px solid black;
}
TD.descr {
	text-align: justify;
	padding-left: 10px;
	padding-right: 10px;
	width: 200px;
}
TABLE.state TD {
	text-align: center;
	padding: 3px;
}
TABLE.state_bot TD {
	text-align: center;
	padding: 3px;
}
TABLE.dummy TD {
	text-align: center;
}
DIV.TITLE {
	text-align: center;
	border-style: double; 
	border-width: 16px;
}
CSS
		style
	end
end

if $0 == __FILE__
	class Senario < SenarioSkeleton
		def initialize
			data = [
				[0, 2, 1, 6],
				["pagedown", <<"T01"],
a typical page down operation.
T01
				[3, 2, 1, 3],
				["resize", <<"T02"],
Changing the height of the view should not affect undo/redo.
T02
				[1, 4, 2, 2],
				["undo (pagedown)", <<"T03"],
Undoing behaves quite differently from a ordinary page-up operation.
This is because of resize!
T03
				[0, 2, 4, 3],
				["redo (pagedown)", <<"T04"],
If we redo, then the page-down operation is no longer a
typical behavier. Therefore <b>watch&nbsp;out</b> redoing page-down, when
the height has changed!
T04
				[0, 5, 1, 3]
			]
			super(data)
		end
	end
	CGI.store("index.html", Senario.build, Senario.get_style)
end
