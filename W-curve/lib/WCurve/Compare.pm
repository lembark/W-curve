########################################################################
# housekeeping
########################################################################

package WCurve::Compare;

use v5.10;
use strict;
use vars qw( $verbose );

use Carp;

use Exporter::Proxy qw( compare );
use Scalar::Util    qw( blessed );
use Symbol          qw( qualify qualify_to_ref );

########################################################################
# package variables
########################################################################

# sanity check: requires an object.

sub compare
{
    my $wc      = $_[0];

    my $pkg     = blessed $wc
    or croak "Bogus compare: non-object '$wc'";

    my $comp    = qualify 'Compare', $pkg;

    my $handler = $comp->can( 'compare' )
    or croak "Bogus compare: '$comp' cannot 'compare'";

    goto &$handler
}

# keep require happy

1

__END__
