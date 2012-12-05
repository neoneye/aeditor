#
#  Using ncurses-5.4  with --enable-widec --with-shared
#
require 'dl/import'
module Curses
	extend DL::Importable
	dlload "libncursesw.so"
	typealias "WINDOW", "void*"
	extern "int addstr(const char *)"
	extern "int cbreak()"
	extern "int endwin()"
	extern "int getch()"
	extern "WINDOW initscr()"
	extern "int noecho()"
	extern "int refresh()"
	extern "int addwstr(const unsigned long *)"
	extern "int addnwstr(const unsigned long *, int)"
end

str = [0x250c, 0x2510, 10, 0x2514, 0x2518].pack("L*")
Curses.initscr
Curses.cbreak
Curses.noecho
Curses.addnwstr(str, str.size)  # no box.. 
Curses.getch
Curses.endwin
