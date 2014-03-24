#! perl

package t::Devel::ParseXS::xsub;

use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Test::Deep;

use Devel::ParseXS;

use t::common qw[ files datafile ];

sub AST { "Devel::XS::AST::" . shift }

for my $file ( $ENV{XSUB} ? $ENV{XSUB} : files( '.pl' ) ) {

    subtest $file => sub {

	my $exp = do $file  or die $@;

	my $xs = do { local $/ = undef; <DATA> };

        my $p       = Devel::ParseXS->new;

	my $stream = noclass( { fh => undef, filename => $file } );

	is(
	   exception{
	       $p->parse_file( \$xs );
	   },
	   undef,
	   "parse $file"
	  );

	cmp_deeply(
		   $p->tree->contents,
		   $exp,
		  'compare');

    };

}

done_testing;
