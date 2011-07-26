
use FindBin::libs;

use Test::More;

my $madness = 'WCurve::Util::JSON';
my @methodz
= qw
(
    import
    fasta2json
);

use_ok $madness;

for my $method ( @methodz )
{
    ok $madness->can( $method ), "$madness has '$method'";
}

done_testing;
