#!/opt/bin/perl

########################################################################D
# housekeeping
########################################################################

package WCurve::Util::CurView;

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
$DB::single = 1;

    my $work_dir    = shift;

    my $path
    = do
    {
        my $input       = $_->[0];

        my $base        = basename $input, @stripz;
        my $dir         = $work_dir || dirname $input;

        "$dir/$base.json"
    };

    open my $fh, '>', $path;

    my $json = $proto->read_seq( @_ )->curview;

    local $\;

    print $fh $json;

    close $fh;

    print STDERR "\nJSON output: $path\n"
    if $proto->verbose;

    $path
}

# keep require happy

1

__END__
