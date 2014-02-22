package t::common;

use lib 't/lib';

use File::Spec::Functions qw[ catfile ];

use Exporter 'import';
our @EXPORT_OK = qw[

  datafile

];


sub datafile {

    my $package = ( caller )[0];

    return catfile( split( '::', $package ), @_ );
}

1;
