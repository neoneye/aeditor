BEGIN {
	require 'logger'
	$logger = Logger.new('aeditor-test.log')
	$logger.level = Logger::DEBUG
}


require 'test/unit'

class Test::Unit::TestCase
	def setup
		$logger.info "setup #{self.name}"
	end
	def teardown
		$logger.info "teardown #{self.name}"
	end
end

module UTF8WideGlyphs
	def self.wide(code)
		[code].pack("U*")
	end
	IDEOGRAPHIC_SPACE = wide(0x3000)
	IDEOGRAPHIC_FULL_STOP = wide(0x3002)
	DITTO_MARK = wide(0x3003)
	LEFT_ANGLE_BRACKET = wide(0x3008)
	WAVE_DASH = wide(0x301c)
	FULLWIDTH_EXCLAMATION_MARK = wide(0xff01)
	FULLWIDTH_NUMBER_SIGN = wide(0xff03)
	FULLWIDTH_SOLIDUS = wide(0xff0f)
	FULLWIDTH_QUESTION_MARK = wide(0xff1f)
	NEONEYE = [0xff2e, 0xff25, 0xff2f, 
		0xff2e, 0xff25, 0xff39, 0xff25].pack("U*")
end
