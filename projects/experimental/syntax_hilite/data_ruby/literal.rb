p <<A, %w(a), <<B, "str", %(lit1\)
heredocA
A
heredocB
B
lit2
lit3(lit4)lit5)


# you can have options on %r{} literals.
p %r{a b}x.source