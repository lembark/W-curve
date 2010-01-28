########################################################################
# housekeeping
########################################################################

package Testify;

use v5.10;
use strict;
use FindBin::libs;
use vars qw( %cornerz );

use Data::Dumper;
use Test::More;
use Test::Deep;

use WCurve;

########################################################################
# package variables
########################################################################

my @basz = sort keys %WCurve::cornerz;

my $compare = WCurve::Floating->can( 'compare' )
or die "Bogus $0: WCurve::Floating cannot 'compare'";

########################################################################
# run tests
########################################################################

for my $base ( @basz )
{
    state $length   = 64;

    my $wc  = WCurve->new( Floating => $base x $length, "$base x $length" );

    ok $length == $wc, "Length $wc == $length";

    my $n   = $wc->[0];
    my $r   = 0.0;
    my $a   = 0.0;
    my $z   = 0;
    my $pow = 1.0;

    my $ac  = $WCurve::anglz{ $base };

    for( 0 .. -1 + $wc )
    {
        ( $n, $r, $a, $z ) = @$n;

        $pow    /= 2;

        my $expect  = 1 - $pow;

        ok $r == $expect,   "Radius = $r ($expect)";
        ok $a == $ac,       "Angle  = $a ($ac)";
        ok $z == $_,        "Z-axis = $z ($_)";
    }
}

done_testing;

# this is not a module

0

__END__
