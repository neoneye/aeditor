# purpose:
# this is an attempt to solve the following problem
#
# problem:
# in AEditor I have a problem when the pulldown menu,
# has gotten focus, then no Escape is unhandled and 
# the dialog closes.
#
# status:
# unsolved.. though I managed to bring it into some weird state?
#
# checklist:
# pressing Esc    must not terminate the window.
# pressing ALT-F  it must open the &File menu.
# pressing ALT-E  it must open the &Edit menu.
# when a menu-title is focused.. via arrow_left/right we must be able to switch to other items.
# pressing CTRL-1 should invoke menu item 1
# pressing CTRL-2 should invoke menu item 2
# 
# open question:
# if there is a menu open.. and one begins to type.
# what should happen then?   
# A: should we close the menu
# B: insert the letter in the buffer.. and keep the menu open?
# C: ignore the keystroke?
#
# If I press TAB then @outer looses it focus.. and it
# no longer outputs "outer".. this must not happen.

require 'fox'
require 'fox/responder'
include Fox

#class OurComposite < FXComposite
class OurComposite < FXHorizontalFrame
	def initialize(parent)
		super(parent, LAYOUT_FILL_X|LAYOUT_FILL_Y)
		self.enable
	end
	def canFocus
		true
	end
end

class Dialog < FXDialogBox
	include Responder
	def initialize(parent)
		super(parent, "Dialog", DECOR_ALL, 
			0, 0, 200, 200, 0, 0, 0, 0, 0, 0)

		# wrapper which we can send our events to
		@outer = OurComposite.new(self)
			
		menu = FXMenubar.new(@outer, LAYOUT_SIDE_TOP|LAYOUT_FILL_X)
		FXHorizontalSeparator.new(
			@outer, LAYOUT_SIDE_TOP|LAYOUT_FILL_X|SEPARATOR_GROOVE)
		menu1 = FXMenuPane.new(self)
		FXMenuCommand.new(menu1, "Quit\tCtrl-1", nil, getApp(), FXApp::ID_QUIT)
		FXMenuTitle.new(menu, "&File", nil, menu1)
		menu2 = FXMenuPane.new(self)
		FXMenuCommand.new(menu2, "Quit\tCtrl-2", nil, getApp(), FXApp::ID_QUIT)
		FXMenuTitle.new(menu, "&Edit", nil, menu2)
		hf = FXHorizontalFrame.new(@outer, LAYOUT_FILL_X|LAYOUT_FILL_Y,
			0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
		inner = FXCanvas.new(hf, nil, 0, LAYOUT_FILL_X|LAYOUT_FILL_Y)

    # lets intercept KEY_Escape so this dialog doesn't
    # get closed by an accident.
		FXMAPFUNC(SEL_KEYPRESS, 0, :onKeyPressWrapper)
		FXMAPFUNC(SEL_KEYRELEASE, 0, :onKeyReleaseWrapper)

		# in fact this widget is supposed to be silent
		@outer.connect(SEL_KEYPRESS) do |sender, sel, event|
			p "outer - keysym=#{event.code} state=#{event.state}"
			inner.onKeyPress(sender, sel, event)
			0
		end
		inner.connect(SEL_KEYPRESS) do |sender, sel, event|
			p "inner - keysym=#{event.code} state=#{event.state}"
			1 # we eat everything
		end

		@outer.setFocus
	end
	def onKeyPressWrapper(sender, sel, event)
		# its not desirable to invoke FXDialogBox::onKeyPress
		# because if you send KEY_Escape then it terminates our window.
		# thus we must never call onKeyPress(sender, sel, event)
		p "wrapper key press - keysym=#{event.code} state=#{event.state}"
		if event.code == KEY_Escape
			p "inside"
			return @outer.handle(self, MKUINT(0, SEL_KEYPRESS), event)
		end
		if onKeyPress(sender, sel, event) != 0
			p "outside"
			return 1
		end
		0
	end
	def onKeyReleaseWrapper(sender, sel, event)
		# its not desirable to invoke FXDialogBox::onKeyRelease
		# because if you send KEY_Escape then it terminates our window.
		# thus we must never call onKeyRelease(sender, sel, event)
		p "wrapper key release - keysym=#{event.code} state=#{event.state}"
		if event.code == KEY_Escape
			p "inside"
			return @outer.handle(self, MKUINT(0, SEL_KEYRELEASE), event)
		end
		if onKeyRelease(sender, sel, event) != 0
			p "outside"
			return 1
		end
		0
	end
end

class OurMainWindow < FXMainWindow
	include Responder

	ID_SPAWN_EDITOR,
	ID_LAST = enum(FXMainWindow::ID_LAST, 2)
	def initialize(application)
		super(application, "Main Window", nil, nil, 
			DECOR_ALL, 0, 0, 320, 200)
		FXMAPFUNC(SEL_COMMAND, ID_SPAWN_EDITOR, :onSpawnEditor)
		FXMAPFUNC(SEL_TIMEOUT, ID_SPAWN_EDITOR, :onSpawnEditor)
	end
	def create
		super
		getApp.addTimeout(1, self, OurMainWindow::ID_SPAWN_EDITOR)
	end
	def onSpawnEditor(sender, sel, event)
		loop do
			win = Dialog.new(self)
			break if win.execute(PLACEMENT_DEFAULT) == 0
		end
		getApp().exit(0)
		return 1
	end
end

FXApp.new("BufferView", "FXRuby") do |application|
	window = OurMainWindow.new(application)
	application.create
	application.run
end