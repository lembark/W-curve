#!/opt/bin/perl

########################################################################D
# housekeeping
########################################################################

package WCurve::Util::JSON;

use v5.12;
use FindBin::libs;
use autodie qw(open close );

use File::Basename;
use JSON::XS;

use WCurve;
use WCurve::Util::ColorTable;

use Exporter::Proxy
qw
(
    fasta2json
);

########################################################################
# package variables
########################################################################

# prototype WCurve, used to call read_seq on the inputs.

my $proto   = WCurve->new( qw( FloatCyl template ) );
my $tiny    = 2 ** -20;

my @fasta_suff  = qw( .bz2 .gz .fasta .fa );

########################################################################
# utility subs
########################################################################

sub fasta2json
{
    my $work    = shift;

    my @pathz
    = map
    {
        my $dir = $work || dirname $_;

        map
        {
            $_->write_json( $dir );
        }
        $proto->read_seq( $_ );
    }
    @_;

    print join "\n\t", "JSON output:", @pathz
    if $proto->verbose;

    wantarray
    ?  @pathz
    : \@pathz
}

# keep require happy

1

__END__
