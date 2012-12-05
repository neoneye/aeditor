# harmless exceptions
class CommandHarmless < StandardError; end
class BufferTop < CommandHarmless; end
class BufferBottom < CommandHarmless; end
class BufferLeft < CommandHarmless; end  

# exceptions which is not harmless
class FoldTagbeginMissing < StandardError; end
class FoldTagendMissing < StandardError; end
