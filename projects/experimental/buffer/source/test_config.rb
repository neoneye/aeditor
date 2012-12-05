require 'test/unit'
require 'aeditor/config'

class TestConfigBase < Test::Unit::TestCase
	class MockOptionAccessor < Config::Base
		def_option(:value)
	end
	def test_option_accessors1
		i = MockOptionAccessor.new
		assert_equal({}, i.hash_of_options)
		i.value = 1
		assert_equal(1, i.get_value)
		assert_equal({:value=>1}, i.hash_of_options)
		i.set_value 2
		assert_equal(2, i.value)
		assert_equal({:value=>2}, i.hash_of_options)
		i.unset :value
		assert_equal({}, i.hash_of_options)
	end
	class MockOptionValidate < Config::Base
		def_option(:tabsize, 8) do |value|
			raise TypeError unless value.kind_of?(Integer)
			raise IndexError unless (1..16).member?(value)
		end
	end
	def test_option_validate1
		i = MockOptionValidate.new
		i.tabsize = 4
		assert_equal({:tabsize=>4}, i.hash_of_options)
		assert_raise(TypeError) { i.tabsize = '4' }
		assert_equal({:tabsize=>4}, i.hash_of_options)
		assert_raise(IndexError) { i.tabsize = -2 }
		assert_equal({:tabsize=>4}, i.hash_of_options)
		i.unset :tabsize
		assert_equal({}, i.hash_of_options)
	end
	class MockMappingAccessor < Config::Base
		def_mapping(:value)
	end
	def test_mapping_accessors1
		i = MockMappingAccessor.new
		assert_equal({}, i.hash_of_values)
		i.set_value(:key1, 1)
		assert_equal(1, i.get_value(:key1))
		assert_equal({:key1=>1}, i.hash_of_values)
		i.set_value(:key2, 2)
		assert_equal(2, i.get_value(:key2))
		assert_equal({:key1=>1, :key2=>2}, i.hash_of_values)
		i.hash_of_values[:key3] = 3  # this is not nice
		assert_equal({:key1=>1, :key2=>2, :key3=>3}, i.hash_of_values)
	end
	class MockMappingValidate < Config::Base
		def_mapping(:front_red) do |key, value|
			raise TypeError unless key.kind_of?(Symbol)
			raise TypeError unless value.kind_of?(Integer)
			raise IndexError unless (0..255).member?(value)
		end
	end
	def test_mapping_validate1
		i = MockMappingValidate.new
		assert_equal({}, i.hash_of_front_reds)
		i.set_front_red(:keyword, 255)
		assert_equal({:keyword=>255}, i.hash_of_front_reds)
		assert_raise(TypeError) { i.set_front_red('keyword', 170) }
		assert_equal({:keyword=>255}, i.hash_of_front_reds)
		assert_raise(TypeError) { i.set_front_red(:keyword, '170') }
		assert_equal({:keyword=>255}, i.hash_of_front_reds)
		assert_raise(IndexError) { i.set_front_red(:keyword, 666) }
		assert_equal({:keyword=>255}, i.hash_of_front_reds)
	end
	class MockCompare < Config::Base
		def_option(:val1)
		def_option(:val2)
	end
	def test_compare1
		a = MockCompare.new
		b = MockCompare.new
		assert_equal(a, b)
		a.val1 = 999
		assert_not_equal(a, b)
		b.val1 = 999
		assert_equal(a, b)
		a.val2 = 'ruby'
		a.unset :val1
		assert_not_equal(a, b)
		b.val2 = 'ruby'
		b.unset :val1
		assert_equal(a, b)
	end
	class MockClone < Config::Base
		def_option(:str)
	end
	def test_clone1
		a = MockClone.new
		a.str = 'im a'
		b = a.clone
		b.str = 'im b'
		assert_equal({:str=>'im b'}, b.hash_of_options)
		assert_equal({:str=>'im a'}, a.hash_of_options)
	end
	# NOTE: maybe it will become necessary to let the block 
	# convert the data into a more appropriate datatype.
	# But for now we don't want any conversion to take place!
	class MockOptionConvert < Config::Base
		def_option(:val1, 'xyz') do |value|
			value.to_sym  # conversion of data should be ignored
		end
	end
	def test_option_convert1
		i = MockOptionConvert.new
		i.val1 = :abc
		assert_equal(:abc, i.val1)
		i.val1 = 'def'
		assert_not_equal(:def, i.val1, 'conversion should not happen')
		assert_equal('def', i.val1)
	end
	# options may have default values
	# mappings cannot have default values
	class MockOptionDefault < Config::Base
		def_option(:tabsize, 8)
	end
	def test_option_default1
		i = MockOptionDefault.new
		assert_equal(8, i.tabsize)
		assert_equal({}, i.hash_of_options)
		assert_equal({:tabsize=>8}, i.hash_of_resulting_options)
		i.tabsize = 4
		assert_equal(4, i.tabsize)
		assert_equal({:tabsize=>4}, i.hash_of_options)
		assert_equal({:tabsize=>4}, i.hash_of_resulting_options)
		i.unset :tabsize
		assert_equal(8, i.tabsize)
		assert_equal({}, i.hash_of_options)
		assert_equal({:tabsize=>8}, i.hash_of_resulting_options)
	end
	# default values may also be wrong..
	# lets ensure they are being checked also
	# mapping doesn't have default values.. so no worry there.
	def test_option_default_bad1
		code = <<-CODE
		class MockOptionDefaultBad < Config::Base
			def_option(:tabsize, 'bad') do |value|
				raise TypeError unless value.kind_of?(Integer)
			end
		end
		CODE
		assert_raise(TypeError) do
			eval code
		end
	end
