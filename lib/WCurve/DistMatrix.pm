########################################################################
# housekeeping
########################################################################

package WCurve::DistMatrix;

use v5.12;
use autodie qw( open close rename );

use Getopt::Long;
use Parallel::Queue;

use File::Basename;

use File::Temp      qw( tempfile );
use Scalar::Util    qw( reftype );

use Exporter::Proxy qw( dist_matrix );

########################################################################
# package variables
########################################################################

my %defaultz
= qw
(
    jobs    1
    tmpdir  /var/tmp
    outdir  /var/tmp

    frag    FloatCyl
    comp    MatchingPeaks
    score   SumChunks
);

########################################################################
# utility subs
########################################################################

sub config
{
    my %config  = %defaultz;

    if( 'HASH' eq reftype $_[0] )
    {
        my $argz    = shift;

        while( my ($k,$v) = each %$argz )
        {
            defined $v
            and $config{ $k } = $v;
        }
    }

    wantarray
    ?  %config
    : \%config
}

sub prepare_files
{
$DB::single = 1;

    my $config  = shift;

    # curves are left on the stack.

    my $i       = $#_;
    my $base    = basename $0;

    my $tmpfile = "$config->{ tmpdir }/$base-$$";

    my @rowz
    = map
    {
        [ tempfile "$tmpfile-row-$_.XXXX" ]
    }
    ( 0 .. $i );

    my $out = [ tempfile "$config->{ outdir }/$base.infile.XXXX" ];
    
    ( $out, \@rowz )
}

sub generate_row
{
$DB::single = 1;

    my ( $config, $i, $fh, $curvz ) = @_;

    my $comp    = WCurve::Compare->new( $config->{ comp } );
    my $score   = WCurve::Score->new( $config->{ score } );

    my $wc  = $curvz->[ $i ];

    for( @{ $curvz }[ ++$i .. $#$curvz ] )
    {
        my $chunkz  =  $comp->compare( $wc, $_ );

        print $fh $score->score( $chunkz ), "\t";
    }

    close $fh;

    return
}

sub merge_rows
{
$DB::single = 1;

    my $rowz    = shift;

    # matrix starts out as upper triangular.

    my @matrix 
    = map
    {
        my $path    = $_->[1];

        open my $fh, '<', $path;

        local $/;

        [ 0, split /\t/, <$fh> ]
    }
    @$rowz;

    # reflecting the columns into rows squares it.

    my $i   = -1;

    for my $row ( @matrix )
    {
        my $j       = $i++;

        my @reflect = map { $_->[$i] } @matrix[ 0 .. $j ];

        unshift $row, @reflect;
    }

    \@matrix
}

sub output_phylip
{
$DB::single = 1;

    my ( $out, $curvz, $rowz ) = @_;

    print $out scalar @$curvz;
    print $out "\n";

    for my $row ( @$rowz )
    {
        printf $out '%-10.10s' => shift @$curvz;
        printf $out "\t%8.6f" => $_ for @$row;
        print  $out "\n";
    }

    close $out;

    return
}

sub cleanup
{
$DB::single = 1;

    my ( $out, $rowz ) = @_;

    unlink $_->[1] for @$rowz;

    ( my $final = $out->[1] ) =~ s/[.]\w+/;

    rename $out->[1], $path;

    $path
}

########################################################################
# exported
########################################################################

sub dist_matrix
{
$DB::single = 1;

    my $wc  = shift;

    my $config  = &config;

    my $curvz   = \@_;

    my ( $out, $rowz ) = prepare_files $config, @_;

    my @queue
    = map
    {
        my $i   = $_;

        sub { generate_row $config, $i, $rowz->[$i][0], $curvz }
    }
    ( 0 .. $#$curvz );

    eval { run_queue $config->{ jobs }, @queue }
    and die "Incomplete queue: $@";

    my $square  = merge_rows $rowz;

    output_phylip $out->[0], $curvz, $square;

    # caller gets back the output path;

    cleanup $out, $rowz;
}

# keep require happy

42

__END__
