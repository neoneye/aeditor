require 'aeditor/backend/history'
require 'common'

class TestHistory < Common::TestCase 
	# originator
	class FakeOriginator
		def initialize
			@x = 0
			@y = 0
		end
		attr_reader :x, :y
		def setx(x); @x = x end
		def sety(y); @y = y end

		def create_memento
			[@x, @y]
		end
		def set_memento(mem)
			setx(mem[0])
			sety(mem[1])
		end
	end

	# originator
	class FakeCommandX < Command
		def initialize(x)
			@x = x
		end
		def execute(buffer)
			buffer.setx(@x)
			false  # should not have any effect
		end
		def create_memento(buffer)
			buffer.x
		end
		def set_memento(buffer, mem)
			buffer.setx(mem)
		end
	end

	# originator
	class FakeCommandBad < Command
		def initialize
		end
		def execute(buffer)
			raise "what happens if exception?"
		end
	end

	class FakeOriginatorBig
		def initialize
			@left = []
			@right = []
			@no_harm = false
		end
		def set_harm
			@no_harm = true
		end
		attr_reader :left, :right, :no_harm
		def push_left(data); @left.push(data) end
		def push_right(data); @right.push(data) end

		def create_memento
			[@left.size, @left+@right]
		end
		def set_memento(mem)
			x, @right = mem
			@left = @right.slice!(0, x)
		end
	end

	class FakeCommandBig < Command
		def initialize(l, r)
			@left = l
			@right = r
		end
		def execute(buffer)
			buffer.push_left(@left) if @left
			buffer.push_right(@right) if @right
			false # should not have any effect
		end
	end
	class FakeCommandOptionalFailure < Command
		def initialize(l, r)
			@left = l
			@right = r
		end
		def execute(buffer)
			raise CommandHarmless if buffer.no_harm
			buffer.push_left(@left) if @left
			buffer.push_right(@right) if @right
		end
	end

	class FakeCaretaker < Caretaker
		attr_reader :undo, :redo, :macro_size
	end
	def test_execute1
		m = FakeOriginator.new
		ct = FakeCaretaker.new(m)
		cmd1 = FakeCommandX.new(3)
		ct.execute(cmd1)
		assert_equal([3, 0], m.create_memento)
		assert_equal(1, ct.undo.size)
		assert_equal([], ct.redo)
	end
	def test_execute2
		m = FakeOriginator.new
		ct = FakeCaretaker.new(m)
		cmd1 = FakeCommandX.new(3)
		ct.execute(cmd1)
		ct.execute_undo
		cmd2 = FakeCommandBad.new   # see if we can deal with failure
		assert_raises(RuntimeError) { ct.execute(cmd2) }
		assert_equal([0, 0], m.create_memento)
		assert_equal([], ct.undo)
		assert_equal(1, ct.redo.size)
	end
	def test_undo1
		m = FakeOriginator.new
		ct = FakeCaretaker.new(m)
		cmd1 = FakeCommandX.new(3)
		ct.execute(cmd1)
		ct.execute_undo
		assert_equal([0, 0], m.create_memento)
		assert_equal([], ct.undo)
		assert_equal(1, ct.redo.size)
	end
	def test_undo2
		m = FakeOriginator.new
		ct = FakeCaretaker.new(m)
		cmd1 = FakeCommandX.new(3)
		cmd2 = FakeCommandX.new(5)
		ct.execute(cmd1)
		ct.execute(cmd2)
		ct.execute_undo
		assert_equal([3, 0], m.create_memento)
		assert_equal(1, ct.undo.size)
		assert_equal(1, ct.redo.size)
		ct.execute_undo
		assert_equal([0, 0], m.create_memento)
		assert_equal([], ct.undo)
		assert_equal(2, ct.redo.size)
	end
	def test_undo3
		m = FakeOriginator.new
		ct = FakeCaretaker.new(m)
		cmd1 = FakeCommandX.new(3)
		cmd2 = FakeCommandX.new(5)
		ct.execute(cmd1)
		ct.execute_undo  # see if we clear redo data correct
		ct.execute(cmd2)
		assert_equal([5, 0], m.create_memento)
		assert_equal(1, ct.undo.size)
		assert_equal([], ct.redo)
	end
	def test_undo4
		m = FakeOriginator.new
		ct = FakeCaretaker.new(m)
		cmd = Command.new
		class << cmd
			def execute(buffer)
				true
			end
			def execute_undo(parent, memento)
				super(parent, [123, 456])
			end
		end
		ct.execute(cmd)
		ct.execute_undo  # see if #undo is invoked correct
		assert_equal([123, 456], m.create_memento)
	end
	def test_undo_error1
		m = FakeOriginator.new
		ct = FakeCaretaker.new(m)
		assert_raises(FakeCaretaker::Nothing2Undo) { ct.execute_undo }
	end
	def test_undo_error2
		m = FakeOriginator.new
		ct = FakeCaretaker.new(m)
		cmd1 = FakeCommandX.new(3)
		ct.execute(cmd1)
		ct.execute_undo
		assert_raises(FakeCaretaker::Nothing2Undo) { ct.execute_undo }
	end
	def test_redo1
		m = FakeOriginator.new
		ct = FakeCaretaker.new(m)
		cmd1 = FakeCommandX.new(3)
		ct.execute(cmd1)
		ct.execute_undo
		ct.execute_redo
		assert_equal([3, 0], m.create_memento)
		assert_equal(1, ct.undo.size)
		assert_equal([], ct.redo)
	end
	def test_redo2
		m = FakeOriginator.new
		ct = FakeCaretaker.new(m)
		cmd1 = FakeCommandX.new(3)
		cmd2 = FakeCommandX.new(5)
		ct.execute(cmd1)
		ct.execute(cmd2)
		ct.execute_undo
		ct.execute_undo
		ct.execute_redo
		assert_equal([3, 0], m.create_memento)
		assert_equal(1, ct.undo.size)
		assert_equal(1, ct.redo.size)
	end
	def test_redo3
		m = FakeOriginator.new
		ct = FakeCaretaker.new(m)
		cmd = Command.new
		class << cmd
			def execute(buffer)
				true
			end
			def execute_redo(parent)
				set_memento(parent, [123, 456])
			end
		end
		ct.execute(cmd)
		ct.execute_undo 
		ct.execute_redo  # see if #undo is invoked correct
		assert_equal([123, 456], m.create_memento)
	end
	def test_redo_error1
		m = FakeOriginator.new
		ct = FakeCaretaker.new(m)
		assert_raises(FakeCaretaker::Nothing2Redo) { ct.execute_redo }
	end
	def test_deep_copy1
		m = FakeOriginatorBig.new
		ct = FakeCaretaker.new(m)
		assert_equal([], m.left)
		assert_equal([], m.right)
		ct.execute(FakeCommandBig.new(1, 3))
		ct.execute(FakeCommandBig.new(2, 4))
		assert_equal([1, 2], m.left)
		assert_equal([3, 4], m.right)
		ct.execute_undo
		assert_equal([1], m.left)
		assert_equal([3], m.right)
		ct.execute_redo
		assert_equal([1, 2], m.left)
		assert_equal([3, 4], m.right)
		ct.execute_undo
		assert_equal([1], m.left, "deep-copy problem")
		assert_equal([3], m.right, "deep-copy problem")
	end
	def test_macro1
		m = FakeOriginatorBig.new
		ct = FakeCaretaker.new(m)
		ct.macro_begin
		ct.execute(FakeCommandBig.new(1, 3))
		ct.execute(FakeCommandBig.new(2, 4))
		assert_equal(2, ct.macro_size)
		macro = ct.macro_end
		assert_equal([1, 2], m.left)
		assert_equal([3, 4], m.right)
		ct.execute(macro)
		assert_equal([1, 2, 1, 2], m.left)
		assert_equal([3, 4, 3, 4], m.right)
		ct.execute_undo
		assert_equal([1, 2], m.left)
		assert_equal([3, 4], m.right)
		ct.execute_redo
		assert_equal([1, 2, 1, 2], m.left)
		assert_equal([3, 4, 3, 4], m.right)
	end
	def test_macro2
		m = FakeOriginatorBig.new
		ct = FakeCaretaker.new(m)
		class << ct
			attr_reader :record_mode
		end
		ct.macro_begin
		assert_equal(true, ct.record_mode)
		ct.execute_undo
		assert_equal(false, ct.record_mode)
		assert_raises(FakeCaretaker::Nothing2Redo) { ct.execute_redo }
		assert_raises(FakeCaretaker::Nothing2Undo) { ct.execute_undo }
	end
	def test_macro3
		m = FakeOriginatorBig.new
		ct = FakeCaretaker.new(m)
		ct.macro_begin
		ct.execute(FakeCommandBig.new(1, 4))
		ct.execute(FakeCommandOptionalFailure.new(2, 5))
		ct.execute(FakeCommandBig.new(3, 6))
		assert_equal(3, ct.macro_size)
		macro = ct.macro_end
		assert_equal([1, 2, 3], m.left)
		assert_equal([4, 5, 6], m.right)
		m.set_harm
		ct.execute(macro)
		# what happens if we play a macro and it fails ?
		# this is what this test-case is about.
		assert_equal([1, 2, 3, 1, 3], m.left)
		assert_equal([4, 5, 6, 4, 6], m.right)
	end
	class FakeCommandValue < Command
		def initialize
			@value = 10000
		end
		def execute(parent)
			@value = parent.i
			parent.output(@value)
		end
		def execute_redo(parent)
			parent.output(-@value)
		end
	end
	class FakeOriginatorValue
		def initialize
			clear
		end
		def output(value)
			@o << value
		end
		attr_reader :i, :o
		def scope(value)
			@i = value
			yield
			@i = 30000
		end
		def create_memento
			[]
		end
		def set_memento(mem)
		end
		def clear
			@i = 20000
			@o = []
		end
	end
	def test_macro_execute_redo1
		m = FakeOriginatorValue.new
		ct = FakeCaretaker.new(m)
		ct.macro_begin
		m.scope(1) { ct.execute(FakeCommandValue.new) }
		m.scope(2) { ct.execute(FakeCommandValue.new) }
		m.scope(3) { ct.execute(FakeCommandValue.new) }
		assert_equal(3, ct.macro_size)
		macro = ct.macro_end
		assert_equal([1, 2, 3], m.o)
		m.clear
		m.scope(4) { ct.execute(macro) }
		assert_equal([4, 4, 4], m.o)
		ct.execute_undo
		m.clear
		m.scope(5) { ct.execute_redo } # does this work ?
		assert_equal([-4, -4, -4], m.o)
	end
end

TestHistory.run if $0 == __FILE__
