#include <ncurses.h>
#include <stdio.h>

int main() {
	int ok = 0, key = 0;
	char sequence_str[] = "x[6A";
	sequence_str[0] = 27;

	initscr();
	keypad(stdscr, TRUE);
	noecho();
	ok = define_key(sequence_str, 42);
	key = getch();
	endwin();
	printf("ok = %d, key = %d\n", ok, key);
	return 0;
}
