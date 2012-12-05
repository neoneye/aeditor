# = iterator.rb - bidirectional external iterators
#
# Here is a bunch of iterator primitives. The primary methods 
# is named <tt>has_next?</tt> and <tt>next</tt> so that should
# be easy to remember. All classes herein is carefully tested.
#
# Author::   Simon Strandgaard (mailto:neoneye@adslhome.dk)
# License::  Ruby license
# Bugs::     http://rubyforge.org/tracker/?atid=149&group_id=18&func=browse
# Download:: http://rubyforge.org/frs/?group_id=18
#
module Iterator

VERSION = "0.8"

# Base class which all iterators should derive from.
# It includes Ruby's Enumerable module.
#
# All iterators are able to move forward. However not all
# iterators are capable of moving backward. For instance 
# Iterator::Continuation are <i>forward-only</i>.
class Base
	include Enumerable
	include Comparable
	# remember to close the door after us. 
	def close; end
	# Reset iterator, so that it points to the <i>first</i> element
	# This method are suppose to return <tt>self</tt>.
	def first; self end
	# move one step forward
	def next1; nil end
	# can we move one step forward
	def has_next?; false end
	# Reset iterator, so that it points to the <i>last</i> element
	# This method are suppose to return <tt>self</tt>.
	def last; self end
	# move one step backwards
	def prev1; nil end
	# can we move one step forward
	def has_prev?; false end
	# return that element we are currently pointing at
	def current; nil end
	# overwrite that element we are currently pointing at
	def current=(value); nil end
	# return the current position
	def position; nil end
	# compare positions
	def <=>(other) 
		if self.class != other.class
			raise TypeError, "supplied type (#{other.class}) not comparable with #{self.class}."
		end
		position <=> other.position 
	end
	# return that element we are currently pointing at <b> - 1</b>
	def current_prev 
		raise "no prev element" unless has_prev?
		begin
			i = self.clone.prev
			return i.current
		ensure
			i.close
		end
	end
	# overwrite that element we are currently pointing at <b> - 1</b>
	def current_prev=(value)
		raise "no prev element" unless has_prev?
		begin
			i = self.clone.prev
			i.current = value
		ensure
			i.close
		end
	end
	# Move <i>n</i> steps forward.
	# This method are suppose to return <tt>self</tt>.
	def next(n=1)
		n.times { self.next1 }
		self
	end
	# Move <i>n</i> steps backwards.
	# This method are suppose to return <tt>self</tt>.
	def prev(n=1)
		n.times { self.prev1 }
		self
	end
	# reset iterator at first element, and move forward
	# until last-element has been reached.
	def each
		first
		while has_next?
			yield(current)
			self.next
		end
	end
	# reset iterator at last element, and move backwards
	# until first-element has been reached.
	def reverse_each
		last
		while has_prev?
			self.prev
			yield(current)
		end
	end
	# create an iterator which moves the opposite direction.
	#
	# <b>remember</b> to invoke <tt>#close</tt> when you are done.
	def reverse
		Reverse.new(self.clone)
	end
end


