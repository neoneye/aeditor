require 'mkmf'

dir_config('ncursesw', '/home/neoneye/include', '/home/neoneye/lib')

ok = true

unless have_header('ncursesw/ncurses.h')
	ok = false
end

unless have_library('ncursesw', 'wcolor_set')
	ok = false
end

if ok
	create_makefile("Tui")
end
