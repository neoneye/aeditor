# blackbox (perl5 style) testing of this engine
require 'common'
require 'blackbox_p5'

class TestBlackboxP5 < Common::TestCase
	class CounterIterator < InputIterator
		@@n_open = 0
		@@n_close = 0
		def initialize(iterator, last_value=nil)
			@@n_open += 1
			@closed = false
			super(iterator, last_value)
		end
		def close
			if @closed
				raise "double close occured"
			end
			@@n_close += 1
			@closed = true
			super
		end
		def self.n_reset
			@@n_open = 0
			@@n_close = 0
		end
		def self.n_balance
			@@n_open - @@n_close
		end
		def self.n_open
			@@n_open
		end
		def self.n_close
			@@n_close
		end
	end
	class CounterScanner < Scanner
		# purpose is to count open/close of iterators
		def wrap_iterator(iterator)
			CounterIterator.new(iterator)
		end
	end
	def assert_regex(expected, regexp_string, input_string, options={})
		check_options_regexp(options)
		actual = nil
		actual_str = "nil"
		full_message = "/#{regexp_string}/ ~= #{input_string.inspect}\n"
		match_encoding = options[:encoding]
		execute_options = {}
		if match_encoding
			execute_options[:match_encoding] = match_encoding
		end
		begin
			CounterIterator.n_reset
			match = CounterScanner.execute(regexp_string, input_string, execute_options)
			actual = match.to_a if match
			actual_str = actual.inspect
		end
		full_message += "<#{expected.inspect}> expected but was\n<#{actual_str}>."
		ok = (expected == actual)
		if CounterIterator.n_balance != 0
			full_message += "\n"
			full_message = "" if ok
			full_message += "Iterator Open=#{CounterIterator.n_open} " +
				"Close=#{CounterIterator.n_close} (Expected them to be equal)."
			ok = false
		end
		assert_block(full_message) { ok }
	end
	def assert_regex_error(regexp_string) 
		full_message = "/#{regexp_string}/ should fail\n"
		ok = false
		begin
			Scanner.execute(regexp_string, input_string)
		rescue
			ok = true
		end
		full_message += "<Error> expected but got <None>."
		assert_block(full_message) { ok }
	end
	def assert_split(expected, regexp_string, limit, input_string)
		actual = nil
		actual_str = "nil"
		full_message = "#{input_string.inspect}.split(/#{regexp_string}/)\n"
		begin
			actual = Scanner.execute_split(regexp_string, input_string, limit)
			actual_str = actual.inspect
		end
		full_message += "<#{expected.inspect}> expected but was\n<#{actual_str}>."
		ok = (expected == actual)
		assert_block(full_message) { ok }
	end
	def assert_scan(expected, regexp_string, input_string, &block)
		actual = nil
		actual_str = "nil"
		full_message = "#{input_string.inspect}.scan(/#{regexp_string}/)\n"
		begin
			if block_given?
				actual = Scanner.execute_scan(regexp_string, input_string) do |match|
					block.call(match)
				end
			else
				actual = Scanner.execute_scan(regexp_string, input_string)
			end
			actual_str = actual.inspect
		end
		full_message += "<#{expected.inspect}> expected but was\n<#{actual_str}>."
		ok = (expected == actual)
		assert_block(full_message) { ok }
	end
	def assert_gsub(expected, regexp_string, input_string, replacement=nil, &block)
		actual = nil
		actual_str = "nil"
		full_message = "#{input_string.inspect}.gsub(/#{regexp_string}/, #{replacement.inspect})\n"
		begin
			if block_given?
				actual = Scanner.execute_gsub(regexp_string, input_string) do |match|
					block.call(match)
				end
			else
				actual = Scanner.execute_gsub(regexp_string, input_string, replacement)
			end
			actual_str = actual.inspect
		end
		full_message += "<#{expected.inspect}> expected but was\n<#{actual_str}>."
		ok = (expected == actual)
		assert_block(full_message) { ok }
	end
	module Works
		include MatchSequence
		include MatchRepeatLazy
		include MatchAlternation3
		include MatchRepeat
		include MatchRepeatMinimum
		include MatchRepeatMaximum   
		include MatchRepeatSequence
		include MatchAlternation
		include MatchVerbose
		include MatchAlternation2
		include MatchAdvancedRandom
		include MatchRepeatLazyNested 
		include MatchRepeatNested  
		include MatchRepeatNested2 
		include MatchRepeatNested3 
		include MatchAnchor
		include MatchAdvancedIprange
		include MatchBackref
		undef test_backref5  # nasty because backref refers to not-yet-existing capture.

		include MatchParentesis
		include MatchLookbehindPositive
		undef test_lookbehind_positive_with_backref1  # backrefs are hard to implement

		include MatchCharclass
		include MatchEmpty
		include MatchEscape

		include MatchCharclassWarn
		undef test_charclass_warn5 # empty char class 

		include MatchEndlessLoop
		undef test_endless_posixcomment1
		undef test_endless_eternal1  # infinite loop

		include MatchLookahead 
		undef test_lookahead_negative5  # problem with subcapture
		undef test_lookahead_negative7  # problem with subcapture
		include MatchLookbehindNegative
		undef test_lookbehind_negative5 # problem with subcapture 
		undef test_lookbehind_negative6 # problem with subcapture 
		undef test_lookbehind_negative7 # problem with subcapture 

		include MatchAtomicGrouping
		include MatchOptionIgnorecase
		include MatchOptionMultiline
		include MatchOptionExtended
		include MatchAdvancedPalindrome

		include MatchEncodingUTF8Codepoints
		undef test_utf8_codepoint2
		include MatchSplit
		include MatchScan
		#include MatchLongScan   # problem with stacklevel too deep
		include MatchGlobalSubstitute
		include MatchEncodingUTF16BECodepoints
		include MatchEncodingUTF16LECodepoints
	end

	module Todo
		include MatchEncodingUTF8Malformed
		include PossessiveQuantifiers
	end

	include Works
   	#include MatchLongScan  # TODO: make me work
end

TestBlackboxP5.run if $0 == __FILE__