# == Iterate Through A Collection 
#
#  require 'iterator'
#  ary = [1, 2, 3, 4]
#  i = Iterator::Collection.new(ary)
#  p i.current  # 1
#  i.next
#  p i.current  # 2 
#  i.close
#
# Above we initialize the collection with an Array, but that could be 
# another similar classes. The class just have to implement a <tt>[]</tt> method
# and a +size+ method, then we are able to iterate through it. 
#
# Because its pretty common to iterate through Array's, there has been 
# added shortcut (Array.create_iterator), so there is less typing.
#
#  require 'iterator'
#  ary = [1, 2, 3, 4]
#  i = ary.create_iterator
#  p i.current  # 1
#  i.next
#  p i.current  # 2
#  i.close
#
class Collection < Iterator::Base
	# which elements points the iterator currently at
	attr_reader :position
	# points at the Array we got initialized with
	attr_reader :data
	# Create a Collection instance. Supply as the +data+ argument, a 
	# reference to the Array you intent to traverse.
	#
	#  data = [1, 2, 3, 4]
	#  iterator = Iterator::Collection.new(data)
	#
	def initialize(data)
		@data = data
		first
	end              
	def close #:nodoc:
	end
	def first #:nodoc:
		@position = 0; 
		self 
	end
	def next1 #:nodoc:
		@position += 1 
	end
	def has_next? #:nodoc: 
		(@position < @data.size) 
	end
	def last #:nodoc:
		@position = @data.size
		self
	end
	def prev1 #:nodoc:
		@position -= 1
	end
	def has_prev? #:nodoc:
		(@position > 0)
	end
	def current #:nodoc:
		raise "index error" if @position >= @data.size
		@data[@position] 
	end
	def current=(value) #:nodoc:
		# TODO: raise "index error" if @position >= @data.size
		# figure out a better way to allow for append to array ?
		@data[@position] = value 
	end
	def current_prev #:nodoc:
		raise "index error" if @position-1 < 0
		@data[@position-1] 
	end
	def current_prev=(value) #:nodoc:
		raise "index error" if @position-1 < 0
		@data[@position-1] = value 
	end
	def ==(other) #:nodoc:
		(self.class == other.class) and 
		(@position == other.position) and 
		(@data == other.data)
	end
end

# == Reverse Direction Of Iterator
#
#  require 'iterator'
#  ary1 = %w(a b c d e f)
#  i1 = ary1.create_iterator
#  iterator = Iterator::Reverse.new(i1)
#  result = iterator.to_a
#  iterator.close
#  i1.close
#  p result  # ["f", "e", "d", "c", "b", "a"]
#
# Is bidirectional.
class Reverse < Iterator::Base
	# Create an instance of Reverse. Must be supplied an iterator.
	def initialize(iterator) 
		@i = iterator 
	end
	attr_reader :i
	def close #:nodoc:
		@i.close
	end
	def clone #:nodoc:
		self.class.new(@i.clone)
	end
	def ==(other) #:nodoc:
		(self.class == other.class) and (@i == other.i)
	end
	def first #:nodoc:
		@i.last
		self
	end
	def next1 #:nodoc:
		@i.prev
	end
	def has_next? #:nodoc:
		@i.has_prev? 
	end
	def last #:nodoc:
		@i.first
		self 
	end
	def prev1 #:nodoc:
		@i.next 
	end
	def has_prev? #:nodoc:
		@i.has_next?
	end
	def current #:nodoc:
		@i.current_prev 
	end
	def current=(value) #:nodoc:
		@i.current_prev=value 
	end
	def position #:nodoc:
		@i.position
	end
	def current_prev #:nodoc:
		@i.current
	end
	def current_prev=(value) #:nodoc:
		@i.current=value 
	end
end

# == Traverse Between 2 Iterators
#
#  require 'iterator'
#  ary1 = %w(a b c d e f)
#  i1 = ary1.create_iterator
#  i1.next
#  i2 = ary1.create_iterator_end
#  i2.prev
#  iterator = Iterator::Range.new(i1, i2)
#  result = iterator.to_a
#  iterator.close
#  i1.close
#  i2.close
#  p result # ["b", "c", "d", "e"]
#
# Observe that both first and last element got correctly excluded 
# from the result.
#
# This is bidirectional.
class Range < Iterator::Base
	# Create an instance of Range, where the spans is defined the
	# +start+ and +stop+ iterators.
	def initialize(start, stop, position=nil)
		super()
		@start = start
		@stop = stop
		@i = position
		first if @i == nil
	end
	def close #:nodoc:
		@start.close
		@stop.close
		@i.close if @i
	end
	def clone #:nodoc:
		self.class.new(@start.clone, @stop.clone, @i.clone)
	end
	def first #:nodoc:
		@i.close if @i
		@i = @start.clone 
		self
	end
	def next1 #:nodoc:
		@i.next
	end
	def has_next? #:nodoc:
		(@i.position < @stop.position)
	end
	def last #:nodoc:
		@i.close if @i
		@i = @stop.clone 
		self
	end
	def prev1 #:nodoc:
		@i.prev
	end
	def has_prev? #:nodoc:
		(@i.position > @start.position)
	end
	def current #:nodoc:
		@i.current
	end
	def current=(value) #:nodoc:
		@i.current = value
	end
	def position #:nodoc:
		@i.position 
	end
