# string can span multiple lines
p "im line one\
im line two"

p "im line tree
im line four"

# % can be followed by (<[{ then it balances with }]>)
p %{im line one {
} im line two}

# % can be followed by any letter
p %|a|, %.b., %%c%, %?d?, %,e,, %'f#{2}'
p %.this is a short story.

# %q without quotes are also possible
p %q hello ;

# %q counts parentesis
p %q(()), %q(()(())(()())), ')', '('

# interpolate
p "#{
42
}" # multiline interpolation!

p "a#{'}'}b"
p "a#{'"'}b"          # "'
p "a#{'"b"'}c"        # "'
p "a#{'"}"'}b"        # "'
p "a#{"#{'b'}"}c"     # "'
eval "p#{"#{' '}"}42" # "'
