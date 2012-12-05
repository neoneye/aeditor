require 'aeditor/backend/buffer_measure'
require 'aeditor/backend/convert'
require 'common'

class FakeMeasure
	include Measure
	def initialize(bytes=0, physical=0, visible=0)
		init_measure
		@bytes = bytes
		@physical_lines = physical
		@visible_lines = visible
	end
end

class TestMeasure < Common::TestCase 
	# -------------------------------------
	# test buffer objects
	# -------------------------------------
	def test_measure_bo1
		m = FakeMeasure.new
		bo = Convert.from_string_into_bufferobjs("abc\ndef\nghi")
		m.add(bo)
		assert_equal(11, m.bytes)
		assert_equal(2, m.physical_lines)
		assert_equal(2, m.visible_lines)
	end
	def test_measure_bo1a
		bo = Convert.from_string_into_bufferobjs("abc\ndef\nghi")
		bytes, physical, visible = Measure::count(bo)
		assert_equal(11, bytes)
		assert_equal(2, physical)
		assert_equal(2, visible)
	end
	def test_measure_bo2
		m = FakeMeasure.new(11, 2, 2)
		bo = Convert.from_string_into_bufferobjs("abc\ndef\nghi")
		m.sub(bo)
		assert_equal(0, m.bytes)
		assert_equal(0, m.physical_lines)
		assert_equal(0, m.visible_lines)
	end
	def test_measure_bo_fold1
		m = FakeMeasure.new
		bo1 = Convert.from_string_into_bufferobjs("abc\nd")
		bo2 = Convert.from_string_into_bufferobjs("01\n23\n45\n67")
		bo3 = Convert.from_string_into_bufferobjs("f\nghi")
		fold = BufferObjects::Fold.new(bo2, "{3}", false)
		m.add(bo1 + [fold] + bo3)
		assert_equal(21, m.bytes)
		assert_equal(2, m.visible_lines)
		assert_equal(5, m.physical_lines)
	end
	def test_measure_bo_fold2
		m = FakeMeasure.new
		bo1 = Convert.from_string_into_bufferobjs("a\nb")
		bo2 = Convert.from_string_into_bufferobjs("01\n23")
		bo3 = Convert.from_string_into_bufferobjs("x\ny\nz")
		bo4 = Convert.from_string_into_bufferobjs("45\n67")
		bo5 = Convert.from_string_into_bufferobjs("c\nd")
		fold1 = BufferObjects::Fold.new(bo3, "{2}", false)
		assert_equal(0, fold1.size_visible_lines)
		fold2 = BufferObjects::Fold.new(bo2 + [fold1] + bo4, "{4}", false)
		m.add(bo1 + [fold2] + bo5)
		assert_equal(21, m.bytes)
		assert_equal(2, m.visible_lines)
		assert_equal(6, m.physical_lines)
	end
	def test_measure_bo_fold_line1
		m = FakeMeasure.new
		bo1 = Convert.from_string_into_bufferobjs("abc\nd")
		bo2 = Convert.from_string_into_bufferobjs("01\n23\n45\n67")
		bo3 = Convert.from_string_into_bufferobjs("f\nghi")
		fold = BufferObjects::Fold.new(bo2, "title", true) # whole line
		m.add(bo1 + [fold] + bo3)
		assert_equal(21, m.bytes)
		assert_equal(3, m.visible_lines) # extra visible line
		assert_equal(5, m.physical_lines)
	end
	def test_measure_bo_fold_line2
		m = FakeMeasure.new
		bo1 = Convert.from_string_into_bufferobjs("a\nb")
		bo2 = Convert.from_string_into_bufferobjs("01\n23")
		bo3 = Convert.from_string_into_bufferobjs("x\ny\nz")
		bo4 = Convert.from_string_into_bufferobjs("45\n67")
		bo5 = Convert.from_string_into_bufferobjs("c\nd")
		fold1 = BufferObjects::Fold.new(bo3, "title", true)
		assert_equal(1, fold1.size_visible_lines)
		fold2 = BufferObjects::Fold.new(bo2 + [fold1] + bo4, "{4}", false)
		m.add(bo1 + [fold2] + bo5)
		assert_equal(21, m.bytes)
		assert_equal(2, m.visible_lines)
		assert_equal(6, m.physical_lines)
	end
	# -------------------------------------
	# test line objects
	# -------------------------------------
	def test_measure_lo1
		m = FakeMeasure.new
		lo = Convert.from_string_into_lineobjs("abc\tdef")
		m.add(lo)
		assert_equal(7, m.bytes)
		assert_equal(0, m.visible_lines)
		assert_equal(0, m.physical_lines)
	end
	def test_measure_lo_fold1
		m = FakeMeasure.new
		bo = Convert.from_string_into_bufferobjs("01\n23\n45\n67")
		fold = LineObjects::Fold.new(bo, "{3}", false)
		lo1 = Convert.from_string_into_lineobjs("abc")
		lo2 = Convert.from_string_into_lineobjs("def")
		m.add(lo1 + [fold] + lo2)
		assert_equal(17, m.bytes)
		assert_equal(0, m.visible_lines)
		assert_equal(3, m.physical_lines)
	end
	def test_measure_lo_fold_line1
		m = FakeMeasure.new
		bo = Convert.from_string_into_bufferobjs("01\n23\n45\n67")
		fold = LineObjects::Fold.new(bo, "title", true)
		lo1 = Convert.from_string_into_lineobjs("abc")
		lo2 = Convert.from_string_into_lineobjs("def")
		m.add(lo1 + [fold] + lo2)
		assert_equal(17, m.bytes)
		assert_equal(1, m.visible_lines)
		assert_equal(3, m.physical_lines)
	end
	# todo:
	# * soft-newline
	# * edit_container#right_bytes
	# * edit_container#right_physical_lines
end

TestMeasure.run if $0 == __FILE__
