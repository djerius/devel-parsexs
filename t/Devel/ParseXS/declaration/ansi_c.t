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

    my $tree = $p->tree;

    my $module = $tree->shift;
    isa_ok ( $module, 'Devel::XS::AST::Module', 'module' );

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

            my $xsub = $tree->shift;
            isa_ok( $xsub, 'Devel::XS::AST::XSub', "xsub" );

            is( $xsub->func_name,   $name,        'name' );
            is( $xsub->return_type, $return_type, 'return type' );

            for my $exp ( @pars ) {

		my ( $type, $name, $default ) = @$exp;

                my $par = $xsub->args->shift;
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

            is( $xsub->args->count, 0, 'no remaining parameters' );

        };


    }


    is( $tree->count, 0, 'no remaining functions' );

};

subtest 'length' => sub {

    my $p = Devel::ParseXS->new;

    my $xs =
q[MODULE = module

void
foo( short length(x) )
];

    is( exception { $p->parse_file( \$xs ) },
        undef, 'parse' );

    my $tree = $p->tree;
    my $module = $tree->shift;

    isa_ok ( $module, 'Devel::XS::AST::Module', 'module' );

    my $xsub = $tree->shift;
    isa_ok( $xsub, 'Devel::XS::AST::XSub', "xsub" );

    is( $xsub->func_name,   'foo',         'name' );
    is( $xsub->return_type, 'void', 'return type' );

    my $par = $xsub->args->shift;
    isa_ok( $par, 'Devel::XS::AST::XSub::Arg', 'arg 1 ast type' );

    is( $par->c_type, 'short', 'arg type' );
    is( $par->length_name, 'x', 'length name' );
    is( $par->in_declaration, 1, 'found in declaration' );

};

subtest 'length, no type' => sub {

    my $p = Devel::ParseXS->new;

    my $xs =
q[MODULE = module

void
foo( length(x) )
];

    like( exception { $p->parse_file( \$xs ) },
        qr/Must specify type/,
	'parse' );


};


done_testing;
