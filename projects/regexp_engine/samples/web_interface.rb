# PURPOSE:
#
#  test regexp interactive via browser
#
#
#
# NOTE:
#
#  this sample requires Apache with 'mod_ruby' installed.
#  Place this sample in your web folder. You may have to change the 
#  file suffix to '.rbx' so that mod_ruby can recognize the file.
#
#
require "cgi"
require "timeout"
$cgi = CGI.new("html4")

def cgi
	$cgi
end

begin
	require "regexp"
rescue LoadError
	cgi.out { cgi.html{ cgi.body{
	<<MSG
<b>ERROR: could not require 'regexp'!</b><br />
package is maybe not installed correct?<br />
check that 'regexp' really are in your path.
<pre>#{$:.join("\n")}</pre>
MSG
	} } }
	exit
end

INFORMATION = <<INF.chomp
<div style="width: 600px"><p>This is a demonstration of 
<b>[</b><tt><a href="http://raa.ruby-lang.org/list.rhtml?name=regexp">regexp-engine</a></tt><b>]</b> 
for Ruby. Featuring both perl5 and perl6 style syntax. However only perl5
can be exercised on this page. Please report bugs to 
<b>[</b><tt><a href="mailto:neoneye@adslhome.dk">Simon Strandgaard</a></tt><b>]</b> 
the author of the engine.</p></div>
INF

def mk_table_pairs(tabledata, style=nil, footcontent=nil)
	cls = (style==nil) ? "" : " class=\"#{style}\""
	footcontent ||= ""
	"<table#{cls}>" + tabledata.map{|(desc, value)|
		"<tr><td>#{desc}</td><td>#{value}</td></tr>"
	}.join("\n") + footcontent + "</table>"
end

def mk_no_result
	tabledata = [
		["status", "-"]
	]
	mk_table_pairs(tabledata, "result")
end

def pretty_tree(str)
	str.gsub!(/(^[\s\+\-\|]+)(?=\w)/, '<span>\1</span>')
	str
end

def mk_result(value_regexp, value_input)
	if value_regexp.size > 40
		return "<b>regexp must max be 40 letters long, try again.</b>"
	end
	if value_input.size > 50
		return "<b>input must max be 50 letters long, try again.</b>"
	end
	table = []
	table << ["regexp", "<tt>"+value_regexp+"</tt>"] 
	table << ["input", "<tt>"+value_input+"</tt>"]
	re = nil
	foot = "could not compile"
	begin
		re = NewRegexp.new(value_regexp)
		tree = pretty_tree(re.tree)
		foot = "<pre>ParseTree\n#{tree}</pre>"
	rescue RegexpError => e
		table << ["error", "<pre>#{e.message}</pre>"]
	end
	if re
		match = nil
		begin
			timeout(8.0) do
				match = re.match(value_input)
			end
		rescue TimeoutError
			return "<b>operation timed out, please report to author.</b>"
		end
		if match
			table << ["status", "match"]
			match.to_a.each_with_index{|str, i|
				table << ["capture ##{i}", "<tt>#{str}</tt>"]
			}
		else
			table << ["status", "<strong>mismatch</strong>"]
		end
	end
	footcontent = "<tr><td colspan=\"2\">#{foot}</td></tr>"
	mk_table_pairs(table, "result", footcontent)
end

def mk_body
	value_regexp = nil
	value_input = nil
	if cgi.has_key?('regexp')
		value_regexp = cgi.params['regexp'][0]
	end
	if cgi.has_key?('input')
		value_input = cgi.params['input'][0]
	end
	fill_random = (value_regexp == nil and value_input == nil) 
	if cgi.has_key?('rand')
		cgi.params['rand'][0] = nil
		fill_random = true
	end
	if fill_random
		random_pairs = [
			["a(.*)b(.*)c(.*)d(.*)e", "0a1b2c3b3cd5e6ee7"],
			["(a.*b){2}", "0a1b2ba3b4"],
			["x(.*)*y(.*)*z", "0x1y2y3z4z5"],
			["(foob|fo|o)*bar", "xfoobarx"],
			["((a|b)(c|d))*", "bcacao"],
			["a(b(c|d)|e)f", "0aef1"],
			['(\w+):\/\/([^/:]+)(:\d*)?([^# ]*)', "http://hidden.neoneye.dk:8080/very/secret.html"]
		]
		value_regexp, value_input = random_pairs[rand(random_pairs.size)]
	end
	result = ""
	if value_regexp or value_input
		result = "\n"+mk_result(value_regexp, value_input)
	else
		result = "\n"+mk_no_result
	end
	result+"\n"+cgi.form("get"){
		"\n<table class=\"form\"><tr><td>" +
		cgi.h5{"search pattern"} +"</td><td>"+
		cgi.text_field("regexp", value_regexp) +"</td></tr>\n<tr><td>"+
		cgi.h5{"input text"} +"</td><td>"+
		cgi.text_field("input", value_input) +
		"</td></tr>\n<tr><td colspan=\"2\" class=\"center\">"+
		cgi.submit("find") + " " + cgi.submit("random", "rand") + 
		"</td></tr></table>" + INFORMATION
	}
rescue => e
	bt = e.backtrace.map{|line| CGI::escapeHTML(line)}.join("\n")
	"Error: " + CGI::escapeHTML(e.message) + "<br><pre>" + bt + "</pre>"
end 

style_css=<<EOCSS
h5 {
	display: inline;
}
body {
	background-color: rgb(180, 180, 180);
	margin-left: 60px;
	margin-right: 60px;
}
table.form {
	background-color: rgb(195, 200, 200);
	border: 2px black solid;
}
table.result {
	float: right;
	background-color: rgb(195, 200, 200);
	border: 2px black solid;
}
td.center {
	text-align: center;
}
pre span {
	color: rgb(90, 110, 110);
}
EOCSS

cgi.out{
	cgi.html{
		cgi.head{ "\n" + cgi.title{"Regular Expressions Playground"} +
			"<style type=\"text/css\">#{style_css}</style>"
		} +
		cgi.body{ mk_body }
	}
}
