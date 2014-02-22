#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Devel::ParseXS' ) || print "Bail out!\n";
}

diag( "Testing Devel::ParseXS $Devel::ParseXS::VERSION, Perl $], $^X" );