end

# == Concat Many Iterators Into One
#
#  require 'iterator'
#  ary1 = %w(a b c)
#  ary2 = [1, 2, 3]
#  i1 = ary1.create_iterator
#  i2 = ary2.create_iterator
#  i3 = Iterator::Continuation.new(ary1, :reverse_each)
#  iterator = Iterator::Concat.new([i1, i2, i3])
#  result = iterator.map{|i|i.inspect}.join(", ")
#  iterator.close
#  i1.close
#  i2.close
#  i3.close
#  puts result  # "a", "b", "c", 1, 2, 3, "c", "b", "a"
#
# Explaination of output: First 3 elements is <tt>ary1</tt>. Middle 3 elements 
# is <tt>ary2</tt>. Last 3 elements is the reverse of <tt>ary1</tt>.
#
# Beware that backward iteration, depends on the features of the supplied
# iterators. If all of them supports backwards iteration, then backwards
# iteration also works when concatenating them. If this isn't fullfilled then
# only forward iteration is possible. 
#
class Concat < Iterator::Base
	# Create an instance of Concat. Must be supplied an
	# Array of iterators as argument.
	#
	#  ary = [i1, i2, i3]
	#  iterator = Iterator::Concat.new(ary)
	#
	def initialize(iterators, position=nil)
		@iterators = iterators
		if position
			@position = position
		else
			@position = 0
			first
		end
		skip_next
	end
	def close #:nodoc:
		@iterators.map{|i|
			i.close
			i = nil
		}
	end
	def clone #:nodoc:
		ary = @iterators.map{|i| i.clone}
		self.class.new(ary, @position)
	end
	attr_reader :position
	def first #:nodoc:
		@position = 0
		@iterators[@position].first
		skip_next
		self
	end
	def skip_next #:nodoc:
		p = @position
		until @iterators[p].has_next? 
			p += 1
			return if p >= @iterators.size 
			@iterators[p].first
		end
		@position = p
	end
	def next1 #:nodoc:
		skip_next
		if @iterators[@position].has_next?
			@iterators[@position].next  
		end
		skip_next
	end
	def has_next? #:nodoc:
		p = @position
		until @iterators[p].has_next?
			p += 1
			return false if p >= @iterators.size
			@iterators[p].first
		end
		true
	end
	def last #:nodoc:
		@position = @iterators.size-1
		@iterators[@position].last
		skip_prev
		self
	end
	def skip_prev #:nodoc:
		p = @position
		until @iterators[p].has_prev? 
			p -= 1
			return if p < 0 
			@iterators[p].last
		end
		@position = p
	end
	def prev1 #:nodoc:
		skip_prev
		if @iterators[@position].has_prev?
			@iterators[@position].prev 
		end
		skip_prev
	end
	def has_prev? #:nodoc:
		p = @position
		until @iterators[p].has_prev?
			p -= 1
			return false if p < 0
			@iterators[p].last
		end
		true
	end
	def current #:nodoc:
		skip_next
		@iterators[@position].current
	end
	def current=(value) #:nodoc:
		skip_next
		@iterators[@position].current = value
	end
	def current_prev #:nodoc:
		skip_prev
		super()
	end
	def current_prev=(value) #:nodoc:
		skip_prev
		super(value)
	end
end

