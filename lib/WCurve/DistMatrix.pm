########################################################################
# housekeeping
########################################################################

package WCurve::DistMatrix;

use v5.12;
use autodie qw( open close rename );

use Getopt::Long;
use Parallel::Queue;

use File::Basename;

use File::Path      qw( make_path remove_tree   );
use File::Temp      qw( tempfile                );
use Scalar::Util    qw( reftype                 );

use Exporter::Proxy qw( dist_matrix );

########################################################################
# package variables
########################################################################

our $verbose    = '';

my %defaultz
= qw
(
    jobs    1
    tmpdir  /var/tmp
    output  /var/tmp/w-curve.infile

    frag    FloatCyl
    comp    MatchingPeaks
    score   SumChunks
);

$defaultz{ session } = '';

my $rmtree_optz =
{
    safe        => 1,
    keep_root   => 1,
};

my $base    = basename $0;

########################################################################
# utility subs
########################################################################

sub config
{
    my %config  = ( pid => $$ );

    if( 'HASH' eq reftype $_[0] )
    {
        my $argz    = shift;

        while( my ($k,$v) = each %defaultz )
        {
            $config{ $k } = $argz->{ $k } // $v;
        }
    }

    $config{ session } ||= join '-', $base, int rand 32678;
    $config{ workdir } //= "$config{ tmpdir }/$config{ session }";
    $config{ outfile } //= "$base.infile";

    print "Working directory: $config{ workdir }"
    if $verbose;

    $config{ comp }
    = WCurve::Compare->new( $config{ comp } );

    $config{ score }
    = WCurve::Score->new( $config{ score } );

    wantarray
    ?  %config
    : \%config
}

sub prepare_files
{
    my $config  = shift;

    # curves are on the stack

    my $workdir = $config->{ workdir };

    -e $workdir || make_path $workdir
    or die "Failed make_path $workdir: $!";

    my @rowz
    = map
    {
        File::Temp->new( DIR => $workdir, UNLINK => 0 )
    }
    ( 1 .. @_ );

    wantarray
    ?  @rowz
    : \@rowz
}

sub generate_row
{
    my ( $config, $i, $tmpfile, $curvz ) = @_;

    my ( $comp, $score ) 
    = @{ $config }{ qw( comp score ) };

    my $wc  = $curvz->[ $i ];
    
    local $\;

    for( @{ $curvz }[ ++$i .. $#$curvz ] )
    {
        local $0    = "Compare: $wc $_";

        my $chunkz  =  $comp->compare( $wc, $_ );

        print $tmpfile $score->compute( $chunkz ), "\t";
    }

    $tmpfile->flush;

    my $size = -s $tmpfile;

    warn "\nOutput: '$wc' ($tmpfile, $size)\n"
    if $verbose;

    $$ != $config->{ pid }
    ? exit 0
    : return
}

sub merge_rows
{
    my $rowz    = shift;

    # matrix starts out as upper triangular.

    my @matrix 
    = map
    {
        print "Read row: $_\n"
        if $verbose;

        $_->seek( 0, 0 );

        local $/;

        [ 0, split /\t/, <$_> ]
    }
    @$rowz;

    # reflecting the columns into rows squares it.

    my $i   = 0;

    for my $row ( @matrix[1..$#matrix] )
    {
        my $j       = $i++;

        my @reflect = map { $_->[$i] } @matrix[ 0 .. $j ];

        unshift $row, @reflect;
    }

    \@matrix
}

sub output_phylip
{
    my ( $config, $curvz, $matrix ) = @_;

    my ( $out, $path ) = tempfile "$config->{ output }.XXXX";

    print "\nOutput: $config->{ output }\n"
    if $verbose;

    print $out scalar @$curvz;
    print $out "\n";

    for( 0 .. $#$matrix )
    {
        printf $out '%-10.10s'  => $curvz->[$_];
        printf $out "\t%8.6f"   => $_ for @{ $matrix->[$_] };
        print  $out "\n";
    }

    close $out;

    rename $path, $config->{ output };

    return
}

sub cleanup
{
    my $config  = shift;

    remove_tree $config->{ workdir }, $rmtree_optz;

    return
}

########################################################################
# exported
########################################################################

sub dist_matrix
{
    my $wc      = shift;
    my $config  = &config;

    local $verbose  = $config->{ verbose } // $wc->verbose // -t;

    for( $config->{ outfile } )
    {
        -e      or last;
        unlink  or die;
    }

    my $output
    = eval
    {
        my $curvz   = \@_;
        my $rowz    = prepare_files $config, @_;

        my @queue
        = map
        {
            my $i   = $_;

            sub { generate_row $config, $i, $rowz->[$i], $curvz }
        }
        ( 0 .. $#$curvz );

        runqueue $config->{ jobs }, @queue
        and die "Unfinished queue";

        my $square  = merge_rows $rowz;

        output_phylip $config, $curvz, $square;

        $config->{ output }
    };

    cleanup $config;

    $output
}

# keep require happy

42

__END__
