# purpose:
# the frontend delivers a KeyEvent to the core when a
# key is pressed.
#
# functions:
# * @key, tells which key were pressed.
# * @modifiers, tells which modifiers were used (SHIFT|ALT|CTRL).
# * @ascii, tells the text-string it corresponds to.
#
# issues:
# * KEY_UNKNOWN is used when there isn't any appropriate keysym.
# * @ascii is nil, when the keyevent doesn't carry text-data.
#
# todo:
# * UCS-4 instead of ascii.
class KeyEvent
	module Key
		# generate all necessary keysym's constants
		class Generator
			def build
				@count = 0
				@result = ""
				id_join(key, "KEY_")
				@result
			end
			def key_fun
				(1..24).to_a.map{|i| "F#{i}"}
			end
			def key_alpha
				('A'..'Z').to_a.map{|i| "#{i}"}
			end
			def key_numeric
				('0'..'9').to_a.map{|i| "#{i}"}
			end
			def key_movement
				%w(UP DOWN LEFT RIGHT PAGE_UP PAGE_DOWN HOME END)
			end
			def key_ascii
				# ascii 9, 10
				%w(TAB NEWLINE) +
				# ascii 32..39
				%w(SPACE EXCLAIM QUOTE2 HASH DOLLAR PERCENT AMPERSAND QUOTE) +
				# ascii 40..47
				%w(LPARAN RPARAN ASTERISK PLUS COMMA MINUS PERIOD SLASH) +
				# ascii 58..64
				%w(COLON SEMICOLON LESS EQUAL GREATER QUESTION AT) +
				# ascii 91..96
				%w(LBRACKET BACKSLASH RBRACKET CARET UNDERSCORE BACKQUOTE) +
				# ascii 123..126
				%w(LCURLY PIPE RCURLY TILDE)
			end
			def key_others
				%w(UNKNOWN INSERT ESCAPE DELETE BACKSPACE)
			end
			def key
				key_others + key_fun + key_alpha +
				key_numeric + key_movement + key_ascii
			end
			def id_join(names, prefix)
				names.each{|name|
					@result << "#{prefix}#{name} = #{@count}\n" if name
					@count += 1
				}
			end
		end
		module_eval(Generator.new.build)
	end
	module Modifier
		SHIFT = 1
		ALT   = 2
		CTRL  = 4
	end

	def initialize(key, ascii, mod)
		@key = key
		@ascii = ascii
		@modifiers = mod
	end
	attr_reader :key, :ascii, :modifiers
	def shift
		(@modifiers & Modifier::SHIFT) != 0
	end
	def alt
		(@modifiers & Modifier::ALT) != 0
	end
	def ctrl
		(@modifiers & Modifier::CTRL) != 0
	end
	def inspect
		mod = []
		mod << "SHIFT" if shift
		mod << "ALT"   if alt
		mod << "CTRL"  if ctrl
		s = mod.empty? ? "0" : mod.join("|")
		"KEY=#{@key}, MOD=#{s}, ASCII=#{@ascii.inspect}"
	end
end

module WindowEventConstants
	WIN_RESIZE     = 1
	WIN_GOT_FOCUS  = 2 
	WIN_LOST_FOCUS = 3 
	WIN_ICONIFY    = 4
	WIN_DEICONIFY  = 5
end
