# Makefile.am -> Makefile.in -> Makefile
# The Rubyembed Project
# $Id: Makefile.am,v 1.2 2003/09/20 14:09:14 neoneye Exp $

EXTRA_DIST = \
	library.h \
	example_bridge_ruby.h \
	example_bridge_ruby_wrap.i \
	rubycpp.h \
	test.rb \
	wrap.sh

CPPFLAGS = @RUBY_CFLAGS@

bin_PROGRAMS = test

test_SOURCES = \
	rubycpp.cpp \
	example_bridge_ruby.cpp \
	example_bridge_ruby_wrap.cpp \
	library.cpp \
	main.cpp

test_LDADD = \
	@RUBY_LIBS@
