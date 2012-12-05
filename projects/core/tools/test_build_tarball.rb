require 'build_tarball'
require 'runit/testcase'
require 'runit/assert'
require 'runit/cui/testrunner'

class TestBuildTarball < RUNIT::TestCase 
	def test_is_release_file
		data = [
			".bad.rb",
			".#buffer.rb.1.23",
			"ok.rb",
			"ok_ok.rb",
			".#4bad.rb.32",
			"otherb",
			".bad.rrb"
		]
		keep, kill = data.partition { |f| is_release_file?(f) }
		# result should be ALL those entries containing OK
		assert_equal(["ok.rb", "ok_ok.rb"], keep)
	end
end

if $0 == __FILE__
	RUNIT::CUI::TestRunner.run(TestBuildTarball.suite)
end
