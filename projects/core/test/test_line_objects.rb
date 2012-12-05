require 'aeditor/backend/line_objects'
require 'aeditor/backend/convert'
require 'common'

class TestLineObjects < Common::TestCase 
	def test_line_to_s1
		line = Line.create("abc", true)
		assert_equal("abc<hard>", line.to_s)
	end
	def test_line_to_s2
		line = Line.create("abc", false)
		assert_equal("abc<soft>", line.to_s)
	end
	def test_array_push1
		line = Line.create("abc", true)
		la = LineArray.new([line])
		la.push(Line.create("def", true))
		assert_equal("abc<hard>def<hard>", la.to_s)
		assert_equal(8, la.bytes)
		assert_equal(2, la.visible_lines)
		assert_equal(2, la.physical_lines)
	end
	def test_array_unshift1
		line = Line.create("def", true)
		la = LineArray.new([line])
		la.unshift(Line.create("abc", true))
		assert_equal("abc<hard>def<hard>", la.to_s)
		assert_equal(8, la.bytes)
		assert_equal(2, la.visible_lines)
		assert_equal(2, la.physical_lines)
	end
	def test_array_pop1
		line1 = Line.create("abc", true)
		line2 = Line.create("def", true)
		la = LineArray.new([line1, line2])
		line = la.pop
		assert_equal("abc<hard>", la.to_s)
		assert_equal("def<hard>", line.to_s)
		assert_equal(4, la.bytes)
		assert_equal(1, la.visible_lines)
		assert_equal(1, la.physical_lines)
	end
	def test_array_shift1
		line1 = Line.create("abc", true)
		line2 = Line.create("def", true)
		la = LineArray.new([line1, line2])
		line = la.shift
		assert_equal("abc<hard>", line.to_s)
		assert_equal("def<hard>", la.to_s)
		assert_equal(4, la.bytes)
		assert_equal(1, la.visible_lines)
		assert_equal(1, la.physical_lines)
	end
	def test_auto_indent1
		line = Line.create("abc", true)
		res = LineIndent.extract_indent(line.lineobjs)
		assert_equal(0, res.size)
	end
	def test_auto_indent2
		line = Line.create("\t abc", true)
		res = LineIndent.extract_indent(line.lineobjs)
		assert_equal("\t ", res.to_s)
	end
end

TestLineObjects.run if $0 == __FILE__
