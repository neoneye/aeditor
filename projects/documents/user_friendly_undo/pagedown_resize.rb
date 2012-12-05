#require 'html_diagram_vertical'
require 'html_diagram_vertical_rmagick'

class SenarioPagedownNormal < SenarioSkeleton
	def initialize
		data = [
			[2, 2, 1, 4],
			["pagedown", <<"T01"],
a typical page down operation.
T01
			[5, 2, 1, 1],
			["undo (pagedown)", <<"T02"],
everything will be restored, exactly as it were before.
T02
			[2, 2, 1, 4],
			["redo (pagedown)", <<"T03"],
you will not be able to tell the difference, wheter pagedown or redo occured.
T03
			[5, 2, 1, 1]
		]
		super(data)
	end
end

class SenarioPagedownNormalBottom < SenarioSkeleton
	def initialize
		data = [
			[1, 2, 4, 0, 1],
			["pagedown", <<"T01"],
We will hit the bottom of the buffer.
T01
			[1, 6, 0, 0, 1],
			["undo (pagedown)", <<"T02"],
everything will be restored, exactly as it were before.
Obsrve that NO scrolling occurs, eg: the view should not
be locked in this case. How does this special case work out
if <TT>resize</TT> is involved?
T02
			[1, 2, 4, 0, 1],
			["redo (pagedown)", <<"T03"],
you will not be able to tell the difference, wheter pagedown or redo occured.
T03
			[1, 6, 0, 0, 1]
		]
		super(data)
	end
end

class SenarioResizeWidenNormal < SenarioSkeleton
	def initialize
		data = [
			[3, 2, 1, 5],
			["pagedown", <<"T01"],
a typical page down operation.
T01
			[6, 2, 1, 2],
			["resize", <<"T02"],
Widening the height of the view affects indirectly redo! 
T02
			[4, 4, 2, 1],
			["undo (pagedown)", <<"T03"],
Preserve the cursors relative position within the view.
T03
			[1, 4, 2, 4],
			["redo (pagedown)", <<"T04"],
Preserve the cursors relative position within the view.
T04
			[4, 4, 2, 1]
		]
		super(data)
	end
end

class SenarioResizeWidenTop < SenarioSkeleton
	def initialize
		data = [
			[0, 2, 1, 6],
			["pagedown", <<"T01"],
a typical page down operation.
T01
			[3, 2, 1, 3],
			["resize", <<"T02"],
Widening the height of the view affects indirectly redo! 
T02
			[1, 4, 2, 2],
			["undo (pagedown)", <<"T03"],
Undoing behaves quite differently from a ordinary page-up operation.
This is because of resize!
<P>Preservation of the cursor-position-within-view is not possible. 
Thus observe that the cursor position within the view is changed. 
This is because we have hit buffer-begin.</P>
T03
			[0, 2, 4, 3],
			["redo (pagedown)", <<"T04"],
I think it would be a bad idea to preserve the cursor position from
<TT>t2</TT>. This just works as an nomal pagedown operation.
T04
			[3, 2, 4, 0]
		]
		super(data)
	end
end

class SenarioResizeWidenBottom < SenarioSkeleton
	def initialize
		data = [
			[3, 2, 1, 3],
			["pagedown", <<"T01"],
a typical page down operation.
T01
			[6, 2, 1, 0],
			["resize", <<"T02"],
Widening the height of the view affects indirectly redo! 
T02
			[4, 4, 1, 0, 1],
			["undo (pagedown)", <<"T03"],
Preservation of the cursor. 
T03
			[1, 4, 2, 2],
			["redo (pagedown)", <<"T04"],
Preservation of the cursor. 
T04
			[4, 4, 1, 0, 1]
		]
		super(data)
	end
end

class SenarioResizeWidenBottom2 < SenarioSkeleton
	def initialize
		data = [
			[1, 1, 2, 2],
			["pagedown", <<"T01"],
a typical page down operation.
T01
			[4, 1, 1, 0, 1], # one empty line at bottom
			["resize", <<"T02"],
Widening the height of the view! 
T02
			[1, 4, 1, 0, 1], # one empty line at bottom 
			["undo (pagedown)", <<"T03"],
Preserving the cursor position is bad in this paticular case.
It is much better to disable <TT>lock_view</TT>.
T03
			[1, 1, 4, 0, 1]  # one empty line at bottom  
		]
		super(data)
	end
end

class SenarioResizeTwisted < SenarioSkeleton
	def initialize
		data = [
			[1, 1, 2, 4],
			["pagedown", <<"T01"],
a typical page down operation.
T01
			[4, 1, 2, 1],
			["resize", <<"T02"],
By resizing + moving + resizing the window, we will 
get this output!
T02
			[3, 2, 1, 2],
			["undo (pagedown)", <<"T03"],
Preservation of the cursor, so you get the feeling that
its the opposite of pagedown(pageup).
T03
			[0, 2, 1, 5],
			["redo (pagedown)", <<"T04"],
Preservation of the cursor, so you get the feeling that
its pagedown.
T04
			[3, 2, 1, 2]
		]
		super(data)
	end
end

class SenarioResizeShrink < SenarioSkeleton
	def initialize
		data = [
			[0, 2, 1, 3],
			["pagedown", <<"T01"],
a typical page down operation.
T01
			[3, 2, 1, 0],
			["resize", <<"T02"],
Shrinking the height of the view affects indirectly redo! 
T02
			[4, 1, 0, 1],
			["undo (pagedown)", <<"T03"],
Undoing behaves quite differently from a ordinary page-up operation.
This is because of resize!
T03
			[1, 1, 0, 4],
			["redo (pagedown)", <<"T04"],
If we redo, then the page-down operation is no longer a
typical behavier. Therefore <b>watch&nbsp;out</b> redoing page-down, when
the height has changed!
T04
			[4, 1, 0, 1]
		]
		super(data)
	end
