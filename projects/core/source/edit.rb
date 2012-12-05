require 'aeditor/backend/edit_container'
require 'aeditor/backend/exceptions'
require 'observer'

module EditConst
	RIGHT = 0
	LEFT  = 1
end

# purpose:
# fundemental strategies for text-editing.
# 
# functions:
# * move_left,   move cursor left.
# * move_right,  move cursor right.
# * insert(obj), insert object before cursor.
# * backspace,   remove object before cursor.
#
# classes:
# * Object,      is base class for all buffer-objects.
# * Seperator,   represent being between 2 objects.
# * Tab,         behaving like normal tab. 
# * TabThrough,  cursor through tabs behavier.
# * VSpace,      virtual space (end of line).
#
# issues:
# * perhaps a 'Text' class can be useful ?
#
# todo:
# * control characters
# * folding area
module EditObjects
	class CannotSplit < StandardError; end
	class Object
		def initialize(parent)
			@parent = parent
		end
		# if width == 1 then bailout and return false
		# if width > 1 then initialize and return true
		def init(x, lr)
			false
		end
		def move_left
			puts "no impl left"
			raise "no impl left"
			@parent.push_right
			obj = @parent.pop_left
			@parent.set_current(obj, EditConst::RIGHT)
		end
		def move_right
			puts "no impl right"
			raise "no impl right"
			@parent.push_left
			obj = @parent.pop_right
			@parent.set_current(obj, EditConst::LEFT)
		end
		def insert(obj)
			raise "no impl insert"
			@parent.push_left
			@parent.set_current(obj, EditConst::RIGHT)
		end
		def backspace
			@parent.pop_left
		end
		def split
			raise CannotSplit
		end
		def width(x, obj)
			1
		end
		def position
			0
		end
	end

	# purpose:
	# represent the infinitly small area between 2 buffer-objects.
	class Seperator < Object
		def move_left
			@parent.sep_move_left
		end
		def move_right
			@parent.sep_move_right
		end
		def insert(obj)
			@parent.push_left(obj)
		end
		def split
		end
		def width(x, obj)
			0
		end
	end

	# purpose:
	# horizontal TABulator with 'normal' behavier
	class Tab < Object
		def initialize(parent, tabsize)
			super(parent)
			@tabsize = tabsize
		end
		def width(x, obj)
			@tabsize - (x % @tabsize)
		end
	end

	# purpose:
	# cursor through tabs strategy
	# converts this tab into spaces when necessary (insert/backspace)
	#
	# issues:
	# * if the cursor is located right after a TAB, so that
	#   the current editor is 'seperator', then the whole
	#   TAB gets destroyed when issuing backspace.
	#   I feel that this is wrong behavier!
	class TabThrough < Object
		def initialize(parent, tabsize)
			super(parent)
			@tabsize = tabsize
			@x = 0
		end
		def init(x, lr)
			# assuming 0 < @x < width
			w = calc_width(x)
			return false if w == 1
			# 'lr' er tvetydig, lav den entydig
			# byt om på LEFT og RIGHT, se om det bliver bedre
			# todo: if lr == EditConst::LEFT
			@x = (lr == EditConst::RIGHT) ? 1 : (w - 1)
			true
		end
		def calc_width(x)
			@tabsize - (x % @tabsize)
		end
		def width(x, obj)
			calc_width(x)
		end
		def insert(obj)
			# assuming 0 < @x < width
			w = calc_width(@parent.x)
			@parent.pad_left(@x)
			@parent.push_left(obj)
			@parent.pad_right(w - @x)
			@parent.set_current_to_seperator
		end
		def backspace
			# assuming 0 < @x < width
			w = calc_width(@parent.x)
			@parent.pad_left(@x - 1)
			@parent.pad_right(w - @x)
			@parent.set_current_to_seperator
		end
		def split
			# assuming 0 < @x < width
			w = calc_width(@parent.x)
			# don't do any left-padding.. because of breakline!
			#@parent.pad_left(@x)
			@parent.pad_right(w - @x)
			@parent.set_current_to_seperator
		end
		def move_left
			# assuming 0 < @x < width
			@x -= 1
			if @x == 0
				@parent.current2right
				@parent.set_current_to_seperator
			end
		end
		def move_right
			# assuming 0 < @x < width
			@x += 1
			if @x == calc_width(@parent.x)
				@parent.current2left  # todo: width
				@parent.set_current_to_seperator
			end
		end
		def position; @x end
	end

	# purpose:
	# virtual space (end of line)
	class VSpace < Object
		def initialize(parent)
			super(parent)
			@x = 0
		end
		def init(x, lr)
			@x = 1
			true
		end
		def insert(obj)
			@parent.pad_left(@x)
			@parent.push_left(obj)
			@parent.current2right
			@parent.set_current_to_seperator
		end
		def backspace
			move_left
		end
		def split
			# don't do any padding.. because of breakline!
			@parent.current2right
			@parent.set_current_to_seperator
		end
		def move_left
			@x -= 1
			if @x == 0
				@parent.current2right
				@parent.set_current_to_seperator
			end
		end
		def move_right
			@x += 1
		end
		def position
			@x
		end
		def width(x, obj)
			-1   # -1 == infinite
		end
	end

	# purpose:
	# fold with normal behavier
	class Fold < Object
		def width(x, obj); obj.title.length end
	end

	# purpose:
	# bookmark with 'normal' behavier
	class Mark < Object
		def initialize(parent)
			super(parent)
		end
		def width(x, obj)
			3    # todo: avoid hardcoding '[1]'.. there can exist other stategies
		end
	end
