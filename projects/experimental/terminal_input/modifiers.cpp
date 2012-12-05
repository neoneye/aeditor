#include <iostream>
using std::cout;
using std::endl;

//#define IS_FREEBSD

#ifdef IS_FREEBSD
#   include <sys/consio.h>  // VT_GETMODE
#endif 
#ifdef IS_LINUX
#   include <sys/ioctl.h>   // TIOCLINUX
#   include <linux/kd.h>
#endif

int get_modifier_state() {

#ifdef IS_LINUX
	struct kbentry entry;
	ioctl (0, KDGKBENT, &entry);
	return entry.kb_table;
#endif
#ifdef IS_LINUX_ALTERNATIVE
	int arg = 6;  // TIOCLINUX function #6
	if(ioctl(fileno(stdin), TIOCLINUX, &arg) < 0) {
		return arg; // state
	}
#endif
#ifdef IS_FREEBSD
	int arg = 6;  // VT_GETMODE function #6
	if(ioctl(fileno(stdin), VT_GETMODE, &arg) < 0) {
		return arg; // state
	}
#endif
	return 0;
}

int main() {
	cout << "enter" << endl;
	while(1) {
		int s = get_modifier_state();
		cout << s << endl;
		/*if(s != 0) {
			break;
		} */
	}
	cout << "leave" << endl;
	return 0;
}
