require 'aeditor/backend/history'
require 'aeditor/backend/commands_base'
require 'aeditor/backend/commands_movement'
require 'aeditor/backend/commands_others'

# purpose:
# the controller in the MVC pattern.
#
# todo:
# * make base class, and inherit from it:
#   vim-bindings, emacs-bindings, brief-bindings...
#
class Control
	class ExitClean < StandardError; end
	def initialize(buffer, view)
		@buffer = buffer
		@view = view
		@caretaker = Caretaker.new(self)
		@view.set_caretaker(@caretaker)
		class << @caretaker
			def create_macro(cmds)
				Commands::CommandMacro.new(cmds)
			end
		end
		@macro = @caretaker.create_macro([])
		@scroll_mode = false
	end
	attr_accessor :view, :buffer
	def do_block_toggle
		return Commands::BlockCopy.new if @buffer.blocking.enabled
		Commands::BlockBegin.new 
	end
	def do_block_paste
		Commands::BlockPaste.new(@buffer.clipboard)
	end
	def do_block_remove
		Commands::BlockRemove.new
	end
	def do_move_left
		return Commands::ScrollLeft.new if @scroll_mode
		Commands::MoveLeft.new 
	end
	def do_move_right
		return Commands::ScrollRight.new if @scroll_mode
		Commands::MoveRight.new 
	end
	def do_move_up
		return Commands::ScrollUp.new if @scroll_mode 
		Commands::MoveUp.new 
	end
	def do_move_down
		return Commands::ScrollDown.new if @scroll_mode 
		Commands::MoveDown.new 
	end
	def do_move_home;      Commands::MoveHome.new end
	def do_move_end;       Commands::MoveEnd.new end
	def do_move_page_up;   Commands::MovePageUp.new end
	def do_move_page_down; Commands::MovePageDown.new end
	def do_backspace;      Commands::Backspace.new end
	def do_breakline;      Commands::Breakline.new end
	def do_play_macro;     @macro end
	def execute(command)
		@buffer.notify_scope do
			@caretaker.execute(command)
		end
	end
	def execute_undo
		@buffer.notify_scope do
			@caretaker.execute_undo
		end
	end
	def execute_redo
		@buffer.notify_scope do
			@caretaker.execute_redo
		end
	end
	def dispatch(event)
		$log.puts <<MSG
Control#dispatch:  Unknown event occured
event = #{event.inspect}
MSG
	end
end
