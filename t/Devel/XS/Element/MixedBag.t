#!perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;

use Devel::XS::AST::Element::MixedBag;

use constant CLASS => 'Devel::XS::AST::Element::MixedBag';

subtest "constructor" => sub {

    is(
        exception {
            CLASS->new;
        },
        undef,
        'no attributes'
    );

    is(
        exception {
            CLASS->new( contents => [] );
        },
        undef,
        'passed an arrayref'
    );

    isnt(
        exception {
            CLASS->new( contents => 'foo' );
        },
        undef,
        'passed a bogus contents attribute'
    );

};

subtest "stack ops" => sub {


    is(
       CLASS->new( contents => [ 0..4 ] )->count,
       5,
       "we can count"
      );

    my $bag = CLASS->new;

    $bag->push( 'arrgh' );
    is ( $bag->count, 1, 'pushed one and have 1 in stack' );
    is ( $bag->last, 'arrgh', 'check pushed value' );

    $bag->unshift( 'grrr' );
    is ( $bag->count, 2, 'unshifted one and have 2 in stack' );
    is ( $bag->first, 'grrr', 'check unshifted value' );
    is ( $bag->last, 'arrgh', 'check pushed value' );

    $bag->push( 'scooby' );
    is ( $bag->count, 3, 'pushed one and have 3 in stack' );
    is ( $bag->last, 'scooby', 'check pushed value' );

    is ( $bag->shift, 'grrr', 'check shifted value' );
    is ( $bag->count, 2, 'shifted one and have 2 in stack' );

    is ( $bag->pop, 'scooby', 'check popped value' );
    is ( $bag->count, 1, 'popped one and have 1 in stack' );

    is ( $bag->shift, 'arrgh', 'check shifted value' );
    is ( $bag->count, 0, 'shifted one and have 0 in stack' );

};


done_testing;
