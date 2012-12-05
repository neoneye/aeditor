require 'terminal'
require 'runit/testcase'
require 'runit/assert'
require 'runit/cui/testrunner'

class TestTerminal < RUNIT::TestCase 
	include KeyEvent::Key
	include KeyEvent::Modifier
	def test_xterm1
		data = [
			"a", [KEY_A, 0],
			"z", [KEY_Z, 0],
			"A", [KEY_A, SHIFT],
			"Z", [KEY_Z, SHIFT],
			0.chr, [KEY_SPACE, CTRL],
			1.chr, [KEY_A, CTRL],
			8.chr, [KEY_H, CTRL], # or [KEY_BACKSPACE, SHIFT]
			9.chr, [KEY_TAB, 0],
			10.chr, [KEY_NEWLINE, 0],
			26.chr, [KEY_Z, CTRL],
			32.chr, [KEY_SPACE, 0],
			129.chr, [KEY_A, ALT|CTRL],
			136.chr, [KEY_H, ALT|CTRL], # or [KEY_BACKSPACE, ALT]
			141.chr, [KEY_M, ALT|CTRL], # or [KEY_NEWLINE, ALT]
			154.chr, [KEY_Z, ALT|CTRL],
			176.chr, [KEY_0, ALT],
			185.chr, [KEY_9, ALT],
			193.chr, [KEY_A, SHIFT|ALT],
			218.chr, [KEY_Z, SHIFT|ALT],
			225.chr, [KEY_A, ALT],
			240.chr, [KEY_P, ALT], # or [KEY_SPACE, ALT]
			250.chr, [KEY_Z, ALT],
			"0", [KEY_0, 0],
			"9", [KEY_9, 0],
			33.chr, [KEY_UNKNOWN, 0],
			126.chr, [KEY_UNKNOWN, 0],
			"\e[15~", [KEY_F5, 0],
			"\e[A",   [KEY_UP, 0],
			"\e[6B",  [KEY_DOWN, SHIFT|CTRL],
			"\e[3C",  [KEY_RIGHT, ALT],
			"\e[3;8~", [KEY_DELETE, SHIFT|ALT|CTRL],
			"\e[Z", [KEY_TAB, SHIFT], 
		]
		term = TermcapXTerm.new
		errors = []
		index = 0
		while data.size > 1
			seq, expected_data = data.slice!(0, 2)
			event = term.seq_key[seq]
			if (event == nil) or (event.kind_of?(KeyEvent) == false)
				str = (event != nil) ? event.inspect : "<nil>"
				errors << <<MSG
INDEX##{index}:  expected class=KeyEvent, got class=#{str}
MSG
			else
				e_key, e_mod = expected_data
				if event.key != e_key
					errors << <<MSG
INDEX##{index}:  expected KEY=#{e_key}, got KEY=#{event.key}
MSG
				end
				if event.modifiers != e_mod
					errors << <<MSG
INDEX##{index}:  expected MOD=#{e_mod}, got MOD=#{event.modifiers}
MSG
				end
			end
			index += 1
		end
		assert_equal([], errors)
	end
end

if $0 == __FILE__
	RUNIT::CUI::TestRunner.run(TestTerminal.suite)
end
