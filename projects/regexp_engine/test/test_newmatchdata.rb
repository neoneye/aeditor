require "common"

class XTestNewMatchData < Common::TestCase
   def assert_regex(expected_match_array, expected_prematch, expected_postmatch, string, positions, message=nil)
      result = NewMatchData.new(string, positions)
      n_ok = true
      n_ok = false unless result.pre_match == expected_prematch
      n_ok = false unless result.to_a == expected_match_array
      n_ok = false unless result.post_match == expected_postmatch

      expected = "#{expected_match_array.inspect};#{expected_prematch};#{expected_postmatch}"
      actual = "#{result.to_a.inspect};#{result.pre_match};#{result.post_match}"

      full_message = build_message(message, expected, actual) do |expected, actual| 
         "#{expected} expected but was #{actual}"
      end

      assert_block(full_message) {n_ok}    
   end

   def test_newmatchdata1()
       assert_regex([""], "", "1234567890", "1234567890", [[0, 0]])  
   end
   def test_newmatchdata2()
       assert_regex(["1234"], "", "567890", "1234567890", [[0, 4]])  
   end
   def test_newmatchdata3()
       assert_regex(["345"], "12", "67890", "1234567890", [[2, 5]])  
   end
   def test_newmatchdata4()
       assert_regex(["34567", "56"], "12", "890", "1234567890", [[2, 7], [4,6]])  
   end
   def test_newmatchdata5()
       assert_regex(["34567", "4", "7"], "12", "890", "1234567890", [[2, 7], [3, 4], [6, 7]])  
   end
   def test_newmatchdata6()
       assert_regex(["34567", "4567", "7"], "12", "890", "1234567890", [[2, 7], [3, 7], [6, 7]])  
   end

end

XTestNewMatchData.run if $0 == __FILE__
