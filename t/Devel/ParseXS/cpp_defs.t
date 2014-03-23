#! perl

package t::Devel::ParseXS::cpp_defs;

use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Data::Section -setup;

use Devel::ParseXS;

use t::common qw[ xs_files slurp ];

for my $xs_file ( xs_files() ) {

    subtest $xs_file => sub {

	my $contents =

        my $p = Devel::ParseXS->new;



	is(
	   exception{
	       $p->fh->open( $xs_file );
	       $p->parse_body;
	   },
	   undef,
	   "parse"
	  );

	my $cpp = $p->tree->contents->[0]->contents;

	chomp $cpp->[0];
	$cpp->[0] .= "\n";

	is_deeply( $cpp, [ ${slurp( $xs_file )} ], "contents" );
    };

}

done_testing;
