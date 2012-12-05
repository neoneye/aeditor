# running all the 1560 rubicon tests takes about 
# 12 seconds on Simon's 700 MHz pentium2
require 'common'
require 'blackbox_rubicon'
require 'timeout'

class TestBlackboxRubicon < Common::TestCase
	def execute_regex(pattern, subject)
		match = nil
		timeout(2.75) do
			match = Scanner.execute(pattern, subject)
		end
		return nil unless match
		match.to_a
	rescue TimeoutError
		raise RegexpError, "operation timed out!"
	end
	def rubicon_skip?(lineno)
		if (lineno % 20) == 0
			print(".") 
			$stdout.flush
		end
		[   
			# often GNU wipes sub-captures, typically with kleene star
			114, 125, 127, 129,
			132, 133, 190, 519,
			529, 551, 552, 553,
			554, 555, 556, 607,

			# GNU special, charclass and extra ']'
			292, 296, 297, 839,
			840, 844, 845, 872,
			1196, 1197, 1202, 1203,

			# misc
			365,  # posix comment cannot repeat
			1024, # posix comment cannot repeat
			269,  # different scoping rules for options (ignorecase)
			970,  # GNU doesn't support captures inside lookahead.. mine does
			1086  # probably bug in rubicon
		].member?(lineno)
	end
	include BlackboxRubicon
end

TestBlackboxRubicon.run if $0 == __FILE__
