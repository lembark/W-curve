########################################################################
# housekeeping
########################################################################

package Testify;

use v5.12;
use strict;
use FindBin::libs;

use Test::More;

use WCurve::Fragment;
use WCurve::Values   qw( anglz cornerz );

########################################################################
# package variables
########################################################################

my @basz = sort grep /[^Nn]/, keys %cornerz;

# i.e., long enough to for rounding errors to crop up.

my $length  = $ENV{ LENGTH } || 48;
my $offset  = $length -1;

########################################################################
# run tests
########################################################################

plan tests => @basz * ( 1 + $length * 3 );

for my $base ( @basz )
{
    my $name    = "$base x $length";

    my $frag
    = WCurve::Fragment->new
    (
        FloatCyl => ( $base x $length ), $name
    );

    ok $frag eq $name,  "Name: $frag ($name)";

    my $i       = 0;
    my $power   = 1.0;

    my $ac      = $anglz{ $base };
    my $listh   = $frag->[0];

    $listh->head;

    while( my ( $radius, $angle, $z ) = $listh->each )
    {
        $power  /= 2;

        my $expect  = 1 - $power;

        ok $radius == $expect,  "Radius = $radius ($expect)";
        ok $angle  == $ac,      "Angle  = $angle  ($ac)";
        ok $z      == ++$i,     "Z      = $z      ($i)";
    }
}

# this is not a module

0

__END__
