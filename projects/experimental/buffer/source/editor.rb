module EditStrategies

class Base
	def initialize(parent)
		@parent = parent
	end
	def position
		0
	end
	def init_begin
	end
	def init_end
	end
	def insert(char)
		raise "derived class (#{self.class}) must overload method, but didn't"
	end
	def backspace
		raise "derived class (#{self.class}) must overload method, but didn't"
	end
	def split
		raise "derived class (#{self.class}) must overload method, but didn't"
	end
	def move_left
		raise "derived class (#{self.class}) must overload method, but didn't"
	end
	def move_right
		raise "derived class (#{self.class}) must overload method, but didn't"
	end
end # class Base

class Seperator < Base
	def insert(char)
		@parent.push_left(char)
	end
	def split
		# do nothing
	end
	def backspace
		@parent.pop_left
	end
	def move_left
		@parent.move_left
	end
	def move_right
		@parent.move_right
	end
end # class Seperator

class ThroughTab < Base
	def initialize(parent)
		super(parent)
		@width = nil
		@x = nil
		@pos = 0
	end
	def position
		@pos
	end
	def init_end
		@x = @parent.x
		tabsize = @parent.tabsize
		@width = @parent.calc_width(@x, "\t")
		@pos = @width - 1
		$logger.debug(2) { "begin: through tabs width=#{@width}" }
	end
	def init_begin
		@x = @parent.x
		tabsize = @parent.tabsize
		@width = @parent.calc_width(@x, "\t")
		@pos = 0
		$logger.debug(2) { "end: through tabs width=#{@width}" }
	end
	def insert(char)
		if @pos < 1
			@parent.push_left(char)
			return true
		end
		@pos.times { @parent.push_left(' ') }
		@parent.push_left(char)
		@parent.pop_right
		(@width-@pos).times { @parent.push_right(' ') }
		@parent.use_seperator_strategy
		true
	end
	def backspace
		if @pos < 1
			@parent.use_seperator_strategy
			return @parent.pop_left
		end
		(@pos-1).times { @parent.push_left(' ') }
		@parent.pop_right
		(@width-@pos).times { @parent.push_right(' ') }
		@parent.use_seperator_strategy
		true
	end
	def split
		if @pos < 1
			@parent.use_seperator_strategy
			return true
		end
		@pos.times { @parent.push_left(' ') }
		@parent.pop_right
		(@width-@pos).times { @parent.push_right(' ') }
		@parent.use_seperator_strategy
	end
	def move_left
		if @pos > 0
			@pos -= 1
			return true
		end
		@parent.move_left
	end
	def move_right
		@pos += 1
		if @pos < @width
			return true
		end
		@parent.move_right
	end
end # class ThroughTab

class VirtualSpace < Base
	def initialize(parent)
		super(parent)
		@pos = nil
	end
	def init_begin
		@pos = 0
	end
	def position
		@pos
	end
	def insert(char)
		@pos.times { @parent.push_left(' ') }
		@parent.push_left(char)
		@parent.use_seperator_strategy
		true
	end
	def backspace
		if @pos < 1
			@parent.use_seperator_strategy
			return @parent.pop_left
		end
		@pos -= 1
		true
	end
	def split
		# split shouldn't do do anything at all
		# for instance when a person hits enter in vspace area
		# then we don't want lots of spaces... 
		# we want nothing to happen.. thus this method is empty
	end
	def move_right
		@pos += 1
		true
	end
	def move_left
		if @pos > 0
			@pos -= 1
			return true
		end
		@parent.move_left
	end
end # class VirtualSpace

end # module EditStrategies

class Editor
	include EditStrategies
	def initialize(model_iterator)
		@x = 0
		@tabsize = 8
		@strategy_seperator = Seperator.new(self)
		@strategy_throughtab = ThroughTab.new(self)
		@strategy_vspace = VirtualSpace.new(self)
		@strategy_vs = nil
		@strategy = @strategy_seperator
		@model = model_iterator
		@left_xs = []  
		use_cursor_through_tabs_strategy(false)
	end
	attr_reader :x, :tabsize, :strategy
	attr_reader :cursor_through_tabs
	def set_model_iterator(iterator)
		@model = iterator
	end
	def cursor_x
		@x + @strategy.position
	end
	def use_cursor_through_tabs_strategy(boolean)
		@cursor_through_tabs = boolean 
		@strategy_tab = boolean ? @strategy_throughtab : @strategy_seperator
	end
	def use_virtual_space_strategy(boolean)
		if boolean
			@strategy_vs = @strategy_vspace
		else
			@strategy_vs = nil
		end
	end
	def set_tabsize(tabsize)
		@tabsize = tabsize
	end
	def do_insert(char)
		@strategy.insert(char)
	end
	def do_backspace
		@strategy.backspace
	end
	def do_split
		@strategy.split
	end
	def do_move_left
		@strategy.move_left
	end
	def do_move_right
		@strategy.move_right
	end
	def do_move_begin
		@model.prev while @model.has_prev?
		@left_xs = []
		@x = 0
		choose_strategy
		@strategy.init_begin
	end
	def do_move_end
		loop do
			ok = internal_move_right
			break unless ok
		end
		@strategy.init_begin
	end
	def choose_strategy
		unless @model.has_next?
			return
		end
		char = @model.current
		if char == "\t"
			$logger.debug(2) { "selected strategy TAB" }
			@strategy = @strategy_tab
		else
			$logger.debug(2) { "selected strategy SEP" }
			@strategy = @strategy_seperator
		end
	end
	def use_seperator_strategy
		@strategy = @strategy_seperator
		# it doesn't matter wether we invoke #begin or #end
		# because Seperator's are infinitly thin. 
		@strategy.init_begin
	end
	def move_left
		if !@model.has_prev? and @left_xs.empty?
			return false
		end
		if !@model.has_prev? or @left_xs.empty?
			raise 'integrity error'
		end
		@model.prev
		@x = @left_xs.pop
		choose_strategy
		@strategy.init_end
		true
	end
	def internal_move_right
		if !@model.has_next?
			return false
		end
		@left_xs << @x
		char = @model.current
		n = calc_width(@x, char)
		@x += n
		@model.next
		@strategy = @strategy_seperator
		true
	end
	def move_right
		if !@model.has_next?
			return false unless @strategy_vs
			@strategy = @strategy_vs
			@strategy.init_begin
			@strategy.move_right
			return true
		end
		internal_move_right
		choose_strategy
		@strategy.init_begin
		true
	end
	def push_left(char)
		n = calc_width(@x, char)
		@left_xs << @x
		@x += n
		@model.insert_before(char)
		true
	end
	def push_right(char)
		@model.insert_after(char)
		true
	end
	def pop_left
		if !@model.has_prev?
			return false
		end
		@model.erase_before
		@x = @left_xs.pop
		true
	end
	def pop_right
		@model.erase_after
		true
	end
	def calc_width(x, char)
		n = 1
		if char == "\t"
			n = @tabsize - (x % @tabsize)
		end
		n
	end
end