# == Convert Ruby's Internal Iterators
#
#  require 'iterator'
#  str = %w(a b c).join("\n")
#  iterator = Iterator::Continuation.new(str, :each_line)
#  result = iterator.map{|i|"<<#{i}>>"}
#  iterator.close
#  p result  # ["<<a\n>>", "<<b\n>>", "<<c>>"]
#
# converts #each intern-iterators into extern-iterators
# forward only. Its not possible to reverse the iterator!
#
class Continuation < Iterator::Base
	# Create a Continuation instance.
	#
	#  data = "hello world"
	#  iterator = Iterator::Continuation.new(data, :each_byte)
	#
	def initialize(instance, symbol, position=nil)
		@instance = instance
		@symbol = symbol
		@position = 0
		first
		(position || 0).times { self.next }
	end
	attr_reader :position
	def first #:nodoc:
		@value = nil
		@resume_where = false
		@return_where = Proc.new{}
		@instance.method(@symbol).call {|i|
			@value = i
			callcc{|@resume_where|
				@return_where.call
				return self
			}
		}
		@resume_where = false
		@return_where.call
		self
	end
	def next1 #:nodoc:
		@position += 1
		callcc{|@return_where| @resume_where.call }
	end
	def has_next? #:nodoc:
		@resume_where != false
	end
	def current #:nodoc:
		@value
	end
	def clone #:nodoc:
		self.class.new(@instance, @symbol, @position)
	end
	def marshal_dump #:nodoc:
		[@instance, @symbol, @position]
	end
	def marshal_load(arr) #:nodoc:
		initialize(*arr)
	end
end


# == Remembering The Last Value
#
#  require 'iterator'
#  ary1 = %w(a b c)
#  i1 = ary1.create_iterator
#  iterator = Iterator::ProxyLast.new(i1)
#  result = []
#  while iterator.has_next?
#    result << [iterator.last_value, iterator.current]
#    iterator.next
#  end
#  iterator.close
#  i1.close
#  p result  # [[nil, "a"], ["a", "b"], ["b", "c"]]
#
# This class is bidirectional, so reverse is therefore possible.
#
class ProxyLast < Iterator::Base
	# Create an instance of ProxyLast. Must supplied an <tt>iterator</tt>.
	# The <tt>last_value</tt> is optional, and is only being 
	# used in the first iteration.
	#
	#  i1 = "hello".split(//).create_iterator
	#  iterator = Iterator::ProxyLast.new(i1, 'border')
	def initialize(iterator, last_value=nil) 
		@i = iterator 
		@last_value = last_value
	end
	# caching of the last element 
	attr_reader :last_value  
	# iterator that is wrapped by us
	attr_reader :i  
	def first #:nodoc:
		@last_value = nil
		@i.first 
		self 
	end
	def next1 #:nodoc:
		@last_value = current
		@i.next1
	end
	def has_next? #:nodoc:
		@i.has_next?
	end
	def current #:nodoc:
		@i.current 
	end
	def current=(value) #:nodoc:
		@i.current = value 
	end
	def position #:nodoc:
		@i.position 
	end
	def close #:nodoc:
		@i.close 
	end
	def clone #:nodoc:
		self.class.new(@i.clone, @last_value)
	end
	def ==(other) #:nodoc:
		(self.class == other.class) and 
		(@i == other.i) and 
		(@last_value == other.last_value)
	end
	def reverse #:nodoc:
		# check if current is present.. otherwise nil
		lastval = @i.has_next? ? @i.current : nil 
		return self.class.new(@i.i.clone, lastval) if @i.kind_of?(Reverse)
		rev = Reverse.new(@i.clone)
		self.class.new(rev, lastval)
	end
end


# == Read from file
#
#  require 'iterator'
#  file = File.open(__FILE__)
#  iterator = Iterator::File.new(file)
#  rev_iterator = iterator.reverse
#  p rev_iterator.map{|byte| byte.chr}.join
#  rev_iterator.close
#  iterator.close
#
# can go both forward and backward
# 
# when you invoke <tt>close</tt> on the iterator it
# will close the file-handle for you.. so no need to
# do <tt>file.close</tt>
class File < Base
	def initialize(file)
		@file = file
	end
	attr_reader :file
	def clone #:nodoc:
		fd = @file.dup
		#fd.seek(@file.pos, IO::SEEK_SET)   # see [ruby-talk:100982]
		self.class.new(fd)
	end
	def close #:nodoc:
		@file.close
	end
	def first #:nodoc:
		@file.rewind
		self
	end
	def last #:nodoc:
		@file.seek(0, IO::SEEK_END)
		self
	end
	def has_next? #:nodoc:
		not @file.eof?
	end
	def next1 #:nodoc:
		@file.seek(1, IO::SEEK_CUR)
	end
	def current #:nodoc:
		byte = @file.getc
		@file.seek(-1, IO::SEEK_CUR)
		byte
	end
	def has_prev? #:nodoc:
		(@file.pos > 0)
	end
	def prev1 #:nodoc:
		@file.seek(-1, IO::SEEK_CUR)
	end
	def current_prev #:nodoc:
		@file.seek(-1, IO::SEEK_CUR)
		@file.getc
	end
	def position #:nodoc:
		@file.pos
	end
