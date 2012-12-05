# module COVERAGE__ originally (c) NAKAMURA Hiroshi, under Ruby's license
# module PrettyCoverage originally (c) Simon Strandgaard, under Ruby's license
# minor modifications by Mauricio Julio Fernández Pradier

require 'fileutils'
require 'rbconfig'
include Config

module PrettyCoverage

class HTML
	def write_page(body, title, css, filename)
		html = <<-EOHTML.gsub(/^\s*/, '') % [title, css, body]
		<?xml version="1.0" encoding="ISO-8859-1"?>
		<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
		  "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
		<html xmlns="http://www.w3.org/1999/xhtml" lang="en" xml:lang="en">
		<head><title>%s</title>
		<style type="text/css">%s</style></head>
		<body>%s</body></html>
		EOHTML
		File.open(filename, "w+") {|f| f.write(html) }
	end
	def escape(text)
		text.gsub(/&/, "&amp;").gsub(/\"/, "&quot;").gsub(/>/, "&gt;").gsub(/</, "&lt;")
	end
	def initialize
		@files = {}
		@files_codeonly = {}
		@filenames = {}
		@sidebar = ""
	end
	def output_dir(&block)
		dir = "coverage"
		if FileTest.directory?(dir)
			FileUtils.rm_rf(dir)
		end
		FileUtils.mkdir(dir)
		FileUtils.cd(dir) { block.call(dir) }
	end
	def load_sidebar
		return unless FileTest.file?("coverage.sidebar")
		data = nil
		File.open("coverage.sidebar", "r") {|f| data = f.read}
		@sidebar = "<div class=\"sidebar\">#{data}</div>"
	end
	def build_filenames
		duplicates = Hash.new(0)
		@files.keys.each do |filename, marked|
			base = File.basename(filename)
			absolute = File.expand_path(filename)
			n = duplicates[base]
			duplicates[base] += 1
			if n > 0
				base += n.to_s
			end
			@filenames[filename] = [base, absolute]
		end
		#p @filenames
	end
	def execute
		puts "execute"
		build_filenames
		load_sidebar
		output_dir do 
			create_file_index
			@files.each do |file, line_marked|
				create_file(file, line_marked, @files_codeonly[file])
			end
		end
	end
	def mk_filename(name)
		base_absolute = @filenames[name]
		raise "should not happen" unless base_absolute
		base, absolute = base_absolute
		return nil if absolute =~ /\A#{Regexp.escape(CONFIG["libdir"])}/
		return nil if base =~ /test_/
		[base + ".html", base, absolute]
	end
	def create_file_index
		output_filename = "index.html"
		rows = []
		filestats = {}
		filestats_code = {}
		@files.sort_by{|k,v| k}.each do|file, line_marked|
			url_filename = mk_filename(file)
			next unless url_filename
			percent = "%02.1f" % calc_coverage(line_marked)
			percent2 = "%02.1f" % calc_coverage(@files_codeonly[file])
			numlines = line_marked.transpose[1].size
			filestats[file] = [calc_coverage(line_marked), numlines]
			filestats_code[file] = [calc_coverage(@files_codeonly[file]),
			                        numlines]
			url, filename, abspath = url_filename
			cells = [
				"<a href=\"#{url}\">#{filename}</a>",
				"<tt>#{numlines}</tt>",
				"&nbsp;", "&nbsp;", "&nbsp;",
				"<tt>#{percent}%</tt>",
				"&nbsp;", "&nbsp;", "&nbsp;",
				"<tt>#{percent2}%</tt>"
			]
			rows << cells.map{|cell| "<td>#{cell}</td>"}
		end
		rows.map!{|row| "<tr>#{row}</tr>"}
		table = "<table>#{rows.join}</table>"
		total_cov = 1.0 *
			filestats.inject(0){|a,(k,v)| a + v[0] * v[1]} /
			filestats.inject(0){|a,(k,v)| a + v[1]}
		total_code_cov = 1.0 *
			filestats_code.inject(0) {|a,(k,v)| a + v[0] * v[1]} /
			filestats_code.inject(0){|a,(k,v)| a + v[1]}
		body = "<h1>Average (with comments): %02.1f%%</h1>" % total_cov
		body << "<h1>Average (code only): %02.1f%%</h1>" % total_code_cov
		body << @sidebar
		body << table
		title = "coverage"
		css = <<-EOCSS.gsub(/^\s*/, '')
		body {
		  background-color: rgb(180, 180, 180);
		}
		span.marked {
		  background-color: rgb(185, 200, 200);
		  display: block;
		}
		div.overview {
		  border-bottom: 8px solid black;
		}
		div.sidebar {
		  float: right;
		  width: 300px;
		  border: 2px solid black;
		  margin-left: 10px;
		  padding-left: 10px;
		  padding-right: 10px;
		  margin-right: -10px;
		  background-color: rgb(185, 200, 200);
		}
		EOCSS
		write_page(body, title, css, output_filename)
	end
	def add_file(file, line_marked)
		percent = calc_coverage(line_marked)
		path = File.expand_path(file)
		return nil if path =~ /\A#{Regexp.escape(CONFIG["rubylibdir"])}/
		return nil if path =~ /\A#{Regexp.escape(CONFIG["sitelibdir"])}/
		#printf("file #{file} coverage=%02.1f%\n", percent)

		# comments and empty lines.. we must
		# propagate marked-value backwards
		line_marked << ["", false]
		(line_marked.size).downto(1) do |index|
			line, marked = line_marked[index-1]
			next_line, next_marked = line_marked[index]
			if line =~ /^\s*(#|$)/ and marked == false
				marked = next_marked
				line_marked[index-1] = [line, marked]
			end
		end
		line_marked.pop
		@files[file] = line_marked
		@files_codeonly[file] = line_marked.select do |(line, marked)|
			line !~ /^\s*(#|$)/
		end
	end
	def calc_coverage(line_marked)
		marked = line_marked.transpose[1]
		n = marked.inject(0) {|r, i| (i) ? (r+1) : r }
		percent = n.to_f * 100 / marked.size
	end
	def format_overview(file, line_marked, code_marked)
		percent = "%02.1f" % calc_coverage(line_marked)
		percent2 = "%02.1f" % calc_coverage(code_marked)
		html = <<-EOHTML.gsub(/^\s*/, '')
		<div class="overview">
		<table>
		<tr><td>filename</td><td><tt>#{file}</tt></td></tr>
		<tr><td>total coverage</td><td>#{percent}%</td></tr>
		<tr><td>code coverage</td><td>#{percent2}%</td></tr>
		</table>
		</div>
		EOHTML
		html
	end
	def format_lines(line_marked)
		result = ""
		last = nil
		end_of_span = ""
		format_line = "%#{line_marked.size.to_s.size}d"
		line_no = 1
		line_marked.each do |(line, marked)|
			if marked != last
				result += end_of_span
				case marked
				when true
					result += "<span class=\"marked\">"
					end_of_span = "</span>"
				when false
					end_of_span = ""
				end
			end
			result += (format_line % line_no) + " " + escape(line) + "\n"
			last = marked
			line_no += 1
		end
		result += end_of_span
		"<pre>#{result}</pre>"
	end
	def create_file(file, line_marked, code_marked)
		url_filename = mk_filename(file)
		return unless url_filename
		output_filename, filename, abspath = url_filename
		puts "outputting #{output_filename.inspect}"
		body = format_overview(abspath, line_marked, code_marked) +
			format_lines(line_marked)
		title = filename + " - coverage"
		css = <<-EOCSS.gsub(/^\s*/, '')
		body {
		  background-color: rgb(180, 180, 180);
		}
		span.marked {
		  background-color: rgb(185, 200, 200);
		  display: block;
		}
		div.overview {
		  border-bottom: 8px solid black;
		}
		EOCSS
		write_page(body, title, css, output_filename)
	end
end # class HTML

end # module PrettyCoverage

SCRIPT_LINES__ = {} unless defined? SCRIPT_LINES__

module COVERAGE__
	COVER = {}
	def self.trace_func(event, file, line, id, binding, klass)
		case event
		when 'c-call', 'c-return', 'class'
			return
		end
		COVER[file] ||= []
		COVER[file][line] ||= 0
		COVER[file][line] += 1
	end
	END {
		set_trace_func(nil)
		printer = PrettyCoverage::HTML.new
		COVER.each do |file, lines|
			next if SCRIPT_LINES__.has_key?(file) == false
			lines = SCRIPT_LINES__[file]
			covers = COVER[file]
			line_status = []
			0.upto(lines.size - 1) do |c|
				line = lines[c].chomp
				marked = false
				if covers[c + 1]
					marked = true
				elsif /^\s*(?:begin\s*(?:#.*)?|ensure\s*(?:#.*)?|else\s*(?:#.*)?)$/ =~ line and covers[c + 1 + 1]
					covers[c + 1] = covers[c + 1 + 1]
					marked = true
				elsif /^\s*(?:end|\})\s*$/ =~ line && covers[c + 1 - 1]
					covers[c + 1] = covers[c + 1 - 1]
					marked = true
				end
				line_status << [line, marked]
			end
			printer.add_file(file, line_status)
		end
		printer.execute
	} # END
	set_trace_func(COVERAGE__.method(:trace_func).to_proc)
end # module COVERAGE__
