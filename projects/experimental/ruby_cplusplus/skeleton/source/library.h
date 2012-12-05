/*
The only thing the public ever will see. No traces of ruby at all! 
The Rubyembed Project
$Id: library.h,v 1.2 2003/09/20 14:09:14 neoneye Exp $
*/
#ifndef EMBEDRUBY_LIBRARY_H
#define EMBEDRUBY_LIBRARY_H

#include <stdexcept>
#include <iostream>

namespace NAMESPACE_LIBRARY {

/*
purpose:
start/stop this library

constraints:
*	lib_begin() must be invoked before using this library.
*	lib_end() must be invoked after using this library.
*/
void lib_begin();
void lib_end();


/*
purpose:
base class for errors
*/
class Error : public std::exception {
public:
	virtual void explain(std::ostream &o) const throw() = 0;
};


/*
purpose:
Encapsulation of the 'ExampleRuby' class.
you can inherit from it and install a callback.

if you plan to build a texteditor, which has a
ruby backend and a c++ frontend. You could
rename 'execute' into 'insert(text)',
rename 'callback' into 'repaint()'.
You will then be able (from C++) to insert
some text in the buffer (in Ruby). And (from Ruby)
to invoke repaint (in C++).

issues:
*	It has a hidden implementation, located in library.cpp.
*/
class ExampleBridgeCppImpl; // pimpl
class ExampleBridgeCpp {
public:
	ExampleBridgeCpp();
	virtual ~ExampleBridgeCpp();

	void execute();
	virtual void callback();
private:
	ExampleBridgeCppImpl *pimpl;
};

} // end of namespace NAMESPACE_LIBRARY

#endif // EMBEDRUBY_LIBRARY_H
