class Fixnum
	def bits
		(self.size * 8 - 1).downto(0) do |i|
			return (i+1) if self[i] == 1
		end
		return 0
	end
end
