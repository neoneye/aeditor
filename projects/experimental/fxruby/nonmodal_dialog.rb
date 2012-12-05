# purpose:
# find a suitable non-modal setup for AEditor
# which works both for windowed mode and fullscreen mode.
#
# questions:
# Q:  how to hide mainwindow?  so it still appears in taskbar in win32?
#
# status:
# shutdown is ok
# 
# checklist:
# ALT-F4 must invoke shutdown on both dialog and window
# quit button must invoke shutdown on both dialog and window
# Close decor must invoke shutdown on both dialog and window
# CTRL-C must invoke shutdown on both dialog and window
# kill must invoke shutdown on both dialog and window
# 


require 'fox'
require 'fox/responder'
include Fox

class MainDialog < FXTopWindow
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
		str_mode = (mode ? 'fullscreen' : 'windowed')
		p str_mode

    button_switch_mode = FXButton.new(
    	self, "mode", nil, nil, 0,
      FRAME_RAISED|FRAME_THICK|LAYOUT_CENTER_X)
    button_switch_mode.connect(
    	SEL_COMMAND, method(:onCmdSwitchMode))
    button_quit = FXButton.new(
    	self, "quit", nil, nil, 0,
      FRAME_RAISED|FRAME_THICK|LAYOUT_CENTER_X)
    button_quit.connect(SEL_COMMAND, method(:maybeShutdownParent))

    FXLabel.new(self, str_mode)

		# this will deal with ALT-F4
		setTarget(self)
		connect(SEL_CLOSE, method(:maybeShutdownParent))
	end
	attr_reader :mode
  def onCmdSwitchMode(sender, sel, event)
  	@terminate = false
		@owner.handle(self, 
			MKUINT(MainWindow::ID_SPAWN, SEL_COMMAND), nil)
  end
	def maybeShutdownParent(sender, sel, event)
		p 'maybe shutdown parent'
		if @terminate
			@owner.handle(self,
				MKUINT(FXApp::ID_QUIT, SEL_COMMAND), nil)
		end
		0
	end
	def shutdown
		p 'dialog shutdown'
		destroy
	end
end # class MainDialog


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
    @dialog = MainDialog.new(self, false)
  end
  def create
  	super
    #show(PLACEMENT_SCREEN)
    @dialog.show(PLACEMENT_SCREEN)
  end
  def onCmdSpawn(sender, sel, event)
  	mode = (@dialog.mode != true)
  	@dialog.hide
  	@dialog.shutdown
  	@dialog = MainDialog.new(self, mode)
  	@dialog.create
  	placement = mode ? PLACEMENT_MAXIMIZED : PLACEMENT_SCREEN
  	@dialog.show(placement)
  end
  def onCmdQuit(sender, sel, event)
  	p 'main quit'
  	@dialog.shutdown
  	getApp().exit(0)
  	1
  end
end # class MainWindow

app = FXApp.new("Dialog", "Experiment")
win = MainWindow.new(app)
app.addSignal("SIGINT", win, FXApp::ID_QUIT)  # CTRL-C
app.addSignal("SIGTERM", win, FXApp::ID_QUIT) # kill
app.create
app.run