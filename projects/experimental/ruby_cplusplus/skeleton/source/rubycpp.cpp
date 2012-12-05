/*
Encapsulation of some common ruby stuff (protection when necessary). 
The Rubyembed Project
$Id: rubycpp.cpp,v 1.2 2003/09/20 14:09:14 neoneye Exp $
*/
#include <iostream>
#include <string>
#include <cstdarg>
#include <sstream>
#include "rubycpp.h"

namespace NAMESPACE_RUBY {
using std::string;
using std::cout;
using std::hex;
using std::ostream;
using std::endl;


/* ------------------------------
memory management
------------------------------ */
Objects::Objects() {
	objects = rb_ary_new();
	rb_gc_register_address(&objects);
}

Objects::~Objects() {
	// dispose array and flush all elements
	rb_gc_unregister_address(&objects);
	/*      
	mass destrurction.
	GC can no longer can mark the elements in
	the Array and therefore they will all get swept.
	*/
}

void Objects::Register(VALUE object) {
	cout << "objects += " << hex << object << endl;
	rb_ary_push(objects, object);
}

void Objects::Unregister(VALUE object) {
	cout << "objects -= " << hex << object << endl;
	rb_ary_delete(objects, object);
}


/* ------------------------------
ruby exceptions into c++ exceptions
------------------------------ */
Error::Error() {
}

Error::~Error() throw() {
}

const char *Error::what() const throw() {
	return name.c_str();
}

void Error::explain(ostream &o) const throw() {
	o << 
		"name=" << name.c_str() << "\n"
		"where=" << where.c_str() << "\n"
		"class=" << klass.c_str() << "\n"
		"message=" << message.c_str() << "\n"
		"backtrace=" << backtrace.c_str() << endl;
}

/*
purpose:
convert a ruby exception into c++

issues:
*	Is this code correct?  Well.. Compare this code against
	ruby1.8.0/eval.c - exc_inspect(), backtrace()
	I think its almost correct. 
*/
Error Error::Create(string name) {
	Error e;
	e.name = name;

	// position
	std::ostringstream where;
	where << ruby_sourcefile << ":" << ruby_sourceline;
	ID id = rb_frame_last_func();
	if(id) {
		where << ":in `" << rb_id2name(id) << "'";
	} 
	e.where = where.str();
	
	VALUE exception_instance = rb_gv_get("$!");

	// class
	VALUE klass = rb_class_path(CLASS_OF(exception_instance));
	e.klass = RSTRING(klass)->ptr; 

	// message
	VALUE message = rb_obj_as_string(exception_instance);
	e.message = RSTRING(message)->ptr;

	// backtrace
	if(!NIL_P(ruby_errinfo)) {
		std::ostringstream o;
		VALUE ary = rb_funcall(ruby_errinfo, rb_intern("backtrace"), 0);
		int c;
		for (c=0; c<RARRAY(ary)->len; c++) {
			o << "\tfrom " << RSTRING(RARRAY(ary)->ptr[c])->ptr << "\n";
		}
		e.backtrace = o.str();
	}
	return e;
}


/* ------------------------------
wrap rb_funcall
------------------------------ */
struct Arguments {
	VALUE recv;
	ID id;
	int n;
	VALUE *argv;
	Arguments(VALUE recv, ID id, int n, VALUE *argv) :
		recv(recv), id(id), n(n), argv(argv) {
	}
};

VALUE FuncallWrap(VALUE arg) {
	Arguments &a = *reinterpret_cast<Arguments*>(arg);
	return rb_funcall2(a.recv, a.id, a.n, a.argv);
}

/*
purpose:
call a ruby function in a safe way. 
translate ruby errors into c++ exceptions.


VALUE Unsafe() {
	return rb_funcall(
		self, 
		rb_intern("test"), 
		1, 
		INT2NUM(42)
	);
}

VALUE Safe() {
	return RUBY_CPP::Funcall(
		self, 
		rb_intern("test"), 
		1, 
		INT2NUM(42)
	);
}
*/
VALUE Funcall(VALUE recv, ID id, int n, ...) {
    VALUE *argv = 0;

    if (n > 0) {
		argv = ALLOCA_N(VALUE, n);
		va_list ar;
		va_start(ar, n);
		int i;
		for(i=0;i<n;i++) {
			argv[i] = va_arg(ar, VALUE);
		}
		va_end(ar);
    } 

	Arguments arg(recv, id, n, argv);
	int error = 0;
	VALUE result = rb_protect(FuncallWrap, reinterpret_cast<VALUE>(&arg), &error);
	if(error)
		throw NAMESPACE_RUBY::Error::Create("cannot invoke ruby-function");
	return result;
}


/* ------------------------------
wrap rb_require
------------------------------ */
VALUE RequireWrap(VALUE arg) {
	const char *filename = reinterpret_cast<const char*>(arg);
	rb_require(filename);
	return Qnil;
}

/*
purpose:
require a ruby-file in a safe way
*/
void Require(std::string filename) {
	int error = 0;
	rb_protect(RequireWrap, reinterpret_cast<VALUE>(filename.c_str()), &error);
	if(error) {
		std::ostringstream o;
		o << "error loading " << filename << ".rb";
		throw NAMESPACE_RUBY::Error::Create(o.str());
	}
}


/* ------------------------------
wrap rb_class_new_instance
------------------------------ */
struct NewArguments {
	const char *klass;
	int n;
	VALUE *argv;
	NewArguments(const char *klass, int n, VALUE *argv) : 
		klass(klass), n(n), argv(argv) {}
};

VALUE NewWrap(VALUE arg) {
	NewArguments &a = *reinterpret_cast<NewArguments*>(arg);
	//VALUE klass = rb_const_get(rb_cObject, rb_intern(a.klass));
	VALUE klass = rb_path2class(a.klass);

	/*
	Apparently there is a difference between 
		a) rb_class_new_instance(a.n, a.argv, klass);
		b) rb_funcall2(klass, rb_intern("new"), a.n, a.argv); 
	Using (a) then we cannot inheirit from a SWIG class.
	Using (b) then there is no problems. 
	
	We don't want problems, so we choose (b)!
	todo: why does (a) not work?

	Using (a) we get this error message:
		EXCEPTION (RUBY):
		name=cannot invoke ruby-function
		where=./test.rb:21
		class=TypeError
		message=wrong argument type RubyView (expected Data)
		backtrace=      from ./test.rb:21:in `repaint'
				from ./test.rb:21:in `insert'
	*/
	//VALUE self = rb_class_new_instance(a.n, a.argv, klass);
	VALUE self = rb_funcall2(klass, rb_intern("new"), a.n, a.argv);
	return self;
}

VALUE New(string klass) {
	NewArguments arg(klass.c_str(), 0, 0);
	int error = 0;
	VALUE self = rb_protect(NewWrap, reinterpret_cast<VALUE>(&arg), &error);
	if(error) {
		std::ostringstream o;
		o << "error creating " << klass;
		throw NAMESPACE_RUBY::Error::Create(o.str());
	}
	return self;
}

} // end of namespace NAMESPACE_RUBY
