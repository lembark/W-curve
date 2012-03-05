########################################################################D
# housekeeping
########################################################################

package WCurve::Util::CurView;

use v5.12;
use FindBin::libs;
use autodie qw( open close );

use File::Basename;

use WCurve;

use Exporter::Proxy
qw
(
    fasta2curview
);

########################################################################
# package variables
########################################################################

my $proto   = WCurve->new( qw( FloatCyl template ) );

my @stripz
= qw
(
    .gz
    .bz2
    .fasta
    .fa
);

########################################################################
# exported
########################################################################

sub fasta2curview
{
    my $work_dir    = shift;

    my $path
    = do
    {
        my $input       = $_[0];

        my $base        = basename $input, @stripz;
        my $dir         = $work_dir || dirname $input;

        "$dir/$base.json"
    };

    my $json    = $proto->read_seq( @_ )->curview;

    open my $fh, '>', $path;

    local $\;

    print $fh $json;

    close $fh;

    print STDERR "\nJSON output: $path\n"
    if $proto->verbose;

    wantarray
    ? ( $path => $json )
    : $path
}

# keep require happy

1

__END__
