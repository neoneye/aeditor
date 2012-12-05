require 'cgi-lib'

class RegexpSenario
	def initialize(title, regex, input)
		@title, @regex, @input = title, regex, input
		@stack = []
	end
	attr_reader :title, :regex, :input
	def status(i, r, stack=nil)
		@stack = stack || @stack
		s = "input=<B>I#{i}</B>&nbsp;&nbsp;regex=<B>R#{r}</B>"
		stack_pretty = @stack.map{|alternation_point, repeats|
			repeat_pretty = repeats.map{|i, r, n, c|
				"I#{i}_R#{r}_N#{n}_C#{c}"
			}.join(",")
			"<B>[I#{alternation_point} &lt;#{repeat_pretty}&gt;]</B>"
		}.join(",&nbsp;")
		s += "&nbsp;&nbsp;stack=[#{stack_pretty}]"
		c = CGI::tag("CODE"){s} 
		CGI::tag("TD", {"COLSPAN"=>"3"}){c} 
	end
	def reaction(condition, action)
		CGI::tag("TD"){condition} + 
		CGI::tag("TD"){"&rarr;"} + 
		CGI::tag("TD"){action} 
	end
	def match(value, action="")
		reaction("i.data == r.data == #{value.inspect}", action)
	end
	def mismatch(ivalue, rvalue, action="")
		reaction("i.data (#{ivalue.inspect}) != r.data " +
			"(#{rvalue.inspect})", action)
	end
	def body
		[]
	end
	def mk_infotable(ary, prefix="", attr=nil)
		attr ||= {}
		r1 = ""
		ary.each_index{|i| r1 += CGI::tag("TH"){prefix+i.to_s}}
		r2 = ary.map{|i| CGI::tag("TD"){i}}.join
		rows = CGI::tag("TR"){r1} + CGI::tag("TR"){r2} 
		CGI::tag("TABLE", attr){rows} 
	end
	def row_info
		txt = mk_infotable(@regex, "R", {"CLASS"=>"infol"}) +
			mk_infotable(@input, "I", {"CLASS"=>"infor"})
		row = CGI::tag("TD", {"COLSPAN"=>"3"}){txt} 
		CGI::tag("TR", {"CLASS"=>"info"}){row} 
	end
	def format_body
		n = 0
		rows = body.map{|r| 
			style = (n % 2 == 0) ? "a" : "b"
			n += 1
			CGI::tag("TR", {"CLASS"=>style}){r} 
		}.join
		CGI::tag("TABLE", {"CLASS"=>"regexp"}){
			row_info + rows 
		}
	end
	def build
		title = CGI::tag("H3"){@title} 
		CGI::tag("DIV", {"CLASS"=>"caption"}){ 
			title +
			format_body
		}
	end
	def RegexpSenario.build
		self.new.build
	end
	def style
		<<STY
table.regexp code {
	background: #77c;
	color: black;
}
table.regexp table.infol {
	border: 1px solid black;
}
table.regexp table.infor {
	border: 1px solid black;
}
table.regexp {
	border: 2px solid black;
}
div.caption h3 {
	margin-bottom: 0px;
}
div.caption {
	text-align: center;
}
body {
	background: #c7c7c9;
}
table.infol {
	float: left;
}
table.infor {
	float: right;
}
STY
	end
end

class String
	def html_save(filename, title=nil, css_data=nil)
		title ||= filename
		style = ""
		if css_data
			style = CGI::tag("STYLE", {"TYPE"=>"text/css"}){css_data}
		end
		filename += ".html"
		head = CGI::tag("HEAD"){CGI::tag("TITLE"){title} + style}
		body = CGI::tag("BODY"){self}
		html = CGI::tag("HTML"){head + body}
		html.save(filename)
	end
	def save(filename)
		File.open(filename, "w+"){|f| f.write self}
	end
end
