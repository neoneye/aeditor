require 'iterator'
require 'regexp/misc'
require 'regexp/parser'
require 'regexp/scanner_nodes'

class NewMatchData 
	attr_reader :pre_match, :post_match, :offset
	attr_reader :length, :captures, :string

	# create a NewMatchData object based on the string being matched
	# and array of match positions which is returned by the scanner 
	def initialize(string, positions)
		@offset, offset_end = positions[0]
		@string = string
		
		@matched_string = @string[@offset...offset_end]
		@length = offset_end - @offset

		@pre_match = @string[0...@offset]
		@post_match = @string[offset_end..-1] 
		
		@captures = positions[1..-1].map do |pair|
			if pair == nil
				nil
			else
				index = pair[0]
				length = pair[1] - index
				@string.slice(index, length)
			end
		end
		
		@match_array = [@matched_string, *@captures]
		@positions = positions
		#assign_globals
	end

=begin
	def assign_globals
		# TODO: assignment seems to be impossible ?
		@captures.each_with_index{|val, i|
			eval("$#{i+1} = val")
		}
		$& = @matched_string
		$` = @pre_match
		$' = @post_match
		$+ = @captures[-1]
	end
=end
	
	# returns the part of the string that was matched
	def to_s      
		@matched_string
	end
	
	# returns an array containing the part of the string that was
	# matched and the captured parts of the string
	def to_a
		@match_array
	end
	def [](index)
		@match_array[index]
	end
	    
	alias :select :[]
	alias values_at :[]
	
	def begin(index)
		@positions[index][0]
	end
	def end(index)
		@positions[index][1]
	end
	def size
		@positions.size
	end
end

class NewRegexp
	#include Debuggable

	# create a NewRegxp object based on the input string  
	# regexp = regular expression string
	def initialize(regexp_string)
		@source = regexp_string
		@scanner = Scanner.mk_regexp_string(regexp_string)
	end

	attr_reader :source, :scanner

	# match the regexp against string
	# returns nil if there is no match
	# or a NewMatchData object 
	def match(input_string)
		@scanner.match_string(input_string)
	end  

	# match the regexp against string
	# returns nil if there is no match
	# or the index of the first matching character   
	def =~(input_string)
		matchdata = @scanner.match_string(input_string)
		return nil unless matchdata
		matchdata.begin(0)
	end

	# smart equality test
	# returns true if the regexp matches the string
	def ===(input_string)
		matchdata = @scanner.match_string(input_string)
		return false unless matchdata
		true
	end

	def tree
		@scanner.tree
	end
end

class InputIterator < Iterator::ProxyLast
	include SymbolNames
	def is_word?(codepoint)
		return true if RANGE_az.member?(codepoint)
		return true if RANGE_AZ.member?(codepoint)
		return true if RANGE_09.member?(codepoint)
		(UNDERSCORE == codepoint)
	end
	def is_boundary?
		before = (@last_value and is_word?(@last_value))
		after = (@i.has_next? and is_word?(@i.current))
		(before != after)
	end
end

class Scanner
	def initialize(root)
		@root = root
	end
	attr_reader :root
	def find_match_at(input)
		#puts(('_'*30) + "execute at position #{input.position}")
		context = @root.mk_initial_context(input)
		@root.match(context)
		context.get_found # transfer ownership
	ensure
		context.close
	end
	def match_loop(input_iterator)
		loop do
			begin
				return find_match_at(input_iterator.clone)
			rescue Mismatch => e
				#puts "Mismatch: #{e.message}"
			end
			break unless input_iterator.has_next?
			input_iterator.next
			#puts "skip position, position -> #{input_iterator.position}"
		end
		nil
	ensure
		input_iterator.close
	end
	def wrap_iterator(iterator)
		InputIterator.new(iterator)
	end
	class MyUTF8 < Iterator::DecodeUTF8
		#alias :position, :glyph_pos
		def position
			@i.position
		end
	end
	class MyUTF16 < Iterator::DecodeUTF16
		#alias :position, :glyph_pos
		def position
			@i.position
		end
	end
	def create_iterator(input_string, encoding=:ASCII) 
		string_iterator = nil
		case encoding
		when :UTF8
			byte_iterator = input_string.create_iterator
			string_iterator = MyUTF8.new(byte_iterator)
		when :UTF16BE
			byte_iterator = input_string.create_iterator
			string_iterator = MyUTF16.mk_be(byte_iterator)
		when :UTF16LE
			byte_iterator = input_string.create_iterator
			string_iterator = MyUTF16.mk_le(byte_iterator)
		when :ASCII
			string_iterator = input_string.create_iterator
		else
			raise "unsupported encoding (#{encoding})"
		end
		wrap_iterator(string_iterator) 
	end
	def extract_positions(context)
		capt_pos = context.captures.map{|i| i ? i.position : nil }
		ok = false
		pos1, pos2 = capt_pos.partition{|i| ok=!ok}
		positions = pos1.zip(pos2)
		positions.map! do |pos|
			p1, p2 = pos
			(p1 && p2) ? pos : nil
		end
		positions
	end
	def match_string(input_string, encoding=:ASCII)
		iterator = create_iterator(input_string, encoding)
		found_context = match_loop(iterator)
		return nil unless found_context
		# transform context into matchdata
		positions = extract_positions(found_context)
		found_context.close
		NewMatchData.new(input_string, positions)
	end
	def split_string(input_string, encoding, limit)
		iterator = create_iterator(input_string, encoding || :ASCII)
		result = []
		limit = nil if limit and limit < 1
		n = 1
		begin
			while (limit == nil) or (n < limit)
				found_context = match_loop(iterator.clone)
				break unless found_context

				a = iterator.position
				b = found_context.captures[0].position
				result << input_string[a, b-a]

				# insert sub-captures
				positions = extract_positions(found_context)
				positions.shift # first capture are the whole match
				positions.each do |pair|
					unless pair
						result << '' 
						next
					end
					a, b = pair
					result << input_string[a, b-a]
				end

				iterator.next while iterator < found_context.captures[1]
				found_context.close
				n += 1
			end
			if (limit != nil) or (iterator.position < input_string.size)
				result << input_string[iterator.position..input_string.size-1]
			end
		ensure
			iterator.close
		end
		unless limit  # lets wipe tailing elements which are empty
			result.pop while result.size > 0 and result.last.empty?
		end
		result
	end
	def scan_string(input_string, encoding, &block)
		iterator = create_iterator(input_string, encoding || :ASCII)
		result = []
		n = 1
		begin
			loop do
				found_context = match_loop(iterator.clone)
				break unless found_context

				positions = extract_positions(found_context)
				match = NewMatchData.new(input_string, positions)

				if block_given?
					block.call(match)
				else
					if positions.size == 1
						a, b = positions[0]
						result << input_string[a, b-a]
					else
						ary = []
						positions.shift # ignore full-match
						positions.each do |pair|
							unless pair
								ary << '' 
								next
							end
							a, b = pair
							ary << input_string[a, b-a]
						end
						result << ary
					end
				end

				iterator.next while iterator < found_context.captures[1]
				found_context.close
			end
		ensure
			iterator.close
		end
		return input_string if block_given?
		result
	end
	def gsub_string!(input_string, encoding, limit=nil, replacement=nil, &block)
		iterator = create_iterator(input_string, encoding || :ASCII)
		result = []
		begin
			while (limit == nil) or (limit and limit > 0)
				found_context = match_loop(iterator.clone)
				break unless found_context

				positions = extract_positions(found_context)
				match = NewMatchData.new(input_string, positions)

				replace_str = ""
				if block_given?
					replace_str = block.call(match)
				end

				if replacement
					i = replacement.create_iterator
					begin
						while i.has_next?
							symbol = i.current
							str = symbol.chr  # TODO: unicode, problem with chr
							if symbol == SymbolNames::BACK_SLASH
								tmp = i.clone
								begin
									tmp.next
									if i.has_next?
										symbol2 = tmp.current
										case symbol2
										when SymbolNames::RANGE_09
											capture = symbol2.chr.to_i # TODO: unicode to_i
											str = match[capture] || ''
											i.next
										when SymbolNames::AMBERSAND
											str = match[0]
											i.next
										when SymbolNames::PLUS
											str = match[-1] || ''
											i.next
										when SymbolNames::BACK_QUOTE
											str = match.pre_match
											i.next
										when SymbolNames::QUOTE
											str = match.post_match
											i.next
										end
									end
								ensure
									tmp.close
								end
							end
							
							replace_str << str
							i.next
						end
					ensure
						i.close
					end
				end

				a, b = positions[0]
				result << [a, b-a, replace_str]

				iterator.next while iterator < found_context.captures[1]
				found_context.close

				limit -= 1 if limit
			end
		ensure
			iterator.close
		end
		result.reverse_each do |offset, length, replace_str|
			input_string[offset, length] = replace_str
		end
		input_string
	end
	def self.check_options(options, *optdecl)
		h = options.clone
		optdecl.each{|name|h.delete(name)}
		raise ArgumentError, "no such option: #{h.keys.join(' ')}" unless h.empty?
	end
	def self.execute(regexp_string, input_string, options={})
		check_options(options, :match_encoding)
		match_encoding = options[:match_encoding] || :ASCII
		scanner = self.compile(regexp_string)
		scanner.match_string(input_string, match_encoding)
	end
	def self.execute_split(regexp_string, input_string, limit=0)
		scanner = self.compile(regexp_string)
		scanner.split_string(input_string, nil, limit)
	end
	def self.execute_scan(regexp_string, input_string, &block)
		scanner = self.compile(regexp_string)
		unless block_given?
			return scanner.scan_string(input_string, nil)
		end
		scanner.scan_string(input_string, nil) do |match|
			block.call(match)
		end
	end
	def self.execute_gsub(regexp_string, input_string, replacement=nil, &block)
		scanner = self.compile(regexp_string)
		unless block_given?
			return scanner.gsub_string!(input_string, nil, nil, replacement)
		end
		scanner.gsub_string!(input_string, nil, nil) do |match|
			block.call(match)
		end
	end
	def self.compile(pattern)
		self.new(Root.compile(pattern))
	end
	def self.mk_regexp_string(regexp_string)  # TODO: get rid of me
		self.new(Root.compile(regexp_string))
	end
	def tree
		@root.parser.inspect
	end
end # class Scanner
