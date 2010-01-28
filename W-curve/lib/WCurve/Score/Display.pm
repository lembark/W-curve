########################################################################
# housekeeping
########################################################################

package WCurve::Score::Display;

use v5.10;
use strict;

use List::Util      qw( max min sum );

use Exporter::Proxy
qw
(
    dump_chunks
);


use WCurve::Dumper;

########################################################################
# package variables
########################################################################

my $verbose = 1;    # progress messages
my $debug   = '';   # skips, snps
my $trace   = '';   # all decision values

########################################################################
# utility subs
########################################################################

########################################################################
# compare entries look like:
# 
# [
#   n0 initial
#   n1 initial
#   n0 final
#   n1 final
#   sum of diff
# ]
########################################################################

sub dump_chunks
{
    my ( $wc, $chunkz ) = @_;  

    local $,    = "\n";
    local $\    = "\n";

    print "$wc", Dumper $chunkz;

    return 1
}

# keep require happy

1

__END__
