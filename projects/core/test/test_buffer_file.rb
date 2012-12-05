require 'aeditor/backend/buffer_file'
require 'tempfile'
require 'fileutils'
require 'common'

class TestBufferFile < Common::TestCase 
	def test_open1
		tmp = Tempfile.new("foo")
		tmp.print("ab\ncd\nef")
		tmp.close
		bo = BufferFile.open(tmp.path)
		tmp.close!
		assert_equal(8, bo.size)
		assert_kind_of(BufferObjects::Newline, bo[2])
		assert_kind_of(BufferObjects::Newline, bo[5])
	end
	def test_open2
		bo = BufferFile.open("non_existing_file")
		assert_equal(0, bo.size)
	end
	def test_save1
		name_orig = "tmp.test_save1"
		name_bak = name_orig+".bak"
		File.open(name_orig, "w") {|f| f.write "123" }
		assert_equal(false, FileTest.exist?(name_bak))
		stat1_orig = File.stat(name_orig)
		assert_equal(3, stat1_orig.size?)
		bo = Convert::from_string_into_bufferobjs("abc\ndef\nghi")
		sleep 1.1 # delay so timestamp can change
		BufferFile.save(bo, name_orig, name_bak)
		stat2_bak = File.stat(name_bak)
		stat2_orig = File.stat(name_orig)
		assert_equal(3, stat2_bak.size?)
		assert_equal(11, stat2_orig.size?)
		assert_equal(stat1_orig.ino, stat2_bak.ino)
		assert_equal(stat1_orig.mtime, stat2_bak.mtime)
		#assert_equal(stat1_orig.ctime, stat2_bak.ctime)
		assert_equal(stat1_orig.mode, stat2_orig.mode)
	ensure
		FileUtils::rm([name_bak]) if FileTest.exist?(name_bak)
		FileUtils::rm([name_orig]) if FileTest.exist?(name_orig)
	end
	def test_save2
		name_orig = "tmp.test_save2"
		name_bak = name_orig+".bak"
		FileUtils.touch(name_orig)
		File.chmod(0600, name_orig) # save should clone permissions
		assert_equal(false, FileTest.exist?(name_bak))
		stat1_orig = File.stat(name_orig)
		BufferFile.save([], name_orig, name_bak)
		assert_equal(true, FileTest.exist?(name_bak))
		assert_equal(true, FileTest.exist?(name_orig))
		stat2_bak = File.stat(name_bak)
		stat2_orig = File.stat(name_orig)
		assert_equal(stat1_orig.ino, stat2_bak.ino)
		assert_equal(stat1_orig.mode, stat2_orig.mode)
	ensure
		FileUtils::rm([name_bak]) if FileTest.exist?(name_bak)
		FileUtils::rm([name_orig]) if FileTest.exist?(name_orig)
	end
	# todo:
	# * test files containing LF + CR.. permutations of these
	# * test files containing control characters 0..31
	# * test loading of unicode files
end

TestBufferFile.run if $0 == __FILE__
