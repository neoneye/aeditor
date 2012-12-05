require 'aeditor/backend/commands_base'

module Commands
	class MoveUp < CommandBackupPosition
		def execute(parent)
			parent.buffer.cmd_move_up
		end
	end
	class MoveDown < CommandBackupPosition
		def execute(parent)
			parent.buffer.cmd_move_down
		end
	end
	class MovePageUp < CommandBackupPosition
		def initialize
			@height = nil
			@lock = false
		end
		def execute(parent)
			y = parent.buffer.position_visible_lines - parent.buffer.position_y
			@lock = (y != 0)
			@height = parent.buffer.visible_lines
			parent.buffer.cmd_move_page_up
		end
		def execute_undo(parent, memento)
			# by locking the view, we can make pageup user-friendly :-)
			# Only few editors is this friendly to their users.
			# http://metaeditor.sf.net/resize.html

			# if pageup did hit the top-of-buffer, then it seems
			# most user-friendly to do movement when undoing.
			# On this point pageup differ from pagedown !!!
			parent.buffer.set_memento(memento, @lock)
		end
		def execute_redo(parent)
			parent.buffer.cmd_move_page_up(@height)
		end
	end
	class MovePageDown < CommandBackupPosition
		def initialize
			@height = nil
			@lock = false
		end
		def execute(parent)
			@lock = !(parent.buffer.data_bottom.empty?)
			@height = parent.buffer.visible_lines
			parent.buffer.cmd_move_page_down
		end
		def execute_undo(parent, memento)
			# by locking the view, we can make pagedown user-friendly :-)
			# Only few editors is this friendly to their users.
			# http://metaeditor.sf.net/resize.html
			parent.buffer.set_memento(memento, @lock)  # lock view => true
		end
		def execute_redo(parent)
			parent.buffer.cmd_move_page_down(@height)
		end
	end
	class ScrollUp < CommandBackupPosition
		def execute(parent)
			parent.buffer.cmd_scroll_up
		end
	end
	class ScrollDown < CommandBackupPosition
		def execute(parent)
			parent.buffer.cmd_scroll_down
		end
	end
end # Commands
