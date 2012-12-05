require 'aeditor/backend/misc'
require 'aeditor/backend/exceptions'

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
class Command
	def execute(parent)
		puts "execute - uninitialized"
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
end

class CommandMacro < Command
	def initialize(commands)
		@commands = commands
	end
	def execute(parent)
		@commands.each do |cmd|
			begin
				cmd.execute(parent)
			rescue CommandHarmless
			end
		end
	end
	def execute_redo(parent)
		@commands.each do |cmd|
			begin
				cmd.execute_redo(parent)
			rescue CommandHarmless
			end
		end
	end
end

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
		mem = cmd.create_memento(@parent)
		cmd.execute(@parent)
		@undo.push([cmd, mem])
		@redo = []
		@macro_size += 1 if @record_mode
	end
	def execute_undo
		if @record_mode and @macro_size == 0
			@record_mode = false
			return
		end
		raise Nothing2Undo if @undo.empty?
		@macro_size -= 1 if @record_mode
		cmd, mem = @undo.pop
		cmd.execute_undo(@parent, mem.deep_clone)
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
		create_macro(cmds.deep_clone)
	end
	# template-method: overload me in order to choose 
	# another CommandMacro class.
	def create_macro(cmds)
		CommandMacro.new(cmds)
	end
end
