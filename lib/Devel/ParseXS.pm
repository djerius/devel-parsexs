package Devel::ParseXS;

use 5.006;
use strict;
use warnings FATAL => 'all';

use Carp;

use Safe::Isa;

use Devel::ParseXS::Stream;

use Devel::XS::AST;
use Devel::XS::AST::Comment;
use Devel::XS::AST::Data;
use Devel::XS::AST::Keyword;
use Devel::XS::AST::Pod;
use Devel::XS::AST::XSub::Section;
use Devel::XS::AST::XSub;

our %Re = (

    COMMENT => qr/^\s*#/,

    # CPP directives:
    #    ANSI:    if ifdef ifndef elif else endif define undef
    #             line error pragma include
    #     gcc:    warning include_next
    #   obj-c:    import
    #  others:    ident (gcc notes that some cpps have this one)
    CPP =>
      qr/^#[ \t]*(?:(?:if|ifn?def|elif|else|endif|define|undef|pragma|error|warning|line\s+\d+|ident)\b|(?:include(?:_next)?|import)\s*["<].*[>"])/,

    POD => qr/^=/,

    MODULE =>
      qr/^MODULE\s*=\s*([\w:]+)(?:\s+PACKAGE\s*=\s*([\w:]+))?(?:\s+PREFIX\s*=\s*(\S+))?\s*$/,

    GKEYWORDS =>
      qr/BOOT|REQUIRE|PROTOTYPES|EXPORT_XSUB_SYMBOLS|FALLBACK|VERSIONCHECK|INCLUDE(?:_COMMAND)?|SCOPE/,

    XSUB_SECTION =>
      qr/ALIAS|C_ARGS|CASE|CLEANUP|CODE|INIT|INPUT|INTERFACE(?:_MACRO)?|OVERLOAD|PPCODE|PREINIT|POSTCALL|PROTOTYPE/,

);

use Class::Tiny
  qw[ fh module package prefix _context ],
  {
    fh       => sub { Devel::ParseXS::Stream->new },
    tree     => sub { Devel::XS::AST->new },
    _context => sub { [ undef ] },
  };


sub BUILD {

    my $self = shift;

    $self->context( $self->tree );

}

sub push_context {

    push @{ $_[0]->_context }, $_[1];

    return;
}

sub pop_context {

    pop @{ $_[0]->_context };

    return;
}

sub context {

    my $self = shift;

    my $context = $self->_context->[-1];

    $self->_context->[-1] = $_[0] if @_;

    return $context;
}


sub stash {

    my $self = shift;

    @_ > 1 && croak( "illegal stash of more than one object\n" );

    $self->context->push( $_[0] );

    return;
}

sub stash_data {

    my $self = shift;

    my $context = $self->context;

    if ( $context->last->$_isa( 'Devel::XS::AST::Data' ) ) {

        $context->last->push( @_ );

    }

    else {

        my $data = $self->create_ast_element(
            'Data',
            {
                contents => [@_],
                attr     => {
                    lineno => $self->fh->lineno,
                    stream => $self->fh->stream,
                },
            } );

        $self->stash( $data );
    }

    return;
}

sub parse_file {

    my ( $self, $file ) = @_;

    $self->fh->open( $file );
    $self->parse_header;
    $self->parse_body;

    return;
}

sub parse_header {

    my $self = shift;

    my $fh = $self->fh;

    my $found_module;

    # read until EOF or we hit a MODULE keyword
    while ( $fh->readline ) {

        next if $self->parse_pod;

        $found_module = 1, last if $self->handle_MODULE;

        $self->stash_data( $_ );

    }

    croak( $fh->lineno, "Didn't find a 'MODULE ... PACKAGE ... PREFIX' line\n" )
      unless $found_module;

    return;
}

sub parse_body {

    my $self = shift;

    my $fh = $self->fh;

    # not in an XSUB in this code, so only parse what's legal
    while ( $fh->readline ) {

        next if /^\s*$/;

        next if $self->parse_pod;

        next if $self->parse_comment;

	$DB::single = 1 if /PROTOTYPES/;

        next if $self->handle_keyword( $Re{GKEYWORDS} );

        # TODO:  pay attention to  C preprocessor stuff

        # we're now handling an XSUB

        $self->parse_xsub;

    }

    return;
}

