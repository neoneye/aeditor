/*
Implementation of the "View" class + lib_begin()/lib_end()
The Rubyembed Project
$Id: library.cpp,v 1.2 2003/09/20 14:09:14 neoneye Exp $
*/
#include <iostream>
#include <stdexcept>

#include "library.h"
#include "rubycpp.h"
#include "example_bridge_ruby.h"

namespace NAMESPACE_LIBRARY {
using std::cout;
using std::endl;
using std::ostream;

NAMESPACE_RUBY::Objects *objects = 0;

/*
purpose:
an instance of the ruby class "View"

functions:
*	invoke functions on the instance.
*/
class ExampleBridgeCppImpl {
private:
	ExampleBridgeCpp *parent;
	VALUE self;
public:
	ExampleBridgeCppImpl(ExampleBridgeCpp *parent) : parent(parent) {
		/*
		What is going on?
		
		Explanation: todo
		*/
		ExampleBridgeRuby::SetParent(parent);
		self = NAMESPACE_RUBY::New("ExampleRuby");
		objects->Register(self);
	}
	~ExampleBridgeCppImpl() {
		objects->Unregister(self);
	}
	void execute() {
		NAMESPACE_RUBY::Funcall(self, rb_intern("execute"), 0); 

		/*
		This is intented to provoke a segfault.

		First we unregister our object and running GC.
		Next we try to access the "dead" object, this
		should result in a segfault.

		objects->Unregister(self);
		NAMESPACE_RUBY::Funcall(rb_cObject, rb_intern("sweep"), 0); 
		NAMESPACE_RUBY::Funcall(self, rb_intern("execute"), 0); 
		*/
	}
};

ExampleBridgeCpp::ExampleBridgeCpp() {
	cout << "ExampleBridgeCpp.ctor: enter" << endl;
	pimpl = new ExampleBridgeCppImpl(this);
	cout << "ExampleBridgeCpp.ctor: leave" << endl;
}

ExampleBridgeCpp::~ExampleBridgeCpp() {
	cout << "ExampleBridgeCpp.dtor: enter" << endl;
	delete pimpl;
	cout << "ExampleBridgeCpp.dtor: leave" << endl;
}

void ExampleBridgeCpp::execute() {
	cout << "ExampleBridgeCpp.execute: enter" << endl;
	pimpl->execute();
	cout << "ExampleBridgeCpp.execute: leave" << endl;
}

void ExampleBridgeCpp::callback() {
	cout << "ExampleBridgeCpp.callback: default" << endl;
}

/*
purpose:
ensure that ruby is only started/stopped once!

todo: 
*	use a singleton for this
*/
static bool lib_running = false;

void lib_begin() {
	if(lib_running)
		return;
	
	// initialize ruby itself
	ruby_init();
	ruby_init_loadpath();
	ruby_script("embed");

	// setup our own environment
	objects = new NAMESPACE_RUBY::Objects;
	ExampleBridgeRuby::RubyInit();
	NAMESPACE_RUBY::Require("test");

	lib_running = true;
}

void lib_end() {
	if(lib_running == false)
		return;
	
	// teardown (reverse initialization order)
	delete objects;
	ruby_finalize();

	lib_running = false;
}

} // end of namespace NAMESPACE_LIBRARY
