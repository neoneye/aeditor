# check that fxruby is installed
begin
	require 'fox'
rescue LoadError => e
	$stderr.puts <<MSG
ERROR: cannot load the 'Fxruby' component!
Please verify that you followed AEditor's
installation procedure correctly.
MSG
	raise e
end

# check that fxruby's version is good
fox_str = Fox::fxrubyversion
unless fox_str.match(/^1\.0\.\d/)
	$stderr.puts <<"MSG"
ERROR: compatibility problems with the 'Fxruby' component!
Expected version "1.0.x", but got #{fox_str.inspect}.
Please verify that you followed AEditor's
installation procedure correctly.
MSG
	raise 'fox version problem'
end

# check that Iterator is installed
begin
	require 'iterator'
rescue LoadError => e
	$stderr.puts <<MSG
ERROR: cannot load the 'Iterator' component!
Please verify that you followed AEditor's
installation procedure correctly.
MSG
	raise e
end


# load the remaining files.. (less likely that this should fail)
require 'aeditor/commands'
require 'aeditor/buffer'
require 'aeditor/fileio'
require 'aeditor/config'
require 'aeditor/session'

require 'fox/responder'
include Fox


module RGB
	def rgb2fixnum(r, g, b)
		r << 16 | g << 8 | b
	end
	def fixnum2red(rgb)
		(rgb >> 16) & 255
	end
	def fixnum2green(rgb)
		(rgb >> 8) & 255
	end
	def fixnum2blue(rgb)
		rgb & 255
	end
	def fixnum2rgb(rgb)
		[fixnum2red(rgb), fixnum2green(rgb), fixnum2blue(rgb)]
	end
	def fixnum_inspect(rgb)
		fixnum2rgb(rgb).inspect
	end
end

include RGB

class CurrentTheme
	DEFAULT_COLORS = {
		:bad      => [[255, 0, 0],     [0, 0, 0]],
		:preproc  => [[0, 0, 0],       [0, 255, 0]],
		:preproc_end   => [[0, 0, 90], [0, 255, 0]],
		:preproc_tab   => [[0, 0, 0],  [0, 255, 0]],
		:assembler=> [[0, 0, 0],       [0, 200, 200]],
		:assembler_end => [[0, 0, 90], [0, 200, 200]],
		:assembler_tab => [[0, 0, 90], [0, 200, 200]],
		:execute  => [[0, 0, 0],       [0, 200, 200]],
		:execute1  => [[0, 0, 0],      [0, 220, 220]],
		:execute_tab => [[0, 0, 0],    [0, 100, 100]],
		:execute_end => [[0, 0, 90],   [0, 200, 200]],
		:end      => [[56, 60, 56],    [30, 40, 20]],
		:keyword  => [[60, 60, 60],    [90, 110, 130]],
		:regexp   => [[30, 80, 0],     [165, 185, 25]],
		:regexp1  => [[60, 80, 180],   [165, 185, 25]],
		:regexp_tab  => [[30, 80, 0],  [165, 185, 25]],
		:regexp_end  => [[30, 80, 0],  [165, 185, 25]],
		:literal  => [[30, 80, 0],     [165, 185, 25]],
		:literal1 => [[30, 80, 0],     [165, 185, 25]],
		:literal_tab => [[30, 60, 0],  [165, 185, 25]],
		:literal_end => [[25, 60, 20], [165, 185, 25]],
		:punct    => [[60, 60, 60],    [120, 120, 120]],
		:symbol   => [[60, 60, 70],    [80, 120, 80]],
		:number   => [[60, 60, 60],    [90, 150, 70]], 
		:string   => [[60, 60, 60],    [90, 150, 70]],
		:string1  => [[94, 44, 89],    [90, 150, 70]],
		:string_tab => [[94, 44, 89],  [90, 100, 70]],
		:string_end => [[60, 60, 60],  [90, 150, 70]],
		:ivar     => [[60, 80, 130],   [0, 0, 0]],
		:cvar     => [[160, 180, 100], [90, 0, 0]],
		:gvar     => [[160, 180, 100], [90, 0, 0]],
		:dot      => [[60, 60, 60],    [80, 170, 110]],
		:dot1     => [[60, 80, 220],   [0, 0, 0]],
		:ivar1    => [[55, 75, 215],   [40, 50, 120]],
		:ident    => [[60, 60, 60],    [80, 120, 80]],
		:tab      => [[50, 54, 50], [48, 52, 48]],
		:text     => [[56, 60, 56], [89, 109, 134]],
		:any      => [[60, 60, 60],    [30, 40, 20]],
		:space    => [[60, 60, 60],    [30, 40, 20]],
		:out      => [[60, 60, 60],    [180, 100, 100]],
		:empty    => [[30, 30, 100],   [0, 0, 0]],
		:mcomment      => [[60, 80, 120],   [0, 0, 0]],
		:mcomment_tab  => [[60, 80, 120],   [0, 0, 0]],
		:mcomment_end  => [[60, 80, 120],   [0, 0, 0]],
		:endoffile     => [[100, 100, 100], [0, 0, 0]], 
		:endoffile_tab => [[83, 83, 97],    [0, 0, 0]],
		:endoffile_end => [[100, 100, 100], [0, 0, 0]],
		:comment       => [[60, 80, 120],   [0, 0, 0]],
		:comment_end   => [[60, 80, 120],   [0, 0, 0]],
		:comment_tab   => [[60, 80, 120],   [0, 0, 0]],
		:heredoc       => [[80, 60, 220],   [30, 40, 20]],
		:heredoc1      => [[80, 60, 220],   [30, 40, 20]],
		:heredoc_tab   => [[30, 70, 190],   [30, 40, 20]],
		:heredoc_end   => [[80, 60, 220],   [30, 40, 20]],
		:heredoc_end2  => [[80, 60, 200],   [30, 40, 20]]
	}
	def initialize
		reset
	end
	attr_reader :fixnum_pairs
	def set_rgb_pair(symbol, background, foreground)
		raise TypeError unless symbol.kind_of?(Symbol)
		@fixnum_pairs[symbol] = [
			rgb2fixnum(*background), 
			rgb2fixnum(*foreground)
		]
	end
	def import(session_theme)
		session_theme.colors.each do |key, (bg, fg)|
			self.set_rgb_pair(key.to_sym, bg, fg)
		end
	end
	def reset
		@fixnum_pairs = {}
		@fixnum_pairs.default = [
			rgb2fixnum(220, 220, 220),
			rgb2fixnum(40, 40, 40)
		]
		DEFAULT_COLORS.each_pair do |symbol, (fg, bg)|
			set_rgb_pair(symbol, fg, bg)
		end
	end
	def set_fg(symbol, rgb)
		raise TypeError unless rgb.kind_of?(Fixnum)
		@fixnum_pairs[symbol][1] = rgb
	end
	def set_bg(symbol, rgb)
		raise TypeError unless rgb.kind_of?(Fixnum)
		@fixnum_pairs[symbol][0] = rgb
	end
	def dump
		res = []
		@fixnum_pairs.each do |key, (fg, bg)|
			s_fg = fixnum_inspect(fg)
			s_bg = fixnum_inspect(bg)
			res << "  #{key.inspect} => [#{s_fg}, #{s_bg}]"
		end
		str = res.join(",\n")
		"theme={\n#{str}\n}"
	end
end

class ThemeDialog < FXDialogBox
	def fixnum2fxrgb(fixnum)
		r, g, b = fixnum2rgb(fixnum)
		FXRGB(r, g, b)
	end
	def fxrgb2fixnum(fxrgb)
		r = FXREDVAL(fxrgb)
		g = FXGREENVAL(fxrgb)
		b = FXBLUEVAL(fxrgb)
		rgb2fixnum(r, g, b)
	end
	def initialize(parent, theme)
		super(parent, "Theme", DECOR_ALL, 0, 0, 300, 600,
			0, 0, 0, 0, 0, 0)
		sa = FXScrollWindow.new(self, 
			VSCROLLER_ALWAYS|LAYOUT_FILL_X|LAYOUT_FILL_Y)
		pairs = FXMatrix.new(sa, 3, MATRIX_BY_COLUMNS|LAYOUT_FILL_X)
		pairs.padLeft = 2
		pairs.padRight = 2
		pairs.padTop = 2
		pairs.padBottom = 2
		pairs.hSpacing = 5
		pairs.vSpacing = 5 
		color_pairs = theme.fixnum_pairs
		color_pairs.keys.each do |key|
			FXLabel.new(pairs, key.to_s)
			# background
			bg = FXColorWell.new(pairs, 
				fixnum2fxrgb(color_pairs[key][0]), nil, 0, 
				FRAME_SUNKEN|FRAME_THICK|ICON_AFTER_TEXT|LAYOUT_FILL_X|LAYOUT_FILL_COLUMN
			)
			bg.connect(SEL_COMMAND) do |sender, sel, clr|
				theme.set_bg(key, fxrgb2fixnum(clr))
				parent.view.render_dirty_all
				parent.view.dirty_all
			end
			bg.connect(SEL_CHANGED) do |sender, sel, clr|
				theme.set_bg(key, fxrgb2fixnum(clr))
				parent.view.render_dirty_all
				parent.view.dirty_all
			end
			bg.connect(SEL_UPDATE) do |sender, sel, ptr|
				col = fixnum2fxrgb(color_pairs[key][0])
				sender.handle(self, MKUINT(ID_SETVALUE, SEL_COMMAND), col)
			end 
			# foreground
			fg = FXColorWell.new(pairs, 
				fixnum2fxrgb(color_pairs[key][1]), nil, 0,
				FRAME_SUNKEN|FRAME_THICK|ICON_AFTER_TEXT|LAYOUT_FILL_X|LAYOUT_FILL_COLUMN
			)
			fg.connect(SEL_COMMAND) do |sender, sel, clr|
				theme.set_fg(key, fxrgb2fixnum(clr))
				parent.view.render_dirty_all
				parent.view.dirty_all
			end
			fg.connect(SEL_CHANGED) do |sender, sel, clr|
				theme.set_fg(key, fxrgb2fixnum(clr))
				parent.view.render_dirty_all
				parent.view.dirty_all
			end
			fg.connect(SEL_UPDATE) do |sender, sel, ptr|
				col = fixnum2fxrgb(color_pairs[key][1])
				sender.handle(self, MKUINT(ID_SETVALUE, SEL_COMMAND), col)
			end 
		end
	end