end


# purpose:
# extend a leftright container with editing capabilities.
# This is actual a state-machine, where the classes
# in EditObjects is the possible states it can be in.
#
# functions:
# * keep track of the current editing state.
# * notifies observers when content/cursor changes.
# * delegates requestes to the current-state-editor,
#   the current-state-editor may change the 
#   current-state.
#
class Edit < EditContainer
	include Observable
	def initialize(space = ' ')
		super()
		@seperator = EditObjects::Seperator.new(self)
		@obj2edit = Hash.new
		@space = space

		# the current editor-strategy we are using
		@editor = @seperator

		# if > 0 then no notify will be generated
		@notify_lock = 0
	end
	attr_reader :left, :right, :current, :editor, :x, :seperator
	attr_reader :space

	def position
		@x + @editor.position
	end
	def measure_width(x, obj)
		editor = find_cooresponding_editor(obj)
		editor.width(x, obj)
	end

	# ---------------------------------
	#          private methods
	# ---------------------------------
	def init_editor(obj, pos, lr)
		editor = find_cooresponding_editor(obj)
		return false if not editor.init(pos, lr)
		@editor = editor
		true
	end
	def sep_move_left
		raise NotBegin if @left.empty?
		mx = @x - @left_x.last  # previous position
		if init_editor(@left.last, mx, EditConst::LEFT)
			left2current
		else
			left2right
		end
	end
	def sep_move_right
		raise NotEnd if @right.empty?
		if init_editor(@right.first, @x, EditConst::RIGHT)
			right2current
		else
			right2left
		end
	end
	def pad_left(n)
		n.times { push_left(@space) }
	end
	def pad_right(n)
		n.times { push_right(@space) }
	end
	def set_current_to_seperator
		@current = nil
		@editor = @seperator
	end
	def find_cooresponding_editor(buffer_obj)
		if not @obj2edit.has_key?(buffer_obj.class)
			raise "no editor for object: #{buffer_obj.class.to_s}"
		end
		#raise if not @obj2edit.has_key?(buffer_obj.class)
		@obj2edit[buffer_obj.class]
	end
	def dump
		[
			"left     #{@left.inspect}",
			"current  #{@current.inspect}",
			"right    #{@right.inspect}",
			"position #{position.to_s}"
		]
	end
	def debug
		msg = "XXX "+dump.join("\nXXX ")
		$log.puts msg
	end
	def get_content
		data = @left
		data << @current if @current != nil
		data += @right
		data
	end

	# purpose:
	# place cursor at position zero. Generates NO dirty notify.
	#
	# issues:
	# * you must yourself manage *dirty*.
	def move_home_internal(content)
		super(content)
		@editor = @seperator
	end
	def is_end
		#(@current == nil) and (@right == [])
		(@right == [])
	end
	# purpose:
	# adjust cursor so it is within the view
	# todo: notify
	def force_range(min, width)
		move_right until position >= min
		move_left  until position < (min+width) 
	end

	def notify_scope
		old_position = position
		if @notify_lock == 0
			clear_dirty
		end
		
		begin
			@notify_lock += 1 
			result = yield
		ensure
			@notify_lock -= 1
		end
		return result if @notify_lock != 0

		cursor = (position != old_position)
		content = is_dirty
		if cursor or content
			changed
			notify_observers(cursor, content)
		end

		result
	end

	# ---------------------------------
	#          public methods
	# ---------------------------------
	def install_editor(object_class, editor_instance)
		@obj2edit[object_class] = editor_instance
	end
	def insert(obj); @editor.insert(obj) end
	def backspace; @editor.backspace end
	def split; @editor.split end
	def move_left; @editor.move_left end
	def move_right; @editor.move_right end
	def replace_content(new_content)
		old = get_content
		old_position = position
		move_home_internal(new_content)
		move_right until position >= old_position
		old
	end
	def measure_indent
		old_position = position
		move_home_internal(get_content)
		indent_lo = LineIndent::extract_indent(right)
		until left.size == indent_lo.size
			move_right
		end
		indent_x = position
		move_home_internal(get_content)
		until position == old_position
			move_right
		end
		[indent_x, indent_lo]
	end
	# returns true if the line only consists 
	# of spaces/tabs or is empty
	def only_spaces?
		cnt = left.size + right.size
		cnt += 1 if current != nil
		#cnt -= 1 # because of VSpace
		x, indent_lo = measure_indent
		#$log.puts "#{indent_lo.size} #{cnt}"
		(indent_lo.size >= cnt) 
	end
	def move_home(toggle_mode = false)
		old_position = position
		if toggle_mode
			indent_x, dummy = measure_indent
		else
			indent_x = 0
		end
		move_home_internal(get_content)
		if old_position != indent_x
			move_right until position == indent_x
		end
		raise CommandHarmless if (position == old_position)
	end
	def move_end
		old_position = position
		begin
			move_home
		rescue CommandHarmless
		end
		move_right until is_end
		raise CommandHarmless if (position == old_position)
	end
	# if there is a Fold object under the cursor
	# then unlink and return it.
	def unlink_fold!
		if @current
			unless @current.kind_of?(LineObjects::Fold)
				raise "no fold to unlink (current-case)"
			end
			@editor = @seperator
			fold = @current
			@current = nil
			# TODO: adjust measure for @current
			return fold
		end
		if @right.size < 1
			raise "no fold to unlink (zero-right)"
			
		end
		unless @right[0].kind_of?(LineObjects::Fold)
			raise "no fold to unlink (right-case)"
		end
		pop_right
	end
	# purpose:
	# take a snapshot of current state, maybe restore it later
	# used by memento
	def create_memento
		objs = @left.clone
		objs << @current if @current
		objs += @right
		if objs.last.kind_of?(LineObjects::VSpace)
			objs.pop
		end
		[position, objs]
	end
	def set_memento(state)
		reset
		pos, objs = state
		objs.reverse_each do |obj|
			push_right(obj)
		end
		while position < pos
			move_right
		end
	end
	def scan_right
		move_home_internal(get_content)
		until @right.empty?
			yield(@right[0])
			right2left
		end
	end
end