end

def document
	CGI::tag("DIV", {"CLASS"=>"TITLE"}) { 
		"AEditor project<BR>Simon Strandgaard<BR>" +
		CGI::tag("A", {"HREF"=>"http://rubyforge.org/cgi-bin/cvsweb.cgi/projects/documents/user_friendly_undo/pagedown_resize.rb?cvsroot=aeditor"}) {
			"$Id: pagedown_resize.rb,v 1.10 2003/09/17 11:45:14 neoneye Exp $"
		} 
	} +
	CGI::tag("P") {
		CGI::tag("H1") {"User-friendly Pagedown"} + <<MSG
At first glance <TT>pagedown</TT> seems to be a trivial operation,
but if we dig deeper, an interesting world appears.
Undo/Redo of pagedown should <B>attempt</B> to restore the original 
state. How should one deal with those cases where 100% restoration
is <B>NOT possible?</B>&nbsp; Lets find out!</P>
<P>If the window has been resized, then it is no longer possible
to restore the exact original state. In such cases it should do 
what seems to be most user-friendly. This is what this document is
about.
MSG
	} +
	CGI::tag("P") {
		CGI::tag("H1") {"Pagedown"} + <<"MSG" +
<P>Undo/Redo should attempt to restore the view position, plus the
cursor-position-within-view.
In certain cases the view position cannot be retored, eg: resize.
Therefore we must try to do the best we can and restore it
into a state as close as possible to the original one.
In order to do this 'nice' restoration, then our memento must
also store <TT>cursor-position-within-view</TT> and <TT>view-height</TT>.</P>
MSG
		SenarioPagedownNormal.build + <<"MSG" +
<P>As you can see both <TT>(t0 == t2)</TT> and <TT>(t1 == t3)</TT> is true.
The corresponding test code looks like this:
<PRE>def test_pagedown_normal1
    i = fake_setup(2, 2, 1, 4)
    assert_equal([2, 2, 1, 4], i.status)
    i.execute :do_move_page_down
    assert_equal([5, 2, 1, 1], i.status)
    i.undo
    assert_equal([2, 2, 1, 4], i.status)
    i.redo
    assert_equal([5, 2, 1, 1], i.status)
end 
</PRE>
</P>
<P>Another interesting case is when the we hit the bottom of the file, 
this look like the following diagram:
</P>
MSG
		SenarioPagedownNormalBottom.build + <<"MSG"
MSG
	} +
	CGI::tag("P") {
		CGI::tag("H1") {"Resize"} + <<"MSG" +
<P>Resize is an operation which cannot be undone, therefore
it doesn't store any any memento data.</P>
<P>Observe that Resize let the cursor-position stay untouched!
If you resize the view by grapping at the bottom-border, then
only the bottom lines is affected. The cursor is frozen and locked 
on to the same <TT>(x, y)</TT> position in the display.</P><P>
MSG
		SenarioResizeTwisted.build + "</P>"
	} +
	CGI::tag("P") {
		CGI::tag("H1") {"A smaller view?"} + <<"MSG" +
<P>Changing the view-height from 4 lines into 2 lines.</P><P>
MSG
		SenarioResizeShrink.build + "</P>"
	} +
	CGI::tag("P") {
		CGI::tag("H1") {"A bigger view?"} + <<"MSG" +
<P>Changing the view-height from 4 lines into 7 lines.</P><P>
MSG
		SenarioResizeWidenNormal.build + <<"MSG" +
</P><P>At the buffer-top it has serious consequences.</P><P>
MSG
		SenarioResizeWidenTop.build + <<"MSG" +
</P><P>At the buffer-bottom there doesn't seems to be any 
problems, at least there is no problems here.</P><P>
MSG
		SenarioResizeWidenBottom.build + <<"MSG" +
</P><P>But at the buffer-bottom there IS a minor problem. 
Compare case <TT>t23</TT> above with below, observe that scrolling 
occurs in the above case and NO scrolling occurs in the below case!
Which behaver should one choose to implement?<BR>
Hmmm.. I think the case below is bad, because it doesn't 
behave like pageup, its behavier reminds me more of move_one_line_up.
Therefore the above case is much better.</P><P>
MSG
		SenarioResizeWidenBottom2.build + "</P>"
	} +
	CGI::tag("P") {
		CGI::tag("H1") {"Conclusion"} + <<MSG
I have learned that <TT>resize</TT> must be considered when
dealing with undo/redo. This document is only about consequences from
<TT>resize</TT>.
I have seen examples of many other editors which erroneous deals
with these situations. It both scares me and makes me more confident!
<P>Is it really worth the efforts, making <TT>pagedown</TT> user-friendly?<BR>
Yes, undo of <TT>Pagedown</TT> can easily be confusing to the observer when
doing pair-programming, this is vital for improving user-frindlyness for the
observer!</P>
<P>The solution is simple: In the border-cases (bottom/top) to use move 
the cursor within the view. In the normal case scrolling is done.
During <TT>set_memento</TT>, you can specify if the view should be 
<TT>lock</TT>ed.</P>
<P>Most of these cases also work for <TT>pageup</TT>, but not all. 
This is because up/down are assymetric. At the bottom there is 
virtual-lines. At the top there is nothing.
BTW: The resize concept also applyes to sideway scrolling!</P>
<P>If we use <TT>softwrap</TT>, then changing the width of the window
is equal to changing the height of the window!</P>
MSG
	} 
end


if $0 == __FILE__
	CGI::store("pagedown_resize.html", document, SenarioSkeleton.get_style, "User-friendly: Pagedown and Resize")
end
