require 'common'

class TestScannerNodes < Common::TestCase  
	include ScannerFactory
	def setup
		@last = mk_capture(mk_last, 1)
	end
	def assert_scanner(expected_ast, regexp_string)
		actual_ast = Root.compile(regexp_string)
		assert_equal(expected_ast, actual_ast, "Regexp=#{regexp_string.inspect}")
	end
	def mk_root(node, number_of_captures)
		capture0 = mk_capture(node, 0)
		Root.new(capture0, number_of_captures)
	end
	def test_inside
		c = mk_match(@last, 'c'[0])
		b = mk_match(c, 'b'[0])
		a = mk_match(b, 'a'[0])
		root = mk_root(a, 2)
		assert_scanner(root, 'abc')
	end
	def test_outside
		xyz = mk_outside(@last, 'x'[0]..'z'[0], 'X'[0]..'Z'[0])
		dot = mk_dot(xyz)
		abc = mk_outside(dot, 'a'[0], 'b'[0], 'c'[0])
		root = mk_root(abc, 2)
		assert_scanner(root, '[^abc].[^x-zX-Z]')
	end
	def test_alternation1
		a = mk_match(@last, 'a'[0])
		b = mk_match(@last, 'b'[0])
		c = mk_match(@last, 'c'[0])
		x = mk_match(c, 'x'[0])
		d = mk_match(@last, 'd'[0])
		alt1 = mk_alt(a, b, x, d)
		root = mk_root(alt1, 2)
		assert_scanner(root, 'a|b|xc|d')
	end
	def test_alternation2
		z = mk_match(@last, 'z'[0])
		cap3 = mk_capture(z, 3)
		cap5 = mk_capture(cap3, 5)
		x = mk_match(cap5, 'x'[0])
		y = mk_match(cap5, 'y'[0])
		alt2 = mk_alt(x, y) 
		cap4 = mk_capture(alt2, 4)
		b = mk_match(cap4, 'b'[0])
		a = mk_match(cap3, 'a'[0])
		alt1 = mk_alt(a, b)
		cap2 = mk_capture(alt1, 2)
		root = mk_root(cap2, 6)
		assert_scanner(root, '(a|b(x|y))z')
	end
	def test_repeat
		b = mk_match(@last, 'b'[0])
		# TODO: remove nil argument
		rep = mk_repeat_greedy(b, nil, 5, 9)
		slot = mk_slot(rep)
		endrep = mk_pattern_end(rep)
		dot = mk_dot(endrep) 
		rep.set_pattern(dot)
		a = mk_match(slot, 'a'[0])
		root = mk_root(a, 2)
		assert_scanner(root, 'a.{5,9}b')
	end
	def test_repeat_sequence
		b = mk_match(@last, 'b'[0])
		# TODO: remove nil argument
		rep2 = mk_repeat_lazy(b, nil, 0, -1)
		endrep2 = mk_pattern_end(rep2)
		dot2 = mk_dot(endrep2)  
		rep2.set_pattern(dot2)
		slot2 = mk_slot(rep2)
		rep = mk_repeat_greedy(slot2, nil, 0, 1)
		endrep = mk_pattern_end(rep)
		dot = mk_dot(endrep)  
		rep.set_pattern(dot)
		slot1 = mk_slot(rep)
		a = mk_match(slot1, 'a'[0])
		root = mk_root(a, 2)
		assert_scanner(root, 'a.?.*?b')
	end
	def test_capture
		# cbegin0..cend0  is the top most level  uses slot 0..1
		# cbegin1..cend1  is a nested level      uses slot 2..3
		bref = mk_backref(@last, 1)
		a = mk_match(bref, 'a'[0])
		cend = mk_capture(a, 3)
		dot2 = mk_dot(cend)  
		dot1 = mk_dot(dot2)  
		cbegin = mk_capture(dot1, 2)
		root = mk_root(cbegin, 4)
		assert_scanner(root, '(..)a\1')
	end
	def test_anchors1
		lend = mk_end_line(@last)
		dot = mk_dot(lend)
		nonw = mk_nonword_boundary(dot)
		a = mk_match(nonw, 'a'[0])
		sbegin = mk_begin_string(a)
		root = mk_root(sbegin, 2)
		assert_scanner(root, '\Aa\B.$')
	end
	def test_anchors2
		send2 = mk_end_string2(@last)
		send = mk_end_string(send2)
		dot = mk_dot(send)
		word = mk_word_boundary(dot)
		a = mk_match(word, 'a'[0])
		lbegin = mk_begin_line(a)
		root = mk_root(lbegin, 2)
		assert_scanner(root, '^a\b.\z\Z')
	end
	def xtest_lookbehind
		# TODO: implement me
		root = 9
		assert_scanner(root, "c(?<=a(.*)b(.*)c)d.")
	end
end

TestScannerNodes.run if $0 == __FILE__
