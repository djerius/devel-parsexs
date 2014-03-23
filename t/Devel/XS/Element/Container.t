#!perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;

use Devel::XS::AST::Element::Container;
use Devel::XS::AST::Comment;

use constant CLASS => 'Devel::XS::AST::Element::Container';
use constant ELEMENT => 'Devel::XS::AST::Comment';


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
        'passed a non arrayref contents attribute'
    );

    isnt(
        exception {
            CLASS->new( contents => [ 'foo' ] );
        },
        undef,
        'passed a bogus contents attribute'
    );

};

subtest "stack ops with wrong type" => sub {


    my $bag = CLASS->new;

    isnt(
        exception {
            $bag->push( 'foo' );
        },
        undef,
        "push non @{[ ELEMENT ]} object"
    );

    isnt(
        exception {
            $bag->unshift( 'foo' );
        },
        undef,
        "unshift non @{[ ELEMENT ]} object"
    );

};

subtest "stack ops" => sub {

    is(
       CLASS->new( contents => [ ELEMENT->new, ELEMENT->new ] )->count,
       2,
       "we can count"
      );

    my $bag = CLASS->new;

    $bag->push( ELEMENT->new( contents => ['arrgh' ] ) );
    is ( $bag->count, 1, 'pushed one and have 1 in stack' );
    is ( $bag->last->as_string, "arrgh\n", 'check pushed value' );

    $bag->unshift( ELEMENT->new( contents => [ 'grrr' ] ) );
    is ( $bag->count, 2, 'unshifted one and have 2 in stack' );
    is ( $bag->first->as_string, "grrr\n", 'check unshifted value' );
    is ( $bag->last->as_string, "arrgh\n", 'check pushed value' );

    $bag->push( ELEMENT->new( contents => [ 'scooby' ] ) );
    is ( $bag->count, 3, 'pushed one and have 3 in stack' );
    is ( $bag->last->as_string, "scooby\n", 'check pushed value' );

    is ( $bag->shift->as_string, "grrr\n", 'check shifted value' );
    is ( $bag->count, 2, 'shifted one and have 2 in stack' );

    is ( $bag->pop->as_string, "scooby\n", 'check popped value' );
    is ( $bag->count, 1, 'popped one and have 1 in stack' );

    is ( $bag->shift->as_string, "arrgh\n", 'check shifted value' );
    is ( $bag->count, 0, 'shifted one and have 0 in stack' );

};


done_testing;
