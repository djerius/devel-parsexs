package Devel::XS::AST::XSub::Arg;

use parent -norequire => 'Devel::XS::AST::Element';

use strict;
use warnings;

use Class::Tiny (
    'c_type',         # C type of argument
    'default',        # default value
    'idx',            # zero-based index of argument in parameter list
    'in_declaration', # if true, definition made in function declaration
    'inout_type',     # IN/OUTLIST/IN_OUTLIST/OUT/IN_OUT behavior
    'length_name',    # initialize with length of this variable
    'name',           # argument name; undefined if a length parameter of varargs
    'optional',       # true if argument need not be specified (must be at end of argument list)
    'pass_addr',      # true if should pass address of C variable to C function
    'varargs',        # true if this is a varargs entry
    'input',          # if in_declaration is false, this points to the
                      # INPUT section where the type is defined
    'init_arg',       # true if the argument should be initialized
    'init_type',      # how to apply initialization 'replace', 'replace_later', 'add_later'
    'init_value',     # what to intialize the argument to

);


1;


