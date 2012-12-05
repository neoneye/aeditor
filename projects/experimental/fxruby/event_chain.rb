# purpose:
# make an widget where we can intercept keyevents
#
# status:
# the OurComposite widget allow us to do so.
# goal fullfilled.

require 'fox'
require 'fox/responder'
include Fox

class OurComposite < FXComposite
	def initialize(parent)
		super(parent)
		self.enable
	end
	def canFocus
		true
	end
end

class OurMainWindow < FXMainWindow
	include Responder

	def initialize(application)
		super(application, "Main Window", nil, nil, DECOR_ALL, 0, 0, 320, 200)

		# wrapper which we can send our events to
		@outer = OurComposite.new(self)
		@middle = OurComposite.new(@outer)
		@inner = FXCanvas.new(@middle, nil, 0, LAYOUT_FILL_X|LAYOUT_FILL_Y)

		@inner.connect(SEL_KEYPRESS) do |sender, sel, event|
			p "inner - keysym=#{event.code} state=#{event.state}"
			1
		end
		@middle.connect(SEL_KEYPRESS) do |sender, sel, event|
			p "middle - keysym=#{event.code} state=#{event.state}"
			next 1 if event.code == KEY_F2
			@inner.onKeyPress(sender, sel, event)
		end
		@outer.connect(SEL_KEYPRESS) do |sender, sel, event|
			p "outer - keysym=#{event.code} state=#{event.state}"
			next 1 if event.code == KEY_F1
			@middle.onKeyPress(sender, sel, event)
		end
		@outer.setFocus
		#@inner.setFocus
		#@outer.killFocus
	end
end

FXApp.new("Test", "FXRuby") do |app|
	window = OurMainWindow.new(app)
	app.create
	window.show(PLACEMENT_SCREEN)
	app.run
end