require 'html_diagram_softwrap'

class CaseResize < SkeletonSoftwrap
	def initialize
		data = [
			[[1, 1], [0, 0, 4, 3], ["ab ", "cd e ", "fg h"]],
			["set-width = 5", "placeholder"],
			[[4, 0], [0, 0, 5, 3], ["ab cd ", "e fg ", "h"]],
		]
		super(data)
	end
end

class CaseInsertPropagate < SkeletonSoftwrap
	def initialize
		data = [
			[[1, 0], [0, 0, 5, 2], ["ab cd"]],
			["insert 'x'", "propagation occured!"],
			[[2, 0], [0, 0, 5, 2], ["axb ", "cd"]],
		]
		super(data)
	end
end

class CaseInsertPropagate2 < SkeletonSoftwrap
	def initialize
		data = [
			[[0, 1], [0, 0, 5, 2], ["ab cd ", "ef"]],
			["insert space", "What should we do with spaces?"],
			[[0, 1], [0, 0, 5, 2], ["ab cd  ", "ef"]],
		]
		super(data)
	end
end

class CaseInsertPropagate3 < SkeletonSoftwrap
	def initialize
		data = [
			[[1, 1], [0, 0, 5, 2], ["abc ", "def"]],
			["insert space", "backward propagation!"],
			[[0, 1], [0, 0, 5, 2], ["abc d ", "ef"]],
		]
		super(data)
	end
end

class CaseInsertNoPropagate < SkeletonSoftwrap
	def initialize
		data = [
			[[1, 0], [0, 0, 5, 2], ["abc"]],
			["insert 'x'", "typical insertion"],
			[[2, 0], [0, 0, 5, 2], ["axbc"]],
		]
		super(data)
	end
end

class CaseBackspacePropagate < SkeletonSoftwrap
	def initialize
		data = [
			[[2, 1], [0, 0, 5, 2], ["ab ", "cde f"]],
			["backspace", "backward propagation occur!"],
			[[4, 0], [0, 0, 5, 2], ["ab ce ", "f"]],
		]
		super(data)
	end
end

class CaseBackspacePropagate2 < SkeletonSoftwrap
	def initialize
		data = [
			[[0, 1], [0, 0, 5, 2], ["ab cd ", "ef"]],
			["backspace", "forward propagation occur!"],
			[[2, 1], [0, 0, 5, 2], ["ab ", "cdef"]],
		]
		super(data)
	end
end

class CaseBackspacePropagate3 < SkeletonSoftwrap
	def initialize
		data = [
			[[2, 0], [0, 0, 5, 2], ["abc ", "de f "]],
			["backspace", "backward propagation occur!"],
			[[1, 0], [0, 0, 5, 2], ["ac de ", "f "]],
		]
		super(data)
	end
end

class CaseBackspaceSpaces < SkeletonSoftwrap
	def initialize
		data = [
			[[1, 1], [0, 0, 5, 2], ["abc ", "d   e"]],
			["backspace", "should we treat spaces like this?"],
			[[0, 1], [0, 0, 5, 2], ["abc    ", "e"]],
		]
		super(data)
	end
end

class CaseBackspaceNoPropagate < SkeletonSoftwrap
	def initialize
		data = [
			[[2, 1], [0, 0, 5, 2], ["ab  ", "cde f"]],
			["backspace", "propagation is not possible."],
			[[1, 1], [0, 0, 5, 2], ["ab  ", "ce f"]],
		]
		super(data)
	end
end

class CaseMoveRight < SkeletonSoftwrap
	def initialize
		data = [
			[[2, 0], [0, 0, 5, 2], ["abcd ", "ef"]],
			["move right", "typical behavier as we know it."],
			[[3, 0], [0, 0, 5, 2], ["abcd ", "ef"]],
		]
		super(data)
	end
end

class CaseMoveRight2 < SkeletonSoftwrap
	def initialize
		data = [
			[[4, 0], [0, 0, 5, 2], ["abcd ", "ef"]],
			["move right", "the cursor gets transfered to next line."],
			[[0, 1], [0, 0, 5, 2], ["abcd ", "ef"]],
		]
		super(data)
	end
end

class CaseMoveRight3 < SkeletonSoftwrap
	def initialize
		data = [
			[[4, 0], [0, 0, 5, 2], ["abcd  ", "ef"]],
			["move right", "skipping spaces, tranfering cursor to next line."],
			[[0, 1], [0, 0, 5, 2], ["abcd  ", "ef"]],
		]
		super(data)
	end
end

