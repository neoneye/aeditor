=begin
purpose:
experimental syntax hiliter

features:
* input-lexers:   ruby
* output-formats: text, html

author:
Simon Strandgaard <neoneye@adslhome.dk>
=end

class PrettyBase
	def initialize
		@result = []
	end
	attr_reader :result
	def close
	end
	def escape(text)
		text
	end
	def default(text)
		@result << escape(text)
	end
	def blank(text); default(text) end
	def comment(text); default(text) end
	def heredoc(*texts); default(texts.join) end
	def identifier(text, type); default(text) end 
	def keyword(text); default(text) end 
	def number(text); default(text) end 
	def string(text); default(text) end 
	def regexp(text); default(text) end 
	def symbol(text); default(text) end 
end

=begin
TODO:  can you extend gray background of comments page wide?  
=end
class PrettyHtml < PrettyBase
	def initialize(output_filename=nil)
		super()
		@filename = output_filename || "index.html"
	end
	def mk_document(title, body)
		css = <<-EOCSS 
		body {
		  background-color: rgb(185, 200, 200);
		}
		pre {
		  font-size: 120%;
		  color: black;
		}
		span.comment, span.keyword, span.string, 
		span.regexp, span.iden0, span.iden1,
		span.symbol, span.heredoc_begin, span.heredoc_end {
		  display: inline;
		}
		span.comment {
		  background-color: rgb(180, 180, 180);
		}
		span.heredoc_begin, span.heredoc_data, span.heredoc_end {
		  background-color: rgb(180, 195, 195);
		}
		span.heredoc_data, span.heredoc_end {
		  border-left: 13px solid rgb(160,175,175);
		  margin-left: -13px;
		}
		span.heredoc_data {
		  display: block;
		  border-right: 13px solid rgb(160,175,175);
		  margin-right: -13px;
		}
		span.keyword, span.symbol {
		  font-weight: 900;
		}
		span.string {
		  font-weight: 800;
		  color: rgb(75, 120, 70);
		}
		span.regexp {
		  font-weight: 800;
		  color: rgb(80, 80, 100);
		}
		span.iden0 {
		  background-color: rgb(185, 200, 200);
		}
		span.iden1 {
		  color: rgb(0, 0, 60);
		  background-color: rgb(187, 200, 208);
		  border-top: 1px solid rgb(180, 200, 198); 
		  border-bottom: 1px solid rgb(180, 200, 198); 
		  margin-top: -1px;
		  margin-bottom: -1px;
		}
		EOCSS
		html = <<-EOHTML 
		<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
		  "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
		<html xmlns="http://www.w3.org/1999/xhtml" lang="en" xml:lang="en">
		<head><title>#{title}</title>
		<style type="text/css">#{css}</style></head>
		<body>#{body}</body></html> 
		EOHTML
		html
	end
	def close
		body = "<pre>" + @result.join + "</pre>"
		html = mk_document("syntax coloring experiment", body)
		File.open(@filename, "w+") {|f| f.write(html) }
	end
	def escape(text)
		text.gsub(/&/, "&amp;").gsub(/\"/, "&quot;").gsub(/>/, "&gt;").gsub(/</, "&lt;")
	end
	def push_tag(name, text)
		etext = escape(text)
		@result << "<span class=\"#{name}\">#{etext}</span>"
	end
	def comment(text)
		push_tag("comment", text)
	end
	def heredoc(*texts)
		push_tag("heredoc_begin", texts[0])
		push_tag("heredoc_data", texts[1])
		push_tag("heredoc_end", texts[2])
	end
	def keyword(text)
		push_tag("keyword", text)
	end
	def string(text)
		push_tag("string", text)
	end
	def symbol(text)
		push_tag("symbol", text)
	end
	def regexp(text)
		push_tag("regexp", text)
	end
	def identifier(text, type) 
		push_tag("iden#{type}", text)
	end 
end

class LexerBase
	def initialize(out_pretty=nil)
		@output = out_pretty || PrettyBase.new
	end
	def blank(text)
		puts "blank: #{text.inspect}"
		@output.blank(text)
	end
	def comment(text)
		puts "comment: #{text.inspect}"
		@output.comment(text)
	end
	def heredoc(*texts)
		puts "heredoc: #{texts.inspect}"
		@output.heredoc(*texts)
	end
	def keyword(text)
		puts "keyword: #{text.inspect}"
		@output.keyword(text)
	end
	def number(text)
		puts "number: #{text.inspect}"
		@output.number(text)
	end
	def string(text)
		puts "string: #{text.inspect}"
		@output.string(text)
	end
	def regexp(text)
		puts "regexp: #{text.inspect}"
		@output.regexp(text)
	end
	def symbol(text)
		puts "symbols: #{text.inspect}"
		@output.symbol(text)
	end
	def identifier(text, type=0)
		puts "identifier#{type}: #{text.inspect}"
		@output.identifier(text, type)
	end
	def lex_next(input)
		case input
		when /\A\S+/
			identifier($&)
		when /\A\s+/
			blank($&)
		else
			raise "should not happen"
		end
		return $'  # post-match
	end
	def lexer_loop(input)
		while input.size != 0
			input = lex_next(input)
		end
		@output.close
	end
end


=begin
TODO:  identify __END__ tags, and color that similar to heredoc.
TODO:  identify syntax errors, and color them red.
TODO:  identify code inlined in strings, regexp, heredoc
TODO:  strings ala VIM.. quotes=color1, stringdata=color2
TODO:  convert tabs into spaces. align to parent position.
TODO:  Can you do this: for each class boundary (say fr 
       Class... to ..end), the color alternates fr white to green.
=end
class LexerRuby < LexerBase
	KEYWORDS = %w(alias and begin BEGIN break case class def) +
		%w(defined? do else elsif end END ensure for if loop) +
		%w(module next nil not or raise redo require rescue) +
		%w(retry return self super then true false undef) +
		%w(unless until yield when while)
	REGEXP_KEYWORD = Regexp.new(
		'\A(?:' +
		KEYWORDS.map{|txt|Regexp.escape(txt)}.join('|') + 
		')\b'
	)

	SYMBOLS = ['(', ')'] + 
		%w(=== ==  =~  =>  =   !=  !~  !) +
		%w(<<  <=> <=  <   >=  >) +
		%w({   }   [   ]) +
		%w(::  :   ... ..) +
		%w(+=  +   -=  -   **  *   /   %) +
		%w(||  |   &&  &) +
		%w(,   ;) 
	REGEXP_SYMBOL = Regexp.new(
		'\A(?:' + 
		SYMBOLS.map{|txt|Regexp.escape(txt)}.join('|') + 
		')'
	)

	REGEXP_BLOCK = Regexp.new(
		'\A(do|\{)(\s*)(\|.*?\|)'
	)

	VAR_GLOBALS = %q(_~*$!@/\\;,.=:<>"-&`'+1234567890).split(//)
	REGEXP_VAR_GLOBAL = Regexp.new(
		'\A\$(?:' +
		VAR_GLOBALS.map{|txt|Regexp.escape(txt)}.join('|') +  
		'[[:alnum:]]+' +
		')'
	)

	STRINGS=[
		'("|\')(?:[^\\\\]|\\\\.)*?\1',   # normal string
		'\%(?:w|q|Q)?\\(.*?\\)'          # %w  strings
	]
	REGEXP_STRING = Regexp.new(
		'\A(?:' + 
		STRINGS.join('|') + 
		')'
	)

	COMMENTS = [
		'#.*$',                     # singleline comment
		'=begin$(?m).*?^=end$'      # multiline comment
	]
	REGEXP_COMMENT = Regexp.new(
		'\A(?:' + 
		COMMENTS.join('|') + 
		')'
	)

	REGEXP_HEREDOCS = [
		/\A(<<(\w+)\s*$.*?)(^.*?)(^\2$.*?^)/m,      #  <<HERE
		/\A(<<-(\w+)\s*$.*?)(^.*?)(^\s*\2$.*?^)/m   #  <<-HERE
	]

	def lex_next(input)
		case input
		when REGEXP_COMMENT
			comment($&)
		when *REGEXP_HEREDOCS
			heredoc($1, $3, $4)
		when REGEXP_BLOCK
			keyword($1); blank($2); identifier($3, 1)
		when REGEXP_KEYWORD
			keyword($&)
		when /\A\d+/
			number($&)
		when REGEXP_STRING
			string($&)   
		when /\A\/(.*?[^\\])?\//, /\A(?m)\/.*?[^\\]\//
			regexp($&)
		when REGEXP_SYMBOL
			symbol($&)
		when REGEXP_VAR_GLOBAL
			identifier($&, 1)  # global var
		when /\A@[[:alnum:]_]+/  
			identifier($&, 1)  # instance var
		when /\A(\.)([[:alnum:]_]+)/
			symbol($1)
			identifier($2, 0)  # dot method
		when /\A[[:alnum:]_]+/
			identifier($&, 0)  # normal var
		when /\A\S+/
			identifier($&, 0)  # normal var
		when /\A\s+/
			blank($&)
		else
			raise "should not happen"
		end
		return $'  # post-match
	end
end

=begin
html = PrettyHtml.new
lex = LexerRuby.new(html)
lex.lexer_loop(<<"CODE")
require 'test'
class Test
	# im a comment
	if 999 < 42
		# im another comment
		puts "hello"
	else
		puts <<EOTEXT
heredoc line#1
heredoc line#2
EOTEXT
	end
end # class Test
CODE
=end

if $0 == __FILE__
	code = ""
	File.open(__FILE__, "r") {|f| code = f.read }
	html = PrettyHtml.new
	lex = LexerRuby.new(html)
	lex.lexer_loop(code)
end
