require 'test/unit'
require 'fileutils'
require 'aeditor/session'

class TestSession < Test::Unit::TestCase
	include Session
	class MockCaretaker < Caretaker
		def puts2(t); end
	end
	def teardown
		FileUtils.rm(Dir.glob('testdata_*'))
	end
	def test_session_new1
		s = MockCaretaker.new
		assert_equal([], s.buffers)
		assert_equal([], s.modes)
	end
	def test_session_open1 
		name_config = 'testdata_config'
		File.open(name_config, 'w+') {|f| f.write(<<-CONTENT)}
		mode :ruby do |m|
			m.file_suffixes = %w(rb)
		end
		CONTENT
		s = MockCaretaker.new
		assert_equal(0, s.modes.size)
		s.load_config(name_config)
		assert_equal(1, s.modes.size, 'failed to load config')
		name_buffer = 'testdata_buffer.rb'
		File.open(name_buffer, 'w+') {|f| f.write(<<-CONTENT)}
		puts "im some ruby code"
		puts "im also a line of ruby code"
		CONTENT
		assert_equal([], s.buffers)
		s.open_buffer(name_buffer)
		assert_equal(1, s.buffers.size)
		ruby_mode = s.modes.last
		assert_equal(ruby_mode, s.buffer.mode, 'failed to recognize suffix')
		s.open_buffer(name_config)
		assert_equal(2, s.buffers.size)
		assert_equal(nil, s.buffer.mode)
	end
	def test_open2
		name_buffer = 'testdata_buffer.rb'
		File.open(name_buffer, 'w+') {|f| f.write("p 42\np 666")}
		s = MockCaretaker.new
		s.open_buffer(name_buffer)
		assert_equal(1, s.buffers.size)
		assert_equal(nil, s.buffer.mode)
		assert_equal("p 42\n-p 666", s.buffer.model.to_a.join('-'))
		assert_equal(name_buffer, s.buffer.title)
		assert_equal(File.expand_path(name_buffer), s.buffer.filename)
	end
	def test_open3
		name_buffer = 'testdata_buffer.rb'
		s = MockCaretaker.new
		assert_equal(0, s.buffers.size)
		e = assert_raises(RuntimeError) do
			s.open_buffer(name_buffer)
		end
		assert_equal(0, s.buffers.size)
		assert_match(/No such file/, e.message)
	end
	def test_open4
		name_buffer = '/etc/shadow'
		s = MockCaretaker.new
		assert_equal(0, s.buffers.size)
		e = assert_raises(RuntimeError) do
			s.open_buffer(name_buffer)
		end
		assert_equal(0, s.buffers.size)
		assert_match(/Permission denied/, e.message)
	end
	def test_open5
		s = MockCaretaker.new
		s.open_buffer_empty
		assert_equal(1, s.buffers.size)
		assert_equal(nil, s.buffer.mode)
		assert_equal('', s.buffer.model.to_a.join('-'))
		assert_equal('unnamed', s.buffer.title)
		assert_equal(nil, s.buffer.filename)
	end
	def test_theme1 
		name_config = 'testdata_config'
		File.open(name_config, 'w+') {|f| f.write(<<-CONTENT)}
		theme :morning do |t|
			t.set_rgb_pair :keyword, [0, 255, 0], [0, 0, 0]
		end
		theme :sunshine do |t|
			t.set_rgb_pair :keyword, [255, 255, 255], [0, 0, 0]
		end
		CONTENT
		s = MockCaretaker.new
		assert_equal(0, s.themes.size)
		s.load_config(name_config)
		assert_equal(2, s.themes.size, 'failed to load config')
	end
	if ENV['LOGNAME'] != 'neoneye'
		undef test_open4      # cannot read, no such file
	end
end
