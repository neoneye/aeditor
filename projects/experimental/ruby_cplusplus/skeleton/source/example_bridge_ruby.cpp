/*
Implementation of the "ExampleBridgeRuby" class + SWIG wrapper.
The Rubyembed Project
$Id: example_bridge_ruby.cpp,v 1.2 2003/09/20 14:09:14 neoneye Exp $
*/
#include <iostream>
#include "example_bridge_ruby.h"
#include "rubycpp.h"

using std::cout;
using std::endl;

NAMESPACE_LIBRARY::ExampleBridgeCpp *ExampleBridgeRuby::temp_parent = 0;

void ExampleBridgeRuby::SetParent(NAMESPACE_LIBRARY::ExampleBridgeCpp *parent) {
	ExampleBridgeRuby::temp_parent = parent;
}

ExampleBridgeRuby::ExampleBridgeRuby() { 
	this->parent = ExampleBridgeRuby::temp_parent;
	cout << "ExampleBridgeRuby.ctor: hello" << endl;
}

ExampleBridgeRuby::~ExampleBridgeRuby() {
	cout << "ExampleBridgeRuby.dtor: hello" << endl;
}

void ExampleBridgeRuby::callback() {
	RUBY_TRY {
		cout << "ExampleBridgeRuby.callback: enter" << endl;
		parent->callback();
		cout << "ExampleBridgeRuby.callback: leave" << endl;
	} RUBY_CATCH
}

extern "C" void Init_Wrapper(); 

void ExampleBridgeRuby::RubyInit() {
	// initialize the SWIG wrapper
	Init_Wrapper();
}
