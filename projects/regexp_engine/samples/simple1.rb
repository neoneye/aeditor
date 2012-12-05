require 'regexp'
re = NewRegexp.new("a(.{4,})b(.+)c")
p re.match("0a1b2a3b4b5c6c7").to_a #-> ["a1b2a3b4b5c6c", "1b2a3b4", "5c6"]
