package Devel::ParseXS;

use 5.006;
use strict;
use warnings FATAL => 'all';

use Carp;

use Safe::Isa;

use ExtUtils::Typemaps qw[ tidy_type ];

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

);

use Class::Tiny
  qw[ fh module package packid prefix _context ],
  {
    argtypes => 1,
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

    # pay attention to continuation lines. Current line was
    # not read in with the stream set to read logical records; first
    # continue it if it needs it.
    $fh->readline( { continue_record => 1 } );
    $fh->logical_record( 1 );

    $self->parse_declaration( $xsub );

    $fh->readline
      or $self->error( 0, "function definition too short\n" );

    $self->stash( $xsub );
    $self->push_context( $xsub );

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

        # XSUB ends if we hit a left adjusted line with a preceding blank one
        $fh->ungetline && last if /^\S/ && $fh->lastline =~ /^\s*$/;

        next if $self->parse_pod;

        next if $self->parse_comment;


        if ( /^\s*($Re{XSUB_SECTION})\s*:\s*(?:#.*)?(.*)/ ) {

            my $section = $self->create_ast_element(
                "XSub::$1",
                {
                    attr => {
                        lineno => $fh->lineno,
                        stream => $fh->stream,
                    },
                    value => $2
                } );

	    $self->pop_context;
            $self->stash( $section );
            $self->push_context( $section );
            next;
        }

        $self->stash_data( $_ );
    }

    # pops XSUB keyword context. either the first implicit INPUT, or
    # one that follows
    $self->pop_context;

    # XSUB context
    $self->pop_context;

    # stop paying attention to continuation lines
    $fh->logical_record(0);

    return;
}

sub parse_declaration {

    my ( $self, $xsub ) = ( shift, shift );

    # we accept (in pseudo-regexp)

    #  (NO_OUTPUT\s+)?return_type
    #  (\n)?
    #  ( func_name\( args \) )?


    $xsub->no_return( 1 ) if s/^\s*NO_OUTPUT\s+//;

    # follow ExtUtils::ParseXS's lead of cleaning up the return type
    # before checking for func_name(... )
    my $return_type = ExtUtils::Typemaps::tidy_type( $_ );

    # if argtypes set, try to parse as <return_type> func_name(...)
    # RE's from ExtUtils:ParseXS
    if ( $self->argtypes
	 && $return_type =~ /^(.*?\w.*?)          # return type
			      \s*\b(\w+\s*\(.*)   # func_name( args )
			    /x
       ) {

	$return_type = $1;
	$self->fh->pushline( $2 );

    }
    $xsub->externC(1) if $return_type =~ s/^extern "C"\s+//;
    $xsub->static(1)  if $return_type =~ s/^static\s+//;

    $xsub->return_type( $return_type );

    $self->fh->readline( { clean_record => 1 } )
      or $self->error( $self->fh->lineno, "function definition too short\n" );

    # parse class? func_name( args ) (const)?
    my $matched =
      my ( $class, $func_name, $orig_args, $const ) =
    /^
     (?:([\w:]*)::)?  	   # C++ class
     (\w+)            	   # name
     \s*
     \(\s* (.*?) \s*\)     # args
     \s*
     (const)?        	   # C++ const
     \s*(;\s*)?      	   # trailing scruff
     $/sx;

    $self->error( 1, "not a function declaration: $_\n" )
      unless $matched;

    $class = "$const $class" if $const;

    $xsub->class( $class );
    $xsub->func_name( $func_name );

    # remove possible prefix and add package name
    ( my $clean_func_name = $func_name ) =~ s/^(@{[ $self->prefix ]})?//;
    $xsub->perl_name( join( '::', $self->package ||(), $clean_func_name ) );
    $xsub->full_func_name( join( '_', $self->packid, $clean_func_name ) );

    # FIXME; parse args into $xsub->args
    $xsub->decl( $orig_args );

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

    return unless
      my ( $module, $package, $prefix ) = $_ =~ $Re{MODULE};


    $self->module(  $module );
    $self->package( defined $package ? $package : '' );
    $self->prefix(  defined $prefix ? quotemeta( $prefix ) : '' );

    (my $packid = $self->package) =~ tr/:/_/;

    $self->packid($packid);

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