end


# purpose:
# inheriting from FXDialogBox is problematic,
# because if you hit the Escape key the window is closed.
# This provides same functionality as FXDialogBox, except
# no close on Escape.
#
# it also contains some code for switching back and forth 
# between windowed-mode and fullscreen-mode.
class HackedDialogBox < FXTopWindow
	def initialize(owner, mode)
  	decor = (mode ? DECOR_NONE : DECOR_ALL)
		super(
			owner,
			'Dialog',
			nil,
			nil,
			decor,
			0, 0, 200, 200,
			0, 0, 0, 0, 0, 0)

    @terminate = true
		@owner = owner
		@mode = mode
		$logger.debug(1) {
			str_mode = (mode ? 'fullscreen' : 'windowed')
			"HackedDialogBox.new in #{str_mode} mode"
		}

		# this will deal with ALT-F4
		setTarget(self)
		connect(SEL_CLOSE, method(:maybeShutdownParent))
	end
	attr_reader :mode
  def onCmdSwitchMode(sender, sel, event)
		$logger.debug(1) { 'HackedDialogBox.onCmdSwitchMode' }
  	@terminate = false
		@owner.handle(self, 
			MKUINT(MainWindow::ID_SPAWN, SEL_COMMAND), nil)
  end
	def maybeShutdownParent(sender, sel, event)
		$logger.debug(1) { 'HackedDialogBox.maybeShutdownParent' }
		if @terminate
			@owner.handle(self,
				MKUINT(FXApp::ID_QUIT, SEL_COMMAND), nil)
		end
		0
	end
	def shutdown
		$logger.debug(1) { 'HackedDialogBox.shutdown' }
		destroy
	end
end

