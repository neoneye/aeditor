require 'test/unit'

class String
	def scan_index(regexp)
		pairs = []
		self.scan(regexp) do
			pairs << [$~.begin(0), $~.end(0)]
		end
		pairs
	end 
end

class RubyLexer
	def initialize
		@number = []
		@punct = []
		@ident = []
		@string = []
		@comment = []
	end
	attr_reader :number, :punct, :ident, :string, :comment
	PUNCT = ['(', ')'] + 
		%w(=== ==  =~  =>  =   !=  !~  !) +
		%w(<<  <=> <=  <   >=  >) +
		%w({   }   [   ]) +
		%w(::  :   ... ..) +
		%w(+=  +   -=  -   **  *   /   %) +
		%w(||  |   &&  &) +
		%w(,   ;) 
	RE_NUMBER = /\d[\d\.]*/
	RE_PUNCT = Regexp.new('(?:' + 
		PUNCT.map{|i| Regexp.escape(i)}.join('|') + ')')
	RE_IDENT = /[[:alpha:]][\w]*/
	RE_STRING = /".*?"|'.*?'/
	RE_COMMENT = /#.*/
	RE_COMMAND = /\.[[:alnum:]_]*[[:alnum:]_\?\!]/
	def lex(string)
		@number = string.scan_index(RE_NUMBER)
		@punct = string.scan_index(RE_PUNCT)
		@ident = string.scan_index(RE_IDENT)
		@string = string.scan_index(RE_STRING)
		@comment = string.scan_index(RE_COMMENT)
		@command = string.scan_index(RE_COMMAND)
	end
	def result
		result = []
		# primary key = string begin position
		# secondary key = priority
		@comment.each {|i1, i2| result << [i1, 0, i2, :comment] }
		@string.each {|i1, i2| result << [i1, 1, i2, :string] }
		@command.each {|i1, i2| result << [i1, 2, i2, :command] }
		@ident.each {|i1, i2| result << [i1, 3, i2, :ident] }
		@number.each {|i1, i2| result << [i1, 4, i2, :number] }
		@punct.each {|i1, i2| result << [i1, 5, i2, :punct] }
		result.sort!
		# collect the highest precedens data
		ary = [0]
		result.each do |i1, prio, i2, symbol|
			next if ary.last > i1 # discard low precedens data
			if ary.last < i1
				ary << :space
				ary << i1
			end
			ary << symbol
			ary << i2
		end
		ary
	end
end

class TestRubyLexer < Test::Unit::TestCase
	def lex(string)
		lexer = RubyLexer.new
		lexer.lex(string)
		lexer
	end
	def test_normal1
		l = lex('0.5*a*a+0.7*b-42')
		assert_equal([[0, 3], [8, 11], [14, 16]], l.number)
		assert_equal([[3, 4], [5, 6], [7, 8], [11, 12], [13, 14]], l.punct)
		assert_equal([[4, 5], [6, 7], [12, 13]], l.ident)
		assert_equal([0, :number, 3, :punct, 4, :ident, 5, :punct, 
			6, :ident, 7, :punct, 8, :number, 11, :punct, 12, :ident, 
			13, :punct, 14, :number, 16], l.result)
	end
	def test_normal2
		l = lex('"def" + \'end\' ### ugh ###')
		assert_equal([[0, 5], [8, 13]], l.string)
		assert_equal([[1, 4], [9, 12], [18, 21]], l.ident)
		assert_equal([[6, 7]], l.punct)
		assert_equal([[14, 25]], l.comment)
		assert_equal([0, :string, 5, :space, 6, :punct, 7, :space, 
			8, :string, 13, :space, 14, :comment, 25], l.result)
	end
	def test_normal3
		l = lex('def dont3; sender(666); end')
		assert_equal([[0, 3], [4, 9], [11, 17], [24, 27]], l.ident)
		assert_equal([[9, 10], [17, 18], [21, 22], [22, 23]], l.punct)
		assert_equal([[8, 9], [18, 21]], l.number)
		assert_equal([0, :ident, 3, :space, 4, :ident, 9, :punct, 
			10, :space, 11, :ident, 17, :punct, 18, :number, 21, :punct,
			22, :punct, 23, :space, 24, :ident, 27], l.result)
	end
	def test_normal4
		l = lex('str3 = str2.upcase.reverse')
		assert_equal([[0, 4], [7, 11], [12, 18], [19, 26]], l.ident)
		assert_equal([[5, 6]], l.punct)
		assert_equal([[3, 4], [10, 12]], l.number)
		assert_equal([0, :ident, 4, :space, 5, :punct, 6, :space, 
			7, :ident, 11, :command, 18, :command, 26], l.result)
	end
end






