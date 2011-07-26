########################################################################
# housekeeping
########################################################################

package Testify;

use v5.10;
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

for my $base ( @basz )
{
    my $name    = "$base x $length";

    my $frag
    = WCurve::Fragment->new
    (
        FloatCart => ( $base x $length ), $name
    );

    ok $frag eq $name,  "Name: $frag ($name)";

    my $i       = 0;
    my $power   = 1.0;

    my $listh   = $frag->list->head;

    while( my ( $x, $y, $z ) = $listh->each )
    {
        $power  /= 2;

        my $expect  = 1 - $power;

        my $found   = abs( $x + $y );

        ok $found  == $expect,  "Found: $found ($expect)";
        ok $x == 0 || $y == 0,  "X or Y was zero";
    }
}

done_testing;

# this is not a module

0

__END__