end


# == Translate UTF8 encoded strings to unicode
#
# Often <tt>String.unpack('U*')</tt> is sufficiently, however sometimes
# more advanced decoding are necessary (when you want to make a
# text-editor or a regexp-engine).
#
#  require 'iterator'
#  str = [9000, 500, 16000, 666].pack('U*')
#  byte_iterator = Iterator::Continuation.new(str, :each_byte)
#  decoder = Iterator::DecodeUTF8.new(byte_iterator)
#  p decoder.to_a   # -> [9000, 500, 16000, 666]
#  decoder.close
#  byte_iterator.close
#
# This class is bidirectional, if you want you can decode UTF8 sequences
# backwards. 
#
# Its readonly for now, maybe I will add write-support in the future, 
# but only if people are putting pressure on me <tt>:-)</tt>
class DecodeUTF8 < Iterator::Base
	# == In case of malformed data a Malformed exception is raised.
	class Malformed < StandardError; end
	# == In case of redundant bytes a Overlong exception is raised.
	class Overlong < StandardError; end

	# Create an instance of the DecodeUTF8 class. Must supplied an 
	# <tt>iterator</tt> which yields integers between 0 and 255.
	def initialize(i, position=nil)
		@i = i
		@position = position || 0
	end
	# the iterator which yields bytes
	attr_reader :i 
	# which character are we pointing at now
	attr_reader :position
	def clone #:nodoc: 
		self.class.new(@i.clone, @position)
	end
	def first #:nodoc:
		@i.first
		@position = 0
		self
	end
	def last #:nodoc:
		@i.first
		self.next while self.has_next? # this line is expensive compared to #first
		self
	end
	def bytes_to_codepoint(ary) #:nodoc:
		first_byte = ary.shift
		bytes, bit = extract_bytes_bit(first_byte)
		res = first_byte & (0xff >> (8 - bit))
		ary.each {|i| res = (res << 6) + (i & 0x3f) }
		res
	end
	def calc_bytes(code_point) #:nodoc:
		[7, 11, 16, 21, 26].each_with_index do |bits, index|
			return index+1 if code_point < (1<<bits)
		end
		6
	end
	def extract_bytes_bit(first_byte) #:nodoc:
		bytes = 2 
		bit = 5
		until first_byte[bit] == 0
			bit -= 1
			bytes += 1
		end
		[bytes, bit]
	end
	def current #:nodoc:
		raise "end of input" unless @i.has_next?             # TODO: test me
		value = @i.current
		return value if value < 0x80
		if (value & 0xc0) == 0x80
			raise Malformed, "unexpected continuation byte. " +
				"byte-offset=#{@i.position}"
		end
		if value == 0xff or value == 0xfe
			raise Malformed, "not a valid UTF8 byte. " +
				"byte-offset=#{@i.position}"
		end
		bytes, = extract_bytes_bit(value)
		ary = [value]
		# parse following bytes in sequence
		input = @i.clone
		begin
			(bytes-1).times do |n|
				input.next
				raise "end of input" unless input.has_next?  # TODO: test me
				val = input.current
				if (val & 0xc0) != 0x80
					raise Malformed, "previous multibyte sequence is incomplete. " +
						"byte-offset=#{input.position}" 
				end
				ary.push(val)
			end
		ensure
			input.close
		end
		codepoint = bytes_to_codepoint(ary)
		check_not_overlong(codepoint, bytes, @i)
		codepoint
	end
	def check_not_overlong(code_point, bytes, iterator) #:nodoc:
		if bytes != calc_bytes(code_point)
			raise Overlong, "byte-offset=#{iterator.position}"
		end
	end
	def has_next? #:nodoc:
		@i.has_next?
	end
	def next1 #:nodoc:
		raise "end of input" unless @i.has_next?    # TODO: test me
		@position += 1
		value = @i.current
		if value < 0x80 # one-byte value
			@i.next
			return
		end
		if (value & 0xc0) == 0x80
			@i.next
			return
		end
		if value >= 0xfe # must not occur in utf8 at all
			@i.next
			return
		end
		# there may be some situations where the code-point are invalid,
		# where we have to stop earlier.
		bytes, = extract_bytes_bit(value)
		@i.next
		(bytes-1).times do |n|
			return unless @i.has_next?
			return if (@i.current & 0xc0) != 0x80
			@i.next
		end
	end
	def has_prev? #:nodoc:
		@i.has_prev?
	end
	def prev1 #:nodoc:
		raise "end of input" unless @i.has_prev?    # TODO: test me
		@position -= 1
		value = @i.current_prev
		@i.prev
		return if value < 0x80 or value >= 0xc0
		input = @i.clone
		begin
			5.times do
				return unless input.has_prev?    # TODO: test me 
				value = input.current_prev
				return if value == 0xff or value == 0xfe
				input.prev
				return if value < 0x80
				if value >= 192  # stop when reaching first-byte
					@i.prev while input < @i
					return
				end
			end
		ensure
			input.close
		end
	end
	def current_prev #:nodoc:
		raise "end of input" unless @i.has_prev?    # TODO: test me
		value = @i.current_prev
		return value if value < 0x80 # one-byte value
		input = @i.clone.prev
		begin
			ary = [value]
			while value < 192 
				if value < 128 or ary.size >= 6
					raise Malformed, "unexpected continuation byte. " +
						"byte-offset=#{@i.position-1}" 
				end
				return unless input.has_prev?    # TODO: test me 
				value = input.current_prev
				input.prev
				ary.unshift(value)
			end
			if ary.first == 0xff or ary.first == 0xfe
				if ary.size > 1
					raise Malformed, "unexpected continuation byte. " +
						"byte-offset=#{@i.position-1}" 
				end
				raise Malformed, "not a valid UTF8 byte. " +
					"byte-offset=#{input.position}"
			end
			bytes, = extract_bytes_bit(ary.first)
			if bytes > ary.size
				raise Malformed, "previous multibyte sequence is incomplete. " +
					"byte-offset=#{@i.position}" 
			end
			codepoint = bytes_to_codepoint(ary)
			check_not_overlong(codepoint, bytes, input)
			return codepoint
		ensure
			input.close
		end
	end
