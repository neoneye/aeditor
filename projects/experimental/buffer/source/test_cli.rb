require 'test/unit'
require 'aeditor/cli'

class TestCommandLineInterface < Test::Unit::TestCase
	class MockCLI < CommandLineInterface
		def initialize
			super
			@actions = []
		end
		attr_reader :actions
		def show_help(msg); @actions << :show_help end
		def show_version; @actions << :show_version end
		def show_badoption(msg); @actions << :show_badoption end
		def launch_editor; @actions << :launch_editor end
		def launch_selftest; @actions << :launch_selftest end
	end
	def parse(argv)
		MockCLI.parse(argv)
	end
	def test_filenames0
		res = parse []
		assert_equal([], res.filenames)
		assert_equal([:launch_editor], res.actions)
	end
	def test_filenames1
		res = parse %w(testfile1 testfile2)
		assert_equal(%w(testfile1 testfile2), res.filenames)
		assert_equal([:launch_editor], res.actions)
	end
	def test_help1
		res = parse %w(-h)
		assert_equal([:show_help], res.actions)
	end
	def test_version1
		res = parse %w(--version)
		assert_equal([:show_version], res.actions)
	end
	def test_selftest1
		res = parse %w(--selftest)
		assert_equal([:launch_selftest], res.actions)
	end
	def test_badoption1
		res = parse %w(--badoption)
		assert_equal([:show_badoption], res.actions)
	end
end
