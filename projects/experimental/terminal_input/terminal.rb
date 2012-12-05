require 'event'

# purpose:
# base class for all termcap classes
class Termcap
	def initialize(seq_key)
		@seq_key = seq_key
	end
	attr_reader :seq_key
end

# purpose:
# build one gigantic hash-table which translates 
# from XTerm-escape-sequences into AEditor-events.
class TermcapXTerm < Termcap
	include KeyEvent::Key
	include KeyEvent::Modifier
	def initialize
		ary = [build_misc, build_alpha, 
			build_numeric]
		seq_key = ary.inject({}){|i, v| v.merge(i)}
		fill_ascii_unknown(seq_key)
		super(seq_key)
	end
	def fill_ascii_unknown(hash)
		32.upto(126) do |i|
			key = hash[i.chr]
			unless key
				hash[i.chr] = KeyEvent.new(KEY_UNKNOWN, i.chr, 0)
			end
		end
	end
	def build_alpha
		res = {}
		# 97-122 normal
		('a'..'z').to_a.each{|i|
			key = eval("KEY_#{i.upcase}")
			res[i] = KeyEvent.new(key, i, 0)
		}
		# 65-90 shift
		('A'..'Z').to_a.each{|i|
			key = eval("KEY_#{i}")
			res[i] = KeyEvent.new(key, i, SHIFT)
		}
		# 225-250 alt
		('A'..'Z').to_a.each{|i|
			key = eval("KEY_#{i}")
			ascii = (i[0] - 'A'[0]) + 225
			res[ascii.chr] = KeyEvent.new(key, nil, ALT)
		}
		# 193-218 shift|alt
		('A'..'Z').to_a.each{|i|
			key = eval("KEY_#{i}")
			ascii = (i[0] - 'A'[0]) + 193
			res[ascii.chr] = KeyEvent.new(key, nil, SHIFT|ALT)
		}
		# 1-26 ctrl
		('A'..'Z').to_a.each{|i|
			key = eval("KEY_#{i}")
			ascii = (i[0] - 'A'[0]) + 1
			res[ascii.chr] = KeyEvent.new(key, nil, CTRL)
		}
		res[0.chr] = KeyEvent.new(KEY_SPACE, nil, CTRL) 
		res[9.chr] = KeyEvent.new(KEY_TAB, 9.chr, 0) 
		res[10.chr] = KeyEvent.new(KEY_NEWLINE, 10.chr, 0) 
		res[32.chr] = KeyEvent.new(KEY_SPACE, 32.chr, 0) 
		# 129-154 alt|ctrl
		('A'..'Z').to_a.each{|i|
			key = eval("KEY_#{i}")
			ascii = (i[0] - 'A'[0]) + 129
			res[ascii.chr] = KeyEvent.new(key, nil, ALT|CTRL)
		}
		res
	end
	def build_numeric
		res = {}
		# 48-57 normal
		('0'..'9').to_a.each{|i|
			key = eval("KEY_#{i}")
			res[i] = KeyEvent.new(key, i, 0)
		}
		# 176-185 alt
		('0'..'9').to_a.each{|i|
			key = eval("KEY_#{i}")
			ascii = (i[0] - '0'[0]) + 176
			res[ascii.chr] = KeyEvent.new(key, nil, ALT)
		}
		res
	end
	def make_key(key, mod) 
		KeyEvent.new(key, nil, mod)
	end
	def build_misc
		res = {}
		build_misc_data.each do |key, val|
			norm, s, a, s_a, c, s_c, a_c, s_a_c = val
			res[norm]  = make_key(key, 0) if norm
			res[s]     = make_key(key, SHIFT) if s
			res[a]     = make_key(key, ALT) if a
			res[s_a]   = make_key(key, SHIFT|ALT) if s_a
			res[c]     = make_key(key, CTRL) if c
			res[s_c]   = make_key(key, SHIFT|CTRL) if s_c
			res[a_c]   = make_key(key, ALT|CTRL) if a_c
			res[s_a_c] = make_key(key, SHIFT|ALT|CTRL) if s_a_c
		end
		res
	end
	def build_misc_data
		{
			# f1 - f12
			KEY_F1  => ["\eOP",   "\eO2P"],
			KEY_F2  => ["\eOQ",   "\eO2Q"], 
			KEY_F3  => ["\eOR",   "\eO2R"],
			KEY_F4  => ["\eOS",   "\eO2S"],
			KEY_F5  => esc2('15'),
			KEY_F6  => esc2('17'),
			KEY_F7  => esc2('18'),
			KEY_F8  => esc2('19'),
			KEY_F9  => esc2('20'),
			KEY_F10 => esc2('21'),
			KEY_F11 => esc2('23'),
			KEY_F12 => esc2('24'),
			# movement
			KEY_UP    => esc1('A'),
			KEY_DOWN  => esc1('B'), 
			KEY_RIGHT => esc1('C'), 
			KEY_LEFT  => esc1('D'), 
			KEY_PAGE_UP   => esc2('5'),
			KEY_PAGE_DOWN => esc2('6'),
			KEY_HOME  => esc1('H'),
			KEY_END   => esc1('F'),
			# others
			KEY_INSERT => esc2('2'),
			KEY_DELETE => esc2('3'),
			KEY_TAB => [nil, "\e[Z"],
		}
	end
	# xterm id-numbers used in escape-sequences
	# 1 = normal (no modifiers)
	# 2 = shift 
	# 3 = alt
	# 4 = shift+alt
	# 5 = ctrl
	# 6 = shift+ctrl
	# 7 = alt+ctrl
	# 8 = shift+alt+ctrl
	def esc1(code)
		["\e[#{code}", "\e[2#{code}", "\e[3#{code}", "\e[4#{code}", 
			"\e[5#{code}", "\e[6#{code}", "\e[7#{code}", "\e[8#{code}"] 
	end
	def esc2(code)
		["\e[#{code}~", "\e[#{code};2~", "\e[#{code};3~", 
			"\e[#{code};4~", "\e[#{code};5~", "\e[#{code};6~", 
			"\e[#{code};7~", "\e[#{code};8~"] 
	end
end
