#! perl

package t::Devel::ParseXS::declaration::ansi_c;

use strict;
use warnings;

use Test::More;
use Test::Fatal;

use Devel::ParseXS;

use t::common qw[ datafile ];

subtest 'ansi-c style' => sub {

    my $p = Devel::ParseXS->new;

    is( exception { $p->parse_file( datafile( [-1], 'ansi_c.xs' ) ) },
        undef, 'open file' );

    my $xsubs = $p->tree->contents;

    for my $spec (
        [ 'char *', 'func', ],
        [ 'char *', 'func', ['...'], ],
        [ 'char *', 'func', [ 'int', 'a' ], ],
        [ 'char *', 'func', [ 'int', 'a' ], ['...'], ],
        [ 'char *', 'func', [ 'int', 'a' ], [ 'int', 'b' ] ],
        [ 'char *', 'func', [ 'int', 'a' ], [ 'int', 'b' ], ['...'], ],
        [ 'char *', 'func', [ 'char *',  'a' ], ],
        [ 'char *', 'func', [ 'char **', 'a' ], ],
        [ 'char *', 'func', [ 'char *', 'a', q{"a1"} ], ],
        [ 'char *', 'func', [ 'char *', 'a', q{"a2"} ], ['...'], ],
        [ 'char *', 'func', [ 'char *', 'a', q{"a3"} ], [ 'int', 'b', '1' ] ],
        [ 'char *', 'func', [ 'char *', 'a', q{"a4"} ], [ 'int', 'b', '2' ], ['...'], ],
      )
    {

        my ( $return_type, $name, @pars ) = @$spec;

        $name = join( '_',
            $name,
            map {   s/\.\.\./ellipsis/;
		    s/\*/star/g;
		    s/\"//g;
		    $_;
		}
	      map { split( ' ', $_ ) } map { @{$_} } @pars
		    );

        subtest $name => sub {

            my $xsub = shift @{$xsubs};
            isa_ok( $xsub, 'Devel::XS::AST::XSub', "xsub" );

            is( $xsub->func_name,   $name,        'name' );
            is( $xsub->return_type, $return_type, 'return type' );

            my $pars = $xsub->args->contents;

            for my $exp ( @pars ) {

		my ( $type, $name, $default ) = @$exp;

                my $par = shift @{$pars};
                isa_ok( $par, 'Devel::XS::AST::XSub::Arg', 'arg 1 ast type' );

                if ( $exp->[0] eq '...' ) {

                    ok( $par->varargs, "varargs" );

                }
                else {

                    is( $par->c_type, $type, 'arg type' );
                    is( $par->name,   $name, 'arg name' );
                    is( $par->default, $default, 'arg default' );
                }
            }

            is( scalar @{$pars}, 0, 'no remaining parameters' );

        };


    }


    is( scalar @{$xsubs}, 0, 'no remaining functions' );

};


done_testing;
