require 'aeditor/history'
require 'aeditor/buffer'

module Commands

class MovementBase < History::Command::Base 
	def create_memento(parent)
		str = parent.create_memento_position
		#str = parent.create_memento
		$logger.debug(2) { "memento.size = #{str.size}" }
		str
	end
end

class SelectionBase < History::Command::Base 
end

class EditBase < History::Command::Base 
end

# commands inherited from here.. I don't know
# exactly yet what to store in their undo-record
class OtherBase < History::Command::Base 
end

class MoveUp < MovementBase
	def execute(view)
		view.move_up
	end
end

class MoveDown < MovementBase
	def execute(view)
		view.move_down
	end
end

class MoveLeft < MovementBase
	def execute(view)
		view.move_left
	end
end

class MoveRight < MovementBase
	def execute(view)
		view.move_right
	end
end

class MovePageUp < MovementBase
	def execute(view)
		view.move_page_up
	end
end

class MovePageDown < MovementBase
	def execute(view)
		view.move_page_down
	end
end

class MoveLineBegin < MovementBase
	def execute(view)
		view.move_home
	end
end

class MoveLineEnd < MovementBase
	def execute(view)
		view.moveto_line_end
	end
end

class MoveWordLeft < MovementBase
	def execute(view)
		view.move_word_prev
	end
end

class MoveWordRight < MovementBase
	def execute(view)
		view.move_word_next
	end
end

class MoveAbsolute < MovementBase
	def initialize(x, y)
		@x = x
		@y = y
	end
	def execute(view)
		view.goto_absolute(
			@x || view.cursor_x,
			@y || view.cursor_y
		)
	end
end

class MoveBracket < MovementBase
	def execute(view)
		str = view.model.lines[view.cursor_y].content
		location = str.match_bracket(view.model_iterator.x) do |y|
			modely = view.cursor_y + y
			next nil if modely < 0
			next nil if modely >= view.model.lines.size
			view.model.lines[modely].content
		end  
		return false unless location
		rely, modelx = location
		view.goto_absolute(0, view.cursor_y + rely)
		view.reload_current_line_modelx(modelx)
		view.render_dirty(view.cursor_cell_y)
		view.dirty_all
		true
	end
end

class MovePattern < SelectionBase
	def initialize(search_pattern, replacement=nil)
		super()
		@pattern = search_pattern
		@replacement = replacement
		@cy = nil
		@cx = nil
		@sy = nil
		@sx = nil
	end
	def create_memento(view)
		# NOTE: Memento::Range is overkill.. but does the job
		str = view.create_memento_range(
			view.cursor_y,
			view.model.lines.size - (view.cursor_y + 1)
		)
		$logger.debug(2) { "memento.size = #{str.size}" }
		str
	end
	def execute(view)
		ok = false
		if @replacement
			ok = view.enter_replace_mode(@pattern, @replacement)
		else
			ok = view.search(@pattern)
		end
		@cy = view.cursor_y
		@cx = view.cursor_x
		@sy = view.selection_y
		@sx = view.selection_x
		ok
	end
	def execute_redo(view)
		view.selection_reset
		view.goto_absolute(@sx, @sy)
		view.selection_init
		view.goto_absolute(@cx, @cy)
		true
	end
end

class ReplaceAndMove < SelectionBase
	def initialize
		super()
		@cy = nil
		@cx = nil
		@sy = nil
		@sx = nil
		@replacement_string = nil
	end
	def create_memento(view)
	  y1 = view.cursor_y
		y2 = view.cursor_y+1
		if view.selection_mode
			y1, y2 = [view.selection_y, view.cursor_y].sort
			y2 += 1
		end
		str = view.create_memento_range(
			y1, view.model.lines.size - y2
		)
		$logger.debug(2) { "memento.size = #{str.size}" }
		str
	end
	def execute(view)
		view.mode_accept
		@replacement_string = view.replacement_string
		@cy = view.cursor_y
		@cx = view.cursor_x
		@sy = view.selection_y
		@sx = view.selection_x
		true
	end
	def execute_redo(view)
		# TODO: it would be nice to use some unittested code here,
		# rather than using this adhoc code.
		view.selection_erase
		view.insert_text(@replacement_string)
		view.goto_absolute(@sx, @sy)
		view.selection_init
		view.goto_absolute(@cx, @cy)
		true
	end
end

class InsertText < EditBase
	def initialize(text)
		super()
		@text = text
	end
	def create_memento(view)  
		lines = @text.count("\n") + 1
		ybottom = [view.model.lines.size - (view.cursor_y+lines), 0].max
		str = view.create_memento_range(view.cursor_y, ybottom)
		$logger.debug(2) { "memento.size = #{str.size}" }
		str
	end
	def execute(view)
		view.insert_text(@text)
	end
end

