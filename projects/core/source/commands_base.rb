require 'aeditor/backend/history'

# purpose:
# base classes for commands, which commands inherit from
module Commands
	# purpose:
	# backup/restore full snapshot of whole buffer
	class Command < Command
		def create_memento(parent)
			super(parent.buffer)
		end
		def set_memento(parent, memento)
			super(parent.buffer, memento)
		end
	end
	# purpose:
	# wrapper for macro
	class CommandMacro < CommandMacro
		def create_memento(parent)
			super(parent.buffer)
		end
		def set_memento(parent, memento)
			super(parent.buffer, memento)
		end
		def execute(parent)
			parent.buffer.notify_scope do
				begin
					super(parent)
				ensure
					# in case something fatal is happening
					# we still want the screen to be refreshed
					parent.buffer.set_dirty_all
				end
			end
		end
	end
	# purpose:
	# backup/restore only content of current line
	class CommandBackupLine < Command
		def create_memento(parent)
			parent.buffer.create_memento(Buffer::Memento::Line)
		end
	end
	# purpose:
	# backup/restore only current-position
	class CommandBackupPosition < Command
		def create_memento(parent)
			parent.buffer.create_memento(Buffer::Memento::Position)
		end
	end
end # Commands