class EditorWidget < HackedDialogBox
	# hardcoded options
	OPTION_OPTIMIZE_VERTICAL_SCROLL = true
	OPTION_GARBAGE_COLLECTION_DELAY = 500


	include Responder

	ID_NEW_BUFFER,
	ID_OPEN_BUFFER,
	ID_CLOSE_BUFFER,
	ID_SAVE_BUFFER,
	ID_SAVEAS_BUFFER,
	ID_FIND,
	ID_FIND_AGAIN,
	ID_SPAWN_REPLACE_DIALOG, 
	ID_SPAWN_GOTOLINE_DIALOG,
	ID_TOGGLE_SCREEN_MODE,
	ID_NEXT_BUFFER,
	ID_PREV_BUFFER,
	ID_SWITCH_TO_BUFFER_0,
	ID_SWITCH_TO_BUFFER_1,
	ID_SWITCH_TO_BUFFER_2,
	ID_SWITCH_TO_BUFFER_3,
	ID_SWITCH_TO_BUFFER_4,
	ID_SWITCH_TO_BUFFER_5,
	ID_SWITCH_TO_BUFFER_6,
	ID_SWITCH_TO_BUFFER_7,
	ID_SWITCH_TO_BUFFER_8,
	ID_SWITCH_TO_BUFFER_9,
	ID_SWITCH_TO_THEME_0,
	ID_SWITCH_TO_THEME_1,
	ID_SWITCH_TO_THEME_2,
	ID_SWITCH_TO_THEME_3,
	ID_SWITCH_TO_THEME_4,
	ID_SWITCH_TO_THEME_5,
	ID_SWITCH_TO_THEME_6,
	ID_SWITCH_TO_THEME_7,
	ID_SWITCH_TO_THEME_8,
	ID_SWITCH_TO_THEME_9,
	ID_SPAWN_FONTDIALOG,
	ID_GARBAGE_COLLECT,
	ID_SCROLLBAR,
	ID_CUT,
	ID_COPY,
	ID_PASTE,
	ID_LAST = enum(HackedDialogBox::ID_LAST, 39)


	DIRTY_ALL = Buffer::View::Caretaker::DIRTY_ALL
	DIRTY_CURSOR = Buffer::View::Caretaker::DIRTY_CURSOR

	# TODO: it would be nice if I could move this to 'commands.rb'
	class SelectionCopy < Commands::OtherBase
		def initialize(session, clipboard_owner)
			super()
			@session = session
			@clipboard_owner = clipboard_owner
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
			@session.set_clipboard(
				view.get_text_selection_array.join
			)
			@clipboard_owner.acquireClipboard([FXWindow.stringType])
		end
		def execute_redo(view)
		end
	end # class SelectionCopy

	def initialize(main_window, is_fullscreen_mode)
		unless main_window.font_created
			raise "Font wasn't created"
		end
		@font = main_window.font
		@is_fullscreen_mode = is_fullscreen_mode
		@respawn = false

		@render_y = 0
		@render_lock = false
		@set_dirty_locked = false

		super(main_window, is_fullscreen_mode)
		@main_window = main_window
		@session = @main_window.session
		@theme = main_window.theme
		@theme_name = nil

		FXMAPFUNC(SEL_COMMAND, ID_TOGGLE_SCREEN_MODE, :onCmdSwitchMode)
		FXMAPFUNC(SEL_COMMAND, ID_SAVEAS_BUFFER, :onSaveAsBuffer)
		FXMAPFUNC(SEL_COMMAND, ID_NEW_BUFFER, :onNewBuffer)
		FXMAPFUNC(SEL_COMMAND, ID_OPEN_BUFFER, :onOpenBuffer)
		FXMAPFUNC(SEL_COMMAND, ID_CLOSE_BUFFER, :onCloseBuffer)
		FXMAPFUNC(SEL_COMMAND, ID_SAVE_BUFFER, :onSaveBuffer)
		FXMAPFUNC(SEL_COMMAND, ID_FIND, :onFind)
		FXMAPFUNC(SEL_COMMAND, ID_FIND_AGAIN, :onFindAgain)
		FXMAPFUNC(SEL_COMMAND, ID_NEXT_BUFFER, :onNextBuffer)
		FXMAPFUNC(SEL_COMMAND, ID_PREV_BUFFER, :onPrevBuffer)
		FXMAPFUNC(SEL_COMMAND, ID_SPAWN_REPLACE_DIALOG, :onSpawnReplaceDialog)
		FXMAPFUNC(SEL_COMMAND, ID_SWITCH_TO_BUFFER_0, :onSwitchToBuffer)
		FXMAPFUNC(SEL_COMMAND, ID_SWITCH_TO_BUFFER_1, :onSwitchToBuffer)
		FXMAPFUNC(SEL_COMMAND, ID_SWITCH_TO_BUFFER_2, :onSwitchToBuffer)
		FXMAPFUNC(SEL_COMMAND, ID_SWITCH_TO_BUFFER_3, :onSwitchToBuffer)
		FXMAPFUNC(SEL_COMMAND, ID_SWITCH_TO_BUFFER_4, :onSwitchToBuffer)
		FXMAPFUNC(SEL_COMMAND, ID_SWITCH_TO_BUFFER_5, :onSwitchToBuffer)
		FXMAPFUNC(SEL_COMMAND, ID_SWITCH_TO_BUFFER_6, :onSwitchToBuffer)
		FXMAPFUNC(SEL_COMMAND, ID_SWITCH_TO_BUFFER_7, :onSwitchToBuffer)
		FXMAPFUNC(SEL_COMMAND, ID_SWITCH_TO_BUFFER_8, :onSwitchToBuffer)
		FXMAPFUNC(SEL_COMMAND, ID_SWITCH_TO_BUFFER_9, :onSwitchToBuffer)
		FXMAPFUNC(SEL_COMMAND, ID_SWITCH_TO_THEME_0, :onSwitchToTheme)
		FXMAPFUNC(SEL_COMMAND, ID_SWITCH_TO_THEME_1, :onSwitchToTheme)
		FXMAPFUNC(SEL_COMMAND, ID_SWITCH_TO_THEME_2, :onSwitchToTheme)
		FXMAPFUNC(SEL_COMMAND, ID_SWITCH_TO_THEME_3, :onSwitchToTheme)
		FXMAPFUNC(SEL_COMMAND, ID_SWITCH_TO_THEME_4, :onSwitchToTheme)
		FXMAPFUNC(SEL_COMMAND, ID_SWITCH_TO_THEME_5, :onSwitchToTheme)
		FXMAPFUNC(SEL_COMMAND, ID_SWITCH_TO_THEME_6, :onSwitchToTheme)
		FXMAPFUNC(SEL_COMMAND, ID_SWITCH_TO_THEME_7, :onSwitchToTheme)
		FXMAPFUNC(SEL_COMMAND, ID_SWITCH_TO_THEME_8, :onSwitchToTheme)
		FXMAPFUNC(SEL_COMMAND, ID_SWITCH_TO_THEME_9, :onSwitchToTheme)
		FXMAPFUNC(SEL_COMMAND, ID_SPAWN_FONTDIALOG, :onSpawnFontDialog)
		FXMAPFUNC(SEL_COMMAND, ID_SPAWN_GOTOLINE_DIALOG, :onSpawnGotoLineDialog)
		FXMAPFUNC(SEL_TIMEOUT, ID_GARBAGE_COLLECT, :onGarbageCollect)
		@timeout_gc = nil
		FXMAPFUNC(SEL_CHANGED, ID_SCROLLBAR, :onScrollbar)
		FXMAPFUNC(SEL_COMMAND, ID_CUT, :onCut)
		FXMAPFUNC(SEL_COMMAND, ID_COPY, :onCopy)
		FXMAPFUNC(SEL_COMMAND, ID_PASTE, :onPaste)

		# data targets
		@target_statusbar_x = FXDataTarget.new('0')
		@target_statusbar_y = FXDataTarget.new('0')
		@target_statusbar_percent = FXDataTarget.new('TOP')
		
		# build status line
		status = FXStatusbar.new(self,
			LAYOUT_SIDE_BOTTOM|LAYOUT_FILL_X|STATUSBAR_WITH_DRAGCORNER)
		status_percent = FXTextField.new(status, 4, 
			@target_statusbar_percent, FXDataTarget::ID_VALUE,
			FRAME_SUNKEN|JUSTIFY_RIGHT|LAYOUT_RIGHT|LAYOUT_CENTER_Y|
			TEXTFIELD_READONLY, 0, 0, 0, 0, 2, 2, 1, 1)
		status_percent.backColor = status.backColor
		status_y = FXTextField.new(status, 5, 
			@target_statusbar_y, FXDataTarget::ID_VALUE,
			FRAME_SUNKEN|JUSTIFY_RIGHT|LAYOUT_RIGHT|LAYOUT_CENTER_Y|
			TEXTFIELD_READONLY, 0, 0, 0, 0, 2, 2, 1, 1)
		status_y.backColor = status.backColor
		FXLabel.new(status, " Y", nil, LAYOUT_RIGHT|LAYOUT_CENTER_Y)
		status_x = FXTextField.new(status, 3, 
			@target_statusbar_x, FXDataTarget::ID_VALUE,
			FRAME_SUNKEN|JUSTIFY_RIGHT|LAYOUT_RIGHT|LAYOUT_CENTER_Y|
			TEXTFIELD_READONLY, 0, 0, 0, 0, 2, 2, 1, 1)
		status_x.backColor = status.backColor
		FXLabel.new(status, " X", nil, LAYOUT_RIGHT|LAYOUT_CENTER_Y)
		@status = status

		# build pull down menu
		menu = FXMenubar.new(self, LAYOUT_SIDE_TOP|LAYOUT_FILL_X)
		FXHorizontalSeparator.new(
			self, LAYOUT_SIDE_TOP|LAYOUT_FILL_X|SEPARATOR_GROOVE)

		# some space in the left side.. in fullscreen mode
    pad_left = @is_fullscreen_mode ? 20 : 0
		hf = FXHorizontalFrame.new(self, LAYOUT_FILL_X|LAYOUT_FILL_Y,
			0, 0, 0, 0, pad_left, 0, 0, 0, 0, 0)
		@canvas = FXCanvas.new(hf, nil, 0, LAYOUT_FILL_X|LAYOUT_FILL_Y)
		@scrollbar = FXScrollbar.new(hf, self, ID_SCROLLBAR, LAYOUT_FILL_Y)

		# build file menu
		menu_file = FXMenuPane.new(self)
		FXMenuCommand.new(menu_file, "New\tCtrl-N", nil, self, ID_NEW_BUFFER)
		FXMenuCommand.new(menu_file, "Open...\tCtrl-O", nil, self, ID_OPEN_BUFFER)
		FXMenuCommand.new(menu_file, "Save\tCtrl-S", nil, self, ID_SAVE_BUFFER)
		FXMenuCommand.new(menu_file, "Save As...", nil, self, ID_SAVEAS_BUFFER)
		FXMenuCommand.new(menu_file, "Close\tCtrl-W", nil, self, ID_CLOSE_BUFFER)
		FXMenuSeparator.new(menu_file)
		q = FXMenuCommand.new(menu_file, "Quit\tCtrl-Q", nil, nil, 0)
    q.connect(SEL_COMMAND, method(:maybeShutdownParent))
		FXMenuTitle.new(menu, "&File", nil, menu_file)

		# build edit menu
		menu_edit = FXMenuPane.new(self)
		FXMenuCommand.new(menu_edit, "Undo\tCtrl-Z").connect(SEL_COMMAND) do
			$logger.debug(1) { "undo" }
			obtain_render_lock do
				@view.execute_undo
			end
			# TODO: doesn't repaint the display correct
		end
		FXMenuCommand.new(menu_edit, "Redo\tCtrl-Shift-Z").connect(SEL_COMMAND) do
			$logger.debug(1) { "redo" }
			obtain_render_lock do
				@view.execute_redo
			end
			# TODO: doesn't repaint the display correct
		end
		FXMenuSeparator.new(menu_edit)
		@macro = nil
		# TODO: make this menuitem dynamic.. reflecting record mode
		FXMenuCommand.new(menu_edit, "Record Macro\tF10").connect(SEL_COMMAND) do
			unless @view.memento_caretaker.record_mode
				@view.memento_caretaker.macro_begin
				@status.statusline.normalText = 'Now recording'
			else
				@macro = @view.memento_caretaker.macro_end
				@status.statusline.normalText = 'Stopped recording'
			end
		end
		FXMenuCommand.new(menu_edit, "Play Macro\tF11").connect(SEL_COMMAND) do
			$logger.debug(1) { "play macro" }
			obtain_render_lock do
				@view.execute(@macro) if @macro
			end
		end
		FXMenuSeparator.new(menu_edit)
		FXMenuCommand.new(menu_edit, "Cut\tCtrl-X", nil, self, ID_CUT)
		FXMenuCommand.new(menu_edit, "Copy\tCtrl-C", nil, self, ID_COPY)
		FXMenuCommand.new(menu_edit, "Paste\tCtrl-V", nil, self, ID_PASTE)
		FXMenuTitle.new(menu, "&Edit", nil, menu_edit)
		
		menu_search = FXMenuPane.new(self)
		FXMenuCommand.new(menu_search, "Find...\tCtrl-F", nil, self, ID_FIND)
		FXMenuCommand.new(menu_search, "Find Again\tF3", nil, self, ID_FIND_AGAIN)
		FXMenuCommand.new(menu_search, "Replace...\tCtrl-R", nil, self, ID_SPAWN_REPLACE_DIALOG)
		FXMenuCommand.new(menu_search, "Goto Line...\tCtrl-L", nil, self, ID_SPAWN_GOTOLINE_DIALOG)
		FXMenuCommand.new(menu_search, "Match Brackets\tCtrl-M").connect(SEL_COMMAND) do
			$logger.debug(1) { "match brackets" }
			unless @view.execute(Commands::MoveBracket.new)
				$logger.debug(1) { "could not find parentesis" }
			end
		end
		FXMenuCommand.new(menu_search, "Toggle Bookmark\tCtrl-B").connect(SEL_COMMAND) do
			$logger.debug(1) { "toggle bookmark" }
			# TODO: don't know yet if it should be undoable?
			has_mark = @view.bookmarks.any? do |(key, yval)|
				(yval == @view.cursor_y)
			end
			if has_mark
				$logger.debug(1) { "removing bookmark" }
				@view.bookmarks.delete_if do |(key, yval)|
					(yval == @view.cursor_y)
				end
			else
				$logger.debug(1) { "placing bookmark" }
				key = 1
				key += 1 while @view.bookmarks.has_key?(key)
				@view.bookmark(key) 
			end
			#p @view.bookmarks
		end
		FXMenuTitle.new(menu, "&Search", nil, menu_search)

		# build buffers menu
		menu_buffers = FXMenuPane.new(self)
		FXMenuCommand.new(menu_buffers, "Prev\tShift-F12", nil, self, ID_PREV_BUFFER)
		FXMenuCommand.new(menu_buffers, "Next\tF12", nil, self, ID_NEXT_BUFFER)
		FXMenuSeparator.new(menu_buffers)
		@menuitem_buffer = []
		10.times do |i|
			id_const = eval("ID_SWITCH_TO_BUFFER_#{i}")
			key = (i != 9) ? i + 1 : 0
			item = FXMenuCommand.new(menu_buffers, 
				"should not be visible\tCtrl-#{key}", nil, self, id_const)
			item.handle(self, MKUINT(FXWindow::ID_HIDE, SEL_COMMAND), nil)
			@menuitem_buffer << item
		end
		FXMenuTitle.new(menu, "&Buffers", nil, menu_buffers)

		# build view menu
		menu_view = FXMenuPane.new(self)
		str = @is_fullscreen_mode ? "Window-mode" : "Fullscreen"
		FXMenuCommand.new(menu_view, str + "\tF8", nil, self, ID_TOGGLE_SCREEN_MODE)
		FXMenuCommand.new(menu_view, "Scrollbar", nil, @scrollbar, FXWindow::ID_TOGGLESHOWN)
		FXMenuCommand.new(menu_view, "Change Font...", nil, self, ID_SPAWN_FONTDIALOG)
		FXMenuCommand.new(menu_view, "Customize Theme...").connect(SEL_COMMAND) {
			$logger.debug(1) { "spawn theme dialog" }
			dialog = ThemeDialog.new(self, @theme)
			dialog.execute
		}
		FXMenuCommand.new(menu_view, "Dump Theme To STDOUT").connect(SEL_COMMAND) {
			msg = "This is a dump of AEditor's current theme\n"
			$stdout.puts(msg + @theme.dump)
		}
		FXMenuSeparator.new(menu_view)
		@menuitem_view = []
		names = @main_window.session.themes.map {|t| "theme - #{t.name}" }
		names.unshift('theme - default')
		names.each_with_index do |name, i|
			id_const = eval("ID_SWITCH_TO_THEME_#{i}")
			item = FXMenuCommand.new(menu_view, name, nil, self, id_const)
			@menuitem_view << item
		end
		FXMenuTitle.new(menu, "&Config", nil, menu_view)

		# build help menu
		menu_help = FXMenuPane.new(self)
		FXMenuCommand.new(menu_help, "&About...").connect(SEL_COMMAND) {
			FXMessageBox.information(self, MBOX_OK, "About Aeditor",
			"Aeditor is a programmers editor, written entirely in Ruby.\n" +
			"By Simon Strandgaard.")
		}
		FXMenuTitle.new(menu, "&Help", nil, menu_help, LAYOUT_RIGHT) 

		# almost the same as #onNextBuffer
		@smart_cursor_content = nil
		@smart_cursor_x = 0
		@smart_cursor_y = 0
		@dirty = DIRTY_ALL
		@buffer = @session.buffer
		@view = @buffer.view
		@view.set_render_callback {|flag| set_dirty(flag) }

		application = getApp()
		@back_buffer = FXImage.new(application, nil, IMAGE_KEEP) 
		@temp_buffer = FXImage.new(application, nil, IMAGE_KEEP) 
		@canvas.connect(SEL_PAINT, method(:onCanvasRepaint))
		@canvas.connect(SEL_CONFIGURE, method(:onCanvasConfigure))
		@canvas.connect(SEL_LEFTBUTTONPRESS, method(:onLeftMousePress))
		@canvas.connect(SEL_RIGHTBUTTONRELEASE, method(:onTextRightMouse))
		@canvas.connect(SEL_KEYPRESS, method(:onKeypress))
		@canvas.connect(SEL_KEYRELEASE) do |sender, sel, event|
			$logger.debug(2) { "release - keysym=#{event.code} state=#{event.state}" }
		end

		self.connect(SEL_CLIPBOARD_REQUEST) do
			txt = @session.clipboard
			# TODO: require 'fox/core'
			# TODO: txt = Fox.fxencodeStringData(@session.clipboard)
			$logger.debug(2) { "transfering paste data=#{txt.inspect}" }
			setDNDData(FROM_CLIPBOARD, FXWindow.stringType, txt)
		end

		refresh_buffer_menu
	end
	attr_reader :is_fullscreen_mode, :respawn, :view
	def dump_cache_status
		$logger.debug(1) { "dumping cache valid overview" }
		str_lcache = @view.lexer_cache_valid.map{|i|"%5s"%i.inspect}.join(', ') 
		$logger.debug(1) { "lcache_valid = [#{str_lcache}]"  }
		str_render = @view.render_valid.map{|i|"%5s"%i.inspect}.join(', ')
		$logger.debug(1) { "render_valid = [#{str_render}]" }
		str_output = @output_valid.map{|i|"%5s"%i.inspect}.join(', ')
		$logger.debug(1) { "output_valid = [#{str_output}]" }
	end
	def dump_lcache_contents
		$logger.debug(1) { "dumping cache text content" }
		lines = @view.lexer_cache_lines.map do |line_endstate|
			next '' unless line_endstate
			line, endstate = line_endstate
			next '' if line.size < 1
			line.transpose[0].join.strip
		end
		$logger.debug(1) { "lexer_cache_lines (text extracted) = #{lines.inspect}" }
	end
	def dump_object_status
		$logger.debug(1) { "dumping object overview" }
		h = {} 
		h.default = 0 
		number_of_objects = ObjectSpace.each_object {|i| h[i.class] += 1 } 
		ary = h.to_a.map{|(k,v)|[v, k.to_s]}.sort
		objects_str = ary.map{|(n,name)|"#{name}=#{n}"}.reverse.join(',')
		sum_str_len = 0
		ObjectSpace.each_object(String) {|i| sum_str_len += i.to_s.size } 
		$logger.debug(1) do <<-STR.gsub(/^\s+/,'')
      #{objects_str}
      total number of objects  = #{number_of_objects}
      total sum of string.size = #{sum_str_len}
      STR
    end
	end
	def read_registry
		# options
		hidescrollbar = getApp().reg().readIntEntry('SETTINGS', 
			'hidescrollbar', 0)
		@scrollbar.hide if hidescrollbar != 0
		# window dimentions
		unless @is_fullscreen_mode
			xx = getApp().reg().readIntEntry('SETTINGS', 'x', 5)
			yy = getApp().reg().readIntEntry('SETTINGS', 'y', 5)
			ww = getApp().reg().readIntEntry('SETTINGS', 'width', 512)
			hh = getApp().reg().readIntEntry('SETTINGS', 'height', 380) 
			position(xx, yy, ww, hh)
		end
		# theme
		str = getApp().reg().readStringEntry('SETTINGS', 'theme', 'nil') 
		@theme_name = nil
		if str != 'nil'
			@session.themes.each do |theme|
				if theme.name == str
					@theme.import(theme)
					@theme_name = str
					break
				end
			end
		end
		unless @theme_name
			$logger.debug(1) { "could not load the theme #{str.inspect}!" }
		else
			$logger.debug(1) { "loaded theme #{@theme_name.inspect} successfully" }
		end
	end
	def write_registry
		$logger.debug(2) { "writing to registry" }
		# options
		getApp().reg().writeIntEntry('SETTINGS', 'hidescrollbar', 
			(@scrollbar.shown() ? 0 : 1)
		)
		# window dimensions
		unless @is_fullscreen_mode
			getApp().reg().writeIntEntry('SETTINGS', 'x', getX())
			getApp().reg().writeIntEntry('SETTINGS', 'y', getY())
			getApp().reg().writeIntEntry('SETTINGS', 'width', getWidth())
			getApp().reg().writeIntEntry('SETTINGS', 'height', getHeight())
		end
		# theme
		getApp().reg().writeStringEntry('SETTINGS', 'theme', 
			@theme_name || 'nil')
	end
	def install_vertical_scroll_callback(view)
		return unless OPTION_OPTIMIZE_VERTICAL_SCROLL
		view.set_vscroll_callback do |y1, y2, count|
			$logger.debug(1) { "vscroll y1=#{y1} y2=#{y2} count=#{count}" }
			fh = @font.fontHeight
			sx = 0
			sy = y1 * fh
			sw = @back_buffer.width
			sh = count * fh
			dy = y2 * fh
			dx = 0
			# blitting where both source and destination are the same, 
			# doesn't work on Windows.. but works on UNIX.
			# A non-ideal solution is to use a temporary buffer, but it
			# has drawback: double as data we must blit takes
			# double as much time.
			# NOTE: real solution is to fix FOX and remove temp_buffer.
			FXDCWindow.new(@temp_buffer) do |dc|
				dc.drawArea(@back_buffer, sx, sy, sw, sh, dx, dy)
			end
			FXDCWindow.new(@back_buffer) do |dc|
				dc.drawArea(@temp_buffer, dx, dy, sw, sh, dx, dy)
			end
			# do scrolling of the arrays where we keep track of the output
			# NOTE: maybe its necessary to clone the lines
			@output_valid[y2, count] = @output_valid[y1, count] #.map{|i| i.clone}
			@lines[y2, count] = @lines[y1, count] #.map{|i| i.clone}
		end
	end
	def shutdown
		$logger.debug(1) { 'EditorWidget.shutdown' }
		write_registry
		destroy
	end
	def create
		read_registry
		super
		# font are already initialized by our parent
		@back_buffer.create
		@temp_buffer.create
		@canvas.setFocus
		update_title 
		install_vertical_scroll_callback(@view)
	end
	def onGarbageCollect(sender, sel, event)
		$logger.debug(2) { "GC begin" }
		GC.enable
		GC.start
		@timeout_gc = nil
		$logger.debug(2) { "GC done" }
		1
	end
	def reset_timeout_for_garbage_collection
		$logger.debug(2) { "reset GC timeout" }
		getApp().removeTimeout(@timeout_gc) if @timeout_gc
		@timeout_gc = getApp().addTimeout(
    	OPTION_GARBAGE_COLLECTION_DELAY,
			self, 
			ID_GARBAGE_COLLECT
		)
	end
	def onCut(sender, sel, event)
		$logger.debug(1) { 'on cut' }
		@view.execute(
			History::Command::Macro.new([
				SelectionCopy.new(@session, self),
				Commands::SelectionErase.new
			])
		)
	end
	def onCopy(sender, sel, event)
		$logger.debug(1) { 'on copy' }
		@view.execute(SelectionCopy.new(@session, self))
	end
	def onPaste(sender, sel, event)
		$logger.debug(1) { 'on paste' }
		str = getDNDData(FROM_CLIPBOARD, FXWindow.stringType)
		return unless str
		@view.execute(Commands::InsertText.new(str))
	end
	def onScrollbar(sender, sel, event)
		$logger.debug(2) {"scroll me, event=#{event.inspect}"}
		newy = event
		# TODO: make me undoable
		@view.set_scroll_y(newy)
		1
	end
	def percent  # TODO: move me to buffer
		max_y = @buffer.model.lines.size-1
		y = @view.cursor_y
		str = case
		when y == 0
			"TOP"
		when y == max_y
			"BOT"
		when (max_y < 1 or max_y < y)
			raise "should not happen, max_y=#{max_y}, y=#{y}"
		else
			"%%%02d" % (y * 100 / max_y) 
		end
		str
	end
	def set_dirty(flag)
