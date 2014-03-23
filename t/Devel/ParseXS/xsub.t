#! perl

package t::Devel::ParseXS::xsub;

use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Data::Section -setup;

use Devel::ParseXS;

use t::common qw[ xs_files ];

for my $xs_file ( xs_files() ) {

    subtest $xs_file => sub {

        my $p       = Devel::ParseXS->new;

	is(
	   exception{
	       $p->parse_file( $xs_file );
	   },
	   undef,
	   "parse $xs_file"
	  );
    };

}

done_testing;
