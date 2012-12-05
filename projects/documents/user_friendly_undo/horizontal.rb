require 'html_diagram_horizontal'

class HorzScrollLeft1 < SkeletonHorz
	def initialize
		data = [
			[1, 1, 1, 1],
			["scroll_left", <<"MSG"],
a typical scroll left operation.
MSG
			[0, 1, 1, 2],
			["undo (scroll_left)", <<"MSG"],
everything will be restored, exactly as it were before.
MSG
			[1, 1, 1, 1],
			["redo (scroll_left)", <<"MSG"],
you will not be able to tell the difference, wheter scroll_left or redo occured.
MSG
			[0, 1, 1, 2]
		]
		super(data)
	end
end

class HorzScrollLeft2 < SkeletonHorz
	def initialize
		data = [
			[0, 1, 1, 2],
			["scroll_left", <<"MSG"],
a non-typical scroll left operation. Preservation is NOT possible.
MSG
			[0, 0, 2, 2],
			["undo (scroll_left)", <<"MSG"],
everything will be restored, exactly as it were before.
MSG
			[0, 1, 1, 2],
			["redo (scroll_left)", <<"MSG"],
you will not be able to tell the difference, wheter scroll_left or redo occured.
MSG
			[0, 0, 2, 2]
		]
		super(data)
	end
end

class HorzScrollRight1 < SkeletonHorz
	def initialize
		data = [
			[1, 1, 1, 2],
			["scroll_right", <<"MSG"],
a typical scroll right operation.
MSG
			[2, 1, 1, 1],
			["undo (scroll_right)", <<"MSG"],
everything will be restored, exactly as it were before.
MSG
			[1, 1, 1, 2],
			["redo (scroll_right)", <<"MSG"],
you will not be able to tell the difference, wheter scroll_right or redo occured.
MSG
			[2, 1, 1, 1]
		]
		super(data)
	end
end

class HorzScrollRight2 < SkeletonHorz
	def initialize
		data = [
			[1, 1, 1, 0],
			["scroll_right", <<"MSG"],
a non-typical scroll right operation.
MSG
			[2, 1, 0, 0, 1], # an extra 
			["undo (scroll_right)", <<"MSG"],
everything will be restored, exactly as it were before.
MSG
			[1, 1, 1, 0],
			["redo (scroll_right)", <<"MSG"],
you will not be able to tell the difference, wheter scroll_right or redo occured.
MSG
			[2, 1, 0, 0, 1]
		]
		super(data)
	end
end

class HorzMoveHome1 < SkeletonHorz
	def initialize
		data = [
			[1, 1, 1, 1],
			["move_end", <<"MSG"],
a typical move_home operation.
MSG
			[0, 0, 2, 2],
			["undo (move_home)", <<"MSG"],
everything will be restored, exactly as it were before.
MSG
			[1, 1, 1, 1],
			["redo (move_home)", <<"MSG"],
you will not be able to tell the difference, wheter move_home or redo occured.
MSG
			[0, 0, 2, 2]
		]
		super(data)
	end
end
class HorzMoveEnd1 < SkeletonHorz
	def initialize
		data = [
			[1, 1, 1, 1],
			["move_end", <<"MSG"],
a typical move_end operation.
MSG
			[2, 2, 0, 0],
			["undo (move_end)", <<"MSG"],
everything will be restored, exactly as it were before.
MSG
			[1, 1, 1, 1],
			["redo (move_end)", <<"MSG"],
you will not be able to tell the difference, wheter move_end or redo occured.
MSG
			[2, 2, 0, 0]
		]
		super(data)
	end
end

def document
	CGI::tag("P") {
		CGI::tag("H1") {"Purpose"} + <<"MSG" 
Idealistic Undo and Redo should restore the original state, exactly
as it were. But under certain conditions such exact restoration is impossible.
Example: resizing the window.
<P>What does it take to make horizontal movement user-friendly?</P>
MSG
	} +
	CGI::tag("P") {
		CGI::tag("H1") {"Scroll Left"} + <<"MSG" +
Move cursor one to the left... let view be locked.
MSG
		CGI::tag("P") { HorzScrollLeft1.build } +
		CGI::tag("P") { "Dealing with begining of line is problematic, as you can see:" } +
		CGI::tag("P") { HorzScrollLeft2.build }
	} +
	CGI::tag("P") {
		CGI::tag("H1") {"Scroll Right"} + <<"MSG" +
Move cursor one to the right... let view be locked.
MSG
		CGI::tag("P") { HorzScrollRight1.build } +
		CGI::tag("P") { "dealing with end of line" } +
		CGI::tag("P") { HorzScrollRight2.build }
	} +
	CGI::tag("P") {
		CGI::tag("H1") {"Move Home"} + <<"MSG" +
Place cursor just before the first character on the line.
MSG
		CGI::tag("P") { HorzMoveHome1.build }
	} +
	CGI::tag("P") {
		CGI::tag("H1") {"Move End"} + <<"MSG" +
Place cursor right after the last character on the line.
MSG
		CGI::tag("P") { HorzMoveEnd1.build }
	} +
	CGI::tag("P") {
		CGI::tag("H1") {"Conclusion"} + <<"MSG" 
No conclusion yet.
MSG
	}
end

if $0 == __FILE__
	CGI::store(
		"horizontal.html", 
		document, 
		Generator.stylesheet,
		"User-friendly: Horizontal Movement"
	)
end
