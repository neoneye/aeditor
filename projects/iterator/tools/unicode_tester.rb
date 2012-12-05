# Convert Codepoint first to UTF-8.. then to UTF-16
# depends on 'libiconv'
#
def str_bytes_hex(str)
	dec = str.unpack('C*')
	hex = dec.map{|i| i.chr.unpack('H*')[0]}.join("-")
	"str=#{str.inspect.ljust(20)} dec=#{dec.inspect.ljust(20)} hex=<#{hex}>"
end

def convert(input)
	before = input.pack('U*')
	File.open("data", "w+") {|f| f.write(before)}
	system('iconv -s -f UTF-8 -t UTF-16BE data > res')
	after = nil
	File.open("res", "r") {|f| after=f.read}
	input_hex = input.map{|i| "%x" % i }.join("-")
	puts <<MSG
---------------------  -----------------------------------------------------------
  input codepoint      #{input.inspect}  <#{input_hex}>
  before (UTF-8)       #{str_bytes_hex(before)}
  after  (UTF-16)      #{str_bytes_hex(after)}
MSG
end

inputs = [
	[0xd7ff],
	[0xd800], [0xdbff], [0xdc00], [0xdfff],  # all outputs  0xfffd
	[0xe000],
	[0xfffd],
	[0xfffe],
	[0xffff],
	[0x10000], # output surrogates
].each {|input| convert(input) }