end # class DecodeUTF8


# == Translate UTF8 encoded strings to unicode
#
# can go both forward and backward.
class DecodeUTF16 < Iterator::Base
	class Malformed < StandardError; end
	def initialize(i, big_endian=true, position=nil)
		@i = i
		@big_endian = big_endian
		@position = position || 0
	end
	attr_reader :position
	def self.mk_be(i)  # big endian
		self.new(i, true)
	end
	def self.mk_le(i)  # little endian
		self.new(i, false)
	end
	def clone
		self.class.new(@i.clone, @big_endian, @position)
	end
	def first
		@i.first
		@position = 0
		self
	end
	def last
		self.next while self.has_next?
		self
	end
	def has_next?
		@i.has_next?
	end
	def next1
		@position += 1
		word1 = readword(@i)
		@i.next
		return unless (0xd800..0xdbff).member?(word1)
		input = @i.clone
		begin
			word2 = readword(input)
			return unless (0xdc00..0xdfff).member?(word2)
		ensure
			input.close
		end
		@i.next(2)
	end
	def readword(iterator)
		raise "end of file" unless iterator.has_next?
		byte1 = iterator.current
		iterator.next
		raise "end of file" unless iterator.has_next?
		byte2 = iterator.current
		byte1, byte2 = byte2, byte1 unless @big_endian
		(byte1 << 8) | byte2
	end
	def readword_prev(iterator)
		raise "end of input" unless iterator.has_prev?
		byte2 = iterator.current_prev
		iterator.prev
		raise "end of input" unless iterator.has_prev?
		byte1 = iterator.current_prev
		byte1, byte2 = byte2, byte1 unless @big_endian
		(byte1 << 8) | byte2
	end
	def raise_malformed_tail(word, position)
		wordhex = "word (%x)" % word
		raise Malformed, "previous #{wordhex} is incomplete, expected the next word " +
			"to be within the range (0xdc00..0xdfff). " +
			"byte-offset=#{position}"
	end
	def raise_malformed_illegal(word, position)
		wordhex = "word (%x)" % word
		raise Malformed, "illegal UTF-16 #{wordhex}, expected it to be " +
			"to be outside the range (0xdc00..0xdfff). " +
			"byte-offset=#{position}"
	end
	def calc_codepoint(word1, word2)
		word1 -= 0xd800
		word1 <<= 10
		word2 -= 0xdc00
		word1 + word2 + 0x10000
	end
	def current
		input = @i.clone
		begin
			word1 = readword(input)
			raise_malformed_illegal(word1, @i.position) if (0xdc00..0xdfff).member?(word1)
			return word1 unless (0xd800..0xdbff).member?(word1)
			input.next
			pos = input.position
			word2 = readword(input)
			raise_malformed_tail(word1, pos) unless (0xdc00..0xdfff).member?(word2)
			return calc_codepoint(word1, word2)
		ensure
			input.close
		end
	end
	def has_prev?
		@i.has_prev?
	end
	def prev1
		@position -= 1
		word2 = readword_prev(@i)
		@i.prev
		return unless (0xdc00..0xdfff).member?(word2)
		input = @i.clone
		begin
			word1 = readword_prev(input)
			return unless (0xd800..0xdbff).member?(word1)
		ensure
			input.close
		end
		@i.prev(2)
	end
	def current_prev
		input = @i.clone
		begin
			word2 = readword_prev(input)
			input.prev
			raise_malformed_tail(word2, @i.position) if (0xd800..0xdbff).member?(word2)
			return word2 unless (0xdc00..0xdfff).member?(word2)
			pos = input.position
			word1 = readword_prev(input)
			input.prev
			unless (0xd800..0xdfff).member?(word1)
				raise_malformed_illegal(word2, pos)
			end
			return calc_codepoint(word1, word2)
		ensure
			input.close
		end
	end 
