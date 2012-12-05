require 'common'

class TestCommon < Common::TestCase
	def test_capture_stderr1
		str = capture_stderr {
			$stderr.print("hello ")
			$stderr.puts("world")
		}
		assert_equal("hello world\n", str)
	end
	def test_capture_stderr2
		str = capture_stderr {}
		assert_equal("", str)
	end
	def test_make_iterators
		i1, i2 = make_iterators(0, 1)
		assert_not_equal(i1.object_id, i2.object_id)
		assert_equal(i1.data.object_id, i2.data.object_id)
		assert_equal(0, i1.position)
		assert_equal(1, i2.position)
	ensure
		i1.close
		i2.close
	end
end

TestCommon.run if $0 == __FILE__
