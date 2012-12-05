require 'aeditor/backend/commands_base'

module Commands
	class MoveLeft < CommandBackupPosition
		def execute(parent)
			parent.buffer.cmd_move_left
		end
	end
	class MoveRight < CommandBackupPosition
		def execute(parent)
			parent.buffer.cmd_move_right
		end
	end
	class MoveHome < CommandBackupPosition
		def execute(parent)
			parent.buffer.cmd_move_home(true)
		end
	end
	class MoveEnd < CommandBackupPosition
		def execute(parent)
			parent.buffer.cmd_move_end
		end
	end
	# purpose:
	# compensate for screw in the Y direction.
	#
	# issues:
	# this is NOT a nice solution, perhaps use
	# buffer#resize_topbottom instead ?
	module Compensate4VerticalScrew
		def execute(parent)
			old = parent.buffer.position_visible_lines
			execute_screw(parent)
			@delta = old - parent.buffer.position_visible_lines
			#$log.puts "screw = #{@delta}"
		end
		def execute_undo(parent, memento)
			parent.buffer.notify_scope {
				# by doing move_up we can avoid that the
				# position-within-view screws if you do
				# 10 undo;
				# 20 redo;
				# 30 goto 10;
				@delta.times { parent.buffer.cmd_move_down }
				(0 - @delta).times { parent.buffer.cmd_move_up }
				super(parent, memento)
			}
		end
	end
	# todo: avoid full snapshot, but how?
	class Backspace < Command #CommandBackupLine
		include Compensate4VerticalScrew
		def execute_screw(parent)
			begin
				parent.buffer.cmd_backspace
			rescue CommandHarmless
				parent.buffer.cmd_joinline
			end
		end
	end
	class Insert < CommandBackupLine
		def initialize(text)
			super()
			@text = text
		end
		def execute(parent)
			parent.buffer.cmd_insert(@text)
		end
	end
	class Breakline < Command
		include Compensate4VerticalScrew
		def execute_screw(parent)
			parent.buffer.cmd_breakline
		end
	end
	class Resize < Command
		def initialize(x, y)
			@x = x
			@y = y
		end
		def execute(parent)
			# resize MUST leave the current buffer position, unchanged
			parent.view.adjust_to_new_window_size(@x, @y)
			parent.buffer.adjust_height(@y)
			parent.view.update
			# don't trash existing redo data. 
			# because we only modify the View and NOT the Model(Buffer)
			# therefore nothing to undo/redo, and thus we can
			#false   # ignore this command completely!
			raise CommandHarmless
		end
		def create_memento(parent)
			nil
		end
		def set_memento(parent, memento)
			raise "resize should have been, but was NOT ignored!"
		end
	end
	class ScrollLeft < Command
		def execute(parent)
			old_pos = parent.buffer.position_x
			parent.view.scroll_left
			parent.buffer.force_range_x(parent.view.x, parent.view.cell_width)
			parent.view.update
			raise CommandHarmless if (old_pos == parent.buffer.position_x)
		end
	end
	class ScrollRight < Command
		def execute(parent)
			old_pos = parent.buffer.position_x
			parent.view.scroll_right
			parent.buffer.force_range_x(parent.view.x, parent.view.cell_width)
			parent.view.update
			raise CommandHarmless if (old_pos == parent.buffer.position_x)
		end
	end
	class BlockBegin < Command
		def execute(parent)
			parent.buffer.cmd_block_begin
			parent.view.update
		end
	end
	class BlockCopy < Command
		def execute(parent)
			parent.buffer.cmd_block_copy
			parent.view.update
		end
	end
	class BlockRemove < Command
		include Compensate4VerticalScrew
		def execute_screw(parent)
			parent.buffer.cmd_block_remove
			parent.view.update
		end
	end
	class BlockPaste < Command
		include Compensate4VerticalScrew
		def initialize(paste_data)
			@paste_data = paste_data
		end
		def execute_screw(parent)
			parent.buffer.cmd_block_paste(@paste_data)
		end
	end
	class FoldExpand < Command
		include Compensate4VerticalScrew
		def execute_screw(parent)
			parent.buffer.cmd_fold_expand
		rescue => e
			msg = "FoldExpand: " + e.message
			raise CommandHarmless, msg
		end
	end
	class FoldCollapse < Command
		include Compensate4VerticalScrew
		def execute_screw(parent)
			parent.buffer.cmd_fold_collapse
		rescue => e
			msg = "FoldCollapse: " + e.message
			raise CommandHarmless, msg
		end
	end
end # Commands
