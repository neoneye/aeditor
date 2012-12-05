require 'cgi-lib'

class CGI
	def CGI.store(filename, html_data=nil, css_data=nil, title=nil)
		title ||= "unnamed"
		html_data ||= "empty"
		if css_data
			style = CGI::tag("STYLE", {"TYPE"=>"text/css"}){css_data} 
		else
			style = ""
		end
		result = CGI::tag("HTML") {
			CGI::tag("HEAD"){ CGI::tag("TITLE"){title} + style } +
			CGI::tag("BODY"){ html_data }
		}
		File.open(filename, "w") { |f| f.write result }
	end
end

class Frame
	def initialize(title, image)
		@title = title
		@image = image
	end
	attr_reader :title, :image
end

class JFrame
	def initialize(title, operation=nil, text=nil)
		@title = title
		@operation = operation || "unnamed"
		@text = text || "unnamed"
	end
	attr_reader :title, :text, :operation
end

class FrameSkeleton
	def initialize(data=nil)
		@frames = []
		@jframes = []
		return unless data
		ok = false
		f, jf = data.partition {|i| ok = !ok}
		state_id = 0
		@frames = f.map{|divisions| 
			diagram = build_diagram(*divisions)
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
	def FrameSkeleton.build
		self.new.generate
	end
	def build_diagram(*divisions)
		""
	end
	def generate
		if @frames.size != (@jframes.size+1)
			$stderr.puts "WARN: number of frames must be one greater than jframes!"
		end
		row0 = CGI::tag("TR") {
			ary = @frames.collect { |frame|
				CGI::tag("TH") { frame.title }
			}
			jary = @jframes.collect { |jf|
				CGI::tag("TH") { jf.title }
			}
			ary.zip(jary).flatten.compact
		}
		row1 = CGI::tag("TR") {
			ary = @frames.collect { |frame|
				CGI::tag("TD", {"ROWSPAN"=>"2", "CLASS"=>"state"}) { frame.image }
			}
			jary = @jframes.collect { |jf|
				CGI::tag("TD", {"CLASS"=>"opera"}) { jf.operation }
			}
			ary.zip(jary).flatten.compact
		}
		row2 = CGI::tag("TR") {
			jary = @jframes.collect { |jf|
				CGI::tag("TD", {"CLASS"=>"descr"}) { jf.text }
			}
			jary.join
		}
		content = row0 + row1 + row2
		CGI::tag("TABLE") { content }
	end
end