=begin
		case flag
		when :all
			$logger.debug(2) { 'dirty all' }
			@dirty = DIRTY_ALL
		when :cursor
			$logger.debug(2) { 'dirty cursor' }
			@dirty |= DIRTY_CURSOR
		else
			raise "unknown dirty flag \"#{flag.to_s}\""
		end
=end
		@dirty |= flag
		# prevent recursion
		return if @set_dirty_locked
		@set_dirty_locked = true
		begin
			render
		ensure
			@set_dirty_locked = false
		end
	end
	def refresh_buffer_menu
		$logger.debug(1) { "refresh buffer menu" }
		@menuitem_buffer.each_with_index do |mi, index|
			if index >= @session.buffers.size 
				mi.handle(self, MKUINT(FXWindow::ID_HIDE, SEL_COMMAND), nil)
				next
			end
			name = @session.buffers[index].title
			mi.handle(self, MKUINT(FXWindow::ID_SETSTRINGVALUE, SEL_COMMAND), name)
			mi.handle(self, MKUINT(FXWindow::ID_SHOW, SEL_COMMAND), nil)
		end
	end
	def onSwitchToBuffer(sender, sel, event)
		index = SELID(sel) - ID_SWITCH_TO_BUFFER_0
		msg = "switch to buffer ##{index} event=#{event}"
		if index < 0 or index >= @session.buffers.size
			$logger.debug(1) {
                msg + " ... index (#{index}) out of " +
				"range 0..#{@session.buffers.size-1}"
            }
			return
		end
		$logger.debug(1) { msg }
		switch_to_buffer(index)
	end
	def onNextBuffer(sender, sel, event) 
		$logger.debug(1) { "next buffer" }
		switch_to_buffer(@session.buffer_index + 1)
	end
	def onPrevBuffer(sender, sel, event) 
		$logger.debug(1) { "prev buffer" }
		switch_to_buffer(@session.buffer_index - 1)
	end
	def switch_to_buffer(buffer_index)
		from_index = @session.buffer_index
		cells_x = @view.number_of_cells_x
		cells_y = @view.number_of_cells_y
		extra_top = @view.extra_top
		extra_bottom = @view.extra_bottom
		if buffer_index < 0
			buffer_index = @session.buffers.size-1
		end
		if buffer_index >= @session.buffers.size
			buffer_index = 0
		end
		$logger.debug(1) { "switching from buffer##{from_index} to buffer##{buffer_index}" }
		@smart_cursor_content = nil
		@smart_cursor_x = 0
		@smart_cursor_y = 0
		@dirty = DIRTY_ALL
		@session.set_buffer_index(buffer_index)
		@buffer = @session.buffer
		@view = @buffer.view
		@view.set_render_callback {|flag| set_dirty(flag) }
		install_vertical_scroll_callback(@view)
		update_title 
		# maybe its better to send a SEL_CONFIGURE event ?
		@view.resize(cells_x, cells_y)
		@view.set_extra_lines(extra_top, extra_bottom)
		# TODO: why is switch unclean, view.reload should not be necessary ?
		@view.reload_lines        
		@view.reload_current_line
		render_dirty_areas
		@canvas.update  
	end
	def update_title
		title = "##{@session.buffer_index} - #{@session.buffer.title}"
		self.handle(self, MKUINT(FXWindow::ID_SETSTRINGVALUE, SEL_COMMAND), title)
	end
	def onSwitchToTheme(sender, sel, event)
		index = SELID(sel) - ID_SWITCH_TO_THEME_0
		msg = "switch to theme ##{index} event=#{event}"
		$logger.debug(1) { msg }
		if index == 0
			@theme.reset
			@view.render_dirty_all
			@view.dirty_all
			@theme_name = nil
			return
		end
		theme = @main_window.session.themes[index-1]
		return unless theme
		@theme.import(theme)
		@view.render_dirty_all
		@view.dirty_all
		@theme_name = theme.name
	end
	class FindDialog < FXDialogBox
		def initialize(main_window)
			super(main_window, "Find text", DECOR_ALL) 
			vf = FXVerticalFrame.new(self)
			@search_text = FXTextField.new(vf, 40, self, ID_ACCEPT)
			# TODO: if one hits enter in the textfield, it should click accept
			hf = FXHorizontalFrame.new(vf)
			FXButton.new(hf, "find").connect(SEL_COMMAND) {
				handle(self, MKUINT(FXDialogBox::ID_ACCEPT, SEL_COMMAND), nil)
			}                          
			#FXHorizontalSeparator.new(hf, SEPARATOR_NONE)
			FXButton.new(hf, "cancel").connect(SEL_COMMAND) {
				handle(self, MKUINT(FXDialogBox::ID_CANCEL, SEL_COMMAND), nil)
			}
		end
		def execute
			create
			@search_text.setFocus
			show(PLACEMENT_SCREEN)
			getApp.runModalFor(self)
		end
		def search_text
			@search_text.getText
		end
	end
	def onFind(sender, sel, event) 
		$logger.debug(1) { "find" }
		win = FindDialog.new(self)
		if win.execute != 0
			$logger.debug(1) {
				"searching:  pattern=#{win.search_text.inspect}"
			}
			obtain_render_lock do
				ok = @view.execute(Commands::MovePattern.new(win.search_text))
				$logger.debug(1) { 
					(ok) ? "search status=ok" : 
					"search status=no match" 
				}
			end
		else
			$logger.debug(1) { "search status=canceled" }
		end
	end
	def onFindAgain(sender, sel, event) 
		$logger.debug(1) { 
			"find again.. pattern=#{@view.search_last_pattern.inspect}"
		}
		obtain_render_lock do
			ok = @view.execute(Commands::MovePattern.new(
				@view.search_pattern_last))
		    $logger.debug(1) { (ok) ? "ok" : "no match" }
		end
	end 
	class ReplaceDialog < FXDialogBox
		def initialize(main_window)
			super(main_window, "Replace text", DECOR_ALL) 
			vf = FXVerticalFrame.new(self)
			@search_text = FXTextField.new(vf, 40)
			@replace_text = FXTextField.new(vf, 40, self, ID_ACCEPT)
			hf = FXHorizontalFrame.new(vf)
			FXButton.new(hf, "replace").connect(SEL_COMMAND) {
				handle(self, MKUINT(FXDialogBox::ID_ACCEPT, SEL_COMMAND), nil)
			}                          
			FXButton.new(hf, "cancel").connect(SEL_COMMAND) {
				handle(self, MKUINT(FXDialogBox::ID_CANCEL, SEL_COMMAND), nil)
			}
		end
		def execute
			create
			@search_text.setFocus
			show(PLACEMENT_SCREEN)
			getApp.runModalFor(self)
		end
		def search_text
			@search_text.getText
		end
		def replace_text
			@replace_text.getText
		end
	end
	class PromptReplaceDialog < FXDialogBox
		def initialize(main_window)
			super(main_window, "Replace this occurence?", DECOR_ALL) 
			hf = FXHorizontalFrame.new(self)
			FXButton.new(hf, "No").connect(SEL_COMMAND) do
				#main_window.view.mode_skip
				# TODO: move this search_again logic to buffer.rb
				ok = main_window.view.execute(Commands::MovePattern.new(
					main_window.view.search_pattern_last))
				$logger.debug(1) { (ok) ? "ok" : "no match" }
			end
			FXButton.new(hf, "Yes").connect(SEL_COMMAND) do
				#main_window.view.mode_accept 
				ok = main_window.view.execute(Commands::ReplaceAndMove.new)
				$logger.debug(1) { (ok) ? "ok replaced" : "no replacement" }
			end
			FXButton.new(hf, "Close").connect(SEL_COMMAND) do
				handle(self, MKUINT(FXDialogBox::ID_CANCEL, SEL_COMMAND), nil)
			end
		end
	end
	def onSpawnReplaceDialog(sender, sel, event) 
		$logger.debug(1) { "spawn replace dialog" }
		win = ReplaceDialog.new(self)
		if win.execute == 0
			$logger.debug(1) { "cancel" }
			return
		end
		print "replacing pattern(#{win.search_text.inspect}) " +
			"with (#{win.replace_text.inspect}) ... "
		@view.execute(Commands::MovePattern.new(
			win.search_text,
			win.replace_text
		))
		PromptReplaceDialog.new(self).execute
	end 
	class GotoLineDialog < FXDialogBox
		def initialize(main_window)
			super(main_window, "Goto line", DECOR_ALL)
			vf = FXVerticalFrame.new(self)
			@text = FXTextField.new(vf, 10, self, ID_ACCEPT,
				TEXTFIELD_INTEGER|TEXTFIELD_NORMAL)
			hf = FXHorizontalFrame.new(vf)
			FXButton.new(hf, "Goto").connect(SEL_COMMAND) do
				handle(self, MKUINT(FXDialogBox::ID_ACCEPT, SEL_COMMAND), nil)
			end
			FXButton.new(hf, "Cancel").connect(SEL_COMMAND) do
				handle(self, MKUINT(FXDialogBox::ID_CANCEL, SEL_COMMAND), nil)
			end
		end
		attr_reader :text
		def execute
			create
			@text.setFocus
			show(PLACEMENT_SCREEN)
			getApp.runModalFor(self)
		end
	end
	def onSpawnGotoLineDialog(sender, sel, event) 
		$logger.debug(1) { "spawn goto line dialog" }
		win = GotoLineDialog.new(self)
		if win.execute != 0
			line = win.text.text.to_i-1
			if line < 0
				line = @view.model.lines.size+line
			end
			$logger.debug(1) { "jumping to line = #{line}" }
			@view.execute(Commands::MoveAbsolute.new(
				@view.cursor_x, line))
		end
	end
	def save_to_file(filename)
		$logger.debug(1) { "saving to file: #{filename}" }
		text = @buffer.model.to_a.join
		begin
			# TODO: check if file has been changed since last save
			FileSaver.save(filename, text)
		rescue RuntimeError => e
			$logger.debug(1) { "failed: #{e.message.inspect}" }
			FXMessageBox.warning(
				self, MBOX_OK, "Failed saving to file!", e.message)
			return false
		end
		$logger.debug(1) { "save done." }
		@status.statusline.normalText = 'File Saved.'
		true
	end
	def onSaveBuffer(sender, sel, event)  
		$logger.debug(1) { "buffer save" }
		if @buffer.filename
			# if its first time we try to save a new file
			# then we should spawn the SaveAs dialog.
			return save_to_file(@buffer.filename)
		end
		spawn_saveas_dialog
	end
	def onSaveAsBuffer(sender, sel, event) 
		spawn_saveas_dialog
	end
	def spawn_saveas_dialog
		$logger.debug(1) { "buffer save as dialogbox" }
		dialog = FXFileDialog.new(self, "Save File")
		dialog.selectMode = SELECTFILE_ANY
		dialog.filename = @buffer.title
		if dialog.execute == 0
			$logger.debug(1) { "canceled save" }
			return 1 
		end
		filename = dialog.filename
		if File.exists?(filename)
			if MBOX_CLICKED_CANCEL == FXMessageBox.question(
				self, MBOX_OK_CANCEL, "Overwrite File?", 
				"Overwrite existing file: #{filename.inspect}?")
				$logger.debug(1) { "canceled overwrite" }
				return 1
			end
		end
		if save_to_file(filename)
			$logger.debug(1) { "attach filename(#{filename}) to buffer" }
			@buffer.set_filename(filename)
			#@buffer.set_title_from_filename
			@buffer.set_title(File.basename(filename))
			# TODO: session: change mode, depending on the extension
			@session.switch_mode_via_filename 
			@view.dirty_all
			update_title
			refresh_buffer_menu
			@main_window.measure_time("saveAs - render") do
				render_dirty_areas
				@canvas.update
			end
		end
		0
	end
	def onOpenBuffer(sender, sel, event)  
		$logger.debug(1) { "open buffer" }
		source_files = <<-EOT.gsub(/^\s*/, '').chomp
		All files (*)
		Ruby (*.rb)
		C/C++ (*.c,*.cc,*.cpp,*.cxx,*.h,*.hh,*.hpp,*.hxx)
		HTML (*.html,*.htm,*.xhtml)
		XML (*.xml)
		EOT

		files = FXFileDialog.getOpenFilenames(
			self, "Open file", nil, source_files)
		#FXMessageBox.information(
		#	self, MBOX_OK, "Selected Files", files.join("\n"))

		if files.empty?
			$logger.debug(1) { "no files was chosen" }
			return 
		end

		files.each do |name|
			# TODO: prevent against double loading
			begin
				@session.open_buffer(name)
			rescue RuntimeError => e
				$logger.debug(1) { e.message }
			end
		end
		# TODO: switch focus to the first opened buffer
		switch_to_buffer(@session.buffers.size-1)
		refresh_buffer_menu
	end
	def onNewBuffer(sender, sel, event)  
		$logger.debug(1) { "new buffer" }
		@session.open_buffer_empty
		switch_to_buffer(@session.buffers.size-1)
		refresh_buffer_menu
	end
	def onCloseBuffer(sender, sel, event)  
		$logger.debug(1) { "close buffer named #{@buffer.title.inspect}" }
		spawn = FileHelper.check_content(
			@buffer.filename, 
			@buffer.model.to_a.join
		)
		if @session.buffers.size <= 1
			# TODO: do something about this rediculus restriction
			$logger.debug(1) { "there must be one buffer open at least" }
			return
		end
		if spawn 
			if MBOX_CLICKED_CANCEL == FXMessageBox.warning(
				self, MBOX_OK_CANCEL, "Discard changes?", 
				"The current buffer is different from the file.\n" +
				"All data will be lost!")
				$logger.debug(1) { "close-buffer canceled" }
				return
			end
		end
		$logger.debug(1) { "closing buffer" }
		#@buffers.delete_at(@buffer_index) 
		@session.close_buffer
		switch_to_buffer(@session.buffer_index)
		refresh_buffer_menu
	end  
	def onLeftMousePress(sender, sel, event)
		fw = @font.fontWidth
		fh = @font.fontHeight
		pixel_x = event.root_x - (@canvas.x + self.x)
		pixel_y = event.root_y - (@canvas.y + self.y)
		#p pixel_x, pixel_y
		cell_x = pixel_x / fw + @view.scroll_x
		cell_y = pixel_y / fh + @view.scroll_y - 1
		@view.execute(Commands::MoveAbsolute.new(cell_x, cell_y))
	end
	def onTextRightMouse(sender, sel, event)
		return 1 if event.moved
		pane = FXMenuPane.new(self)
		mode_title = @is_fullscreen_mode ? "window mode" : "fullscreen mode"
		FXMenuCommand.new(pane, mode_title, nil, self, EditorWidget::ID_TOGGLE_SCREEN_MODE)
		FXMenuSeparator.new(pane)
		q = FXMenuCommand.new(pane, "Quit", nil, nil, 0)
    q.connect(SEL_COMMAND, method(:maybeShutdownParent))
		pane.create
		pane.popup(nil, event.root_x, event.root_y)
		getApp().runModalWhileShown(pane)
		return 1
	end
	def onSpawnFontDialog(sender, sel, ptr)
		win = FXFontDialog.new(self, "Choose Font", DECOR_TITLE|DECOR_BORDER)
		# TODO: validate font.. before spawn.. in order to
		# prevent spawning this dialog with an illegal fontdesc.
		# If an illegal fontdesc are used, then the dialog is
		# hardly usable.
		win.fontSelection = @font.fontDesc
		return 1 if win.execute == 0
		font = FXFont.new(getApp(), win.fontSelection)
		font.create
		$logger.debug(2) { "font=" + fxunparsefontdesc(font.fontDesc).inspect }
		@font = font
		@main_window.set_font(@font)
		@smart_cursor_content = nil
		recalc_cellarea
		@view.render_dirty_all
		@view.dirty_all
		return 1
	end 
	STATE_MASK = SHIFTMASK | CONTROLMASK | ALTMASK
	def dispatch_keyevent_simon(event)
		command = nil
		case event.code
		when KEY_Up
			if (event.state & STATE_MASK) == 0
				command = Commands::MoveUp.new
			elsif (event.state & STATE_MASK) == SHIFTMASK
				command = Commands::SwapUp.new
			end
		when KEY_Down
			if (event.state & STATE_MASK) == 0
				command = Commands::MoveDown.new
			elsif (event.state & STATE_MASK) == SHIFTMASK
				command = Commands::SwapDown.new
			end
		when KEY_Page_Up
			if (event.state & STATE_MASK) == 0
				command = Commands::MovePageUp.new
			elsif (event.state & STATE_MASK) == CONTROLMASK
				command = Commands::MoveAbsolute.new(
					@view.cursor_x, 0)
			end
		when KEY_Page_Down
			if (event.state & STATE_MASK) == 0
				command = Commands::MovePageDown.new
			elsif (event.state & STATE_MASK) == CONTROLMASK
				command = Commands::MoveAbsolute.new(
					@view.cursor_x, @view.model.lines.size-1)
			end
		when KEY_Left
			if (event.state & STATE_MASK) == 0
				command = Commands::MoveLeft.new
			elsif (event.state & STATE_MASK) == SHIFTMASK
				command = Commands::Unindent.new
			elsif (event.state & STATE_MASK) == CONTROLMASK
				command = Commands::MoveWordLeft.new
			end
		when KEY_Right
			if (event.state & STATE_MASK) == 0
				command = Commands::MoveRight.new
			elsif (event.state & STATE_MASK) == SHIFTMASK
				command = Commands::Indent.new
			elsif (event.state & STATE_MASK) == CONTROLMASK
				command = Commands::MoveWordRight.new
			end
		when KEY_Home
			command = Commands::MoveLineBegin.new
		when KEY_End
			command = Commands::MoveLineEnd.new
		when KEY_Return
			command = Commands::BreakLine.new
		when KEY_BackSpace
			command = Commands::Backspace.new
		when KEY_Delete
			command = Commands::Delete.new
		when KEY_F1 
			dump_object_status
			dump_cache_status
			dump_lcache_contents
		when KEY_F5
			if @view.selection_mode
				$logger.debug(1) { "f5 - done with selection" }
				command = History::Command::Macro.new([
					SelectionCopy.new(@session, self),
					Commands::BacktoNormal.new
				])
			else
				$logger.debug(1) { "f5 - init selection" }
				command = Commands::SelectionInit.new
			end
		when KEY_F6
			$logger.debug(1) { "f6 - paste selected text" }
			str = getDNDData(FROM_CLIPBOARD, FXWindow.stringType)
			command = Commands::InsertText.new(str) if str
		when KEY_F7
			$logger.debug(1) { "f7 - delete selected text" }
			command = Commands::SelectionErase.new
		when KEY_F9
			$logger.debug(1) { "f9 - cycle between marks" }
			res = []
			@view.bookmarks.each do |key, yval|
				res << [yval, key]
			end
			res.sort!
			y = @view.cursor_y
			pick_first = true
			res.each do |(yval, key)|
				if yval > y
					command = Commands::MoveAbsolute.new(nil, yval)
					pick_first = false
					break
				end
			end
			if pick_first and res.size > 0
				yval, key = res.first
				command = Commands::MoveAbsolute.new(nil, yval)
			end
		when KEY_F4
			$logger.debug(1) { "f4 - incremental centering" }
			@view.scroll_to_center  # generates no undo
		when KEY_Escape
			$logger.debug(1) { "escape - resets" }
			command = Commands::BacktoNormal.new
		else
			if event.text and event.text.size == 1 and 
				(event.text[0] == 9 or event.text[0] >= 32)
				command = Commands::InsertText.new(event.text)
			end
		end
		command
	end
	def dispatch_keyevent_cua(event)
		command = nil
		move_cmd = nil
		delete_cmd = nil
		edit_cmd = nil
		case event.code
		when KEY_Up
			move_cmd = Commands::MoveUp.new
		when KEY_Down
			move_cmd = Commands::MoveDown.new
		when KEY_Page_Up
			if (event.state & CONTROLMASK) != 0
				move_cmd = Commands::MoveAbsolute.new(
					@view.cursor_x, 0)
			else
				move_cmd = Commands::MovePageUp.new
			end
		when KEY_Page_Down
			if (event.state & CONTROLMASK) != 0
				move_cmd = Commands::MoveAbsolute.new(
					@view.cursor_x, @view.model.lines.size-1)
			else
				move_cmd = Commands::MovePageDown.new
			end
		when KEY_Left
			move_cmd = ((event.state & CONTROLMASK) != 0) ?
				Commands::MoveWordLeft.new : Commands::MoveLeft.new
		when KEY_Right
			move_cmd = ((event.state & CONTROLMASK) != 0) ?
				Commands::MoveWordRight.new : Commands::MoveRight.new
		when KEY_Home
			move_cmd = Commands::MoveLineBegin.new
		when KEY_End
			move_cmd = Commands::MoveLineEnd.new
		when KEY_Return
			edit_cmd = Commands::BreakLine.new
		when KEY_BackSpace
			delete_cmd = Commands::Backspace.new
		when KEY_Delete
			delete_cmd = Commands::Delete.new
		when KEY_F1 
			dump_object_status
			dump_cache_status
			dump_lcache_contents
		when KEY_F9
			$logger.debug(1) { "f9 - cycle between marks" }
			res = []
			@view.bookmarks.each do |key, yval|
				res << [yval, key]
			end
			res.sort!
			y = @view.cursor_y
			pick_first = true
			res.each do |(yval, key)|
				if yval > y
					command = Commands::MoveAbsolute.new(nil, yval)
					pick_first = false
					break
				end
			end
			if pick_first and res.size > 0
				yval, key = res.first
				command = Commands::MoveAbsolute.new(nil, yval)
			end
		when KEY_F4
			$logger.debug(1) { "f4 - incremental centering" }
			@view.scroll_to_center  # generates no undo
		when KEY_Escape
			$logger.debug(1) { "escape - resets" }
			command = Commands::BacktoNormal.new
		else
			if event.text and event.text.size == 1 and 
				(event.text[0] == 9 or event.text[0] >= 32)
				edit_cmd = Commands::InsertText.new(event.text)
			end
		end
		if edit_cmd
      if @view.selection_mode
				command = History::Command::Macro.new([
					Commands::SelectionErase.new, edit_cmd])
      else
      	command = edit_cmd
      end
		end
		if delete_cmd
      if @view.selection_mode
      	command = Commands::SelectionErase.new
      else
      	command = delete_cmd
      end
		end
		if move_cmd
			state = ((event.state & SHIFTMASK) != 0)
      if state == @view.selection_mode
				command = move_cmd
			elsif state
				command = History::Command::Macro.new([
					Commands::SelectionInit.new, move_cmd])
			else
				command = History::Command::Macro.new([
					Commands::BacktoNormal.new, move_cmd])
			end
		end
		command
	end
	def onKeypress(sender, sel, event)
		$logger.debug(2) { "keycode=#{event.code.inspect} keystate=#{event.state.inspect}" }
		if event.state & ALTMASK != 0
			# let pulldown menu deal with this event
			return 0
		end
		
		# TODO: make this with callback instead
		meth = case @session.global_conf.keymap
		when :simon
			:dispatch_keyevent_simon
		else
			:dispatch_keyevent_cua
		end
		command = send(meth, event)
		unless command
			$logger.debug(1) { "keypress (propagate to parent) - " + 
				"keysym=#{event.code} " +
				"state=#{event.state} " +
				"text=#{event.text}"}
			return 0 # let parent deal with this event
		end
		obtain_render_lock do
			@view.execute(command)
		end
		1
	end
	def place_smart_cursor(x, y)
		@smart_cursor_content = @lines[y][2][x]
		@lines[y][2][x] = rgb2fixnum(0, 255, 0)
		@output_valid[y] = false
		#@view.render_dirty(y)
		@smart_cursor_x = x
		@smart_cursor_y = y
	end
	def obtain_render_lock(&block)
		# TODO: this level of locking is no longer necessary
		# now I have locking inside the buffer. Thus remove this!
		old, @render_lock = @render_lock, true
		retval = nil
		begin
			retval = block.call
		ensure
			@render_lock = old
			render
		end
		retval
	end
	def render
		return if @render_lock
		GC.disable
		@main_window.measure_time("render") do
			render_dirty_areas
			@canvas.update  # flag as dirty
			@canvas.repaint # paint the dirty area
		end
		GC.enable
		reset_timeout_for_garbage_collection
		#GC.start
	end
	def render_dirty_areas
		@view.scroll_to_cursor
		if @view.selection_mode
			@dirty = DIRTY_ALL
			@view.render_dirty(@view.cursor_cell_y+@view.extra_top)
			@view.render_dirty(@smart_cursor_y)
		end
		case @dirty
		when 0
			# do nothing
		when DIRTY_CURSOR
			t1 = Time.now.to_f
			#GC.disable
			if @smart_cursor_content
				@lines[@smart_cursor_y][2][@smart_cursor_x] = @smart_cursor_content
				#@view.render_dirty(@smart_cursor_y)
				$logger.debug(2) { 
                    "dirty_cursor: setting output_valid[#{@smart_cursor_y}]=" + 
                    "false output_valid.size=#{@output_valid.size}" 
                }
				@output_valid[@smart_cursor_y] = false
			end
			place_smart_cursor(@view.cursor_cell_x, 
				@view.cursor_cell_y+@view.extra_top)
			invalid_lines = []
			@output_valid.each_with_index do |valid, index|
				invalid_lines << index unless valid
			end
			render_view(@back_buffer)
			@dirty = 0
			t2 = Time.now.to_f
			#GC.enable
			$logger.debug(1) do
				stotal = "%2.4f sec" % (t2-t1)
				sdirty = invalid_lines.inspect
        "refresh #{stotal}  (rows=#{sdirty})"
      end
		else
			# do full update
			t1 = Time.now.to_f
			#GC.disable  
			# if we don't disable GC, it often begins cleaning up during 
			# this full screen update, causing a slowdown of ~100 miliseconds 
			# on my 700MHz box. by disabling GC the time spend on update gets 
			# almost constant. recomputing all 60 lines takes ~0.4 seconds in 
			# total. we don't want 100 miliseconds more because of GC.
			apply_lexer
			t2 = Time.now.to_f
			place_smart_cursor(@view.cursor_cell_x, 
				@view.cursor_cell_y+@view.extra_top)
			render_view(@back_buffer)
			t3 = Time.now.to_f
			#GC.enable
			@dirty = 0
			$logger.debug(1) do
				stotal = "%2.4f sec" % (t3-t1)
				slexer = "lexer=%2.4f" % (t2-t1)
				spaint = "paint=%2.4f" % (t3-t2)
      	"refresh #{stotal}  (#{slexer} #{spaint})"
      end
		end
	end
	def onCanvasRepaint(sender, sel, event)
		@main_window.measure_time("onCanvasRepaint") do
			FXDCWindow.new(sender, event) do |dc|
				dc.drawImage(@back_buffer, 0, 0)
			end
		end
	end
	def recalc_cellarea
		fw = @font.fontWidth
		fh = @font.fontHeight
		dw = @back_buffer.width
		dh = @back_buffer.height
		# TODO: compute the size of the area insize which the cursor can go..
		# beware that its distinct from the area needed for rendering.
		cells_y = dh / fh
		outside = dh % fh
		extra_top = 0
		extra_bottom = 0
		render_pixel_y = 0
