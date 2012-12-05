unless defined?($logger)
	class MockLogger
		def debug(code=nil, &block)
			#puts block.call
		end
	end
	$logger = MockLogger.new
end

require 'test/unit'