end # class TestConfigBase

class TestConfig < Test::Unit::TestCase
	include Config
	def setup
		@modes = []
		@dummy_mode = Mode.new(:dummy)
		@themes = []
		@dummy_theme = Theme.new(:dummy)
		@global_conf = Global.new
	end
	def lookup(name)
		#puts "lookup name=#{name.inspect}"
		@modes.each do |mode|
			if mode.name == name
				#puts "ok"
				return mode 
			end
		end
		#puts "failed"
		nil
	end
	def register(mode)
		@modes << mode
	end
	def register_theme(theme)
		@themes << theme
	end
	def test_global1
		global do |g|
			g.keymap = :simon
		end
		e = Global.new
		e.set_keymap(:simon)
		assert_equal(e, @global_conf)
		global do |g|
			g.unset :keymap
		end
		assert_equal({}, @global_conf.hash_of_options)
	end
	def test_mode1
		mode :symbolname do |m|
			m.tabsize = 4
			m.cursor_through_tabs = true
		end
		e = Mode.new(:symbolname)
		e.set_tabsize 4
		e.set_cursor_through_tabs true
		assert_equal([e], @modes)
	end
	def test_mode2
		mode 'stringname' do |m|
			m.lexer = :ruby
		end
		e = Mode.new('stringname')
		e.set_lexer :ruby
		assert_equal([e], @modes)
	end
	def test_mode3
		mode :name do |m|
			m.lexer = :ruby
			m.tabsize = 3
		end
		e = Mode.new('name')
		e.set_tabsize 3
		e.set_lexer :ruby
		assert_equal([e], @modes)
		mode :name do |m|
			assert_equal(3, m.tabsize)
			m.tabsize = 5
		end
		e2 = Mode.new('name')
		e2.set_tabsize 5
		e2.set_lexer :ruby
		assert_equal([e2], @modes)
	end
	def test_mode4
		mode :parent do |m|
			m.tabsize = 3
			m.file_suffixes = %w(c cc)
		end
		mode :derived, :parent do |m|
			m.file_suffixes = %w(cpp cxx)
		end
		p = Mode.new('parent')
		p.set_tabsize 3
		p.set_file_suffixes %w(c cc)
		d = Mode.new('derived')
		d.set_tabsize 3
		d.set_file_suffixes %w(cpp cxx)
		assert_equal([p, d], @modes)
	end
	def test_mode_illegal1
		e = assert_raises(TypeError) { mode(666) }
		assert_match(/expected.*?Symbol.*?but got/, e.message)
		assert_match(/expected.*?String.*?but got/, e.message)
		assert_match('but got Fixnum', e.message)
	end
	def test_mode_illegal2
		assert_raises(ArgumentError) { mode() }
	end
	def test_set_tabsize_ok1 
		@dummy_mode.set_tabsize(1)
		@dummy_mode.set_tabsize(3)
		@dummy_mode.set_tabsize(9)
		@dummy_mode.set_tabsize(16)
	end
	def test_set_tabsize_illegal1
		e = assert_raises(TypeError) { @dummy_mode.set_tabsize(3.5) }
		assert_match('expected Integer', e.message)
		assert_match('but got Float', e.message)
	end
	def test_set_tabsize_illegal2
		e = assert_raises(IndexError) { @dummy_mode.set_tabsize(0) }
		assert_match('expected integer to be in range 1..16', e.message)
		assert_match('but got 0', e.message)
	end
	def test_set_cursor_through_tabs_illegal1
		e = assert_raises(TypeError) do 
			@dummy_mode.set_cursor_through_tabs('string')
		end
		assert_match('expected true/false', e.message)
		assert_match('but got String', e.message)
	end
	def xtest_set_lexer_illegal1 # TODO: compare against builtin lexers
		e = assert_raises(ArgumentError) { @dummy_mode.set_lexer('perl') }
		# TODO: actually its better with a warning in this case
		assert_match('expected name of a builtin lexer', e.message)
		assert_match('but got perl', e.message)
	end
	def test_theme1
		theme :morning do |t|
			t.set_rgb_pair :keyword, [66, 6, 66], [99, 9, 99] 
			# override the first set_rgb_pair :keyword
			t.set_rgb_pair 'keyword', [255, 0, 255], [0, 255, 0]
		end
		e = Theme.new('morning')
		e.set_rgb_pair(:keyword, [255, 0, 255], [0, 255, 0])
		assert_equal([e], @themes)
		ne = Theme.new('morning')
		ne.set_rgb_pair(:keywordz, [33, 0, 255], [0, 255, 0])
		assert_not_equal([ne], @themes)
	end
	def test_set_rgb_pair_illegal1
		e = assert_raises(TypeError) do
			@dummy_theme.set_rgb_pair(33, [0, 0, 0], [0, 0, 0])
		end
		assert_match(/expected.*?Symbol.*?but got/, e.message)
		assert_match(/expected.*?String.*?but got/, e.message)
		assert_match(/but got Fixnum/, e.message)
	end
	def test_set_rgb_pair_illegal2
		e = assert_raises(TypeError) do
			@dummy_theme.set_rgb_pair(:keyword, :bad, [0, 0, 0])
		end
		assert_match(/expected background.*?Array of integers/, e.message)
		assert_match(/but got Symbol/, e.message)
	end
	def test_set_rgb_pair_illegal3
		e = assert_raises(TypeError) do
			@dummy_theme.set_rgb_pair(:keyword, [0, 0, 3.3], [0, 0, 0])
		end
		assert_match(/expected background.*?Array of integers/, e.message)
		assert_match(/but the array contained a Float/, e.message)
	end
	def test_set_rgb_pair_illegal4
		e = assert_raises(ArgumentError) do
			@dummy_theme.set_rgb_pair(:keyword, [255, 0, 0], [0, 256, 0])
		end
		assert_match(/expected foreground.*?Array of integers/, e.message)
		assert_match(/in the range 0\.\.255/, e.message)
		assert_match(/but got a value.*?outside that range/, e.message)
	end
end