=begin
		# center active lines
		if outside > 0
			extra_top = 1
			extra_bottom = 1
			render_pixel_y = fh - (outside / 2)
		end
=end
		# this is more visually appealing than centering
		if outside > 0
			extra_bottom = 1
		end
		@render_y = render_pixel_y
		@view.resize(
			(dw + fw - 1) / fw,
			cells_y
			#(dh + fh - 1) / fh
		)
		@view.set_extra_lines(extra_top, extra_bottom)
		@view.dirty_all
		@lines = [nil] * (cells_y+extra_bottom)
		@output_valid = [true] * (cells_y+extra_bottom)
		#@dirty = DIRTY_ALL
		#render_dirty_areas
	end
	def onCanvasConfigure(sender, sel, event)
		obtain_render_lock do
			@back_buffer.create unless @back_buffer.created?
			@temp_buffer.create unless @temp_buffer.created?
			@back_buffer.resize(sender.width, sender.height)
			@temp_buffer.resize(sender.width, sender.height)
			recalc_cellarea
		end
	end
	RGB_ARROW = rgb2fixnum(180, 100, 100)
	def decorate_cell(line)
		letters, fgs, bgs = line
		letters.each_with_index do |letter, index|
			case letter
			when "\t"
				letters[index] = '_'
			when "\n"
				letters[index] = 183.chr  # center dot
				r, g, b = fixnum2rgb(bgs[index])
				bg_r = [r * 1.05 + 25, 255].min.to_i
				bg_g = [g * 0.95 - 15, 0].max.to_i
				bg_b = [b * 0.95 - 15, 0].max.to_i
				fgs[index] = rgb2fixnum(bg_r, bg_g, bg_b)
			when "\001"
				letters[index] = '<'
				fgs[index] = RGB_ARROW
			when "\002"
				letters[index] = '>'
				fgs[index] = RGB_ARROW
			end
		end
	end
	def decorate_line_selection(line, index)
		return line unless @view.selection_mode
		xy1 = [@view.cursor_x, @view.cursor_y+@view.extra_top]
		xy2 = [@view.selection_x, @view.selection_y+@view.extra_top]
		y1, x1, y2, x2 = @view.sort_by_yx(xy1, xy2)
		y1 -= @view.scroll_y
		y2 -= @view.scroll_y
		return line unless (y1..y2).member?(index)
		$logger.debug(1) { "decor selection  view_line_number=#{index}" }
		x1 -= @view.scroll_x
		x2 -= @view.scroll_x
		y = index
		letters, fgs, bgs = line
		fgs.each_with_index do |fg, x|
			# TODO: this can be made faster, by moving it outside the loop
			if (y > y1 and y < y2) or 
				(y == y1 and y != y2 and x >= x1) or 
				(y == y2 and y != y1 and x < x2) or
				(y == y1 and y == y2 and x >= x1 and x < x2)
				bg = bgs[x]
				r, g, b = fixnum2rgb(bg)
				bg_r = [r * 0.9 + 128, 255].min.to_i
				bg_g = [g * 1.5 + 128, 255].min.to_i
				bg_b = [b * 1.2 + 128, 255].min.to_i
				r, g, b = fixnum2rgb(fg)
				fg_r = [r * 0.25 + 64, 255].min.to_i 
				fg_g = [g * 0.75 + 64, 255].min.to_i 
				fg_b = [b * 0.5 + 64, 255].min.to_i 

				fgs[x] = rgb2fixnum(fg_r, fg_g, fg_b)
				bgs[x] = rgb2fixnum(bg_r, bg_g, bg_b)
			end
		end
	end
	def decorate_line_bottom(line, index)
		return if @view.extra_bottom == 0 or index < @view.number_of_cells_y
		return if @view.lines.last.kind_of?(Buffer::View::Line::Empty)
		letters, fgs, bgs = line
		bgs.each_with_index do |bg, index|
			r, g, b = fixnum2rgb(bg)
			avg = (r + g + b) / 3
			r = r * 0.45 + avg * 0.45
			g = g * 0.45 + avg * 0.45
			b = b * 0.45 + avg * 0.45
			bgs[index] = rgb2fixnum(r.to_i, g.to_i, b.to_i)
		end
		fgs.each_with_index do |fg, index|
			r, g, b = fixnum2rgb(fg)
			avg = (r + g + b) / 3
			r = r * 0.5 + avg * 0.75
			g = g * 0.5 + avg * 0.75
			b = b * 0.5 + avg * 0.75
			fgs[index] = rgb2fixnum(r.to_i, g.to_i, b.to_i)
		end
	end
	def apply_lexer
		@main_window.measure_time("apply_lexer") do
			$logger.debug(2) { "lexing" }
			@view.output_cells.each_with_index do |letters_states, index|
				unless letters_states
					@output_valid[index] = true
					next
				end
				letters, states = letters_states
				fgs = []
				bgs = []
	 			# convert states into colors via theme
				states.each do |state|
					bg, fg = @theme.fixnum_pairs[state]
					fgs << fg
					bgs << bg
				end
				line = [letters, fgs, bgs]
				decorate_cell(line)
				decorate_line_selection(line, index)
				decorate_line_bottom(line, index)
				
				@lines[index] = line
				@output_valid[index] = false
			end
			$logger.debug(2) { "apply_lexer:  output_valid.size=#{@output_valid.size} " + 
				"lines.size=#{@lines.size}" }
		end
	end
	def render_view(drawable)
		@main_window.measure_time("render_view") do
			FXDCWindow.new(drawable) do |dc|
				render_rows(dc)
			end 
		end
		# update scrollbar
		@scrollbar.setRange(
			@view.model.lines.size+@view.extra_bottom)
		@scrollbar.setPage(@view.lines.size)
		@scrollbar.setPosition(@view.scroll_y)

		# update statusbar
		@target_statusbar_x.value = @view.cursor_x.to_s
		@target_statusbar_y.value = (@view.cursor_y+1).to_s
		@target_statusbar_percent.value = percent.to_s
