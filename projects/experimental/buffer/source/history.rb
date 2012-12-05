module History

module Command

# purpose:
# base class for undoable commands.
#
# as default we do full backup of *everything*
# by overwriting the get/set-memento methods
# you can instead keep track of delta-changes.
#
# functions:
# * execute, run's the operation.. 
#   you must return false if data is unmodified.
#   example: pressing move_up at buffer_top => nothing (false)
#
# * execute_undo, restore data as it were before 
#   the operation took place.
#
# * execute_redo, run the operation again!
#
class Base
	def execute(parent)
		$logger.debug(1) { "execute - uninitialized" }
		false
	end
	def create_memento(parent)
		parent.create_memento
	end
	def set_memento(parent, memento)
		parent.set_memento(memento)
	end
	def execute_undo(parent, memento)
		set_memento(parent, memento)
	end
	def execute_redo(parent)
		execute(parent)
	end
	def execute_and_get_memento(parent)
		memento = create_memento(parent)
		status = execute(parent)
		[status, memento]
	end
end

# purpose:
# take full snapshot.. this can be expensive
class MacroOld < Base
	def initialize(commands)
		@commands = commands
	end
	def execute(parent)
		@commands.each do |cmd|
			cmd.execute(parent)
		end
	end
	def execute_redo(parent)
		@commands.each do |cmd|
			cmd.execute_redo(parent)
		end
	end
end


# purpose:
# take small memento snapshots.
class Macro < Base
	def initialize(commands)
		@commands = commands
		@memento = nil
	end
	def create_memento(parent)
		nil
	end
	def set_memento(parent, memento)
		nil
	end
	def execute(parent)
		mementoes = []
		@commands.each do |cmd|
			ok, mem = cmd.execute_and_get_memento(parent)
			mementoes << mem
		end
		@mementoes = mementoes
		true
	end
	def execute_undo(parent, memento)
		raise 'should not happen' if memento.size != @commands.size
		(memento.size-1).downto(0) do |index|
			@commands[index].execute_undo(parent, memento[index])
		end
	end
	def execute_redo(parent)
		@commands.each do |cmd|
			cmd.execute_redo(parent)
		end
	end
	def execute_and_get_memento(parent)
		status = execute(parent)
		[status, @mementoes]
	end
end

end # module Command

# purpose:
# snapshots of undo/redo state data
# 
class Caretaker
	class Nothing2Undo < StandardError; end
	class Nothing2Redo < StandardError; end
	def initialize(parent)
		@undo = []
		@redo = []
		@parent = parent
		@record_mode = false
		@macro_size = 0
	end
	attr_reader :record_mode
	def execute(cmd)
		ok, mem = cmd.execute_and_get_memento(@parent)
		@undo.push([cmd, mem])
		if @redo.size > 0
			$logger.debug(1) { "discarding #{@redo.size} redo elements!" }
		end
		@redo = []
		@macro_size += 1 if @record_mode
		ok
	end
	def execute_undo
		if @record_mode and @macro_size == 0
			@record_mode = false
			return
		end
		raise Nothing2Undo if @undo.empty?
		@macro_size -= 1 if @record_mode
		cmd, mem = @undo.pop
		cmd.execute_undo(@parent, mem)
		@redo.unshift([cmd, mem])
	end
	def execute_redo
		raise Nothing2Redo if @redo.empty?
		cmd, mem = @redo.shift
		# mem = cmd.create_memento(@parent)   # not necessary
		cmd.execute_redo(@parent)
		@undo.push([cmd, mem])
		@macro_size += 1 if @record_mode
	end
	def macro_begin
		return if @record_mode
		@macro_size = 0
		@record_mode = true
	end
	def macro_end
		return nil unless @record_mode 
		@record_mode = false
		entries = @undo.slice(-@macro_size, @macro_size)
		cmds = entries.map{|cmd, memento| cmd}
		create_macro(cmds)
	end
	# template-method: overload me in order to choose 
	# another CommandMacro class.
	def create_macro(cmds)
		Command::Macro.new(cmds)
	end
end # class Caretaker

end # module History
