module Match
	class Include
		def initialize(*symbols); @symbols = symbols end
		def is_member?(symbol); @symbols.include?(symbol) end
		attr_reader :symbols
		def ==(other)
			return false if other.class != self.class
			symbols == other.symbols
		end
		def inspect; "<" + @symbols.join + ">" end
	end
	class Exclude
		def initialize(*symbols); @symbols = symbols end
		def is_member?(symbol)
			return true unless symbol
			not @symbols.include?(symbol) 
		end
		attr_reader :symbols
		def ==(other)
			return false if other.class != self.class
			symbols == other.symbols
		end
		def inspect; "<^" + @symbols.join + ">" end
	end
end
