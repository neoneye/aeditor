/*
The "ExampleBridgeRuby" class makes c++callbacks visible to ruby.
The Rubyembed Project
$Id: example_bridge_ruby.h,v 1.2 2003/09/20 14:09:14 neoneye Exp $

purpose:
make c++ callbacks available to ruby.

issues:
*	There is a reason why this file is not contained within 
	a namespace. This is because we wanna be easy with SWIG.
	I dont know if this is actual a problem, but im just assuming.
*/
#ifndef EMBEDRUBY_EXAMPLE_BRIDGE_RUBY_H
#define EMBEDRUBY_EXAMPLE_BRIDGE_RUBY_H

#include "library.h"

/*
purpose:
make c++ callbacks available to ruby

functions:
*	callback()  invokes the virtual function parent->callback().

constraints:
*	This object is managed from ruby, thus dont raise
	c++ exceptions. Instead raise ruby exceptions.

issues:
*	ruby-wrapper, the global_example is ugly. But unfortunatly 
	I do not know any other ways to initialize this struct!
*/
class ExampleBridgeRuby {
private:
	NAMESPACE_LIBRARY::ExampleBridgeCpp *parent;
	static NAMESPACE_LIBRARY::ExampleBridgeCpp *temp_parent;
public:
	ExampleBridgeRuby();
	~ExampleBridgeRuby();
	void callback();

	// bootstrapping 
	static void SetParent(NAMESPACE_LIBRARY::ExampleBridgeCpp *parent);
	static void RubyInit();
};

#endif // EMBEDRUBY_EXAMPLE_BRIDGE_RUBY_H