end # end class DecodeUTF16


# = <tt>STL</tt> Like Operations
#
# These routines are a <tt>STL</tt> rip off. So if you already know <tt>STL</tt>,
# then you should feel like home.
#
module Algorithm
	# Copies elements from <tt>source</tt> to <tt>destination</tt>.
	# source:: are the range <tt>[ibegin, iend]</tt>. 
	# destination:: are the range <tt>[result, result + (iend - ibegin)]</tt>.
	def self.copy(ibegin, iend, result)
		while ibegin.has_next? and ibegin.position < iend.position
			result.current = ibegin.current
			result.next
			ibegin.next
		end
		result
	end
	# Copies elements from <tt>source</tt> to <tt>destination</tt>.
	# source:: are the range <tt>[ibegin, ibeing + count]</tt>. 
	# destination:: are the range <tt>[result, result + count]</tt>.
	def self.copy_n(ibegin, count, result)
		while ibegin.has_next? and count > 0
			result.current = ibegin.current
			result.next
			ibegin.next
			count -= 1
		end
		result
	end
	# Copies elements from <tt>source</tt> to <tt>destination</tt> (backwards).
	# source:: are the range <tt>[ibegin, iend]</tt>. 
	# destination:: are the range <tt>[result, result + (iend - ibegin)]</tt>.
	def self.copy_backward(ibegin, iend, result)
		while iend.has_prev? and iend.position > ibegin.position
			iend.prev
			result.current = iend.current
			result.next
		end
		result
	end
	# Overwrite all elements in <tt>destination</tt> with <tt>value</tt>.
	# destination:: are the range <tt>[ibegin, iend]</tt>.
	def self.fill(ibegin, iend, value)
		while ibegin.has_next? and ibegin.position < iend.position
			ibegin.current = value
			ibegin.next
		end
	end
	# Overwrite all elements in <tt>destination</tt> with <tt>value</tt>.
	# destination:: are the range <tt>[ibegin, ibegin + count]</tt>.
	def self.fill_n(ibegin, count, value)
		while ibegin.has_next? and count > 0
			ibegin.current = value
			ibegin.next
			count -= 1
		end
	end
	# Apply unary operation to elements in <tt>source</tt> and output 
	# result to <tt>destination</tt>. 
	# source:: are the range <tt>[ibegin, iend]</tt>. 
	# destination:: are the range <tt>[obegin, obegin + (iend - ibegin)]</tt>.
	#
	# Conceptualy the same as: 
	#   output = input.map{|i| block.call(i)}
	def self.transform(ibegin, iend, obegin, &block)
		while ibegin.has_next? and ibegin.position < iend.position
			obegin.current = block.call(ibegin.current)
			ibegin.next
			obegin.next
		end
	end
	# Apply binary operation to elements in <tt>source</tt> and output 
	# result to <tt>destination</tt>. 
	# source:: are the ranges <tt>[ibegin1, iend1]</tt> and <tt>[ibegin2, iend2]</tt>. 
	# destination:: are the range <tt>[obegin, obegin + min[iend1-ibegin1, iend2-ibegin2]]</tt>.
	#
	# Conceptualy the same as: 
	#   output = input1.zip(input2).map{|i1, i2| block.call(i1, i2)}
	def self.transform2(ibegin1, iend1, ibegin2, iend2, obegin, &block)
		while ibegin1.has_next? and ibegin1.position < iend1.position and
			  ibegin2.has_next? and ibegin2.position < iend2.position
			obegin.current = block.call(ibegin1.current, ibegin2.current)
			ibegin1.next
			ibegin2.next
			obegin.next
		end
	end
