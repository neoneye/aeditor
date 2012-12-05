# 28feb2004, Simon has just began implementation.
#
#
require 'regexp/abstract_syntax'

=begin
functions
* none

TODO:
* .    dot           ->  <any />   or   &any;
* [abc]              ->  <match>a b c</match>
* [^abc]             ->  <invmatch>a b c</invmatch>
* [a-z]              ->  <match>  <range begin="a" end="z"/>  </match>
* [[:digit:]]        ->  <match>  <class name="digit"/>       </match>
* (?i)               ->  <option ignorecase="yes" />
* (?: ... )*         ->  <loop> ... </loop>
* (?: ... ){5,42}?   ->  <loop min="5" max="42" greedy="no"> ... </loop>
* \1                 ->  <backref register="1" />
* " "                ->  &space;
* $                  ->  <linebegin/>
* ^                  ->  <lineend/>
* \b                 ->  <boundary/>
* ( ... )            ->  <group> ... </group>
=end
class ParserXml  # TODO: inherit from base class
	def initialize(input_text)
		@input = input_text
		listener = RegexpListener.new
		require "rexml/document"
		REXML::Document.parse_stream(@input, listener)
		@expression = listener.get_result
	end
	attr_reader :expression

	class RegexpListener
		include Debuggable
		include RegexFactory
		def initialize
			@result = []
		end
		def get_result
			return @result[0] if @result.size == 1
			mk_sequence(*@result)
		end
		def tag_start(name, attributes)
			puts "tag-start: " + name.inspect
		end
		def tag_end(name)
			puts "tag-end: " + name.inspect
		end
		def text(text)
			puts "text: " + text.inspect
			text.split(//).each do|symbol|
				next if [" ", "\t", "\n"].include?(symbol) 
				@result << mk_letter(symbol)
			end
		end
	end
end
