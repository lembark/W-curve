########################################################################
# housekeeping
########################################################################

use v5.10;
use strict;
use FindBin::libs;

use Test::More;

use WCurve;
use WCurve::Test::RandomDNA;

########################################################################
# package variables
########################################################################

my $chunkz = 
[
    [
        # w/ gap-cost == 1.0, 
        # initial alignment yields:
        #
        # prior => ( 0.5 + 2.0 ) = 2.5

        qw
        (
            0
            0
            1
            3
            0.5
        )
    ],
    [
        # i = 2 - 1 = 1
        # j = 6 - 3 = 3
        # k = 100
        # skip = min 3,1 = 1
        # gap  = max 3,1 - skip = 3 - 1 = 2
        # score = 1 * ( 0.5/100) + ( 2 * 2 ) + 0.5 = 4.505

        qw
        (
            2
            6
            102
            106
            0.5
        )
    ],
    [
        # i = 110 - 110 = 0
        # j = 119 - 109 = 10
        # score = 0 + ( 10 - 0 ) = 10

        qw
        (
            110
            109
            110
            119
            0
        )
    ],


    # total score = ( 2.5 + 2.505 + 10 ) / 119

];

my $expect = ( 2.5 + 4.505 + 10 ) / ( 110 + 119 );

########################################################################
# utility subs
########################################################################

########################################################################
# run test
########################################################################

my $found   = WCurve::Score->score( SimpleTotal => $chunkz );

my $diff    = abs( $found - $expect );

ok 0.000001 > $diff, "Compare is $found ($diff)";

done_testing;

# this is not a module

0

__DATA__