sub parse_xsub {

    my $self = shift;

    my $fh = $self->fh;

    my $xsub = $self->create_ast_element(
        'XSub',
        {
            attr => {
                lineno => $fh->lineno,
                stream => $fh->stream,
            },
        } );

    chomp;
    $xsub->return_type( $_ );

    $fh->readline
      or $self->error( 0, "function definition too short\n" );
    chomp;
    $xsub->decl( $_ );

    $self->stash( $xsub );
    $self->push_context( $xsub );

    # at this point we'd normally check for ANSI C style argument
    # types; those would normally get stuck into an INPUT section
    # for now assume non-ANSI style

    # first section is implicitly INPUT
    my $input = $self->create_ast_element(
        'XSub::INPUT',
        {
            attr => {
                lineno => $fh->lineno,
                stream => $fh->stream,
            },
        } );
    $self->stash( $input );
    $self->push_context( $input );

    while ( $fh->readline ) {

        # end on a blank line (not quite clear from the docs when an
        # XSUB ends...)
        last if /^\s*$/;

        next if $self->parse_pod;

        next if $self->parse_comment;

        # not quite sure if these are allowed in an initial INPUT
        # section...
        next if $self->handle_keyword( $Re{GKEYWORDS} );

        if ( /^($Re{XSUB_SECTION})\s*:\s*(?:#.*)?(.*)/ ) {

            my $section = $self->create_ast_element(
                "XSub::$1",
                {
                    attr => {
                        lineno => $fh->lineno,
                        stream => $fh->stream,
                    },
                    value => $2
                } );
            $self->stash( $section );
            $self->context( $section->context );
            next;
        }

        $self->stash_data( $_ );
    }

    # pops XSUB keyword context. either the first implicit INPUT, or
    # one that follows
    $self->pop_context;

    # XSUB context
    $self->pop_context;

    return;
}

sub parse_pod {

    my $self = shift;

    return unless $_ =~ $Re{POD};

    my @pod = ( $_ );

    my $fh = $self->fh;

    my %attr = (
        lineno => $fh->lineno,
        stream => $fh->stream
    );
    while ( $fh->readline ) {
        push @pod, $_;
        last if /^=cut\s*$/;
    }

    $self->error( $attr{lineno}, "unterminated pod starting here\n" )
      if !defined $_;

    $self->stash(
        $self->create_ast_element(
            'Pod',
            {
                attr     => \%attr,
                contents => \@pod
            } ) );

    return 1;
}

sub parse_comment {

    my $self = shift;

    my @comments;

    my $fh = $self->fh;

    my %attr = (
        lineno => $fh->lineno,
        stream => $fh->stream
    );

  LOOP:
    {
        do {

            last if $_ !~ $Re{COMMENT} || $_ =~ $Re{CPP};

            push @comments, $_;

        } while ( $fh->readline );
    }

    if ( @comments ) {
        $self->stash(
            $self->create_ast_element(
                'Comment',
                {
                    attr     => \%attr,
                    contents => \@comments,
                } ) );

        # last line wasn't a comment; put it back
        $fh->ungetline;
        return 1;
    }

    return;
}

sub handle_keyword {

    my ( $self, $re ) = @_;

    return
      unless my ( $kwd, $arg ) = /^\s*($re)\s*:\s*(?:#.*)?(.*)/;

    my $handler = 'handle_' . $kwd;

    return $self->$handler( $arg )
	if $self->can( $handler );

    $self->stash(
		 $self->create_ast_element(
					   'Keyword',
            {
                attr => {
                    lineno => $self->fh->lineno,
                    stream => $self->fh->stream,
                },
                keyword => $kwd,
                arg     => $arg,
            } ) );

    return 1;
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

    my %attr = (
        lineno => $fh->lineno,
        stream => $fh->stream
    );

    my @contents;

    while ( $fh->readline ) {

        last if /^\s*$/;
        push @contents, $_;
    }

    $self->stash(
        $self->create_ast_element(
            'BOOT',
            {
                attr     => \%attr,
                contents => \@contents,
            } ) );

    return 1;
}

sub error {

    my ( $self, $lineno ) = ( shift, shift );

    croak( $self->fh->filename, $lineno ? ( ': ', $self->fh->lineno ) : (),
        ': ', @_ );
}

sub create_ast_element {

    my ( $self, $class, $attr ) = @_;

    $class = 'Devel::XS::AST::' . $class;

    my @missing = grep { !defined $attr->{attr}{$_} } qw[ lineno stream ];

    croak( "missing attribute(s) for object of class $class: @missing\n" )
      if @missing;

    return $class->new( $attr );
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

Copyright (C) 2014 Smithsonian Astrophysical Observatory
Copyright (C) 2014 Diab Jerius

This program is free software: you can redistribute it and/or modify
it under the same terms as Perl itself.

Portions taken from ExtUtils::ParseXS, Copyright 2002-2013 by Ken
Williams, David Golden and other contributors.


=cut

1;    # End of Devel::ParseXS