class CaseMoveRightVSpace < SkeletonSoftwrap
	def initialize
		data = [
			[[2, 1], [0, 0, 5, 2], ["abcd  ", "e"]],
			["move right", "virtual space."],
			[[3, 1], [0, 0, 5, 2], ["abcd  ", "e"]],
			["insert 'x'", "virtual space become real space."],
			[[4, 1], [0, 0, 5, 2], ["abcd  ", "e  x"]],
		]
		super(data)
	end
end

def document
	CGI::tag("DIV", {"CLASS"=>"TITLE"}) { 
		"AEditor project<BR>Simon Strandgaard<BR>" +
		CGI::tag("A", {"HREF"=>"http://rubyforge.org/cgi-bin/cvsweb.cgi/projects/documents/user_friendly_undo/softwrap.rb?cvsroot=aeditor"}) {
			"$Id: softwrap.rb,v 1.12 2003/09/26 08:31:28 neoneye Exp $"
		} 
	} +
	CGI::tag("P") {
		CGI::tag("H1") {"Consequences Of Word Wrap"} + <<MSG
Wordwrap has big impact on undo/redo. In this document I
will try to identify special cases of some typical editing operations.
At the same time undo/redo of a operation must restore to a
state as close as possible to the original state (user friendly).
MSG
	} +
	CGI::tag("P") {
		CGI::tag("H1") {"Resize"} + <<MSG
Changing the width of the view is interesting from a undo/redo
point of view, because resize doesn't have any undo/redo data
at all (its not a operation you can undo/redo).
MSG
	} +
	CaseResize.build +
	CGI::tag("P") { <<MSG
As you can imagine resize can be VERY disturbing.
MSG
	} +
	CGI::tag("P") {
		CGI::tag("H1") {"Backspace"} + <<MSG
You may know backspace as that key which deletes the character 
at the left side of the cursor. But in word-wrap mode
there appears many special cases in backspaces behavier.
Sometimes propagation is necessary.
MSG
	} +
	CaseBackspaceNoPropagate.build +
	CGI::tag("P") { <<MSG
But if there are enough empty space on the previous line,
then backward propagation must occur.
MSG
	} +
	CaseBackspacePropagate3.build +
	CGI::tag("P") { <<MSG
placeholder.
MSG
	} +
	CaseBackspacePropagate.build +
	CGI::tag("P") { <<MSG
Also a forward propagate is possible!
MSG
	} +
	CaseBackspacePropagate2.build +
	CGI::tag("P") { <<MSG
Deleting a the 'd' letter, then we have to deal
with spaces. How does other editors deal with this
paticular case?
MSG
	} +
	CaseBackspaceSpaces.build +
	CGI::tag("P") { <<MSG
Many absurd cases.. Is this the way backspace really should behave?
Please tell me if you have other suggestions.
MSG
	} +
	CGI::tag("P") {
		CGI::tag("H1") {"Insert"} + <<MSG
Insert a letter to the left side of the cursor. 
MSG
	} + 
	CaseInsertNoPropagate.build +
	CGI::tag("P") { <<MSG
In word-wrap mode when a line exceeds the border of the 
view then its propagated to the next line. 
MSG
	} +
	CaseInsertPropagate.build +
	CGI::tag("P") { <<MSG
A minor problem related to wrapping spaces. Is this 
the way to do it?  I think so.
MSG
	} +
	CaseInsertPropagate2.build +
	CGI::tag("P") { <<MSG
Watch out backward propagation is also possible with insertion.
MSG
	} +
	CaseInsertPropagate3.build +
	CGI::tag("P") {
		CGI::tag("H1") {"Horizontal Movement"} + <<MSG
Sideways movement of the cursor gets another behaver
in word-wrap mode. Especialy those cases where the cursor
were suppose to point to the 'spaces' which is outside
the view. In such case it is necessary to make a
compromise. Not nice at all.
MSG
	} + 
	CaseMoveRight.build +
	CGI::tag("P") { <<MSG
placeholder.
MSG
	} +
	CaseMoveRight2.build +
	CGI::tag("P") { <<MSG
placeholder.
MSG
	} +
	CaseMoveRight3.build +
	CGI::tag("P") { <<MSG
At the end of the line there are virtual spaces.
They only become real spaces when you start edit them.
MSG
	} +
	CaseMoveRightVSpace.build 
end

if $0 == __FILE__
	require 'html_diagram_vertical'
	CGI::store("softwrap.html", document, SenarioSkeleton.get_style, "A Study Of Word-Wrap")
end
