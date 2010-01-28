########################################################################
# housekeeping
########################################################################

package WCurve::Generate;

use v5.10;
use strict;

use Carp;

use Exporter::Proxy     qw( dispatch=generate );

use WCurve::Constants   qw( anglz cornerz TINY ZERO );

########################################################################
# package variables
########################################################################

########################################################################
# methods
########################################################################

sub fragment
{
    state $entire   = __PACKAGE__->can( 'entire' );

    my ( $wc, $seq, $name, $start, $finish ) = @_;

    $start  ||= 0;
    $finish ||= ( length $seq ) - $start;

    $seq    = substr $seq, $start, $finish;

    $name   .= "-$start-$finish";

    $wc->$entire( $seq, $name, $start, $finish );
}


# keep require happy

1

__END__
