package t::common;

use lib 't/lib';

use File::Spec::Functions qw[ catfile ];

use IO::File;
use IO::Handle;
use File::Glob ':bsd_glob';

use Exporter 'import';
our @EXPORT_OK = qw[

  datafile
  data
  xs_files
  slurp

];

sub psplice {

    my ( $array ) = shift;

    if ( @_ ) {

	my $offset = shift;

	unless ( @_ )  {

	    splice( @{$array}, $offset );

	}

	else {

	    my $length = shift;

	    unless ( @_ ) {

		splice( @{$array}, $offset, $length );

	    }
	    else {

		splice( @{$array}, $offset, $length, @_ );

	    }

	}

    }

}


sub datafile {

    my $package = ( caller )[0];

    my @path = split( '::', $package );

    psplice( \@path, @{ shift() } )
	if 'ARRAY' eq ref $_[0];

    return catfile( @path, @_ );
}

sub xs_files {

    my $package = ( caller )[0];

    my @path = split( '::', $package );

    psplice( \@path, @{ shift() } )
	if 'ARRAY' eq ref $_[0];

    return glob( catfile( @path, '*.xs' ) );
}


sub data {

    my $package = ( caller )[0];

    return $package->section_data( @_ ) ;

}

sub slurp {

    my $file = shift;

    local $/ = undef;

    open ( my $fh, '<', $file )
	or die( "error opening $file\n" );

    my $contents = <$fh>;

    close $fh;

    return \$contents;
}

1;
