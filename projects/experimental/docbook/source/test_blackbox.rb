require 'test/unit'

module AbstractSyntax

class Base
end

class Section < Base
end

class Para < Base
end

end # module AbstractSyntax

class TestBlackbox < Test::Unit::TestCase
	def parse(docbook_str)
		p docbook_str
	end
	def test_section1
		docbook = "<section><title>Title</title><para>" +
			"Im a para.</para></section>"
		html = "<h2>Title</h2><p>Im a para.</p>"
		parse(docbook)
	end
end # class TestBlackbox