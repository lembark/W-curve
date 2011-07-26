########################################################################
# housekeeping
########################################################################

package WCurve::Score::Display;

use v5.10;
use strict;

use WCurve::Util::Print qw( print_dump );

########################################################################
# package variables
########################################################################

our $VERSION    = 0.01;

sub compute
{
    # propagate the score object, display what's left.

    my ( $score, $resultz ) = @_;

    my $i   = 0;
    my $j   = 0;

    my @display
    = map
    {
        my ( $diff, $s0, $s1, $e0, $e1 ) = @$_;

        my $size    = $e0 - $s0;
        my $offset  = $s0 - $s1;
        my $gap     = $offset - $j;
        
        $j          = $offset;

        sprintf 
        "%3d: %9.6f %5d %5d %+d (%+4d)",
        $i++, $diff, $s0, $size, $gap, $offset
    }
    @$resultz;

    print_dump @display;

    $score
}

# keep require happy

1

__END__
