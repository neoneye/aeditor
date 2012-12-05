require 'terminal'

class Input
	def initialize(fd, termcap)
		@fd = fd
		@read_ary = [@fd]
		@termcap = termcap
	end
	def event_loop
		loop do
			event = wait_event
			dispatch(event) if event
		end
	end
	def dispatch(event)
		p event
	end
	def close
	end
private
	def wait_event
		ready = select(@read_ary)[0]
		if ready.include?(@fd)
			unless @fd.eof
				#puts "got: data"
				seq = @fd.read
				key = @termcap.seq_key[seq]
				return key if key 
				puts "no binding for sequence: #{seq.inspect}"
			else
				puts "got: eof"
				@read_ary.delete @fd
				#thread_out.kill if @read_ary == []
			end
		else
			raise "should not happen"
		end
		nil
	end
end

class InputStdin < Input
	def initialize
		require 'fcntl'
		fd = $stdin
		fd.fcntl(Fcntl::F_SETFL, Fcntl::O_NONBLOCK)

		require 'termios'
		@old_term = Termios.tcgetattr(fd)
		term = @old_term.dup
		# we don't want notify only on newline!
		# disabling ICANON gives us notify on each keystroke.
		term.lflag &= ~Termios::ICANON
		# we don't want echo on the terminal!
		# disabling ECHO causes the terminal to be silent.
		term.lflag &= ~Termios::ECHO
		# we don't want ctrl-c to terminate the application.
		# disabling ISIG then we ourselves handle ctrl-c.
		#term.lflag &= ~Termios::ISIG
		# unknown options.. 
		#term.lflag &= ~Termios::ECHONL # ?
		#term.iflag &= ~Termios::IXON   # ?
		#term.iflag &= ~Termios::IXOFF  # ?
		Termios.tcsetattr(fd, Termios::TCSANOW, term)

		termcap = TermcapXTerm.new
		super(fd, termcap)
	end
	def close
		Termios.tcsetattr(@fd, Termios::TCSANOW, @old_term)
	end
end

class Keymap
	include KeyEvent::Key
	def initialize
		build_keymap
	end
	def build_keymap
		km = {
			KEY_LEFT       => cmd_move_left,
			KEY_LEFT|SHIFT => cmd_unindent,
			KEY_LEFT|CTRL  => cmd_word_left
		}
	end
end


if $0 == __FILE__
	i = InputStdin.new
	begin
		i.event_loop
	ensure
		i.close
	end
end
