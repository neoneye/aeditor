# do not run this test as ROOT.. since
# I test permissions assuming only user-access.
# For least amount of damage, I have chosen only
# to exercise the '/etc/hostname' file.
#
require 'test/unit'
require 'aeditor/fileio'

class TestFileio < Test::Unit::TestCase
	def teardown
		FileUtils.rm(Dir.glob('testdata_*'))
	end
	def save_file(name, content)
		FileSaver.save(name, content)
	end
	def test_save1
		text = 'abc'
		name = 'testdata_1'
		name_bak = name + '.bak'
		save_file(name, text)
		assert_equal([text], IO.readlines(name))
		assert_equal(false, File.exists?(name_bak))
	end
	def test_save2
		text1 = 'abc'
		text2 = 'xyz'
		name = 'testdata_1'
		name_bak = name + '.bak'
		save_file(name, text1)
		File.utime(2000, 1000, name)   # epoch + 1000 seconds
		time1m = File.mtime(name)
		time1a = File.atime(name)
		time_before = Time.now
		sleep 0.2
		save_file(name, text2)
		# check content of files
		assert_equal([text2], IO.readlines(name))
		assert_equal([text1], IO.readlines(name_bak))
		# check time
		assert_equal(time1m, File.mtime(name_bak))
		assert_equal(time1a, File.atime(name_bak))
		assert_operator(File.mtime(name).to_i, :>=, time_before.to_i)
		assert_operator(File.mtime(name).to_i, :<=, time_before.to_i+1)
		assert_operator(File.atime(name).to_i, :>=, time_before.to_i)
		assert_operator(File.atime(name).to_i, :<=, time_before.to_i+1)
	end
	def test_save3
		text1 = 'abc'
		text2 = 'xyz'
		name = 'testdata_1'
		name_bak = name + '.bak'
		FileUtils::touch(name_bak)
		save_file(name, text1)
		assert_equal([text1], IO.readlines(name))
		assert_equal([], IO.readlines(name_bak))
		File.chmod(0600, name)
		File.chmod(0666, name_bak)
		stat1 = File.stat(name)
		save_file(name, text2)
		assert_equal([text2], IO.readlines(name))
		assert_equal([text1], IO.readlines(name_bak))
		stat2 = File.stat(name)
		stat3 = File.stat(name_bak)
		# check inodes
		assert_not_equal(stat1.ino, stat2.ino)
		assert_equal(stat1.ino, stat3.ino)
		# check permissions
		assert_equal(stat1.mode, stat3.mode)
		assert_equal(stat1.mode, stat2.mode)
	end
	def test_save4
		text1 = 'abc'
		text2 = 'xyz'
		name2 = 'testdata_2'
		name1 = 'testdata_1'
		name1_bak = name1 + '.bak'
		FileUtils::touch(name2)
		FileUtils::symlink(name2, name1)
		assert_equal(true, FileTest.symlink?(name1))
		assert_equal(false, FileTest.symlink?(name2))
		assert_equal(false, File.exists?(name1_bak))
		save_file(name1, text1)
		assert_equal(true, FileTest.symlink?(name1))
		assert_equal(false, FileTest.symlink?(name2))
		assert_equal(true, File.exists?(name1_bak))
	end
	def test_save_fail1
		name = '/etc/hostname'
		e = assert_raises(RuntimeError) do
			save_file(name, 'abc')
		end
		assert_match(/file.*?#{name}/, e.message)
		assert_no_match(/symlink/, e.message)
		assert_match(/write/, e.message)
		assert_match(/permission/, e.message)
	end
	def test_save_fail2
		name1 = '/etc/hostname'
		name2 = 'testdata_2'
		FileUtils::symlink(name1, name2)
		e = assert_raises(RuntimeError) do
			save_file(name2, 'abc')
		end
		assert_match(/symlink.*?#{name2}.*?#{name1}/, e.message)
		assert_match(/write/, e.message)
		assert_match(/permission/, e.message)
	end
	def test_save_fail3
		text = 'abc'
		name = '/etc/testdata_1'
		name_bak = name + '.bak'
		e = assert_raises(RuntimeError) do
			save_file(name, text)
		end
		assert_match(/file.*?#{name}/, e.message)
		assert_match(/could not create/, e.message)
	end
	def test_modified1
		text = 'abc'
		name = 'testdata_1'
		save_file(name, text)
		assert_equal(false, FileHelper.check_content(name, 'abc'))
	end
	def test_modified2
		text = 'abcx'
		name = 'testdata_1'
		save_file(name, text)
		assert_equal(true, FileHelper.check_content(name, 'abc'))
	end
	def test_modified3
		name = 'testdata_1'
		assert_equal(true, FileHelper.check_content(name, 'abc'))
	end
	def test_modified4
		assert_equal(true, FileHelper.check_content(nil, 'abc'))
	end
	def test_find_dir_in_path1
		assert_match(/drb\z/, FileHelper.find_dir_in_path('drb'))
	end
	def test_find_dir_in_path2
		assert_nil(FileHelper.find_dir_in_path('notexisting'))
	end
	if ENV['LOGNAME'] != 'neoneye' 
		undef test_save2      # File.atime problem on Unixes/Windows
		undef test_save3      # File.inode problem on Windows
		undef test_save4      # symlink problem on Windows
		undef test_save_fail1
		undef test_save_fail2
		undef test_save_fail3
	end
end