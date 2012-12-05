#include "ruby.h"
#include "ncurses.h"
#include "locale.h"

/*

if (c == KEY_MOUSE) {
	MEVENT event;

	getmouse(&event);
	wprintw(win, "KEY_MOUSE, %s", mouse_decode(&event));
	getyx(win, y, x);
	move(event.y, event.x);
	addch('*');
	wmove(win, y, x);
}

*/


VALUE tui_init(VALUE self) {
	setlocale(LC_ALL, "");
	
	initscr();


	/*intrflush(stdscr, 0);*/
	keypad(stdscr, TRUE); /* enable keyboard mapping */
	nonl();               /* tell curses not to do NL->CR/NL on output */
	raw();                /* characters typed are immediately passed through */
	noecho();             /* don't echo input */
	meta(stdscr, 1);

	if(has_colors() == 0) {
		endwin();
		return Qfalse;
	}
	start_color();
	
		
	init_pair(1, COLOR_YELLOW, COLOR_BLUE);  /* text */
	init_pair(2, COLOR_WHITE, COLOR_BLUE);  /* keyword */
	init_pair(3, COLOR_BLACK, COLOR_CYAN);  /* selection */
	init_pair(4, COLOR_GREEN, COLOR_BLUE);  /* strings */
	init_pair(5, COLOR_YELLOW, COLOR_BLACK);  /* fold */
	init_pair(6, COLOR_BLACK, COLOR_BLUE);  /* borders */
	init_pair(7, COLOR_CYAN, COLOR_BLUE);  /* - */
	init_pair(8, COLOR_BLUE, COLOR_BLUE);  /* tabs */
	init_pair(9, COLOR_BLACK, COLOR_RED);  /* error */
	init_pair(10, COLOR_RED, COLOR_BLUE);  /* error */
	
	color_set(1, 0);
	bkgdset(1);
	
	/*clear();
	move(0, 0);
	addnstr("hi", 2);
	refresh();*/
		
	return Qtrue;
}


VALUE tui_close(VALUE self) {
	endwin();
	return Qnil;
}


VALUE tui_clear(VALUE self) {
	clear();
	return Qnil;
}


VALUE tui_clrtoeol(VALUE self) {
	clrtoeol();
	return Qnil;
}


VALUE tui_refresh(VALUE self) {
	refresh();
	return Qnil;
}


VALUE tui_width(VALUE self) {
	return INT2FIX(stdscr->_maxx + 1);
}


VALUE tui_height(VALUE self) {
	return INT2FIX(stdscr->_maxy + 1);
}


VALUE tui_move(VALUE self, VALUE x, VALUE y) {
	int ix;
	int iy;
	ix = FIX2INT(x);
	iy = FIX2INT(y);
	move(iy, ix);
	return Qnil;
}


VALUE tui_print(VALUE self, VALUE text) {
	const char *str;
	str = STR2CSTR(text);
	addstr(str);
	return Qnil;
}


VALUE tui_setcolor(VALUE self, VALUE pen) {
	int ipen;
	ipen = FIX2INT(pen);
	color_set(ipen, 0);
	return Qnil;
}


VALUE tui_getch(VALUE self) {
	int code;
	code = getch();
	return INT2FIX(code);
}


VALUE tui_nodelay(VALUE self, VALUE b) {
	nodelay(stdscr, (b == Qtrue));
	return Qnil;
}


VALUE tui_wcwidth(VALUE self, VALUE glyph) {
	long ig;
	int res; 
	ig = FIX2LONG(glyph);
	res = wcwidth(ig);
	return INT2FIX(res);
}


VALUE m_tui;

void Init_Tui() {
	m_tui = rb_define_module("Tui");
	rb_define_module_function(m_tui, "init",    tui_init,    0);
	rb_define_module_function(m_tui, "close",   tui_close,   0);
	rb_define_module_function(m_tui, "move",    tui_move,    2);
	rb_define_module_function(m_tui, "print",   tui_print,   1);
	rb_define_module_function(m_tui, "set_color", tui_setcolor, 1);
	rb_define_module_function(m_tui, "clear",   tui_clear,   0);
	rb_define_module_function(m_tui, "clear_to_eol", tui_clrtoeol, 0);
	rb_define_module_function(m_tui, "getch",   tui_getch,   0);
	rb_define_module_function(m_tui, "nodelay", tui_nodelay, 1);
	rb_define_module_function(m_tui, "refresh", tui_refresh, 0);
	rb_define_module_function(m_tui, "width",   tui_width,   0);
	rb_define_module_function(m_tui, "height",  tui_height,  0);
	rb_define_module_function(m_tui, "wcwidth", tui_wcwidth, 1);
}