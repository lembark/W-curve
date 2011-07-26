
use v5.10;
use strict;
use FindBin::libs;

use Test::More;

use WCurve::Score;

my @expected   
= qw
(
    initialize 
    output_list
    payload
);

plan tests => scalar @expected;

ok ( WCurve::Score->can( $_ ), "WCurve::Score can '$_'" )
for @expected;

0

__END__
