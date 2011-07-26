########################################################################
# housekeeping
########################################################################

package WCurve::Test::RandomDNA::Constants;

use v5.12;
use strict;

use Exporter::Proxy
qw
(
    dna
    snp
);

########################################################################
# package variables
########################################################################

our @dna = qw( a c g t );

our %snp = 
(
    A   => [ qw(   C G T ) ],
    C   => [ qw( A   G T ) ],
    G   => [ qw( A C   T ) ],
    T   => [ qw( A C G   ) ],
);

$snp{ lc $_ } = $snp{ $_ }
for keys %snp;

1

__END__
