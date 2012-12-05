unless defined?($logger)
	class MockLogger
		def debug(code=nil, &block)
			#puts block.call
		end
	end
	$logger = MockLogger.new
end

require 'test/unit'
require 'aeditor/buffer'

class TestBuffer < Test::Unit::TestCase
	MODEL = Buffer::Model::Caretaker
	def test_model_new
		model = MODEL.new
		assert_equal(1, model.number_of_lines)
		assert_equal("", model.to_a.join("-"))
	end
	def test_model_open1
		model = MODEL.open("abc")
		assert_equal(1, model.number_of_lines)
		assert_equal("abc", model.to_a.join("-"))
	end
	def test_model_open2
		model = MODEL.open("abc\ndef\nghi")
		assert_equal(3, model.number_of_lines)
		assert_equal("abc\n-def\n-ghi", model.to_a.join("-"))
	end
	def test_model_open3
		model = MODEL.open("abc\ndef\nghi\n")
		assert_equal(4, model.number_of_lines)
		assert_equal("abc\n-def\n-ghi\n-", model.to_a.join("-"))
	end
	def test_model_open4
		model = MODEL.open('')
		assert_equal(1, model.number_of_lines)
		assert_equal('', model.to_a.join("-"))
	end
	def test_model_line_clone1
		model = MODEL.open("abc\ndef\nghi\n")
		line = model.lines[1].clone
		assert_equal('e', line.content.slice!(1, 1))
		assert_equal("abc\n-def\n-ghi\n-", model.to_a.join("-"))
		assert_equal("df\n", line.text)
	end
	def test_model_iterator_forward1
		model = MODEL.open("abcdef\nghijkl")
		i = model.mk_iterator(3, 1)
		ary_current = []
		while i.has_next?
			ary_current << i.current
			i.next
		end
		assert_equal(%w(j k l), ary_current)
		assert_equal(6, i.x)
	end
	def test_model_iterator_backward1
		model = MODEL.open("abcdef\nghijkl")
		i = model.mk_iterator(3, 1)
		ary_current = []
		while i.has_prev?
			i.prev
			ary_current.unshift(i.current)
		end
		assert_equal(%w(g h i), ary_current)
		assert_equal(0, i.x)
	end
	VIEW = Buffer::View::Caretaker
	def test_view_new1
		model = MODEL.open("abc\ndef\nghi\n")
		view = VIEW.new(model, 80, 2)
		assert_equal(0, view.scroll_y)
		assert_equal(0, view.scroll_x)
		assert_equal(0, view.cursor_y)
		assert_equal(0, view.cursor_x)
		assert_equal(80, view.number_of_cells_x)
		assert_equal(2, view.number_of_cells_y)
	end
	def test_view_new2
		model = MODEL.open("abc\ndef\nghi\n")
		view = VIEW.new(model, 80, 2)
		assert_equal("abc\n-def\n", view.to_a.join("-"))
	end
	def test_view_new3
		model = MODEL.open("abc")
		view = VIEW.new(model, 80, 2)
		assert_equal("abc-", view.to_a.join("-"))
	end
	def test_view_new4
		model = MODEL.open("abc")
		view = VIEW.new(model, 80, 4)
		assert_equal("abc---", view.to_a.join("-"))
	end
	def test_view_resize_smaller1
		model = MODEL.open("abc\ndef\nghi\njkl\nmno")
		view = VIEW.new(model, 80, 4)
		view.resize(80, 2)
		assert_equal("abc\n-def\n", view.to_a.join("-"))
		assert_equal(80, view.number_of_cells_x)
		assert_equal(2, view.number_of_cells_y)
	end
	def test_view_resize_bigger1
		model = MODEL.open("abc\ndef\nghi\njkl\nmno")
		view = VIEW.new(model, 80, 2)
		view.resize(80, 4)
		assert_equal("abc\n-def\n-ghi\n-jkl\n", view.to_a.join("-"))
		assert_equal(80, view.number_of_cells_x)
		assert_equal(4, view.number_of_cells_y)
	end
	# TODO: ensure cursor are inside view when resizing
	def test_view_scroll_ypositive1
		model = MODEL.open("abc\ndef\nghi\njkl\nmno")
		view = VIEW.new(model, 80, 2)
		view.set_scroll_y(1)
		assert_equal("def\n-ghi\n", view.to_a.join("-"))
		assert_equal(1, view.scroll_y)
	end
	def test_view_scroll_ypositive2
		model = MODEL.open("abc\ndef\nghi\njkl\nmno")
		view = VIEW.new(model, 80, 2)
		view.set_scroll_y(2)
		assert_equal("ghi\n-jkl\n", view.to_a.join("-"))
		assert_equal(2, view.scroll_y)
	end
	def test_view_scroll_ypositive3
		model = MODEL.open("abc\ndef\nghi\njkl")
		view = VIEW.new(model, 80, 3)
		view.set_scroll_y(3)
		assert_equal(3, view.scroll_y)
		assert_equal(false, view.set_scroll_y(4))
		assert_equal(3, view.scroll_y)
		assert_equal("jkl--", view.to_a.join("-"))
	end
	def test_view_scroll_ynegative1
		model = MODEL.open("abc\ndef\nghi\njkl\nmno")
		view = VIEW.new(model, 80, 2)
		view.set_scroll_y(2)
		assert_equal("ghi\n-jkl\n", view.to_a.join("-"))
		view.set_scroll_y(1)
		assert_equal("def\n-ghi\n", view.to_a.join("-"))
		assert_equal(1, view.scroll_y)
	end
	def test_view_scroll_ynegative2
		model = MODEL.open("abc\ndef\nghi\njkl\nmno")
		view = VIEW.new(model, 40, 3)
		assert_equal(0, view.scroll_y)
		assert_equal(0, view.cursor_y)
		assert_equal(false, view.set_scroll_y(-1))  # hit top of view
		assert_equal(0, view.scroll_y)
		assert_equal(0, view.cursor_y)
	end
	def test_view_cursor_ynegative1
		model = MODEL.open("abc\ndef\nghi\njkl\nmno")
		view = VIEW.new(model, 40, 3)
		view.set_scroll_y(2)
		view.change_cursor_y(2)
		assert_equal(4, view.cursor_y)
		assert_equal(true, view.change_cursor_y(-1))  # normal
		assert_equal(3, view.cursor_y)
	end
	def test_view_cursor_ynegative2
		model = MODEL.open("abc\ndef\nghi\njkl\nmno")
		view = VIEW.new(model, 40, 3)
		view.set_scroll_y(2)
		assert_equal(2, view.cursor_y)
		assert_equal(false, view.change_cursor_y(-1))  # hit top of view
		assert_equal(2, view.cursor_y, "change_cursor_y wasn't harmless")
	end
	def test_view_cursor_ynegative3
		model = MODEL.open("1\n2\n3\n4\n5\n6\n7\n8\n9")
		view = VIEW.new(model, 40, 5)
		view.change_cursor_y(3)
		assert_equal(3, view.cursor_y)
		view.selection_init
		view.output_cells
		assert_equal(true, view.change_cursor_y(-2))   # normal
		assert_equal(1, view.cursor_y)
		assert_equal([true, false, false, false, true],
			view.render_valid)
	end
	def test_view_cursor_ypositive1
		model = MODEL.open("abc\ndef\nghi\njkl\nmno")
		view = VIEW.new(model, 40, 3)
		view.set_scroll_y(2)
		view.change_cursor_y(1)
		assert_equal(3, view.cursor_y)
		assert_equal(true, view.change_cursor_y(+1))  # normal
		assert_equal(4, view.cursor_y)
	end
	def test_view_cursor_ypositive2
		model = MODEL.open("abc\ndef\nghi\njkl\nmno")
		view = VIEW.new(model, 40, 3)
		view.set_scroll_y(2)
		view.change_cursor_y(2)
		assert_equal(4, view.cursor_y)
		assert_equal(false, view.change_cursor_y(+1))  # hit bottom of view
		assert_equal(4, view.cursor_y, "change_cursor_y wasn't harmless")
	end
	def test_view_cursor_ypositive3
		model = MODEL.open("1\n2\n3\n4\n5\n6\n7\n8\n9")
		view = VIEW.new(model, 40, 5) 
		view.change_cursor_y(1)
		assert_equal(1, view.cursor_y)
		view.selection_init
		view.output_cells
		assert_equal(true, view.change_cursor_y(2))   # normal
		assert_equal(3, view.cursor_y)
		assert_equal([true, false, false, false, true],
			view.render_valid)
	end
	def test_view_move_down1
		model = MODEL.open("abc\ndef")
		view = VIEW.new(model, 80, 4)
		assert_equal(true, view.move_down)
		assert_equal(false, view.move_down)  # hit bottom of view
		assert_equal(1, view.cursor_y)
		view.insert_text("x")
		assert_equal("abc\n-xdef--", view.to_a.join("-")) 
	end
	def test_view_cursor_xnegative1
		model = MODEL.open("abc\ndef\nghijkl\nmno\npqr")
		view = VIEW.new(model, 10, 3)
		view.set_scroll_y(2)
		5.times { view.move_right }
		assert_equal(5, view.cursor_x)
		assert_equal(true, view.move_left) # normal
		assert_equal(4, view.cursor_x)
	end
	def test_view_cursor_xpositive1
		model = MODEL.open("abc\ndef\nghijkl\nmno\npqr")
		view = VIEW.new(model, 10, 3)
		view.set_scroll_y(2)
		5.times { view.move_right }
		assert_equal(5, view.cursor_x)
		assert_equal(true, view.move_right)
		assert_equal(6, view.cursor_x)
	end
	def test_view_move_right_skiptabs1
		model = MODEL.open("\ta\tab\tabc\tabcd\tx\n")
		view = VIEW.new(model, 80, 1)
		view.set_tabsize(4)
		view.set_mode_cursor_through_tabs(false)
		ary_cursor_x = [view.cursor_x]
		ary_model_x = [view.model_x]
		16.times do
			view.move_right
			ary_cursor_x << view.cursor_x
			ary_model_x << view.model_x
		end
		assert_equal((0..16).to_a, ary_model_x)
		cx = [0, 4, 5, 8, 9, 10, 12, 13, 14, 15, 16, 17, 18, 19, 20, 24, 25]
		assert_equal(cx, ary_cursor_x)
	end
	def test_view_move_left_skiptabs1
		model = MODEL.open("\ta\tab\tabc\tabcd\tx\n")
		view = VIEW.new(model, 80, 1)
		view.set_tabsize(4)
		view.set_mode_cursor_through_tabs(false)
		view.moveto_line_end
		ary_cursor_x = [view.cursor_x]
		ary_model_x = [view.model_x]
		16.times do
			view.move_left
			ary_cursor_x.unshift(view.cursor_x)
			ary_model_x.unshift(view.model_x)
		end
		assert_equal((0..16).to_a, ary_model_x)
		cx = [0, 4, 5, 8, 9, 10, 12, 13, 14, 15, 16, 17, 18, 19, 20, 24, 25]
		assert_equal(cx, ary_cursor_x)
	end
	def test_view_breakline1
		model = MODEL.open("abcd\nefg\nhij")
		view = VIEW.new(model, 80, 3)
		view.move_right
		view.move_right
		view.sync_lcache
		assert_equal([true, true, true], view.lexer_cache_valid)
		view.breakline
		assert_equal([false, false, true], view.lexer_cache_valid)
		assert_equal("ab\n-cd\n-efg\n", view.to_a.join("-"))
		assert_equal(0, view.cursor_x)
	end
	def test_view_breakline2
		model = MODEL.open("abcd")
		view = VIEW.new(model, 80, 3)
		view.move_right
		view.move_right
		view.breakline
		assert_equal("ab\n-cd-", view.to_a.join("-"))
	end
	def test_view_breakline3
		model = MODEL.open("ab\ncd\nef\nghij\nkl\nmn\nopq\nr")
		view = VIEW.new(model, 80, 4)
		view.move_page_down
		view.move_right
		view.move_right
		assert_equal(3, view.model_iterator.y)
		assert_equal(2, view.model_iterator.x)
		assert_equal(3, view.scroll_y)
		assert_equal(3, view.cursor_y)
		assert_equal(2, view.cursor_x)
		assert_equal("ghij\n-kl\n-mn\n-opq\n", view.to_a.join("-"))
		view.breakline
		assert_equal("gh\n-ij\n-kl\n-mn\n", view.to_a.join("-"))
		assert_equal(0, view.cursor_x)
	end
	def test_view_breakline4
		model = MODEL.open("1\n2\n3X\n4\n5\n6\n7\n8")
		view = VIEW.new(model, 4, 6)
		view.move_down
		view.move_down
		view.move_right
		assert_equal([0, 2, 1], [view.scroll_y, view.cursor_y, view.cursor_x])
		y1s = []
		y2s = []
		counts = []
		view.set_vscroll_callback do |y1, y2, count|
			y1s << y1
			y2s << y2
			counts << count
		end
		assert_equal(%w(1 2 3X 4 5 6), get_stripped_texts(view))
		view.output_cells
		# <what to exercise>
		view.breakline_internal
		# </what to exercise>
		assert_equal([[3], [4], [2]], [y1s, y2s, counts])
		assert_equal([true, true, false, false, true, true],
			view.lexer_cache_valid)
		assert_equal([true, true, false, false, true, true],
			view.render_valid)
		assert_equal(%w(nil nil 3 X nil nil), get_stripped_texts(view))
	end
	def test_view_breakline5
		model = MODEL.open("1\n2\n3\n4\n5X\n6\n7\n8")
		view = VIEW.new(model, 4, 5)
		view.move_down
		view.move_down
		view.move_down
		view.move_down
		view.move_right
		assert_equal([0, 4, 1], [view.scroll_y, view.cursor_y, view.cursor_x])
		y1s = []
		y2s = []
		counts = []
		view.set_vscroll_callback do |y1, y2, count|
			y1s << y1
			y2s << y2
			counts << count
		end
		assert_equal(%w(1 2 3 4 5X), get_stripped_texts(view))
		view.output_cells
		assert_equal(5, view.lexer_cache_valid.size)
		# <what to exercise>
		view.breakline_internal
		# </what to exercise>
		assert_equal([0, 5, 0], [view.scroll_y, view.cursor_y, view.cursor_x])
		assert_equal([[], [], []], [y1s, y2s, counts])
		assert_equal([true, true, true, true, false],
			view.lexer_cache_valid)
		assert_equal([true, true, true, true, false],
			view.render_valid)
		assert_equal(%w(nil nil nil nil 5), get_stripped_texts(view))
	end
	def test_view_breakline6
		model = MODEL.open("1\n \t\t2\n3\n4\n5X\n6\n7\n8")
		view = VIEW.new(model, 10, 5)
		view.set_tabsize(4)
		view.set_mode_cursor_through_tabs(true)
		view.set_mode_autoindent(true)
		view.move_down
		view.move_right
		view.move_right
		view.move_right
		view.move_right
		view.move_right
		view.move_right
		assert_equal([0, 1, 6], [view.scroll_y, view.cursor_y, view.cursor_x])
		y1s = []
		y2s = []
		counts = []
		view.set_vscroll_callback do |y1, y2, count|
			y1s << y1
			y2s << y2
			counts << count
		end
		assert_equal(%W(1 \ \t\t\t\t\t\t\t2 3 4 5X), get_stripped_texts(view))
		view.output_cells
		assert_equal(5, view.lexer_cache_valid.size)
		# <what to exercise>
		view.breakline
		# </what to exercise>
		assert_equal([0, 2, 6], [view.scroll_y, view.cursor_y, view.cursor_x])
		assert_equal([[2], [3], [2]], [y1s, y2s, counts])
		assert_equal([true, false, false, true, true],
			view.lexer_cache_valid)
		assert_equal([true, false, false, true, true],
			view.render_valid)
		assert_equal(%W(nil #{} \ \t\t\t\ \ 2 nil nil), 
			get_stripped_texts(view))
	end
	def test_view_breakline7
		model = MODEL.open("0123")
		view = VIEW.new(model, 8, 6)
		view.move_right
		view.move_right
		assert_equal([0, 0, 2], [view.scroll_y, view.cursor_y, view.cursor_x])
		y1s = []
		y2s = []
		counts = []
		view.set_vscroll_callback do |y1, y2, count|
			y1s << y1
			y2s << y2
			counts << count
		end
		assert_equal(%W(0123 #{} #{} #{} #{} #{}), 
			get_stripped_texts(view).map{|i| i.gsub(/\s*/, '')} )
		view.output_cells
		assert_equal(6, view.lexer_cache_valid.size)
		# <what to exercise>
		view.breakline_internal
		# </what to exercise>
		assert_equal([0, 1, 0], [view.scroll_y, view.cursor_y, view.cursor_x])
		assert_equal(%W(01\n 23), model.to_a)
		assert_equal([[1], [2], [4]], [y1s, y2s, counts])
		assert_equal([false, false, true, true, true, true],
			view.lexer_cache_valid)
		assert_equal([false, false, true, true, true, true],
			view.render_valid)
		assert_equal(%w(01 23 nil nil nil nil), 
			get_stripped_texts(view).map{|i| i.gsub(/\s*/, '')} )
	end
	def test_view_breakline8
		model = MODEL.open("1\n2\n34")
		view = VIEW.new(model, 8, 3)
		view.set_extra_lines(0, 1)
		view.move_down
		view.move_down
		view.move_right
		assert_equal([0, 2, 1], [view.scroll_y, view.cursor_y, view.cursor_x])
		y1s = []
		y2s = []
		counts = []
		view.set_vscroll_callback do |y1, y2, count|
			y1s << y1
			y2s << y2
			counts << count
		end
		assert_equal(%W(1 2 34 #{}), 
			get_stripped_texts(view).map{|i| i.gsub(/\s*/, '')} )
		view.output_cells
		assert_equal(4, view.lexer_cache_valid.size)
		# <what to exercise>
		view.breakline_internal
		# </what to exercise>
		assert_equal([0, 3, 0], [view.scroll_y, view.cursor_y, view.cursor_x])
		assert_equal(%W(1\n 2\n 3\n 4), model.to_a)
		assert_equal([[], [], []], [y1s, y2s, counts])
		assert_equal([true, true, false, false], view.lexer_cache_valid)
		assert_equal([true, true, false, false], view.render_valid)
		assert_equal(%w(nil nil 3 4), 
			get_stripped_texts(view).map{|i| i.gsub(/\s*/, '')} )
		view.scroll_to_cursor
		assert_equal([1, 3, 0], [view.scroll_y, view.cursor_y, view.cursor_x])
	end
	def test_view_breakline_vspace1
		model = MODEL.open("abcd\nefgh")
		view = VIEW.new(model, 80, 2)
		view.moveto_line_end
		view.move_right
		view.move_right
		assert_equal(6, view.cursor_x)
		assert_equal(4, view.model_iterator.x)
		view.breakline
		assert_equal("abcd\n-\n", view.to_a.join("-"))
	end
	def test_view_breakline_vspace2
		model = MODEL.open("abcd")
		view = VIEW.new(model, 80, 2)
		view.moveto_line_end
		view.move_right
		view.move_right
		assert_equal(6, view.cursor_x)
		assert_equal(4, view.model_iterator.x)
		view.breakline
		assert_equal("abcd\n-", view.to_a.join("-"))
	end
	def generic_view_breakline_ai(text, times_right, expected_text, onoff)
		model = MODEL.open(text)
		view = VIEW.new(model, 80, 2)
		view.set_mode_cursor_through_tabs(onoff)
		view.set_mode_autoindent(true)
		view.set_tabsize(4)
		times_right.times { view.move_right }
		view.breakline
		assert_equal(expected_text, view.to_a.join("-"))
	end
	def test_view_breakline_autoindent10
		generic_view_breakline_ai("\t \tabcd", 10, "\t \tab\n-\t \tcd", true)
	end
	def test_view_breakline_autoindent11
		generic_view_breakline_ai("\t \tabcd", 8, "\n-\t \tabcd", true)
	end
	def test_view_breakline_autoindent12
		generic_view_breakline_ai("\t\tabcd", 6, "\n-\t  abcd", true)
	end
	def test_view_breakline_autoindent13
		generic_view_breakline_ai("\t\tabcd", 2, "\n-  abcd", true)
	end
	def test_view_breakline_autoindent14
		# when cursor_x=0.. then indentation is wiped completely
		# maybe it would be better not to wipe in this special case ?
		generic_view_breakline_ai("\t\tabcd", 0, "\n-abcd", true)
	end
	def test_view_breakline_autoindent20
		generic_view_breakline_ai("\t \tabcd", 5, "\t \tab\n-\t \tcd", false)
	end
	def test_view_breakline_autoindent21
		generic_view_breakline_ai("\t \tabcd", 3, "\n-\t \tabcd", false)
	end
	def test_view_breakline_autoindent22
		generic_view_breakline_ai("\t\tabcd", 1, "\n-\tabcd", false)
	end
	def test_view_breakline_autoindent23
		# when cursor_x=0.. then indentation is wiped completely
		# maybe it would be better not to wipe in this special case ?
		generic_view_breakline_ai("\t\tabcd", 0, "\n-abcd", false)
	end
	# TODO: exercise breakline_ai inside vspace
	def test_view_joinline1
		model = MODEL.open("ab\ncd\nef\ngh")
		view = VIEW.new(model, 80, 3)
		view.sync_lcache
		assert_equal([true, true, true], view.lexer_cache_valid)
		view.joinline
		assert_equal([false, true, false], view.lexer_cache_valid)
		assert_equal("abcd\n-ef\n-gh", view.to_a.join("-"))
		assert_equal(2, view.cursor_x)
	end
	def test_view_joinline2
		model = MODEL.open("1\n2\n3\n4\n5\n6\n7\n8")
		view = VIEW.new(model, 4, 5)
		view.set_extra_lines(0, 1)
		view.move_down
		view.move_down
		assert_equal(%w(1 2 3 4 5 6), get_stripped_texts(view))
		y1s = []
		y2s = []
		counts = []
		view.set_vscroll_callback do |y1, y2, count|
			y1s << y1
			y2s << y2
			counts << count
		end
		# <what to exercise>
		view.joinline
		# </what to exercise>
		assert_equal([1, 2], [view.cursor_x, view.cursor_y])
		assert_equal([[4], [3], [2]], [y1s, y2s, counts]) 
		assert_equal([true, true, false, true, true, false], 
			view.lexer_cache_valid)
		assert_equal([true, true, false, true, false, false], 
			view.render_valid)
		assert_equal(%w(nil nil 34 nil 6 7), get_stripped_texts(view))
	end
	def test_view_joinline3
		model = MODEL.open("1\n2\n3\n4\n5\n6\n7\n8\n9\n10")
		view = VIEW.new(model, 4, 5)
		view.set_extra_lines(0, 1)
		view.set_scroll_y(2)
		assert_equal(%w(3 4 5 6 7 8), get_stripped_texts(view))
		y1s = []
		y2s = []
		counts = []
		view.set_vscroll_callback do |y1, y2, count|
			y1s << y1
			y2s << y2
			counts << count
		end
		# <what to exercise>
		view.joinline
		# </what to exercise>
		assert_equal([1, 2, 2], [view.cursor_x, view.cursor_y, view.scroll_y])
		assert_equal([[2], [1], [4]], [y1s, y2s, counts]) 
		assert_equal([false, true, true, true, true, false], 
			view.lexer_cache_valid)
		assert_equal([false, true, true, true, false, false], 
			view.render_valid)
		assert_equal(%w(34 nil nil nil 8 9), get_stripped_texts(view))
	end
	def test_view_move_home1
		model = MODEL.open("\t  ab\ncd\n")
		view = VIEW.new(model, 80, 2)
		view.set_tabsize(4)
		assert_equal(0, view.cursor_x)
		view.move_home
		assert_equal(6, view.cursor_x)
		view.move_home
		assert_equal(0, view.cursor_x)
		view.move_home
		assert_equal(6, view.cursor_x)
	end
	def test_view_move_home2
		model = MODEL.open("\t\t  \ncd\n")
		view = VIEW.new(model, 80, 2)
		view.set_tabsize(4)
		assert_equal(0, view.cursor_x)
		view.move_home
		assert_equal(10, view.cursor_x)
		view.move_home
		assert_equal(0, view.cursor_x)
		view.move_home
		assert_equal(10, view.cursor_x)
	end
	def test_view_move_home3
		model = MODEL.open("\t\tabc\n\nxzy")
		view = VIEW.new(model, 80, 2)
		view.set_tabsize(4)
		view.move_down
		assert_equal(0, view.cursor_x)
		assert_equal(0, view.model_iterator.x)
		view.move_home
		assert_equal(8, view.cursor_x)
		assert_equal(0, view.model_iterator.x)
	end
	def test_view_move_home4
		model = MODEL.open("\t\t abc\n  \n\t\t\t\nxzy")
		view = VIEW.new(model, 80, 2)
		view.set_mode_cursor_through_tabs(true)
		view.set_tabsize(4)
		view.move_down
		view.move_down
		assert_equal(0, view.cursor_x)
		assert_equal(2, view.cursor_y)
		assert_equal(0, view.model_iterator.x)
		view.move_home
		assert_equal(9, view.cursor_x)
		assert_equal(2, view.model_iterator.x)
	end
	def generic_test_view_move_pageup(view_height, scroll_y, 
		rel_cursor_y, expected_scroll_y, expected_cursor_y)
		model = MODEL.open((1..10).to_a.join("\n"))
		view = VIEW.new(model, 80, view_height)
		view.set_scroll_y(scroll_y)
		view.change_cursor_y(rel_cursor_y) 
		e1 = [scroll_y, scroll_y+rel_cursor_y]
		assert_equal(e1, [view.scroll_y, view.cursor_y])
		view.move_page_up 
		e2 = [expected_scroll_y, expected_cursor_y]
		assert_equal(e2, [view.scroll_y, view.cursor_y])
	end
	def test_view_move_pageup_normal
		generic_test_view_move_pageup(5, 7, 2, 3, 5)
		generic_test_view_move_pageup(5, 4, 1, 0, 1)
	end
	def test_view_move_pageup_normal2top
		generic_test_view_move_pageup(5, 1, 4, 0, 4)
		generic_test_view_move_pageup(5, 1, 2, 0, 2)
	end
	def test_view_move_pageup_top
		generic_test_view_move_pageup(5, 0, 4, 0, 0)
		generic_test_view_move_pageup(5, 0, 1, 0, 0)
	end
	def generic_test_view_move_pagedown(view_height, scroll_y, 
		rel_cursor_y, expected_scroll_y, expected_cursor_y)
		model = MODEL.open((1..10).to_a.join("\n"))
		view = VIEW.new(model, 80, view_height)
		view.set_scroll_y(scroll_y)
		view.change_cursor_y(rel_cursor_y) 
		e1 = [scroll_y, scroll_y+rel_cursor_y]
		assert_equal(e1, [view.scroll_y, view.cursor_y])
		view.move_page_down 
		e2 = [expected_scroll_y, expected_cursor_y]
		assert_equal(e2, [view.scroll_y, view.cursor_y])
	end
	def test_view_move_pagedown_normal
		generic_test_view_move_pagedown(5, 0, 2, 4, 6)
		generic_test_view_move_pagedown(5, 3, 2, 7, 9)
		generic_test_view_move_pagedown(5, 5, 0, 9, 9)
	end
	def test_view_move_pagedown_normal2bot
		generic_test_view_move_pagedown(5, 4, 3, 5, 8)
		generic_test_view_move_pagedown(5, 2, 4, 5, 9)
	end
	def test_view_move_pagedown_bot
		generic_test_view_move_pagedown(5, 5, 1, 5, 9)
		generic_test_view_move_pagedown(5, 6, 1, 6, 9)
		generic_test_view_move_pagedown(5, 7, 2, 7, 9)
		generic_test_view_move_pagedown(5, 9, 0, 9, 9)
	end
	def test_view_selection_extract1
		model = MODEL.open("abc\ndefgh\nijk\nlmn")
		view = VIEW.new(model, 80, 2)
		view.move_right
		view.selection_init
		assert_equal(true, view.selection_mode)
		assert_equal(0, view.selection_y)
		assert_equal(1, view.selection_x)
		view.move_down
		view.move_down
		view.move_right
		assert_equal("bc\n-defgh\n-ij", view.get_text_selection_array.join('-'))
		view.selection_reset
		assert_equal(false, view.selection_mode)
		assert_equal([], view.get_text_selection_array)
	end
	def test_view_selection_extract2
		model = MODEL.open("abc\ndefgh\nijk\nlmn")
		view = VIEW.new(model, 80, 2)
		3.times { view.move_right }
		3.times { view.move_down }
		view.selection_init
		assert_equal(true, view.selection_mode)
		assert_equal(3, view.selection_y)
		assert_equal(3, view.selection_x)
		view.move_up
		view.move_up
		assert_equal("gh\n-ijk\n-lmn", view.get_text_selection_array.join('-'))
		view.selection_reset
		assert_equal(false, view.selection_mode)
		assert_equal([], view.get_text_selection_array)
	end
	def test_view_selection_extract3
		model = MODEL.open("abc\ndefghijk\nlmn")
		view = VIEW.new(model, 80, 2)
		view.move_down
		view.moveto_line_end
		view.move_left
		view.selection_init
		assert_equal(true, view.selection_mode)
		assert_equal(1, view.selection_y)
		assert_equal(7, view.selection_x)
		view.moveto_line_begin
		view.move_right
		assert_equal("efghij", view.get_text_selection_array.join('-'))
		view.selection_reset
		assert_equal(false, view.selection_mode)
		assert_equal([], view.get_text_selection_array)
	end
	def test_view_selection_extract4
		model = MODEL.open("\tx")
		view = VIEW.new(model, 80, 2)
		view.set_tabsize(4)
		view.set_mode_cursor_through_tabs(true)
		view.moveto_line_begin
		view.move_right
		assert_equal(1, view.cursor_x)
		view.selection_init
		assert_equal(1, view.selection_x)
		view.moveto_line_end
		view.move_left
		view.move_left
		assert_equal(3, view.cursor_x)
		assert_equal(1, view.selection_x)
		assert_equal("  ", view.get_text_selection_array.join('-'))
		assert_equal("\tx", model.to_a.join("-"))
	end
	def test_view_selection_extract5
		model = MODEL.open("\ta\tb\tc")
		view = VIEW.new(model, 80, 2)
		view.set_tabsize(4)
		view.set_mode_cursor_through_tabs(true)
		view.moveto_line_begin
		view.move_right
		view.move_right
		assert_equal(2, view.cursor_x)
		view.selection_init
		assert_equal(2, view.selection_x)
		view.moveto_line_end
		view.move_left
		view.move_left
		view.move_left
		assert_equal(10, view.cursor_x)
		assert_equal(2, view.selection_x)
		assert_equal("  a\tb ", view.get_text_selection_array.join('-'))
		assert_equal("\ta\tb\tc", model.to_a.join("-"))
	end
	def test_view_selection_extract6
		model = MODEL.open("\ta\tb\tc")
		view = VIEW.new(model, 80, 2)
		view.set_tabsize(4)
		view.set_mode_cursor_through_tabs(false)
		ary = view.copy_text([2, 0], [10, 0])
		assert_equal("  a\tb ", ary.join('-'))
		assert_equal("\ta\tb\tc", model.to_a.join("-"))
	end
	def test_view_insert_text1
		model = MODEL.open("abc\ndefg\nhij")
		view = VIEW.new(model, 80, 2)
		view.move_down
		view.move_right
		view.move_right
		assert_equal(1, view.cursor_y)
		assert_equal(2, view.cursor_x)
		assert_equal(2, view.model_iterator.x)
		view.insert_text("xxx\nyyy\nzzz")
		assert_equal("abc\n-dexxx\n-yyy\n-zzzfg\n-hij", 
			model.to_a.join("-")) 
		assert_equal(3, view.cursor_y)
		assert_equal(3, view.cursor_x)
		assert_equal(3, view.model_iterator.x)
	end
	def test_view_erase1
		model = MODEL.open("abc\ndefg\nhij\nklmn")
		view = VIEW.new(model, 80, 2)
		view.erase([1, 0], [1, 2])
		assert_equal("aij\n-klmn", model.to_a.join("-")) 
	end
	def test_view_erase2
		model = MODEL.open("abc\ndefg\nhij\nklmn")
		view = VIEW.new(model, 80, 2)
		view.erase([3, 0], [0, 2])
		assert_equal("abchij\n-klmn", model.to_a.join("-")) 
	end
	def test_view_erase3
		model = MODEL.open("ab\ncdefghij\nklmn")
		view = VIEW.new(model, 80, 2)
		view.erase([2, 1], [6, 1])
		assert_equal("ab\n-cdij\n-klmn", model.to_a.join("-")) 
	end
	def test_view_erase4
		model = MODEL.open("aaaA\tB")
		view = VIEW.new(model, 80, 2)
		view.set_tabsize(4)
		view.set_mode_cursor_through_tabs(true)
		view.erase([5, 0], [7, 0])
		assert_equal("aaaA  B", model.to_a.join("-")) 
	end
	def test_view_erase5
		model = MODEL.open("\ta\tb\tc")
		view = VIEW.new(model, 80, 2)
		view.set_tabsize(4)
		view.set_mode_cursor_through_tabs(false)
		view.erase([2, 0], [10, 0])
		assert_equal("    c", model.to_a.join("-")) 
	end
	def test_view_erase6
		model = MODEL.open("a\tb\tc")
		view = VIEW.new(model, 80, 2)
		view.set_tabsize(4)
		view.set_mode_cursor_through_tabs(false)
		view.erase([4, 0], [5, 0])
		assert_equal("a\t\tc", model.to_a.join("-")) 
	end
	def test_view_selection_erase1
		model = MODEL.open("abcd\nefgh\nijklmn")
		view = VIEW.new(model, 80, 2)
		view.move_right
		view.move_right
		view.selection_init
		view.move_down
		view.move_down
		view.move_right
		view.move_right
		view.selection_erase # place cursor at selection-position
		assert_equal("abmn", model.to_a.join("-")) 
		assert_equal(0, view.cursor_y)
		assert_equal(2, view.cursor_x)
		view.insert_text('X')
		assert_equal("abXmn", model.to_a.join("-")) 
	end
	def test_view_selection_erase2
		model = MODEL.open("abcd\nefgh\nijklmn")
		view = VIEW.new(model, 80, 2)
		view.move_down
		view.move_down
		view.move_right
		view.move_right
		view.move_right
		view.move_right
		view.selection_init
		view.move_up
		view.move_up
		view.move_left
		view.move_left
		view.selection_erase # cursor already is at cursor-position
		assert_equal("abmn", model.to_a.join("-")) 
		assert_equal(0, view.cursor_y)
		assert_equal(2, view.cursor_x)
		view.insert_text('X')
		assert_equal("abXmn", model.to_a.join("-")) 
	end
	def generic_view_move_word_right(input_str, times_right, expected_x)
		model = MODEL.open(input_str)
		view = VIEW.new(model, 80, 2)
		ary_x = [view.cursor_x]
		ary_return = []
		times_right.times do
			ary_return << view.move_word_right
			ary_x << view.cursor_x
		end
		assert_equal(expected_x, ary_x)
		ary_return
	end
	def generic_view_move_word_left(input_str, times_left, expected_x)
		model = MODEL.open(input_str)
		view = VIEW.new(model, 80, 2)
		view.moveto_line_end
		ary_x = [view.cursor_x]
		ary_return = []
		times_left.times do
			ary_return << view.move_word_left
			ary_x.unshift(view.cursor_x)
		end
		assert_equal(expected_x, ary_x)
		ary_return
	end
	def test_view_move_word_right1
		ary_ret = generic_view_move_word_right(
			"abcd ef g\nxyz", 6, [0, 4, 5, 7, 8, 9, 9])
		assert_equal([true, true, true, true, true, false], ary_ret)
	end
	def test_view_move_word_right3
		generic_view_move_word_right("\tab\t\nxyz", 4, [0, 8, 10, 16, 16])
	end
	def test_view_move_word_left1
		ary_ret = generic_view_move_word_left(
			"abcd ef g\nxyz", 6, [0, 0, 4, 5, 7, 8, 9])
		assert_equal([true, true, true, true, true, false], ary_ret)
	end
	def test_view_move_word_right2
		generic_view_move_word_right(
			"obj.call_me(42, 3.4, count)\nxyz", 15, 
			[0, 3, 4, 11, 12, 14, 15, 16, 17, 18, 19, 20, 21, 26, 27, 27]
		)
	end
	def test_view_move_word_left2
		generic_view_move_word_left(
			"obj.call_me(42, 3.4, count)\nxyz", 15, 
			[0, 0, 3, 4, 11, 12, 14, 15, 16, 17, 18, 19, 20, 21, 26, 27]
		)
	end
	def test_view_move_word_left3
		generic_view_move_word_left("\tab\t\nxyz", 4, [0, 0, 8, 10, 16])
	end
	def test_view_swap_lower1
		model = MODEL.open("abc\ndef\nghi\njkl\nmno")
		view = VIEW.new(model, 80, 4)
		assert_equal(0, view.cursor_y)
		assert_equal(0, view.scroll_y)
		view.swap_lower
		assert_equal(1, view.cursor_y)
		assert_equal(0, view.scroll_y)  # no scroll if cursor are in top-half
		assert_equal("def\n-abc\n-ghi\n-jkl\n-mno", model.to_a.join("-")) 
		view.insert_text('X')
		assert_equal("def\n-Xabc\n-ghi\n-jkl\n-mno", model.to_a.join("-")) 
	end
	def test_view_swap_lower2
		model = MODEL.open("abc\ndef\nghi\njkl\nmno")
		view = VIEW.new(model, 80, 4)
		view.move_down
		view.move_down
		assert_equal(2, view.cursor_y)
		assert_equal(0, view.scroll_y)
		view.swap_lower
		assert_equal(3, view.cursor_y)
		assert_equal(1, view.scroll_y) # scroll when cursor are in bottom half
		assert_equal("abc\n-def\n-jkl\n-ghi\n-mno", model.to_a.join("-")) 
	end
	def test_view_swap_lower3
		model = MODEL.open("abc\ndef")
		view = VIEW.new(model, 80, 4)
		view.move_down
		assert_equal(false, view.swap_lower)
		assert_equal("abc\n-def", model.to_a.join("-")) 
	end
	def test_view_swap_lower4
		model = MODEL.open("abc\ndef")
		view = VIEW.new(model, 80, 4)
		view.swap_lower
		assert_equal("def\n-abc", model.to_a.join("-")) 
	end
	def test_view_swap_lower5
		model = MODEL.open("abc\ndef\nghi\njkl\n")
		view = VIEW.new(model, 80, 4)
		view.move_down
		view.selection_init
		view.move_down
		view.move_down
		assert_equal(1, view.selection_y)
		view.swap_lower_selection
		assert_equal("abc\n-jkl\n-def\n-ghi\n-", model.to_a.join("-")) 
		assert_equal(2, view.selection_y)
		view.insert_text('X')
		assert_equal("abc\n-jkl\n-def\n-ghi\n-X", model.to_a.join("-")) 
	end
	def test_view_swap_upper1
		model = MODEL.open("abc\ndef\nghi\njkl\nmno")
		view = VIEW.new(model, 80, 4)
		3.times { view.move_down }
		assert_equal(3, view.cursor_y)
		assert_equal(0, view.scroll_y)
		view.swap_upper
		assert_equal(2, view.cursor_y)
		assert_equal(0, view.scroll_y)  # no scroll if cursor are in bottom-half
		assert_equal("abc\n-def\n-jkl\n-ghi\n-mno", model.to_a.join("-")) 
		view.insert_text('X')
		assert_equal("abc\n-def\n-Xjkl\n-ghi\n-mno", model.to_a.join("-")) 
	end
	def test_view_swap_upper2
		model = MODEL.open("abc\ndef\nghi\njkl\nmno\npqr")
		view = VIEW.new(model, 80, 4)
		view.set_scroll_y(2)
		view.change_cursor_y(1)
		assert_equal(3, view.cursor_y)
		assert_equal(2, view.scroll_y)
		view.swap_upper
		assert_equal(2, view.cursor_y)
		assert_equal(1, view.scroll_y)  # scroll when cursor are in bottom half 
		assert_equal("abc\n-def\n-jkl\n-ghi\n-mno\n-pqr", model.to_a.join("-")) 
	end
	def test_view_swap_upper3
		model = MODEL.open("abc\ndef")
		view = VIEW.new(model, 80, 4)
		view.move_down
		view.swap_upper
		assert_equal("def\n-abc", model.to_a.join("-")) 
	end
	def test_view_swap_upper4
		model = MODEL.open("abc\ndef\nghi\njkl")
		view = VIEW.new(model, 80, 4)
		view.move_down
		view.selection_init
		view.move_down
		view.move_down
		assert_equal(1, view.selection_y)
		view.swap_upper_selection
		assert_equal("def\n-ghi\n-abc\n-jkl", model.to_a.join("-")) 
		assert_equal(0, view.selection_y)
		view.insert_text('X')
		assert_equal("def\n-ghi\n-Xabc\n-jkl", model.to_a.join("-")) 
	end
	def test_view_indent1
		model = MODEL.open("abc\ndef")
		view = VIEW.new(model, 80, 4)
		view.set_tabsize(2)
		assert_equal(0, view.cursor_x)
		view.indent("\t")
		assert_equal(0, view.cursor_x)
		assert_equal("\tabc\n-def", model.to_a.join("-")) 
	end
	def test_view_indent2
		model = MODEL.open("abc\ndef")
		view = VIEW.new(model, 80, 4)
		view.set_tabsize(2)
		view.moveto_line_end
		assert_equal(3, view.cursor_x)
		view.indent("\t")
		assert_equal(3, view.cursor_x)
		assert_equal("\tabc\n-def", model.to_a.join("-")) 
	end
	def test_view_indent3
		model = MODEL.open("abc\ndef\nghi\njkl\nmno")
		view = VIEW.new(model, 80, 4)
		view.set_tabsize(2)
		view.move_down
		view.selection_init
		view.move_down
		view.move_down
		view.indent_selection("\t")
		assert_equal("abc\n-\tdef\n-\tghi\n-jkl\n-mno", model.to_a.join("-")) 
	end
	def test_view_unindent1
		model = MODEL.open("\tabc\ndef")
		view = VIEW.new(model, 80, 4)
		view.set_tabsize(2)
		view.unindent
		assert_equal("abc\n-def", model.to_a.join("-")) 
	end
	def test_view_unindent2
		model = MODEL.open("\t\tabc\ndef")
		view = VIEW.new(model, 80, 4)
		view.set_tabsize(2)
		view.unindent
		assert_equal("\tabc\n-def", model.to_a.join("-")) 
	end
	def test_view_unindent3
		model = MODEL.open("abc\ndef")
		view = VIEW.new(model, 80, 4)
		view.set_tabsize(2)
		assert_equal(false, view.unindent)
		assert_equal("abc\n-def", model.to_a.join("-")) 
	end
	def test_view_unindent4
		model = MODEL.open(" abc\ndef")
		view = VIEW.new(model, 80, 4)
		view.set_tabsize(2)
		view.unindent
		assert_equal("abc\n-def", model.to_a.join("-")) 
	end
	def test_view_unindent5
		model = MODEL.open("abc\n\t def\n \tghi\n jkl\nmno")
		view = VIEW.new(model, 80, 4)
		view.set_tabsize(2)
		view.move_down
		view.selection_init
		view.move_down
		view.move_down
		view.move_down
		view.unindent_selection
		assert_equal("abc\n- def\n-ghi\n-jkl\n-mno", model.to_a.join("-")) 
	end
	LINE_EMPTY = Buffer::View::Line::Empty
	LINE_NORMAL = Buffer::View::Line::Normal
	def test_view_extralines_reload1
		model = MODEL.open("abc\ndef")
		view = VIEW.new(model, 20, 4)
		view.set_extra_lines(2, 3)
		assert_equal(0, view.cursor_y)
		assert_equal(0, view.scroll_y)
		assert_equal(2 + 4 + 3, view.to_a.size)
		assert_kind_of(LINE_EMPTY, view.lines[0])  # this is an extra line
		assert_kind_of(LINE_EMPTY, view.lines[1])  # this is an extra line
		assert_kind_of(LINE_NORMAL, view.lines[2]) # abc\n
		assert_equal("--abc\n-def-----", view.to_a.join("-")) 
	end
	def test_view_extralines_reload2
		model = MODEL.open("abc\ndef\nghi\njkl")
		view = VIEW.new(model, 20, 4)
		view.set_scroll_y(2)
		view.set_extra_lines(3, 2)
		assert_equal(2, view.cursor_y)
		assert_equal(2, view.scroll_y)
		assert_equal(3 + 4 + 2, view.to_a.size)
		assert_kind_of(LINE_EMPTY, view.lines[0])  # this is an extra line
		assert_kind_of(LINE_NORMAL, view.lines[1]) # this is an extra line
		assert_kind_of(LINE_NORMAL, view.lines[2]) # this is an extra line 
		assert_kind_of(LINE_NORMAL, view.lines[3]) # ghi\n
		assert_kind_of(LINE_NORMAL, view.lines[4]) # jkl
		assert_kind_of(LINE_EMPTY, view.lines[5])  #
		assert_kind_of(LINE_EMPTY, view.lines[6])  #
		assert_kind_of(LINE_EMPTY, view.lines[7])  # this is an extra line 
		assert_kind_of(LINE_EMPTY, view.lines[8])  # this is an extra line 
		assert_equal("-abc\n-def\n-ghi\n-jkl----", view.to_a.join("-")) 
	end
	def test_view_extralines_insert1
		model = MODEL.open("1\n2\n3\nabc\ndefg\nhi")
		view = VIEW.new(model, 20, 4)
		view.set_scroll_y(3)
		view.set_extra_lines(2, 2)
		assert_equal(0, view.cursor_cell_y)
		view.move_down
		assert_equal(4, view.cursor_y)
		assert_equal(1, view.cursor_cell_y)
		view.move_right
		view.move_right
		assert_equal(2, view.cursor_x)
		view.insert_text('XXX')
		assert_equal("2\n-3\n-abc\n-deXXXfg\n-hi---", view.to_a.join("-")) 
		assert_equal(4, view.number_of_cells_y)
	end
	def test_view_extralines_move_up1
		model = MODEL.open("abc\ndef")
		view = VIEW.new(model, 20, 2)
		view.set_extra_lines(2, 0)
		assert_equal(false, view.move_up)
	end
	def test_view_extralines_move_up2
		model = MODEL.open("1\n2\n3\nabc\ndef")
		view = VIEW.new(model, 20, 2)
		view.set_scroll_y(3)
		view.move_down
		view.set_extra_lines(2, 0)
		assert_equal(4, view.cursor_y)
		assert_equal(1, view.cursor_cell_y)
		assert_equal("2\n-3\n-abc\n-def", view.to_a.join("-")) 
		assert_equal(true, view.move_up)
		assert_equal(0, view.cursor_cell_y)
		assert_equal("2\n-3\n-abc\n-def", view.to_a.join("-")) 
		assert_equal(true, view.move_up)
		assert_equal("1\n-2\n-3\n-abc\n", view.to_a.join("-")) 
		assert_equal(true, view.move_up)
		assert_equal("-1\n-2\n-3\n", view.to_a.join("-")) 
		assert_equal(true, view.move_up)
		assert_equal("--1\n-2\n", view.to_a.join("-")) 
		assert_equal(false, view.move_up)    # hit top of view 
		assert_equal(0, view.cursor_cell_y)
	end
	def test_view_extralines_move_down1
		model = MODEL.open("abc\ndef")
		view = VIEW.new(model, 20, 2)
		view.set_extra_lines(0, 2)
		assert_equal(true, view.move_down)
		assert_equal(false, view.move_down)  # hit bottom of view
	end
	def test_view_extralines_move_down2
		model = MODEL.open("1\n2\n3\nabc\ndef")
		view = VIEW.new(model, 20, 2)
		view.set_extra_lines(0, 2)
		assert_equal(0, view.scroll_y)
		assert_equal(true, view.move_down)
		assert_equal(0, view.scroll_y)
		assert_equal(true, view.move_down)
		assert_equal(1, view.scroll_y)
		assert_equal("2\n-3\n-abc\n-def", view.to_a.join("-")) 
		assert_equal(true, view.move_down)
		assert_equal(true, view.move_down)
		assert_equal(false, view.move_down)
		assert_equal(3, view.scroll_y)
		assert_equal(4, view.cursor_y)
		assert_equal("abc\n-def--", view.to_a.join("-")) 
	end
	def get_stripped_texts(view)
		view.output_cells.map do |letters_states| 
			next 'nil' unless letters_states
			letters_states[0].join.gsub(/\n.*\z/m, "")
		end  
	end
	def generic_test_view_callback_copy_lines(
		# before
		cy1, sy1, texts1,
		# after
		cy2, sy2, params, lcache, render, texts2, texts3,
		&block
		)
		model = MODEL.open("0\n1\n2\n3\n4\n5\n6\n7\n8\n9\n10\n11")
		view = VIEW.new(model, 3, 5)
		view.set_extra_lines(0, 1)
		view.set_scroll_y(sy1)
		(cy1 - sy1).times do
			view.move_down
		end
		assert_equal(cy1, view.cursor_y)
		assert_equal(sy1, view.scroll_y)
		assert_equal([false]*6, view.render_valid)
		assert_equal(texts1, get_stripped_texts(view), 
			'recompute all lcache entries')
		assert_equal([true]*6, view.render_valid)
		y1s = []
		y2s = []
		counts = []
		view.set_vscroll_callback do |y1, y2, count|
			y1s << y1
			y2s << y2
			counts << count
		end
		# <what to exercise>
		block.call(view)
		# </what to exercise>
		assert_equal(cy2, view.cursor_y)
		assert_equal(sy2, view.scroll_y)
		assert_equal(6, view.render_valid.size)
		assert_equal(params, [y1s, y2s, counts], 
			'paramerets supplied to vscroll_callback')
		assert_equal(lcache, view.lexer_cache_valid)
		assert_equal(render, view.render_valid)
		assert_equal(texts2, get_stripped_texts(view), 
			'recompute lexer cache dirty entries')
		view.render_dirty_all
		assert_equal(texts3, get_stripped_texts(view), 
			'all entries in lcache should be uptodate')
	end
	def test_view_callback_copy_lines_scrollup1
		generic_test_view_callback_copy_lines(
			1, 
			1, 
			%w(1 2 3 4 5 6),
			0, 
			0, 
			[[0], [1], [5]],
			[false, true, true, true, true, true],
			[false, false, true, true, true, false],
			%w(0 1 nil nil nil 5),
			%w(0 1 2 3 4 5)
		) do |view|
			view.move_up
		end
	end
	def test_view_callback_copy_lines_scrollup2
		generic_test_view_callback_copy_lines(
			4, 
			1, 
			%w(1 2 3 4 5 6),
			3, 
			0, 
			[[0], [1], [5]],
			[false, true, true, true, true, true],
			[false, true, true, true, false, false],
			%w(0 nil nil nil 4 5), 
			%w(0 1 2 3 4 5)
		) do |view|
			view.set_scroll_y(0)
		end
	end
	def test_view_callback_copy_lines_scrollup3
		generic_test_view_callback_copy_lines(
			4, 
			2, 
			%w(2 3 4 5 6 7),
			2, 
			0, 
			[[0], [2], [4]],
			[false, false, true, true, true, true],
			[false, false, true, true, false, false],
			%w(0 1 nil nil 4 5), 
			%w(0 1 2 3 4 5)
		) do |view|
			view.set_scroll_y(0)
		end
	end
	def test_view_callback_copy_lines_scrollup4
		generic_test_view_callback_copy_lines(
			6, 
			3, 
			%w(3 4 5 6 7 8),
			3, 
			0, 
			[[0], [3], [3]],
			[false, false, false, true, true, true],
			[false, false, false, true, true, false],
			%w(0 1 2 nil nil 5),
			%w(0 1 2 3 4 5)
		) do |view|
			view.set_scroll_y(0)
		end
	end
	def test_view_callback_copy_lines_scrollup5
		generic_test_view_callback_copy_lines(
			5, 
			3, 
			%w(3 4 5 6 7 8),
			2, 
			0, 
			[[0], [3], [3]],
			[false, false, false, true, true, true],
			[false, false, false, true, true, false],
			%w(0 1 2 nil nil 5),
			%w(0 1 2 3 4 5)
		) do |view|
			view.set_scroll_y(0)
		end
	end
	def test_view_callback_copy_lines_scrollup6
		generic_test_view_callback_copy_lines(
			6, 
			4, 
			%w(4 5 6 7 8 9),
			2, 
			0, 
			[[0], [4], [2]],
			[false, false, false, false, true, true],
			[false, false, false, false, true, false],
			%w(0 1 2 3 nil 5),
			%w(0 1 2 3 4 5)
		) do |view|
			view.set_scroll_y(0)
		end
	end
	def test_view_callback_copy_lines_scrollup7
		generic_test_view_callback_copy_lines(
			3, 
			2, 
			%w(2 3 4 5 6 7),
			1, 
			0, 
			[[0], [2], [4]],
			[false, false, true, true, true, true],
			[false, false, false, false, true, false],
			%w(0 1 2 3 nil 5),
			%w(0 1 2 3 4 5)
		) do |view|
			view.selection_init
			view.set_scroll_y(0)
		end
	end
	def test_view_callback_copy_lines_scrollup8
		generic_test_view_callback_copy_lines(
			6, 
			2, 
			%w(2 3 4 5 6 7),
			4, 
			0, 
			[[0], [2], [4]],
			[false, false, true, true, true, true],
			[false, false, true, true, false, false],
			%w(0 1 nil nil 4 5),
			%w(0 1 2 3 4 5)
		) do |view|
			view.selection_init
			view.set_scroll_y(0)
		end
	end
	def test_view_callback_copy_lines_scrolldown1
		generic_test_view_callback_copy_lines(
			4, 
			0, 
			%w(0 1 2 3 4 5), 
			5, 
			1, 
			[[1], [0], [5]],
			[true, true, true, true, true, false],
			[true, true, true, false, false, false],
			%w(nil nil nil 4 5 6),
			%w(1 2 3 4 5 6)
		) do |view|
			view.move_down
		end
	end
	def test_view_callback_copy_lines_scrolldown2
		generic_test_view_callback_copy_lines(
			0, 
			0, 
			%w(0 1 2 3 4 5),
			2, 
			2, 
			[[2], [0], [4]],
			[true, true, true, true, false, false],
			[true, true, true, false, false, false],
			%w(nil nil nil 5 6 7),
			%w(2 3 4 5 6 7)
		) do |view|
			view.set_scroll_y(2)
		end
	end
	def test_view_callback_copy_lines_scrolldown3
		generic_test_view_callback_copy_lines(
			4, 
			0, 
			%w(0 1 2 3 4 5), 
			7, 
			3, 
			[[3], [0], [3]],
			[true, true, true, false, false, false],
			[true, false, false, false, false, false],
			%w(nil 4 5 6 7 8),
			%w(3 4 5 6 7 8)
		) do |view|
			view.set_scroll_y(3)
		end
	end
	def test_view_callback_copy_lines_scrolldown4
		generic_test_view_callback_copy_lines(
			3, 
			0, 
			%w(0 1 2 3 4 5), 
			7, 
			4, 
			[[4], [0], [2]],
			[true, true, false, false, false, false],
			[true, false, false, false, false, false],
			%w(nil 5 6 7 8 9),
			%w(4 5 6 7 8 9)
		) do |view|
			view.set_scroll_y(4)
		end
	end
	def test_view_callback_copy_lines_scrolldown5
		generic_test_view_callback_copy_lines(
			4, 
			0, 
			%w(0 1 2 3 4 5), 
			8, 
			4, 
			[[4], [0], [2]],
			[true, true, false, false, false, false],
			[false, false, false, false, false, false],
			%w(4 5 6 7 8 9),
			%w(4 5 6 7 8 9)
		) do |view|
			view.set_scroll_y(4)
		end
	end
	def test_view_callback_copy_lines_scrolldown6
		generic_test_view_callback_copy_lines(
			2, 
			0, 
			%w(0 1 2 3 4 5), 
			6, 
			4, 
			[[4], [0], [2]],
			[true, true, false, false, false, false],
			[false, false, false, false, false, false],
			%w(4 5 6 7 8 9),
			%w(4 5 6 7 8 9)
		) do |view|
			view.selection_init
			view.set_scroll_y(4)
		end
	end
	def test_view_callback_copy_lines_scrolldown7
		generic_test_view_callback_copy_lines(
			1, 
			0, 
			%w(0 1 2 3 4 5), 
			3, 
			2, 
			[[2], [0], [4]],
			[true, true, true, true, false, false],
			[false, false, true, false, false, false],
			%w(2 3 nil 5 6 7),
			%w(2 3 4 5 6 7)
		) do |view|
			view.selection_init
			view.set_scroll_y(2)
		end
	end
	def test_output_cells1
		model = MODEL.open("12\t345\nabc")
		view = VIEW.new(model, 10, 4)
		view.set_tabsize(4)
		assert_not_equal([nil, nil, nil, nil], view.output_cells)
		view.render_dirty(0)
		view.render_dirty(1)
		view.render_dirty(2)
		view.render_dirty(3)
		output = view.output_cells
		assert_equal(nil, view.output_cells[0])
		exp_text0 = "12\t\t345\n  ".split(//)
		exp_symbols0 = ([:text]*2) + ([:tab]*2) + ([:text]*3) + ([:end]*3)
		expected0 = [exp_text0, exp_symbols0]
		assert_equal(expected0, output[0])
		exp_text1 = "abc       ".split(//)
		exp_symbols1 = [:text]*3 + [:end]*7
		expected1 = [exp_text1, exp_symbols1]
		assert_equal(expected1, output[1])
		expected23 = ([[" ", :empty]]*10).transpose
		assert_equal(expected23, output[2])
		assert_equal(expected23, output[3])
	end
	def test_output_cells2
		model = MODEL.open("0123456789\n    45\n\n")
		view = VIEW.new(model, 6, 4)
		view.set_tabsize(4)
		view.set_scroll_x(2)
		view.render_dirty(0)
		view.render_dirty(1)
		view.render_dirty(2)
		view.render_dirty(3)
		output = view.output_cells
		exp_text0 = "\0013456\002".split(//)
		exp_symbols0 = [:text, :text, :text, :text, :text, :text]
		expected0 = [exp_text0, exp_symbols0]
		assert_equal(expected0, output[0])
		exp_text1 = "  45\n ".split(//)
		exp_symbols1 = [:text, :text, :text, :text, :end, :end]
		expected1 = [exp_text1, exp_symbols1]
		assert_equal(expected1, output[1])
		exp_text2 = "      ".split(//)
		exp_symbols2 = [:end]*6
		expected2 = [exp_text2, exp_symbols2]
		assert_equal(expected2, output[2])
	end
	def test_horizontal_scroll1
		model = MODEL.open("0123456789\nabcdefghi")
		view = VIEW.new(model, 5, 4)
		3.times { view.move_right }
		view.set_scroll_x(2)
		assert_equal(1, view.cursor_cell_x)
		assert_equal([false]*4, view.render_valid)
		output1 = view.output_cells
		assert_equal([true]*4, view.render_valid)
		assert_equal("\001345\002".split(//), output1[0][0])
		assert_equal("\001def\002".split(//), output1[1][0])
		assert_equal("     ".split(//), output1[2][0])
		assert_equal("     ".split(//), output1[3][0])
		assert_equal([nil]*4, view.output_cells)
		# <this is what we want to exercise>
		view.set_scroll_x(1)   # should mark the lines as dirty
		output2 = view.output_cells
		# </this is what we want to exercise>
		assert_equal([true]*4, view.render_valid)
		assert_equal("\001234\002".split(//), output2[0][0])
		assert_equal("\001cde\002".split(//), output2[1][0])
		assert_equal("     ".split(//), output2[2][0])
		assert_equal("     ".split(//), output2[3][0])
		assert_equal([nil]*4, view.output_cells)
	end
	def test_view_lexer_states1
		model = MODEL.open("txt = <<HERE\nim a comment\nHERE\np txt")
		view = VIEW.new(model, 10, 2)
		view.set_lexer(LexerRuby::Lexer.new)
		assert_equal([[]], view.lexer_states)
		view.set_scroll_y(2)
		hd = LexerRuby::State::Heredoc.new('HERE', false, true)
		assert_equal([[], [hd], [hd]], view.lexer_states)
		view.set_scroll_y(1)
		assert_equal([[], [hd]], view.lexer_states)
	end
	class MockLexer < LexerBase
		def initialize
			super
			@log = []
			@state_overwrite_data = nil
		end
		attr_reader :log
		def set_state_overwrite_data(ary)
			@state_overwrite_data = ary
		end
		class State
			def initialize(number)
				@number = number
			end
			attr_reader :number
			def ==(other)
				(self.class == other.class) and (@number == other.number)
			end
		end
		def lex_line(text)
			@log << text.clone
			s = @states.pop
			if @state_overwrite_data and @state_overwrite_data.size > 0
				#p s
				@states = @state_overwrite_data.shift
			else
				@states << State.new(s.kind_of?(State) ? s.number+1 : 0)
			end
			@result << [text, :mocked]
		end
		def reset_log
			@log = []
		end
	end
	def prepare_for_test_lcache_sync
		model = MODEL.open((1..30).to_a.join("\n"))
		view = VIEW.new(model, 5, 10)
		lexer = MockLexer.new
		view.set_lexer(lexer)
		assert_equal([[]], view.lexer_states)
		view.set_scroll_y(10)
		view.change_cursor_y(5)
		assert_equal([10, 15], [view.scroll_y, view.cursor_y])
		[model, view, lexer]
	end
	def test_view_lcache_sync1 
		model, view, lexer = prepare_for_test_lcache_sync 
		expected = [[]] 
		(0..9).each {|i| expected << [MockLexer::State.new(i)] }
		assert_equal(expected, view.lexer_states)
		assert_equal([false]*10, view.lexer_cache_valid)
		assert_equal([nil]*10, view.lexer_cache_states)
		view.sync_lcache 
		assert_equal([true]*10, view.lexer_cache_valid)
		expected = [] 
		(10..19).each {|i| expected << [MockLexer::State.new(i)] }
		assert_equal(expected, view.lexer_cache_states)
		view.reset_lcache
		assert_equal([false]*10, view.lexer_cache_valid)
		assert_equal([nil]*10, view.lexer_cache_states)
		# <this_is_what_we_want_to_exercise>
		view.output_cells
		# </this_is_what_we_want_to_exercise>
		assert_equal([true]*10, view.lexer_cache_valid)
		expected = [] 
		(10..19).each {|i| expected << [MockLexer::State.new(i)] }
		assert_equal(expected, view.lexer_cache_states)
	end
	def test_view_lcache_sync2
		model, view, lexer = prepare_for_test_lcache_sync 
		view.sync_lcache 
		view.lcache_clear(1)
		view.lcache_clear(3)
		lexer.reset_log
		assert_equal([], lexer.log)
		# <this_is_what_we_want_to_exercise>
		view.sync_lcache 
		# </this_is_what_we_want_to_exercise>
		assert_equal(%W(12 14), lexer.log)
	end
	def test_view_lcache_sync3
		model, view, lexer = prepare_for_test_lcache_sync 
		view.sync_lcache 
		view.lcache_clear(1)
		lexer.reset_log
		assert_equal([], lexer.log)
		# tell lexer what states it should output
		to_output = []
		[9, 8, 7, 14].each {|i| to_output << [MockLexer::State.new(i)] }
		lexer.set_state_overwrite_data(to_output)
		# <this_is_what_we_want_to_exercise>
		view.sync_lcache 
		# </this_is_what_we_want_to_exercise>
		expected = [] 
		[10, 9, 8, 7, 14, 15, 16, 17, 18, 19].each {|i| 
			expected << [MockLexer::State.new(i)] }
		assert_equal(expected, view.lexer_cache_states)
		# check that only minimal propagation occured
		assert_equal(%W(12 13 14 15), lexer.log)
	end
	def test_view_lcache_insert1
		model = MODEL.open("1\n2\n3\n4\n5\n6\n7\n8")
		view = VIEW.new(model, 4, 6)
		view.output_cells
		assert_equal([true]*6, view.render_valid)
		view.render_dirty(3)
		assert_equal([true, true, true, false, true, true], view.render_valid)
		view.lcache_insert_line(1, false)
		assert_equal([true, false, true, true, false, true], view.render_valid,
			'insert-scroll of the render_valid array')
	end
	def test_view_lcache_remove1
		model = MODEL.open("1\n2\n3\n4\n5\n6\n7\n8")
		view = VIEW.new(model, 4, 6)
		view.output_cells
		assert_equal([true]*6, view.render_valid)
		view.render_dirty(3)
		assert_equal([true, true, true, false, true, true], view.render_valid)
		view.lcache_remove_line(1, false)
		assert_equal([true, true, false, true, true, false], view.render_valid,
			'remove-scroll of the render_valid array')
	end
	def test_view_search1
		model = MODEL.open("abc\ndef\nghi\nklmn")
		view = VIEW.new(model, 10, 2)
		assert_equal(true, view.search("hi"))
		assert_equal(2, view.cursor_y)
		assert_equal(1, view.cursor_x)
		assert_equal(true, view.selection_mode)
		assert_equal(2, view.selection_y)
		assert_equal(3, view.selection_x)
		assert_equal([['hi']], view.get_text_selection_array)
	end
	def test_view_search2
		model = MODEL.open("def\nhighi\nklmn")
		view = VIEW.new(model, 10, 2)
		view.move_down
		view.move_right
		assert_equal(true, view.search("hi"))
		assert_equal(1, view.cursor_y)
		assert_equal(3, view.cursor_x)
		assert_equal(true, view.selection_mode)
		assert_equal(1, view.selection_y)
		assert_equal(5, view.selection_x)
		assert_equal([['hi']], view.get_text_selection_array)
	end
	def test_view_search3
		model = MODEL.open("abxabxabxabxabx")
		view = VIEW.new(model, 10, 2)
		6.times { view.move_right }
		assert_equal(true, view.search("ab"))
		# cursor_x is already pointing at the third match.. so skip it
		assert_equal([9, 0], [view.cursor_x, view.cursor_y])
		assert_equal(true, view.selection_mode)
		assert_equal([11, 0], [view.selection_x, view.selection_y])
		assert_equal([['ab']], view.get_text_selection_array)
		# search again
		assert_equal(true, view.search_again)
		assert_equal([12, 0], [view.cursor_x, view.cursor_y])
		assert_equal(true, view.selection_mode)
		assert_equal([14, 0], [view.selection_x, view.selection_y])
		assert_equal([['ab']], view.get_text_selection_array)
	end
	def test_view_search4
		model = MODEL.open("ab\ncd\nef")
		view = VIEW.new(model, 10, 2)
		assert_equal(false, view.search('beef'))
		assert_equal([0, 0], [view.cursor_x, view.cursor_y])
		assert_equal(false, view.selection_mode)
	end
	def test_view_search5
		model = MODEL.open("ab\ncd\nef")
		view = VIEW.new(model, 10, 2)
		assert_equal(false, view.search_again)
	end
	def test_view_search6
		model = MODEL.open((0..40).to_a.join("\n"))
		view = VIEW.new(model, 10, 3)
		y1s = []
		y2s = []
		counts = []
		view.set_vscroll_callback do |y1, y2, count|
			y1s << y1
			y2s << y2
			counts << count
		end
		assert_equal(true, view.search('30'))
		assert_equal([[], [], []], [y1s, y2s, counts])
		assert_equal([0, 30], [view.cursor_x, view.cursor_y])
		assert_equal(true, view.selection_mode)
	end
	def test_view_replace1
		model = MODEL.open("aYYb\nYYcdYY\neYYf")
		view = VIEW.new(model, 10, 2)
		view.enter_replace_mode('YY', 'X')
		assert_equal([1, 0], [view.cursor_x, view.cursor_y])
		assert_equal([3, 0], [view.selection_x, view.selection_y])
		assert_equal(true, view.selection_mode)
		view.mode_accept
		assert_equal("aXb\n-YYcdYY\n-eYYf", model.to_a.join("-")) 
		assert_equal([0, 1], [view.cursor_x, view.cursor_y])
		assert_equal([2, 1], [view.selection_x, view.selection_y])
		view.mode_accept
		assert_equal("aXb\n-XcdYY\n-eYYf", model.to_a.join("-")) 
		assert_equal([3, 1], [view.cursor_x, view.cursor_y])
		assert_equal([5, 1], [view.selection_x, view.selection_y])
		view.mode_skip
		assert_equal("aXb\n-XcdYY\n-eYYf", model.to_a.join("-")) 
		assert_equal([1, 2], [view.cursor_x, view.cursor_y])
		assert_equal([3, 2], [view.selection_x, view.selection_y])
		view.mode_accept
		assert_equal("aXb\n-XcdYY\n-eXf", model.to_a.join("-")) 
		assert_equal([2, 2], [view.cursor_x, view.cursor_y])
		assert_equal(false, view.selection_mode)
	end
	def test_view_mark1
		model = MODEL.open("a\nb\nc\nd\ne\nf")
		view = VIEW.new(model, 10, 2)
		view.move_down
		view.bookmark(0)
		view.move_down
		view.bookmark(2)
		view.move_down
		view.bookmark(1)
		assert_equal({0=>1, 1=>3, 2=>2}, view.bookmarks)
		view.goto_bookmark(0)
		assert_equal(1, view.cursor_y)
		view.goto_bookmark(1)
		assert_equal(3, view.cursor_y)
	end
	def make_bookmarks(view)
		view.move_down
		view.bookmark(0)
		view.move_down
		view.bookmark(1)
		view.move_down
		view.bookmark(2)
		view.move_down
		view.bookmark(3)
	end
	def test_view_mark2
		model = MODEL.open("a\nb\nc\nd\ne\nf")
		view = VIEW.new(model, 10, 2)
		make_bookmarks(view)
		assert_equal({0=>1, 1=>2, 2=>3, 3=>4}, view.bookmarks)
		view.adjust_bookmarks(2, 1)  # insert one line after line#2
		assert_equal({0=>1, 1=>2, 2=>4, 3=>5}, view.bookmarks)
		view.adjust_bookmarks(2, -2)  # remove two line after line#2
		assert_equal({0=>1, 1=>2, 2=>2, 3=>3}, view.bookmarks)
	end
	def test_view_mark_breakline1
		model = MODEL.open("a\nb\nc\nd\ne\nf")
		view = VIEW.new(model, 10, 2)
		make_bookmarks(view)
		assert_equal({0=>1, 1=>2, 2=>3, 3=>4}, view.bookmarks)
		view.move_up
		view.move_up
		assert_equal(2, view.cursor_y)
		view.breakline
		assert_equal(3, view.cursor_y)
		assert_equal({0=>1, 1=>2, 2=>4, 3=>5}, view.bookmarks)
	end
	def test_view_mark_breakline2
		model = MODEL.open("a\nb\nc\nd\ne\nf")
		view = VIEW.new(model, 10, 2)
		view.set_mode_autoindent(true)
		make_bookmarks(view)
		assert_equal({0=>1, 1=>2, 2=>3, 3=>4}, view.bookmarks)
		view.move_up
		view.move_up
		assert_equal(2, view.cursor_y)
		view.breakline
		assert_equal(3, view.cursor_y)
		assert_equal({0=>1, 1=>2, 2=>4, 3=>5}, view.bookmarks)
	end
	def test_view_mark_joinline1
		model = MODEL.open("a\nb\nc\nd\ne\nf")
		view = VIEW.new(model, 10, 2)
		make_bookmarks(view)
		assert_equal({0=>1, 1=>2, 2=>3, 3=>4}, view.bookmarks)
		view.move_up
		view.move_up
		assert_equal(2, view.cursor_y)
		view.joinline
		assert_equal(2, view.cursor_y)
		assert_equal({0=>1, 1=>2, 2=>2, 3=>3}, view.bookmarks)
	end
	def test_view_mark_swap_oneline1
		model = MODEL.open("a\nb\nc\nd\ne\nf")
		view = VIEW.new(model, 10, 2)
		make_bookmarks(view)
		assert_equal({0=>1, 1=>2, 2=>3, 3=>4}, view.bookmarks)
		view.move_up
		assert_equal(3, view.cursor_y)
		view.swap_upper
		assert_equal(2, view.cursor_y)
		assert_equal({0=>1, 1=>3, 2=>2, 3=>4}, view.bookmarks)
		view.swap_lower
		assert_equal(3, view.cursor_y)
		assert_equal({0=>1, 1=>2, 2=>3, 3=>4}, view.bookmarks)
	end
	def test_view_mark_selection_erase1
		model = MODEL.open("a\nb\nc\nd\ne\nf")
		view = VIEW.new(model, 10, 2)
		make_bookmarks(view)
		assert_equal({0=>1, 1=>2, 2=>3, 3=>4}, view.bookmarks)
		view.move_up
		view.selection_init
		assert_equal(3, view.cursor_y)
		view.move_up
		view.move_up
		assert_equal(1, view.cursor_y)
		assert_equal(3, view.selection_y)
		view.selection_erase
		assert_equal(1, view.cursor_y)
		assert_equal("a\n-d\n-e\n-f", model.to_a.join("-")) 
		assert_equal({0=>1, 1=>1, 2=>1, 3=>2}, view.bookmarks)
	end
	def test_view_mark_selection_erase2
		model = MODEL.open("1abcde\n2ABCDE\n3abcde\n4ABCDE\n5abcde\n6ABCDE")
		view = VIEW.new(model, 10, 2)
		make_bookmarks(view)
		assert_equal({0=>1, 1=>2, 2=>3, 3=>4}, view.bookmarks)
		view.move_up
		view.moveto_line_end
		view.move_left
		view.selection_init
		assert_equal([5, 3], [view.cursor_x, view.cursor_y])
		view.move_up
		view.move_up
		view.moveto_line_begin
		view.move_right
		assert_equal([1, 1], [view.cursor_x, view.cursor_y])
		assert_equal([5, 3], [view.selection_x, view.selection_y])
		view.selection_erase
		assert_equal(1, view.cursor_y)
		assert_equal("1abcde\n-2E\n-5abcde\n-6ABCDE", model.to_a.join("-")) 
		assert_equal({0=>1, 1=>1, 2=>1, 3=>2}, view.bookmarks)
	end
	def test_view_mark_selection_swap1
		model = MODEL.open("a\nb\nc\nd\ne\nf")
		view = VIEW.new(model, 10, 2)
		make_bookmarks(view)
		assert_equal({0=>1, 1=>2, 2=>3, 3=>4}, view.bookmarks)
		view.selection_init
		view.move_up
		view.move_up
		view.swap_upper_selection
		assert_equal("a\n-c\n-d\n-b\n-e\n-f", model.to_a.join('-'))
		assert_equal({0=>3, 1=>1, 2=>2, 3=>4}, view.bookmarks)
		view.swap_lower_selection
		assert_equal("a\n-b\n-c\n-d\n-e\n-f", model.to_a.join('-'))
		assert_equal({0=>1, 1=>2, 2=>3, 3=>4}, view.bookmarks)
	end
	def test_view_mark_insert_text1
		model = MODEL.open("a\nb\nc\nd\ne\nf")
		view = VIEW.new(model, 10, 2)
		make_bookmarks(view)
		assert_equal({0=>1, 1=>2, 2=>3, 3=>4}, view.bookmarks)
		view.move_up
		view.move_up
		view.insert_text("12\nxx\n34")
		assert_equal("a\n-b\n-12\n-xx\n-34c\n-d\n-e\n-f", model.to_a.join('-'))
		assert_equal({0=>1, 1=>2, 2=>5, 3=>6}, view.bookmarks)
	end
	MEMENTO_ALL = Buffer::View::Memento::All
	def test_view_memento_all1
		model = MODEL.open("a\nb\nc\nd\ne\nf")
		view = VIEW.new(model, 10, 2)
		view.move_right
		view.move_down
		view.selection_init
		view.move_down
		view.move_down
		assert_equal([1, 3], [view.cursor_x, view.cursor_y])
		assert_equal([1, 1], [view.selection_x, view.selection_y])
		assert_equal(true, view.selection_mode)
		# make snapshot
		memento_str = view.create_memento
		memento = Marshal.load(memento_str)
		assert_kind_of(MEMENTO_ALL, memento)
		assert_equal(model, memento.model)
		assert_equal(1, memento.cursor_x)
		assert_equal(3, memento.cursor_y)
		# mess up the model
		view.selection_reset
		view.move_up
		view.insert_text('X')
		assert_equal([2, 2], [view.cursor_x, view.cursor_y])
		assert_equal(false, view.selection_mode)
		assert_equal("a\nb\ncX\nd\ne\nf", model.to_a.join)
		# restore the original model
		view.set_memento(memento_str)
		model = view.model
		assert_equal([1, 3], [view.cursor_x, view.cursor_y])
		assert_equal([1, 1], [view.selection_x, view.selection_y])
		assert_equal(true, view.selection_mode)
		assert_equal("a\nb\nc\nd\ne\nf", model.to_a.join)
	end
	MEMENTO_POSITION = Buffer::View::Memento::Position
	def test_view_memento_position1
		model = MODEL.open("a\nb\nc\nd\ne\nf")
		view = VIEW.new(model, 10, 2)
		view.move_right
		view.move_down
		view.selection_init
		view.move_down
		view.move_down
		assert_equal([1, 3], [view.cursor_x, view.cursor_y])
		assert_equal([1, 1], [view.selection_x, view.selection_y])
		assert_equal(true, view.selection_mode)
		# make snapshot
		memento_str = view.create_memento_position
		memento = Marshal.load(memento_str)
		assert_kind_of(MEMENTO_POSITION, memento)
		assert_equal(1, memento.cursor_x)
		assert_equal(3, memento.cursor_y)
		# mess up the model
		view.move_down
		view.move_right
		view.move_right
		assert_equal([3, 4], [view.cursor_x, view.cursor_y])
		assert_equal(true, view.selection_mode)
		assert_equal("a\nb\nc\nd\ne\nf", model.to_a.join)
		# restore the original model
		view.set_memento(memento_str)
		model = view.model
		assert_equal([1, 3], [view.cursor_x, view.cursor_y])
		assert_equal([1, 1], [view.selection_x, view.selection_y])
		assert_equal(true, view.selection_mode)
		assert_equal("a\nb\nc\nd\ne\nf", model.to_a.join)
	end
	MEMENTO_RANGE = Buffer::View::Memento::Range
	def test_view_memento_range1
		model = MODEL.open("a\nb\nc\nd\ne\nf")
		view = VIEW.new(model, 10, 2)
		view.move_right
		view.move_down
		view.selection_init
		view.move_down
		assert_equal([1, 2], [view.cursor_x, view.cursor_y])
		assert_equal([1, 1], [view.selection_x, view.selection_y])
		assert_equal(true, view.selection_mode)
		# make snapshot
		memento_str = view.create_memento_range(2, 2)
		memento = Marshal.load(memento_str)
		assert_kind_of(MEMENTO_RANGE, memento)
		assert_equal(%W(c\n d\n), memento.model_lines.map{|l| l.text})
		assert_equal(1, memento.cursor_x)
		assert_equal(2, memento.cursor_y)
		assert_equal(2, memento.y_top)
		assert_equal(2, memento.y_bottom)
		# mess up the model
		view.breakline
		view.insert_text("XYZ")
		view.selection_reset
		view.selection_init
		assert_equal([3, 3], [view.selection_x, view.selection_y])
		view.selection_reset
		assert_equal([3, 3], [view.cursor_x, view.cursor_y])
		assert_equal(false, view.selection_mode)
		assert_equal("a\nb\nc\nXYZ\nd\ne\nf", model.to_a.join)
		# restore the original model
		view.set_memento(memento_str)
		model = view.model
		assert_equal([1, 2], [view.cursor_x, view.cursor_y])
		assert_equal([1, 1], [view.selection_x, view.selection_y])
		assert_equal(true, view.selection_mode)
		assert_equal("a\nb\nc\nd\ne\nf", model.to_a.join)
	end
	def test_view_memento_range2
		model = MODEL.open("a\nb\nc\nd\ne\nf")
		view = VIEW.new(model, 10, 2)
		view.move_right
		view.move_down
		view.selection_init
		view.move_down
		assert_equal([1, 2], [view.cursor_x, view.cursor_y])
		assert_equal([1, 1], [view.selection_x, view.selection_y])
		assert_equal(true, view.selection_mode)
		# make snapshot
		memento_str = view.create_memento_range(2, 2)
		memento = Marshal.load(memento_str)
		assert_kind_of(MEMENTO_RANGE, memento)
		assert_equal(%W(c\n d\n), memento.model_lines.map{|l| l.text})
		assert_equal(1, memento.cursor_x)
		assert_equal(2, memento.cursor_y)
		assert_equal(2, memento.y_top)
		assert_equal(2, memento.y_bottom)
		# mess up the model
		view.joinline
		assert_equal([1, 2], [view.cursor_x, view.cursor_y])
		assert_equal(true, view.selection_mode)
		assert_equal("a\nb\ncd\ne\nf", model.to_a.join)
		# restore the original model
		view.set_memento(memento_str)
		model = view.model
		assert_equal([1, 2], [view.cursor_x, view.cursor_y])
		assert_equal([1, 1], [view.selection_x, view.selection_y])
		assert_equal(true, view.selection_mode)
		assert_equal("a\nb\nc\nd\ne\nf", model.to_a.join)
	end
	def test_view_memento_range3
		model = MODEL.open('')
		view = VIEW.new(model, 10, 4)
		view.insert_text('a')
		memento_str = view.create_memento_range(0, 0)
		view.breakline
		assert_equal([0, 1], [view.cursor_x, view.cursor_y])
		assert_equal(%W(a\n #{}), model.to_a)
		# restore the original model
		view.set_memento(memento_str)
		model = view.model
		assert_equal(%w(a), model.to_a)
		assert_equal([1, 0], [view.cursor_x, view.cursor_y])
		# replay events again
		view.breakline
		assert_equal([0, 1], [view.cursor_x, view.cursor_y])
		assert_equal(%W(a\n #{}), model.to_a)
	end
end