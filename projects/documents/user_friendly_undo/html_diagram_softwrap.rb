require 'misc'
require 'build_image_softwrap'

class SkeletonSoftwrap < FrameSkeleton
	@@diagram_id = 0
	@@diagrams = {}
	def build_diagram(*divisions)
		diagram_file = @@diagrams[divisions]
		unless diagram_file
			diagram_file = "soft"+@@diagram_id.to_s+".png"
			@@diagram_id += 1
			BuildImageSoftwrap.build(divisions, diagram_file)
			@@diagrams[divisions] = diagram_file 
			print "."
			$stdout.flush
		end
		CGI::tag("IMG", {"src"=>diagram_file})
	end
end

if $0 == __FILE__
	class Test < SkeletonSoftwrap
		def initialize
			data = [
				[[0, 2], [0, 0, 2, 4], ["ab ", "c ", "de  ", "f"]],
				["moveright", "placeholder"],
				[[1, 2], [0, 0, 2, 4], ["ab ", "c ", "de  ", "f"]],
				["insert 'X'", "placeholder"],
				[[2, 2], [1, 0, 2, 4], ["ab ", "c ", "deX  ", "f"]],
			]
			super(data)
		end
	end
	CGI::store("softwrap.html", Test.build, "", "Softwrap and Undo")
end
