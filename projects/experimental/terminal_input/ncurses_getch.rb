require 'ncurses'

def wait_event
	# getch waits until key is pressed
	Ncurses.timeout(-1)
	event = Ncurses.getch
	return [event] if event != 27

	# getch returns *almost* immediately
	Ncurses.timeout(50)
	seq = []
	until event == Ncurses::ERR
		seq << event
		event = Ncurses.getch
	end
	seq
end

Ncurses.initscr
#Ncurses.raw
Ncurses.nonl  # ctrl-m  => '13' instead of '10'
Ncurses.noecho
Ncurses.keypad(Ncurses.stdscr, false) # deal with escape code ourselfes
event = wait_event
Ncurses.endwin

class Fixnum
	def chr
		((self > 31) && (self < 256)) ? super() : "<#{self}>"
	end
end

def ascii_to_s(ary)
	ary.inject(""){|v, e| v << e.chr}
end

p event
seq = ascii_to_s(event)
p seq


require 'terminal'
tc = TermcapXTerm.new
key = tc.seq_key[seq]
p key
