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
use WCurve::Test::Cmdline;

########################################################################
# package variables
########################################################################

my %cmdline = test_opts;

my $seq     = 'tagc' x 8;
my $expect  = 447;

########################################################################
# run tests
########################################################################

plan tests => 24;

my $listh
= do
{
    my $frag
    = WCurve::Fragment->new
    (
        FloatCyl => $seq, 'catg x 8'
    );

    $frag->[0]
};

$listh->head->next( 8 );

while( my ( $radius, $angle, $z ) = $listh->each )
{
    my $found   = int( 1_000 * $radius );

    ok $found == $expect, "Radius: $radius (.$expect)";
}

# this is not a module

0

__END__
