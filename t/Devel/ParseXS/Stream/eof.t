#!perl

package t::Devel::ParseXS::Stream::eof;

use strict;
use warnings;

use Test::Fatal;
use Test::More;

use Devel::ParseXS::Stream;

subtest 'no stream, $_' => sub {

    my $s = Devel::ParseXS::Stream->new;

    local $_ = 'a';
    is( $s->readline, undef, 'got EOF' );
    is( $_, undef, 'reset $_' );

};

subtest 'no stream, $buf' => sub {

    my $s = Devel::ParseXS::Stream->new;

    local $_ = 'b';
    my $buf = 'a';
    is( $s->readline( $buf ), undef, 'got EOF' );
    is( $_, 'b', q[don't touch $_] );
    is( $buf, undef, q[reset $buf] );

};

subtest 'empty stream, $_' => sub {

    my $s = Devel::ParseXS::Stream->new;

    my $input = '';

    is( exception{ $s->open( \$input ) },
	undef,
	'open string' );

    local $_ = 'a';
    is( $s->readline, undef, 'got EOF' );
    is( $_, undef, 'reset $_' );

};

subtest 'empty stream, $buf' => sub {

    my $s = Devel::ParseXS::Stream->new;

    my $input = '';

    is( exception{ $s->open( \$input ) },
	undef,
	'open string' );

    local $_ = 'b';
    my $buf = 'a';
    is( $s->readline( $buf ), undef, 'got EOF' );
    is( $_, 'b', q[don't touch $_] );
    is( $buf, undef, q[reset $buf] );

};

subtest 'ungetline, $_' => sub {

    my $s = Devel::ParseXS::Stream->new;

    my $input = '';

    is( exception{ $s->open( \$input ) },
	undef,
	'open string' );

    $s->ungetline;

    local $_ = 'a';
    is( $s->readline, undef, 'got EOF' );
    is( $_, undef, 'reset $_' );

};

subtest 'ungetline, $buf' => sub {

    my $s = Devel::ParseXS::Stream->new;

    my $input = '';

    is( exception{ $s->open( \$input ) },
	undef,
	'open string' );

    $s->ungetline;

    local $_ = 'b';
    my $buf = 'a';
    is( $s->readline( $buf ), undef, 'got EOF' );
    is( $_, 'b', q[don't touch $_] );
    is( $buf, undef, q[reset $buf] );

};


done_testing;

