/*
Garbage collector mayhem
Artificial test case
Define NORMAL for usual stack behaviour (stack initialized at top level)

Make sure Ruby include is in path, and that this is linked to the Ruby library
Example:
\ruby-1.8.0\win32> cl -O1 -MD -I .. boom.c msvcrt-ruby18.lib && boom
*/

#include <stdlib.h>
#include <stdio.h>
#include "ruby.h"

#ifdef OBSERVE
void observe() {
    VALUE *sp = &sp;
    printf("SP = %08X\n", sp);
}
#else
#define observe()
#endif

typedef void (*void_func)();

void pad_stack(int size, void_func fun) {
    volatile void  *pad = alloca(size);
    fun();
}

void test_init() {
    ruby_init();
    // Scramble
    rb_eval_string("print \"in test_init() \"");
    observe();
}

void collect() {
    //printf("Collecting garbage...\n");
    rb_eval_string("GC.start");
    //printf("Garbage collected!\n");
}

void allocate_some() {
    VALUE stuff[1024];
    int i,j;
    
    printf("in allocate_some() ");
    observe();
    
    // This probably invokes the garbage collector implicitly
    for(i = 0; i < 1024; i++) {
        stuff[i] = rb_ary_new2(10000);
    }
    for(i = 0; i < 1024; i++) {
        for(j = 0; j < 10000;j++)
            rb_ary_store(stuff[i], j, Qnil);
    }
    
    collect();
    
    for(i = 0; i < 1024; i++) {
        for(j = 0; j < 10000;j++) {
            if(rb_ary_entry(stuff[i], j) != Qnil) {
                printf("Houston, we have a problem...\n");
                abort();
            }
        }
    }
    printf("All OK!\n");
}


int
main(argc, argv, envp)
    int argc;
    char **argv, **envp;
{
#ifdef _WIN32
    NtInitialize(&argc, &argv);
#endif

#ifndef NORMAL
    pad_stack(50000, test_init);
    allocate_some();
#else
    test_init();
    pad_stack(10000, allocate_some);
#endif
    
    return 0;
} 