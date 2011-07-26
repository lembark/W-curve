
package WCurve::Util::DumperConfig;

use strict;

use Data::Dumper;

use Symbol  qw( qualify_to_ref );

# configure dumper output here.

$Data::Dumper::Terse        = 1;
$Data::Dumper::Indent       = 1;
$Data::Dumper::Purity       = 0;
$Data::Dumper::Deepcopy     = 0;
$Data::Dumper::Quotekeys    = 0;

sub import
{
    my $caller  = caller;

    my $ref     = qualify_to_ref 'Dumper', $caller;

    *$ref       = __PACKAGE__->can( 'Dumper' );

    return
}

# keep require happy

1

__END__
