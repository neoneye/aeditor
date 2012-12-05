require 'regexp/scanner'

class String
	def mk_scanner(pattern)
		return pattern.scanner if pattern.kind_of?(NewRegexp)
		return NewRegexp.new(pattern).scanner if pattern.kind_of?(String)
		return NewRegexp.new(pattern.to_s).scanner if pattern.respond_to?(:to_s)
		raise TypeError, "expected String or NewRegexp, but got #{pattern.class}" 
	end
	private :mk_scanner
	def gsub5(pattern, replacement=nil, &block)
		mk_scanner(pattern).gsub_string!(self.clone, nil, nil, replacement, &block)
	end
	def gsub5!(pattern, replacement=nil, &block)
		mk_scanner(pattern).gsub_string!(self, nil, nil, replacement, &block)
	end
	def sub5(pattern, replacement=nil, &block)
		mk_scanner(pattern).gsub_string!(self.clone, nil, 1, replacement, &block)
	end
	def sub5!(pattern, replacement=nil, &block)
		mk_scanner(pattern).gsub_string!(self, nil, 1, replacement, &block)
	end
	def split5(pattern, limit=nil)
		mk_scanner(pattern).split_string(self, nil, limit)
	end
	def scan5(pattern, &block)
		mk_scanner(pattern).scan_string(self, nil, &block)
	end
	def match5(pattern)
		mk_scanner(pattern).match_string(self)
	end
end

# TODO: maybe install regexp methods in Kernel as well ?

class Regexp
	def tree
		NewRegexp.new(source).tree
	end
end