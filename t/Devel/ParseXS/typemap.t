#! perl

package t::Devel::ParseXS::typemap;

use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Data::Section -setup;

use Devel::ParseXS;

for my $section ( grep { /:input/ } __PACKAGE__->section_data_names ) {

    ( my $test ) = $section =~ /(.*):input/;

    subtest $test => sub {

        my $p       = Devel::ParseXS->new;
        my $input   = __PACKAGE__->section_data( $section );
        my $content = __PACKAGE__->section_data( $test . ':content' );

        $p->fh->open( $input );

        $p->parse_body;

        my $typemap = $p->tree->first;

        isa_ok( $typemap, 'Devel::XS::AST::Typemap', 'parsed typemap section' );
        is( join( "\n", @{ $typemap->contents }, '' ),
            ${$content}, 'typemap contents' );
    };

}

subtest 'eof' => sub {

    my $p     = Devel::ParseXS->new;
    my $input = __PACKAGE__->section_data( 'unterminated' );

    $p->fh->open( $input );

    like(
        exception { $p->parse_body },
        qr/unterminated typemap/i,
        'catch unterminated typemap'
    );

};

done_testing;


__DATA__
__[ unquote:input ]__
TYPEMAP: << EOT
a
b
c
d
EOT
__[ unquote:content ]__
a
b
c
d
__[ squote:input ]__
TYPEMAP: << 'EOT';
e
f
g
h
EOT
__[ squote:content ]__
e
f
g
h
__[ dquote:input ]__
TYPEMAP: << 'EOT';
i
j
k
l
EOT
__[ dquote:content ]__
i
j
k
l
__[ unterminated ]__
TYPEMAP: << 'EOT';
m
n
o
__END__
