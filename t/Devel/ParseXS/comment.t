#! perl

package t::Devel::ParseXS::comment;

use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Data::Section -setup;
use Safe::Isa;

use Devel::ParseXS;

use t::common qw[ datafile ];

subtest 'comments only' => sub {


    my $p = Devel::ParseXS->new;

    is (
	exception { $p->fh->open( datafile('comment_only.xs' ) ) },
	undef,
	'open file'
       );

    is (
	exception {
	    while( $p->fh->readline  ) {
		last if $p->parse_comment;
	    };
	},
	undef,
	'parse file'
       );

    my $comment = $p->context->[0];

    my $found_comments =
    ok (
	defined $comment && $comment->$_isa( 'Devel::ParseXS::Comment' ),
        'found comment'
       );

    SKIP : {

	skip "didn't find comments; can't continue", 1 unless $found_comments;


	is( $comment->lineno, 7, 'comment starting line number' );

	is(
	   $comment->as_string,
	   ${ __PACKAGE__->section_data( 'comments only' ) },
	   'comment content'
	  );

    }

};

subtest 'comments+cpp' => sub {


    my $p = Devel::ParseXS->new;

    is (
	exception { $p->fh->open( datafile('comment_cpp.xs' ) ) },
	undef,
	'open file'
       );

    is (
	exception {
	    while( $p->fh->readline  ) {
		last if $p->parse_comment;
	    };
	},
	undef,
	'parse file'
       );

    my $comment = $p->context->[0];

    my $found_comments =
    ok (
	defined $comment && $comment->$_isa( 'Devel::ParseXS::Comment' ),
        'found comment'
       );

    SKIP : {

	skip "didn't find comments; can't continue", 1 unless $found_comments;


	is( $comment->lineno, 25, 'comment starting line number' );

	is(
	   $comment->as_string,
	   ${ __PACKAGE__->section_data( 'comments+cpp' ) },
	   'comment content'
	  );

    }

};



done_testing;

__DATA__
__[ comments only ]__
# only
# comments
# in
# here
__[ comments+cpp ]__
# only
# non
# cpp
# comments
# in
# here
__END__
