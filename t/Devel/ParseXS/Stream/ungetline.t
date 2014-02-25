#!perl

package t::Devel::ParseXS::Stream::ungetline;

use strict;
use warnings;

use Test::Fatal;
use Test::More;

use Devel::ParseXS::Stream;

use t::common qw[ datafile ];

subtest "ungetline" => sub {

    my $s = Devel::ParseXS::Stream->new;

    my $opened =
    is(
        exception {
            $s->open( datafile( [-1, 1, 'stream' ], 'file1' ) );
        },
        undef,
        'open stream'
    );

	my $line;
	is (
	    exception {
		1 while( $s->readline( $line ) && $line =~ /[abc]/ );
	    },
	    undef,
	    'read stream'
	);

        is ( $line, 'd4', 'expected line contents' );
	is ( $s->lineno, 4, 'expected line number' );

	$s->ungetline(1);

	$s->readline( $line );

	is ( $line, 'd4', 'repeated line contents' );
	is ( $s->lineno, 4, 'repeated line number' );

	$s->readline( $line );

	is ( $line, 'e5', 'next line' );
	is ( $s->lineno, 5, 'next line number' );

};



done_testing;
