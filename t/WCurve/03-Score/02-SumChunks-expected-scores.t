#!/opt/bin/perl

use v5.10;
use strict;
use FindBin::libs;

use Test::More;
use Object::Exercise;

use WCurve::Score;
use WCurve::Util::Print    qw( nastygram );

my $scorh  = WCurve::Score->new( SumChunks => );

$scorh->$_( 1 )
for $scorh->attributes;

my @opz =
(
    
    [
        # 2 * length => scale == 10

        [
            compute =>
            [
                [ 0,    1, 1, 1, 1  ],
                [ 0,    1, 1, 5, 5  ],
                [ 0,    5, 5, 5, 5  ]
            ]
        ],
        [ 0 ],
        'compute -> 0'
    ],

    [
        [
            compute => 
            [
                [ 1,    1, 1, 1, 1  ],
                [ 0,    1, 1, 5, 5  ],
                [ 0,    5, 5, 5, 5  ]
            ]
        ],
        [ 0.10 ],
        'diff = 1/10 -> 0.10',
    ],

    [
        [
            compute => 
            [
                [ 2,    1, 1, 1, 1  ],
                [ 0,    1, 1, 5, 5  ],
                [ 0,    5, 5, 5, 5  ]
            ]
        ],
        [ 0.20 ],
        'diff = 2/10 => 0.20'
    ],

    [
        [
            compute => 
            [
                [ 0,    1, 1, 1, 1  ],
                [ 2,    1, 1, 5, 5  ],
                [ 0,    5, 5, 5, 5  ]
            ]
        ],
        [ 0.20 ],
        'diff = 2/10 => 0.20'
    ],

    [
        [
            compute => 
            [
                [ 0,    1, 1, 1, 1  ],
                [ 0,    1, 1, 5, 5  ],
                [ 2,    5, 5, 5, 5  ]
            ]
        ],
        [ 0.20 ],
        'diff = 2/10 => 0.20'
    ],

    [
        [
            compute => 
            [
                [ 1,    1, 1, 1, 1  ],
                [ 1,    1, 1, 5, 5  ],
                [ 0,    5, 5, 5, 5  ]
            ]
        ],
        [ 0.20 ],
        'diff = 2/10 => 0.20'
    ],

    [
        [
            compute => 
            [
                [ 1,    1, 1, 1, 1  ],
                [ 0,    1, 1, 5, 5  ],
                [ 1,    5, 5, 5, 5  ]
            ]
        ],
        [ 0.20 ],
        'diff = 2/10 => 0.20'
    ],

    [
        [
            compute => 
            [
                [ 1,    1, 1, 1, 1  ],
                [ 1,    1, 1, 5, 5  ],
                [ 1,    5, 5, 5, 5  ]
            ]
        ],
        [ 0.30 ],
        'diff = 3/10 => 0.30'
    ],

    [
        [
            compute => 
            [
                [ 0,    1, 1, 2, 2  ],
                [ 0,    2, 2, 5, 5  ],
                [ 0,    5, 5, 5, 5  ]
            ]
        ],
        [ 0.20 ],
        'prior => [ 0,    1, 1, 2, 2  ] => 2 / 10 = 0.20'
    ],

    [
        [
            compute => 
            [
                [ 0,    1, 1, 1, 1  ],
                [ 0,    1, 1, 4, 4  ],
                [ 0,    4, 4, 5, 5  ]
            ]
        ],
        [ 0.10 ],
        'after => [ 0, 4, 4, 5, 5  ] => indel * 5-4 = 1 / 10 = 0.10'
    ],

    [
        [
            compute => 
            [
                [ 0,    1, 1, 1, 1  ],
                [ 0,          1, 1, 4, 4  ],
                [ 0,                4, 5, 4, 5  ]
            ]
        ],
        [ 0.10 ],
        '1 base gap =>  1 / 10 = 0.10',
    ],

    break =>

    [
        [
            compute => 
            [
                [ 0,    1, 1, 1, 1  ],
                [ 0,          1, 1, 3, 3  ],
                [ 0,                4, 5, 5, 5  ]
            ]
        ],
        [ 0.10 ],
        'gap = 2 - 1 = 1 / 10 = 0.10',
    ],

);

$scorh->$exercise( @opz );

0

__END__