end # module Algorithm


# = Addons to Ruby's Array class, String class...etc
#
# A few useful specializations of Iterator::Algorithm methods.
module Goodies
	# create iterator which points at the position before first element.
	#
	# <b>remember</b> to invoke <tt>#close</tt> when you are done.
	def create_iterator
		Collection.new(self)
	end
	# create iterator which points at the position after last element.
	#
	# <b>remember</b> to invoke <tt>#close</tt> when you are done.
	def create_iterator_end
		Collection.new(self).last
	end
end # module Goodies

end # module Iterator


class Array
	include Iterator::Goodies
	# Copies elements from <tt>source</tt> into a new Array, and return it.
	# source:: are the range <tt>[ibegin, iend]</tt>. 
	def self.copy(ibegin, iend)
		ir = (result = []).create_iterator
		Iterator::Algorithm.copy(ibegin, iend, ir)
		return result
	ensure
		ir.close
	end
	# Copies elements from <tt>source</tt> into a new Array, and return it.
	# source:: are the range <tt>[ibegin, ibegin + count]</tt>. 
	def self.copy_n(ibegin, count)
		ir = (result = []).create_iterator
		Iterator::Algorithm.copy_n(ibegin, count, ir)
		return result
	ensure
		ir.close
	end
	# Copies elements (backwards) from <tt>source</tt> into a new Array, and return it.
	# source:: are the range <tt>[ibegin, iend]</tt>. 
	def self.copy_backward(ibegin, iend)
		ir = (result = []).create_iterator
		Iterator::Algorithm.copy_backward(ibegin, iend, ir)
		return result
	ensure
		ir.close
	end
end

class String
	include Iterator::Goodies
end

if $0 == __FILE__
	puts "iterator module, version=#{Iterator::VERSION}"
end
