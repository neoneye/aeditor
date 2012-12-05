/*
Tell SWIG that it should generate a "ExampleBridgeRuby" class for us.
The Rubyembed Project
$Id: example_bridge_ruby_wrap.i,v 1.2 2003/09/20 14:09:14 neoneye Exp $
*/
%module Wrapper 

%{
#include "example_bridge_ruby.h"
%}

%name(ExampleBridgeRuby) class ExampleBridgeRuby {
public:                   
	ExampleBridgeRuby();
	void callback();
};