=begin
		# TODO: placebo.. I don't think this makes statusbar update faster
		@target_statusbar_x.handle(self,
			MKUINT(FXDataTarget::ID_VALUE, SEL_CHANGED), nil)
		@target_statusbar_y.handle(self,
			MKUINT(FXDataTarget::ID_VALUE, SEL_CHANGED), nil)
		@target_statusbar_percent.handle(self,
			MKUINT(FXDataTarget::ID_VALUE, SEL_CHANGED), nil)
=end
	end
	def render_rows(dc)
		fh = @font.fontHeight
		dc.textFont = @font
		position_y = - @render_y
		$logger.debug(2) { "output_valid.size=#{@output_valid.size}" }
		n = 0
		@output_valid.each_with_index do |valid, index|
			unless valid
				line = @lines[index]
				unless line
					$logger.debug(1) { "should not happen, see line #{__LINE__} in #{__FILE__}... with index #{index}" }
				else
					render_row(dc, position_y, line)
					@output_valid[index] = true
					n += 1
				end
			end
			position_y += fh
		end
		$logger.debug(2) { "rendered #{n} rows" }
	end
	def render_row(dc, position_y, line)
		unless line
			$logger.debug(1) { "should not happen, see line #{__LINE__} in #{__FILE__}" }
			return
		end
    letters, fgs, bgs = line
    n = letters.size
    if n != bgs.size or n != fgs.size
    	raise 'integrity error'
    end
		
		fw = @font.fontWidth
		fh = @font.fontHeight
		position_y_font = position_y + fh - @font.fontDescent
		dc.textFont = @font
		position_x = 0
		
		letters.each_with_index do |text, index|
			bg = bgs[index]
			fg = fgs[index]
			dc.foreground = FXRGB(
				fixnum2red(bg), fixnum2green(bg), fixnum2blue(bg)
			)
			dc.fillRectangle(position_x, position_y, fw, fh)
			dc.foreground = FXRGB(
				fixnum2red(fg), fixnum2green(fg), fixnum2blue(fg)
			)
			glyph_width = @font.getTextWidth(text)
			glyph_x = (fw - glyph_width) / 2
			dc.drawText(position_x+glyph_x, position_y_font, text)
			position_x += fw
		end
	end
