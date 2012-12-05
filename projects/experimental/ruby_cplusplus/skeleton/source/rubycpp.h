/*
Common ruby stuff (exceptions, funcall, require, new).
The Rubyembed Project
$Id: rubycpp.h,v 1.2 2003/09/20 14:09:14 neoneye Exp $
*/
#ifndef EMBEDRUBY_RUBY_CPP_H
#define EMBEDRUBY_RUBY_CPP_H

#include <string>
#include <iostream>
#include <stdexcept>
#include <sstream>
#include <ruby.h>
#include "library.h"

namespace NAMESPACE_RUBY {
using std::string;
using std::ostream;

/*
purpose:
rubys garbage collector must know about our
non-exported ruby instances in C++. 
Otherwise we can suddenly get killed without warning!

In the "pragmatic programmers guide" 
section "Sharing Data Between Ruby and C"
they recommends C object gets registered
in a global array.
*/
class Objects {
private:
	VALUE objects;
public:
	Objects();
	~Objects();

	void Register(VALUE object);
	void Unregister(VALUE object);
};

/*
purpose:
translate a ruby exception into an c++ exception.

usage:
	void Test() {
		int error = 0;
		rb_protect(WrapTest, reinterpret_cast<VALUE>(this), &error);
		if(error)
			throw NAMESPACE_RUBY::Error::Create("error loading test.rb");
	}
*/
class Error : public NAMESPACE_LIBRARY::Error {
private:
	string name;
	string where;
	string message;
	string klass;
	string backtrace;

	Error();
public:
	virtual ~Error() throw();
	virtual const char *what() const throw();
	virtual void explain(ostream &o) const throw();
	static Error Create(string name);
};


/*
purpose:
call a ruby function in a safe way. 
translate ruby errors into c++ exceptions.

usage:
instead of calling rb_funcall(), do this:

	VALUE Safe() {
		return RUBY_CPP::Funcall(
			self, 
			rb_intern("test"), 
			1, 
			INT2NUM(42)
		);
	}
*/
VALUE Funcall(VALUE recv, ID id, int n, ...);


/*
purpose:
require a ruby-file in a safe way
*/
void Require(std::string filename);


/*
purpose:
create a new instance in a safe way
*/
VALUE New(string klass);

} // end of namespace NAMESPACE_RUBY


/*
purpose:
translate from c++ 2 ruby exceptions

adapted from 
http://groups.google.com/groups?hl=en&lr=&ie=UTF-8&selm=20020408192019.E15413%40atdesk.com&rnum=10

RUBY_CATCH
Cant raise the exception from catch block, because 
the C++ exception wont get properly destroyed.
Thus we must delay it til after the catch block!
*/
#define RUBY_TRY \
	extern VALUE ruby_errinfo; \
	ruby_errinfo = Qnil; \
	try

#define RUBY_CATCH \
	catch(const std::exception &e) { \
		std::ostringstream o; \
		o << "c++error: " << e.what(); \
		ruby_errinfo = rb_exc_new2(rb_eRuntimeError, o.str().c_str()); \
	} catch(...) { \
		ruby_errinfo = rb_exc_new2(rb_eRuntimeError, "c++error: Unknown error"); \
	} \
	if(!NIL_P(ruby_errinfo)) { \
		rb_exc_raise(ruby_errinfo); \
	}

#endif // EMBEDRUBY_RUBY_CPP_H
