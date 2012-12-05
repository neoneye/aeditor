require 'aeditor/ncurses/cmdline'
require 'common'

class TestCmdline < Common::TestCase
	def test_normal1
		argv = %w(a b c d)
		res = Cmdline.parse(argv)
		assert_equal(%w(a b c d), res.files_to_open)
	end
	def test_normal2
		argv = []
		res = Cmdline.parse(argv)
		assert_equal([], res.files_to_open)
	end
	def test_version1
		argv = ["--version"]
		e = assert_raises(Cmdline::Message) { Cmdline.parse(argv) }
		assert_match(/ver \d+.\d+/, e.message)
	end
	def test_version2
		argv = ["-v"]
		e = assert_raises(Cmdline::Message) { Cmdline.parse(argv) }
		assert_match(/ver \d+.\d+/, e.message)
	end
	def test_version3
		argv = ["-v", "file3"]
		e = assert_raises(Cmdline::Message) { Cmdline.parse(argv) }
		assert_match(/ver \d+.\d+/, e.message)
	end
	def test_bad_option1
		argv = ["--badbadbad"]
		e = assert_raises(Cmdline::Error) { Cmdline.parse(argv) }
		# TODO: assert_match(/invalid option.*--badbadbad/i, e.message)
	end
	def test_restore_argv1
		ARGV.replace(%w(a b c d))
		argv = ["--version"]
		assert_raises(Cmdline::Message) { Cmdline.parse(argv) }
		assert_equal(%w(a b c d), ARGV)
	end
end

TestCmdline.run if $0 == __FILE__
