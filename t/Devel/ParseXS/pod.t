#! perl

package t::Devel::ParseXS::pod;

use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Data::Section -setup;

use Devel::ParseXS;

use t::common qw[ datafile ];
use MyTest::store_stream;

subtest 'pod' => sub {

    my $p = Devel::ParseXS->new;

    is( exception { $p->fh->open( datafile( 'pod.xs' ) ) },
        undef, 'open file' );

    {
        my $store = MyTest::store_stream->new;

        is(
            exception {
                while ( $p->fh->readline ) {
                    last if $p->parse_pod;
                    $store->store( $p->fh );
                }
            },
            undef,
            'parse file'
        );

        is(
            $store->as_string->{dollar_},
            ${ __PACKAGE__->section_data( 'pod: pre' ) },
            'content before pod'
        );

    }

    {

        my $pod = $p->tree->contents->[0];

        isa_ok( $pod,  'Devel::XS::AST::Pod', 'found pod' );

        is( $pod->attr->{lineno}, 7, 'pod starting line number' );

        is(
            $pod->as_string,
            ${ __PACKAGE__->section_data( 'pod' ) },
            'pod content'
        );

    }

    {
        my $store = MyTest::store_stream->new;

        is(
            exception {
                while ( $p->fh->readline ) {
                    $store->store( $p->fh );
                }
            },
            undef,
            'parse remainder of file'
        );

        is(
            $store->as_string->{dollar_},
            ${ __PACKAGE__->section_data( 'pod: post' ) },
            'content after pod'
        );

    }


};

subtest 'pod not ok' => sub {

    my $p = Devel::ParseXS->new;

    like(
        exception {
            $p->parse_file( datafile( 'pod_not_ok.xs' ) );
        },
        qr/unterminated pod/,
        'parse pod'
    );


};


done_testing;

__DATA__
__[ pod: pre ]__
stuff
that
isn't
a
comment

__[ pod ]__
=pod

Podish
Things
here
=cut
__[ pod: post ]__

more
stuff
that
isn't
a
comment

__END__