class BreakLine < EditBase
	def create_memento(view)  
		str = view.create_memento_range(
			view.cursor_y,
			view.model.lines.size - (view.cursor_y+1)
		)
		$logger.debug(2) { "memento.size = #{str.size}" }
		str
	end
	def execute(view)
		view.breakline
	end
end

class Backspace < EditBase
	def create_memento(view)  
		y = [view.cursor_y-1, 0].max
		str = view.create_memento_range(
			y,
			view.model.lines.size - (view.cursor_y+1)
		)
		$logger.debug(2) { "memento.size = #{str.size}" }
		str
	end
	def execute(view)
		view.real_backspace
	end
end

class Delete < EditBase
	def create_memento(view)  
		# maybe I backup one line too much.. cannot tell (too sleepy)
		y1 = [view.cursor_y-1, 0].max
		y2 = [view.cursor_y+2, view.model.lines.size].min
		str = view.create_memento_range(y1, 
			view.model.lines.size - y2)
		str
	end
	def execute(view)
		unless view.model_iterator.has_next?
			if view.cursor_y >= view.model.lines.size-1
				$logger.debug(1) { "cannot delete bottom of file" }
				return false
			end
			view.editor.do_split
			view.joinline
		else
			view.move_right
			view.backspace
		end
		true
	end
end

class SwapUp < EditBase
	def create_memento(view)
	  y1 = view.cursor_y
		y2 = view.cursor_y+1
		if view.selection_mode
			y1, y2 = [view.selection_y, view.cursor_y].sort
			y2 += 1
		end
		y1 -= 1
		$logger.debug(2) { "lines=#{lines}" }
		str = view.create_memento_range(
			[y1, 0].max, view.model.lines.size - y2
		)
		$logger.debug(2) { "memento.size = #{str.size}" }
		str
	end
	def execute(view)
		if view.selection_mode
			view.swap_upper_selection
		else
			view.swap_upper
		end
	end
end

class SwapDown < EditBase
	def create_memento(view)
	  y1 = view.cursor_y
		y2 = view.cursor_y+1
		if view.selection_mode
			y1, y2 = [view.selection_y, view.cursor_y].sort
			y2 += 1
		end
		y2 += 1
		$logger.debug(2) { "lines=#{lines}" }
		str = view.create_memento_range(
			y1, [view.model.lines.size - y2, 0].max
		)
		$logger.debug(2) { "memento.size = #{str.size}" }
		str
	end
	def execute(view)
		if view.selection_mode
			view.swap_lower_selection
		else
			view.swap_lower
		end
	end
end

class Indent < EditBase
	def create_memento(view)
	  y1 = view.cursor_y
		y2 = view.cursor_y+1
		if view.selection_mode
			y1, y2 = [view.selection_y, view.cursor_y].sort
			y2 += 1
		end
		$logger.debug(2) { "lines=#{lines}" }
		str = view.create_memento_range(
			y1, view.model.lines.size - y2
		)
		$logger.debug(2) { "memento.size = #{str.size}" }
		str
	end
	def execute(view)
		if view.selection_mode
			view.indent_selection("\t")
		else
			view.indent("\t")
		end
	end
end

class Unindent < EditBase
	def create_memento(view)
	  y1 = view.cursor_y
		y2 = view.cursor_y+1
		if view.selection_mode
			y1, y2 = [view.selection_y, view.cursor_y].sort
			y2 += 1
		end
		$logger.debug(2) { "lines=#{lines}" }
		str = view.create_memento_range(
			y1, view.model.lines.size - y2
		)
		$logger.debug(2) { "memento.size = #{str.size}" }
		str
	end
	def execute(view)
		if view.selection_mode
			view.unindent_selection
		else
			view.unindent
		end
	end
end

class SelectionInit < OtherBase
	def create_memento(view)
		# NOTE: Memento::Range is overkill.. but does the job
		str = view.create_memento_range(
			view.cursor_y,
			view.model.lines.size - (view.cursor_y + 1)
		)
		$logger.debug(2) { "memento.size = #{str.size}" }
		str
	end
	def execute(view)
		view.selection_init
	end
end

class SelectionErase < OtherBase
	def create_memento(view)
	  y1 = view.cursor_y
		y2 = view.cursor_y+1
		if view.selection_mode
			y1, y2 = [view.selection_y, view.cursor_y].sort
			y2 += 1
		end
		str = view.create_memento_range(
			y1, view.model.lines.size - y2
		)
		$logger.debug(2) { "memento.size = #{str.size}" }
		str
	end
	def execute(view)
		view.selection_erase
	end
end

# purpose:
# leave special modes when hitting Escape.. (back to normal)
class BacktoNormal < OtherBase
	def create_memento(view)
		# NOTE: Memento::Range is overkill.. but does the job
		str = view.create_memento_range(
			view.cursor_y,
			view.model.lines.size - (view.cursor_y + 1)
		)
		$logger.debug(2) { "memento.size = #{str.size}" }
		str
	end
	def execute(view)
		view.selection_reset
	end
end

end # module Commands
