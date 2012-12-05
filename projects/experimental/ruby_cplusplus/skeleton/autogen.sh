#!/bin/sh
set -x
aclocal
autoheader
autoconf
automake --add-missing
