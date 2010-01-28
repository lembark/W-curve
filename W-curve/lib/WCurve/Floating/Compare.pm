########################################################################
# housekeeping
########################################################################

package WCurve::Floating::Compare;

use v5.10;
use strict;
use vars qw( $verbose );

# pull in the comparision code.
# each module needs to export the valid $type 
# argument for compare.

use WCurve::Floating::Compare::MatchingPeaks;

use Exporter::Proxy qw( dispatch=compare );

$verbose    = $ENV{ VERBOSE } || 0;

sub verbose
{
    $verbose    = $_[1] // $verbose
}

# keep require happy

1

__END__