end

class MainWindow < FXMainWindow
	include Responder
	ID_SPAWN,
	ID_LAST = enum(FXMainWindow::ID_LAST, 2)
  def initialize(owner)
  	super(owner, "Invisible MainWindow", 
  		nil, nil, DECOR_NONE, 0, 0, 50, 50)
		FXMAPFUNC(SEL_COMMAND, ID_SPAWN, :onCmdSpawn)
    FXMAPFUNC(SEL_COMMAND, FXApp::ID_QUIT, :onCmdQuit)
    FXMAPFUNC(SEL_SIGNAL, FXApp::ID_QUIT, :onCmdQuit)
    @dialog = nil
  end
  def mk_dialog(mode)
  	raise "derived class must overload me"
  	# @dialog = FreshDialog.new
  	# @dialog.create
  	# @dialog.show
  end
  def onCmdSpawn(sender, sel, event)
  	mode = (@dialog.mode != true)
  	@dialog.hide
  	@dialog.shutdown
  	mk_dialog(mode)
  end
  def shutdown
  	# overload me
  end
  def onCmdQuit(sender, sel, event)
  	$logger.debug(1) { 'MainWindow.onCmdQuit' }
  	@dialog.shutdown
  	shutdown
  	getApp().exit(0)
  	1
  end
