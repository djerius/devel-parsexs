package Devel::ParseXS;

use 5.006;
use strict;
use warnings FATAL => 'all';

use Carp;
use IO::File;
use IO::Unread qw[ unread ];

use Devel::ParseXS::Pod;
use Devel::ParseXS::Keyword;
use Devel::ParseXS::Boot;
use Devel::ParseXS::Stream;

our %Re = (

    COMMENT => qr/^\s*#/,

    # CPP directives:
    #    ANSI:    if ifdef ifndef elif else endif define undef
    #        line error pragma
    #    gcc:    warning include_next
    #   obj-c:    import
    #   others:    ident (gcc notes that some cpps have this one)
    CPP =>
      qr/^#[ \t]*(?:(?:if|ifn?def|elif|else|endif|define|undef|pragma|error|warning|line\s+\d+|ident)\b|(?:include(?:_next)?|import)\s*["<].*[>"])/,

    POD => qr/^=/,

    MODULE =>
      qr/^MODULE\s*=\s*([\w:]+)(?:\s+PACKAGE\s*=\s*([\w:]+))?(?:\s+PREFIX\s*=\s*(\S+))?\s*$/,

    GKEYWORDS =>
      qr/BOOT|REQUIRE|PROTOTYPES|EXPORT_XSUB_SYMBOLS|FALLBACK|VERSIONCHECK|INCLUDE(?:_COMMAND)?|SCOPE/,

    XSUB_SECTION =>
      qr/C_ARGS|PPCODE|CODE|ALIAS|INIT|PREINIT|INTERFACE(?:_MACRO)?|CASE|CLEANUP|POSTCALL|PROTOTYPE|OVERLOAD/,

);

use Class::Tiny
  qw[ fh module package prefix context ],
  {
    fh => sub { Devel::ParseXS::Stream->new },
    header => sub { [] },
    body   => sub { [] },
  };

sub stash {

    my $self = shift;

    push @{ $self->context eq 'header' ? $self->header : $self->body }, @_;

}

sub parse_file {

    my ( $self, $file ) = @_;

    $self->fh->open( $file );

    $self->context( 'header' );
    $self->parse_header;
    $self->context( 'body' );
    $self->parse_body;

}

sub parse_header {

    my $self = shift;

    my $fh = $self->fh;

    my $header = $self->header;

    my $in_pod;
    my $found_module;

    # read until EOF or we hit a MODULE keyword
    while ( $fh->readline  ) {

        next if $self->parse_pod;

        $found_module = 1, last if $self->handle_MODULE;

        push @{$header}, $_;

    }

    croak( $fh->lineno,
        "Didn't find a 'MODULE ... PACKAGE ... PREFIX' line\n" )
      unless $found_module;

    return;
}

sub parse_body {

    my $self = shift;

    my $fh = $self->fh;

    # not in an XSUB in this code, so only parse what's legal
    while ( $fh->readline ) {

        next if /^\s*$/;

        next if $self->parse_comment;

        next if $self->handle_keyword( $Re{GKEYWORDS} );

        next if $self->parse_pod;

        # TODO:  pay attention to  C preprocessor stuff

        # we're now handling an XSUB

        next if $self->parse_xsub;

    }

}

sub parse_xsub {

    my $self = shift;

    chomp( my $return_type = $_ );

    my $fh = $self->fh;

    $fh->readline( my $decl )
	or $self->error( $fh->lineno, "function definition too short\n" );

    # at this point we'd normally check for ANSI C style argument
    # types; those would normally get stuck into an INPUT section
    # for now assume non-ANSI style

    while ( $fh->readline ) {

	next if $self->parse_pod;

    }


}

# slurp up lines until next keyword appears
sub slurp_xsub_section {

    my $self = shift;

    my @contents;

    my $fh = $self->fh;

  LOOP: {

        do {

            last if /^($Re{XSUB_SECTION})\s*:\s*(?:#.*)?(.*)/;

            push @contents, $_;

        } while ( readline( $fh ) );
    }

}


sub parse_pod {

    my $self = shift;

    return unless $_ =~ $Re{POD};

    my @pod = ( $_ );

    my $fh = $self->fh;

    my $lineno = $fh->lineno;
    while ( $fh->readline ) {
        push @pod, $_;
        last if /^=cut\s*$/;
    }

    $self->error( $lineno, "unterminated pod starting here\n" )
      if !defined $_;

    $self->stash(
        Devel::ParseXS::Pod->new( stream => $fh->stream, contents => \@pod ) );

    return 1;
}

sub parse_comment {

    my $self = shift;

    my @comments;

    my $fh = $self->fh;

  LOOP:
    {
        do {

            last if $_ !~ $Re{COMMENT} || $_ =~ $Re{CPP};

            push @comments, $_;

        } while ( $fh->readline );
    }

    if ( @comments ) {
        $self->stash( Devel::ParseXS::Comment->new( contents => \@comments ) );
        return 1;
    }

    return;
}

sub handle_keyword {

    my ( $self, $re ) = @_;

    return
      unless my ( $kwd, $arg ) = /^\s*($re)\s*:\s*(?:#.*)?(.*)/;

    my $handler = 'handle_' . $kwd;

    return $self->can( $handler )
      ? $self->$handler( $arg )
      : $self->stash(
        Devel::ParseXS::Keyword->new( keyword => $kwd, arg => $arg ) );

}

sub handle_MODULE {

    my $self = shift;

    return unless $_ =~ $Re{MODULE};

    $self->module( $1 );
    $self->package( $2 );
    $self->prefix( $3 );

    return 1;
}

sub handle_BOOT {

    # ignore any arguments
    my $self = shift;

    my $fh = $self->fh;

    my @contents;

    while ( $fh->readline ) {

        last if /^\s*$/;
        push @contents, $_;
    }

    $self->stash( Devel::ParseXS::BOOT->new( contents => \@contents ) );

}

sub error {

    my ( $self, $lineno ) = ( shift, shift );

    croak( $self->fh->filename, $lineno ? ( ': ', $self->fh->lineno ) : (),
        ': ', @_ );
}


=head1 NAME

Devel::ParseXS - The great new Devel::ParseXS!

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use Devel::ParseXS;

    my $foo = Devel::ParseXS->new();
    ...

=head1 EXPORT

A list of functions that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.

=head1 SUBROUTINES/METHODS

=head2 function1

=cut

sub function1 {
}

=head2 function2

=cut

sub function2 {
}

=head1 AUTHOR

Diab Jerius, C<< <djerius at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-devel-parsexs at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Devel-ParseXS>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Devel::ParseXS


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Devel-ParseXS>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Devel-ParseXS>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Devel-ParseXS>

=item * Search CPAN

L<http://search.cpan.org/dist/Devel-ParseXS/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2014 Diab Jerius.

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see L<http://www.gnu.org/licenses/>.


=cut

1;    # End of Devel::ParseXS
