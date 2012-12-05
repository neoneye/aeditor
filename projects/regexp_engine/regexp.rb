require 'regexp/interface'

module AE
	VERSION = '0.12'
end # module AE

if __FILE__ == $0
	puts <<MSG
This is package is Regexp-#{AE::VERSION}, which can help
you searching for advanced text-patterns.
See 'samples/' for usage.
MSG
end