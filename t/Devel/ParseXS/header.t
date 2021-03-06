#!perl

package t::Devel::ParseXS::header;

use Test::More;
use Test::Fatal;
use Data::Section -setup;

use Devel::ParseXS;

use t::common qw[ datafile data];

subtest 'header ok' => sub {

    my $p = Devel::ParseXS->new;

    is(
        exception {
            $p->parse_file( datafile( 'header_ok.xs' ) );
        },
        undef,
        'parse pod'
    );

    {
        my $element = $p->tree->shift;

	isa_ok( $element, 'Devel::XS::AST::Data', 'found_data' )
          && is( $element->as_string, ${ data( 'data1' ) }, 'data1' );
    }

    {
        my $element = $p->tree->shift;

        isa_ok( $element, 'Devel::XS::AST::Pod', 'found pod' )
          && is( $element->as_string, ${ data( 'pod' ) }, 'pod' );
    }

    {
        my $element = $p->tree->shift;
        isa_ok( $element, 'Devel::XS::AST::Data', 'found data' )
          && is( $element->as_string, ${ data( 'data2' ) }, 'data2' );
    }


    is( $p->module->module,  'Trial::Foo', 'module name' );
    is( $p->module->package, 'Foo::Bar',   'package name' );
    is( $p->module->prefix,  'Bar',        'prefix name' );

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
__[ data1 ]__
other
stuff
in
the
header

__[ pod ]__
=head1 NAME

 trial


=cut
__[ data2 ]__

more
stuff
in
the
header

__END__
