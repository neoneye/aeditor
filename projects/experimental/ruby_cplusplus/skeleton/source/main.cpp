/*
Invoke some ruby-code which will invoke our c++callback.
The Rubyembed Project
$Id: main.cpp,v 1.2 2003/09/20 14:09:14 neoneye Exp $
*/
#include <iostream>
#include <stdexcept>
#include <signal.h>

#include "library.h"

using std::cout;
using std::cerr;
using std::endl;
using std::exception;

class ExampleCpp : public NAMESPACE_LIBRARY::ExampleBridgeCpp {
public:
	ExampleCpp() {
		cout << "ExampleCpp.ctor: hello" << endl;
	}
	virtual ~ExampleCpp() {
		cout << "ExampleCpp.dtor: hello" << endl;
	}
	void callback() {
		cout << "ExampleCpp.callback: bingo" << endl;
		//throw std::runtime_error("deal with me");
	}
};

void Test() {
	ExampleCpp().execute();
}

int SafeMain() {
	try {
		NAMESPACE_LIBRARY::lib_begin();
		cout << "----------------------" << endl;
		Test();
		cout << "----------------------" << endl;
		NAMESPACE_LIBRARY::lib_end();
		return 0;
	} catch(const NAMESPACE_LIBRARY::Error &e) {
		cerr << "EXCEPTION (RUBY):" << endl;
		e.explain(cerr);
		return 1;
	} catch(const exception &e) {
		cerr << "EXCEPTION=" << e.what() << endl;
		return 1;
	}
}

void sig_handler(int x) {
	cerr << "something bad happened! x=" << x << endl;
	exit(-1);
}

int main() {
	cout << "main: enter" << endl;
	signal(SIGABRT, sig_handler);
	int status = SafeMain();
	cout << "main: leave (" << status << ")" << endl;
	return status;
}