end # class MainWindow


class OurMainWindow < MainWindow
	def dotfile_in_homedir
		homedir = ENV['HOME']
		if homedir
			filename = File.join(homedir, '.aeditor') 
			unless File.exists?(filename)
				$logger.warn { "could not find primary config, " +
					"filename=#{filename.inspect}" }
				filename = nil 
			end
			return filename 
		end
	  $logger.fatal <<WARNING
WARNING: could not determine where the homedir are located at.
To tell this program where your homedir are located,
then you may set the environment variable 'HOME'.
For instance by typing:  setenv HOME '/home/mynickname' .
press a key to continue.
WARNING
		nil
	end
	def dotfile_in_progdir
		progdir = FileHelper.find_dir_in_path('aeditor')
		return File.join(progdir, 'config_default') if progdir
		$logger.fatal 'could not determine progdir'
		nil
	end

	def initialize(application, filenames)
		super(application)
		@statistics_time = Hash.new {|h, k| h[k] = [] }

		@font_created = false
		@font = nil

		@session = Session::Caretaker.new

		# load configuration files
		primary_config_ok = false
		homedir_dotfile = dotfile_in_homedir
		if homedir_dotfile
			$logger.warn { 
				"attempting to load primary config, " +
				"filename=#{homedir_dotfile.inspect}"
			}
			begin	
				@session.load_config(homedir_dotfile)
				primary_config_ok = true
			rescue => e
				$logger.fatal <<WARNING
Configuration error occured when loading #{homedir_dotfile.inspect}
Using the default configuration instead.
#{e.inspect}
WARNING
			end
		end
		unless primary_config_ok
			progdir_dotfile = dotfile_in_progdir
			$logger.warn { 
				"attempting to load secondary config, " +
				"filename=#{progdir_dotfile.inspect}"
			}
			begin
				@session.load_config(progdir_dotfile)
			rescue => e
				$logger.fatal <<WARNING
Configuration error occured when loading #{progdir_dotfile.inspect}
Please report this problem to the author of this program.
#{e.inspect}
WARNING
			end
		end
		
		filenames.each do |name|
			begin
				@session.open_buffer(name)
			rescue RuntimeError => e
				$logger.debug(1) { e.message }
			end
		end
		if @session.buffers.empty?
			@session.open_buffer_empty
		end
		# TODO: session: goto buf 0
		@theme = CurrentTheme.new
	end
	attr_reader :session, :theme, :font_created, :font
	def read_registry
		str = getApp().reg().readStringEntry('SETTINGS', 'font', '') 
		if str == ''
			str = "[Courier] 100 400 1 0 0 1"
			$logger.debug(1) { "using default font #{str.inspect}" }
		end
		fontdesc = fxparsefontdesc(str)
		if fontdesc
			@font = FXFont.new(getApp(), fontdesc) 
		else
			raise "could not read font #{str.inspect}"
		end
	end
	def write_registry
		str = fxunparsefontdesc(@font.getFontDesc)
		getApp().reg().writeStringEntry('SETTINGS', 'font', str)
	end
	def create
		read_registry
		super
		unless @font
			# just in case font initialization failed in #read_registry
			# I know this font is ugly on windows
			@font = FXFont.new(
				getApp(), 
				"courier",
				20,
				FONTWEIGHT_BOLD,
				FONTSLANT_REGULAR,
				FONTENCODING_DEFAULT,
				FONTSETWIDTH_DONTCARE,
				FONTPITCH_FIXED
			)
		end
		@font.create
		@font_created = true
		# lets make a hidden mainwindow
		#show(PLACEMENT_SCREEN)
		mk_dialog(false)
	end
	def set_font(font)
		@font = font
	end
	def mk_dialog(mode)
		@dialog = EditorWidget.new(self, mode)
		@dialog.create
  	placement = mode ? PLACEMENT_MAXIMIZED : PLACEMENT_DEFAULT
  	@dialog.show(placement)
	end
	def measure_time(name, &block)
		time1 = Time.now
		begin
			return block.call
		ensure
			time = Time.now - time1
			@statistics_time[name] << time
			$logger.debug(2) { "#{name} took #{time} seconds." if time > 0.001 }
		end
	end
	def write_summary
		$logger.debug(1) { ('-'*80) + "\nsummary of time usage in seconds." }
		result = []
		@statistics_time.each do |name, times|
			sum = times.inject(0.0) {|sum, time| sum + time}
			average = 0.0
			average = sum / times.size unless times.empty?
			peek = times.max
			result << [average, name, peek]
		end
		str_ary = ["_______NAME_________  AVERAGE PEEK"]
		result.sort.reverse.each do |(avg, name, peek)|
			str = "#{name.rjust(20)}  %2.4f  %2.4f" % [avg, peek]
			str_ary << str
		end
		$logger.debug(1) { str_ary.join("\n") }
	end
	def shutdown
		write_registry
		write_summary
	end
end

class OurApp < FXApp
	def self.run(filenames=nil)
		$stdout.sync = true   # flush after puts
		OurApp.new("BufferView", "FXRuby") do |app|
			window = OurMainWindow.new(app, filenames||[$0])
			app.addSignal("SIGINT", window, FXApp::ID_QUIT)
			app.addSignal("SIGTERM", window, FXApp::ID_QUIT)
			app.create
			#window.show(PLACEMENT_SCREEN)
			app.run
		end
	rescue Exception => e
		File.open("__backtrace__", "w+") do |f|
			f.write e.message
			f.write e.backtrace.join("\n")
		end
		raise
	end
end

OurApp.run if $0 == __FILE__
