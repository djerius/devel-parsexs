#!perl

package t::Devel::ParseXS::header;

use Test::More;
use Test::Fatal;
use Data::Section -setup;
use Safe::Isa;

use Devel::ParseXS;

use t::common qw[ datafile ];

subtest 'pod ok' => sub {

    my $p = Devel::ParseXS->new;

    is(
        exception {
            $p->parse_file( datafile( 'pod_ok.xs' ) );
        },
        undef,
        'parse pod'
    );

    my $pod_ok =
    ok(
        defined $p->header
       && defined $p->header->[0]
       && $p->header->[0]->$_isa( 'Devel::ParseXS::Pod' ),
        'found pod'
      );


    SKIP : {

	skip "didn't find pod; can't continue", 1 unless $pod_ok;


	is(
	   $p->header->[0]->as_string,
	   ${ __PACKAGE__->section_data( 'pod_ok' ) },
	   'pod contents'
	  );

    }


    is( $p->module, 'Trial::Foo', 'module name' );
    is( $p->package, 'Foo::Bar', 'package name' );
    is( $p->prefix, 'Bar', 'prefix name' );


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

subtest 'no module' => sub {

    my $p = Devel::ParseXS->new;

    like(
        exception {
            $p->parse_file( datafile( 'no_module.xs' ) );
        },
        qr/Didn't find a 'MODULE/,
        'parse pod'
    );


};

done_testing;


__DATA__

__[ pod_ok ]__
=head1 NAME

 trial


=cut
__END__
