#!/opt/bin/perl

use v5.12;
use strict;
use FindBin::libs;

use Test::More;
use Object::Exercise;

use WCurve::Score;
use WCurve::Util::Print    qw( nastygram );

my $scoreh  = WCurve::Score->new( SumChunks => ( 1 ) x 4 );

my @opz =
(
    
    [
        [
            compute =>
            [
                [   0,   1,  1,  1, 1    ],
                [   0,   1,  1, 20,20    ],
                [   0,  20, 20, 20,20    ]
            ]
        ],
        [ 0 ],
        'compute -> 0'
    ],
);

$scoreh->$exercise( @opz );

0

__END__
