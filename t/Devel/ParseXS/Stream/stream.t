#!perl

package t::Devel::ParseXS::Stream::stream;

use strict;
use warnings;

use Test::Fatal;
use Test::More;

use Devel::ParseXS::Stream;
use Data::Section -setup;

use t::common qw[ datafile ];
use MyTest::store_stream;

subtest 'no stream' => sub {

    my $s = Devel::ParseXS::Stream->new;

    $_ = '';
    is( $s->readline && $_, undef, 'no stream' );

};


subtest 'one stream' => sub {

    my $s = Devel::ParseXS::Stream->new;

    my $opened = is(
        exception {
            $s->open( datafile( 'file1' ) );
        },
        undef,
        'open stream'
    );

  SKIP: {
        skip "couldn't open file", 2 unless $opened;

        my $store = MyTest::store_stream->new;

        $store->store( $s ) while defined $s->readline;

        my %store = $store->as_string;

        is( $store{dollar_},
            ${ __PACKAGE__->section_data( 'one stream line' ) },
            '$_ contents' );

        is(
            $store{line},
            ${ __PACKAGE__->section_data( 'one stream line' ) },
            'line contents'
        );

        is( $store{lineno},
            ${ __PACKAGE__->section_data( 'one stream lineno' ) },
            'line number' );

        is(
            $store{lastline},
            ${ __PACKAGE__->section_data( 'one stream lastline' ) },
            'last line contents'
        );

        is(
            $store{lastlineno},
            ${ __PACKAGE__->section_data( 'one stream lastlineno' ) },
            'last line number'
        );
    }

};


subtest 'two streams' => sub {

    my $s = Devel::ParseXS::Stream->new;

    is(
        exception {
            $s->open( datafile( 'file1' ) );
        },
        undef,
        'open stream'
    );

    my $store = MyTest::store_stream->new;

    for ( 1 .. 3 ) {

        $s->readline;
        $store->store( $s )

    }

    is(
        exception {
            $s->open( datafile( 'file2' ) );
        },
        undef,
        'open stream'
    );

    $store->store( $s ) while defined $s->readline;

    my %store = $store->as_string;

    is( $store{dollar_}, ${ __PACKAGE__->section_data( 'two stream line' ) },
        '$_ contents' );

    is(
        $store{line},
        ${ __PACKAGE__->section_data( 'two stream line' ) },
        'line contents'
    );

    is( $store{lineno}, ${ __PACKAGE__->section_data( 'two stream lineno' ) },
        'line number' );

    is(
        $store{lastline},
        ${ __PACKAGE__->section_data( 'two stream lastline' ) },
        'last line contents'
    );

    is(
        $store{lastlineno},
        ${ __PACKAGE__->section_data( 'two stream lastlineno' ) },
        'last line number'
    );
};


done_testing;

__DATA__

__[ one stream line]__
a1
b2
c3
d4
e5
f6
__[ one stream lineno]__
1
2
3
4
5
6
__[ one stream lastline]__

a1
b2
c3
d4
e5
__[ one stream lastlineno]__
0
1
2
3
4
5
__[ two stream line]__
a1
b2
c3
g1
h2
i3
j4
k5
l6
d4
e5
f6
__[ two stream lineno]__
1
2
3
1
2
3
4
5
6
4
5
6
__[ two stream lastline]__

a1
b2
c3
g1
h2
i3
j4
k5
l6
d4
e5
__[ two stream lastlineno]__
0
1
2
3
1
2
3
4
5
6
4
5
__END__
