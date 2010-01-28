########################################################################
# housekeeping
########################################################################

package WCurve::Dumper;

use v5.10;
use strict;

use Exporter::Proxy 
qw
(
    Dumper
);

use Data::Dumper;

$Data::Dumper::Terse        = 1;
$Data::Dumper::Indent       = 1;
$Data::Dumper::Purity       = 1;
$Data::Dumper::Deepcopy     = 0;
$Data::Dumper::Quotekeys    = 0;

# keep require happy

1

__END__
