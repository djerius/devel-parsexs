#! perl

package t::Devel::ParseXS::declaration::edge_cases;


use strict;
use warnings;

use Test::More;
use Test::Fatal;

use Data::Section -setup;

use Devel::ParseXS;


my @sections = grep { /.xs/ } __PACKAGE__->section_data_names;

for my $section ( @sections ) {

    ( my $result = $section) =~ s/.xs/.yaml/;

    subtest $section => sub {

	my $xs   = __PACKAGE__->section_data( $section );
	my $yaml =  __PACKAGE__->section_data( $result );

	my $p = Devel::ParseXS->new;

	is( exception { $p->parse_file( $xs ) },
	    undef,
	    "parse $section"
	  );

	my $tree = $p->tree;

	is ( $tree->count, 2, "number of parsed top sections" );

	my $module = shift @{$tree->contents};
	isa_ok ( $module, 'Devel::XS::AST::Module', 'module' );

	my $xsub = shift @{$tree->contents};
	isa_ok ( $xsub, 'Devel::XS::AST::XSub', 'parsed xsub' );

	is ( $xsub->func_name, 'func', 'xsub name' );
	is ( $xsub->return_type, 'char *', 'xsub return type' );

	is ( $xsub->args->count, 2, 'number of xsub parameters' );

	ok ( defined $xsub->arg( 'a' ), 'xsub parameter a exists' );
	is ( $xsub->arg('a')->c_type, 'int **', 'xsub parameter a C type' );
	ok ( ! $xsub->arg( 'a' )->pass_addr, 'xsub parameter a & flag' );

	ok ( defined $xsub->arg( 'b' ), 'xsub parameter b exists' );
	is ( $xsub->arg('b')->c_type, 'char ***', 'xsub parameter b C type' );
	ok ( $xsub->arg( 'b' )->pass_addr, 'xsub parameter b & flag is set' );
	ok ( ! $xsub->arg( 'b' )->init_arg, 'xsub parameter b will not be intialized' );

    };

}

done_testing;

__DATA__

__[ extra_spaces.xs ]__
MODULE = Trial::Foo  PACKAGE = Foo::Bar PREFIX = Bar

char  *
func ( int * * a, b = NO_INIT )
  char ** *& b   = NO_INIT
__[ extra_spaces.yaml ]__
__END__
