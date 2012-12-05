module BlackboxRubicon
	def execute_regex(pattern, subject)
		raise "must overload me, before usage"
	end
	def make_result(registers, repl)
		s = repl.clone
		reg = registers
		reg.map!{|i| i || ""}
		reg.fill("", reg.size..12)
		s.gsub!(/([^\\])\\\#\{\$&\}/, '\1REG0')  # hack to find slash prefixes
		s.gsub!(/([^\\])\\\#\{\$1\}/, '\1REG1')  # hack to find slash prefixes
		s.gsub!(/\#\{\$&\}/, reg[0])
		1.upto(10){|i| s.gsub!(/#\{\$#{i}\}/, reg[i]) }
		s.gsub!(/\\\\/, '\\')
		s.gsub!(/REG0/, '#{$&}')  # hack to replace slash prefixes
		s.gsub!(/REG1/, '#{$1}')  # hack to replace slash prefixes
		s
	end
	def rubicon_skip?(lineno)
		false
	end
	def test_rubicon
		# we not interested in text after null, see http://ruby-talk.org/97426
		our_name = $0.match(/^.*?(?=\000|$)/).to_s
		start = File.dirname(our_name)
		file_name = nil
		for base in [".", "language"]
			file_name = File.join(start, base, 'blackbox_rubicon_data')
			break if File.exist? file_name
			file_name = nil
		end

		fail("Could not find file containing regular expression tests") unless file_name

		errors = []
		good = []
		skipped = 0

		lineno =  0
		IO.foreach(file_name) do |line|
			lineno += 1
			if rubicon_skip?(lineno)
				skipped += 1
				next 
			end
			line.sub!(/\r?\n\z/, '')
			next if /^#/ =~ line || /^$/ =~ line
			pat, subject, result, repl, expect = line.split(/\t/, 6)

			# TODO: should this line be here?
			next if result == 'c'

			for mes in [subject, expect]
				if mes
					mes.gsub!(/\\n/, "\n")
					mes.gsub!(/\\000/, "\0")
					mes.gsub!(/\\255/, "\255")
				end
			end
        
			reg = nil
			begin
				reg = execute_regex(pat, subject)
			rescue RegexpError => detail
				if result != 'c'
					errors << [lineno, 
						"expected '#{expect}', " +
						"got error='#{detail.to_s}'"]
					next
				end
				if detail.to_s != expect
					errors << [lineno, "expected error " + 
						"'#{expect}', got '#{detail.to_s}'"]
					next
				end
				good << lineno
				next
			rescue => detail
				errors << [lineno, detail.inspect]
				next
			end
			case result
			when 'y'
				if reg == nil
					errors << [lineno, 
						"expected '#{expect}', " + 
						"got 'nil', " +
						"repl='#{repl}'"
					]
					next
				end
				if repl != '-'
					got = make_result(reg, repl)
					if expect != got
						errors << [lineno, 
							"expected '#{expect}', " + 
							"got '#{got}', " +
							"repl='#{repl}'"
						]
						next
					end
				end
				good << lineno
			when 'n'
				if reg != nil
					errors << [lineno, 
						"expected 'nil', got '#{reg}'"]
					next
				end
				good << lineno
			when 'c'
				errors << [lineno, "'#{line}' should not have compiled"]
				next
			end
		end
		#puts "passed testcases: " + good.join(", ")
		gs = good.size
		es = errors.size
		percent = (gs*100).to_f / (gs+es+skipped).to_f
		msg = "pass=#{gs}, fail=#{es}, skipped=#{skipped},  pass/total=#{percent}"
		assert_equal([], errors, msg)
	end
end # module BlackboxRubicon
