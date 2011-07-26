########################################################################
# housekeeping
########################################################################

package WCurve::Compare::PrintResults;

use v5.10;
use strict;

use Carp;

use Exporter::Proxy qw( print_results );
use List::Util      qw( sum min max );

########################################################################
# dispatcher
########################################################################

sub print_results
{
    if( ! ref $_[1] )
    {
        my $op  = splice @_, 1, 1;

        my $handler = __PACKAGE__->can( $op )
        or confess "Bogus print_results: unknown '$op'";

        goto &$handler
    }
    else
    {
        my ( $comp, $wc0, $wc1 ) = @_;

        given( $comp->compare_type( $wc0, $wc1 ) )
        {
            when( 0 ) { goto &single_single }
            when( 1 ) { goto &single_multi  }
            when( 2 ) { goto &multi_multi   }
        }
    }
}

########################################################################
# via dispatcher

sub partition
{
    my ( $comp, $wc, $template ) = splice @_, 0, 3;

    # result array is left on the stack.

    my @chunkz  = ();

    my $start   = 0;

    print "\n\n";

    my @fragz   = $template->fragments;

    my ( $frag_format, $filler )
    = do
    {
        my $a   = max map { length "$_" } @fragz;
        my $b   = '[ %5d .. %5d ]';

        (
            "%s %-$a.${a}s  $b : $b\t%7.4f %5d %5d (%3d%% )\n",
            ' ' x ( $a + length "$template" )
        )
    };

    print "Partition:\t$wc\n";

    print $filler, ' ' x 48, "\tCompare  Tmpl  Used (Used%)\n";

    for my $frag ( @fragz )
    {
        my $a   = shift 
        or next;

        $frag->filler
        and next;

        @chunkz
        = @$a > 2
        ? @$a
        : ( [ ( 0 ) x 5 ] ) x 3
        ;

        my $prior   = shift @chunkz;
        my $after   = pop   @chunkz;

        my $size    = $frag->size;

        my $total
        = $chunkz[0][1] 
        ? $chunkz[-1][3] - $chunkz[0][1] + 1
        : 0
        ;

        my $pct     = int ( 100 * $total / $size );

        $start      ||= $frag->start - 1;

        my $diff
        = sum map 
        {
            $_
            ? $_->[0] / ( $_->[3] - $_->[1] + 1 )
            : 0
        }
        @chunkz;

        printf $frag_format,
        "$template",
        "$frag",
        $chunkz[ 0][1]  ,
        $chunkz[-1][3]  ,
        $chunkz[ 0][2]  ,
        $chunkz[-1][4]  ,
        $diff,
        $size           , # Length
        $total          , # Used Bases
        $pct            , # Used Pct
        ;

        if( $comp->verbose )
        {
            print "\n";

            if( @$a )
            {
                my $last    = $prior;

                for( @chunkz )
                {
                    my $run     = $_->[3] - $_->[1];
                    my $pct     = 100 * $run / $size;
                    my $offset  = $_->[1] - $_->[2];

                    my $i   = $_->[1] - $last->[3];
                    my $j   = $_->[2] - $last->[4];

                    my $skip    = min( $i, $j );
                    my $gap     = max( $i, $j ) - $skip;

                    printf 
                    "%s [ %5d .. %5d ] : [ %5d .. %5d ] %5d (%5.1f%%) +%d\n",
                    $filler,
                    @{$_}[2,4,1,3,0],
                    $run,
                    $pct,
                    $offset,
                    ;

                    printf "  %5d gap", $gap
                    if $gap;

                    print "\n";

                    $last   = $_;
                }
            }
            else
            {
                # deal with the unalgined fragments.
                # for now this is a non-issue.
            }
        }
    }

    print "\n\n";

    return
}

sub single_single
{
    my ( $comp, $wc0, $wc1 ) = splice @_, 0, 3;

    # result array is left on the stack.

    my @chunkz
    = ref $_[0][0]
    ? @{ $_[0] }
    : @_
    ;

    my ( $frag0 ) = $wc0->fragments;
    my ( $frag1 ) = $wc1->fragments;

    my $size0   = $frag0->size;
    my $size1   = $frag1->size;

    my $diff    = sum map { $_->[0] } @chunkz;

    my $prior   = shift @chunkz;
    my $after   = pop   @chunkz;

    my $total0  = $after->[1] - $prior->[3] + 1;
    my $total1  = $after->[2] - $prior->[4] + 1;

    printf 
    "\nChunk\t\t[ %-14.14s ] %7s [ %-14.14s ] %7s %7s\n",
    "$wc0"  ,
    'Size'  ,
    "$wc1"  ,
    'Size'  ,
    'Offset',
    ;

    printf 
    "\n\t\t[ %-14.14s ] (%5d) [ %-14.14s ] (%5d)\n",
    "$frag0"    ,
    $size0      ,
    "$frag1"    ,
    $size1      ,
    ;

    printf "\t%7.4f\t[ %5d .. %5d ] (%5d) [ %5d .. %5d ] (%5d)\n\n",
    $diff,
    $prior->[3] ,
    $after->[1] ,
    $total0     ,
    $prior->[4] ,
    $after->[2] ,
    $total1     ,
    ;

    my $i       = 0;
    my $offset  = 0;

    for my $chunk ( @chunkz )
    {
        $chunk  or next;
        @$chunk or next;

        $total0     = $chunk->[3] - $chunk->[1];
        $total1     = $chunk->[4] - $chunk->[2];

        $offset     = $chunk->[1] - $chunk->[2];

        printf "(%3d)\t%7.4f\t[ %5d .. %5d ] (%5d) [ %5d .. %5d ] (%5d) (%5d)\n",
        ++$i,
        $chunk->[0],
        $chunk->[1] ,
        $chunk->[3] ,
        $total0     ,
        $chunk->[2] ,
        $chunk->[4] ,
        $total1     ,
        $offset     ,
        ;
    }

    print "\n";

    return
}

sub single_multi
{
    my ( $comp, $wc0, $wc1 ) = splice @_, 0, 3;

    # result array is left on the stack.

    my @resultz
    = ref $_[0][0][0]
    ? @{ $_[0] }
    : @_
    ;

    my ( $frag0 )   = $wc0->fragments;

    my $size0       = $frag0->size;

    for my $frag1 ( $wc1->fragments )
    {
        my $chunkz  = shift @resultz
        or next;

        my $size1   = $frag1->size;

        my $diff    = sum map { $_->[0] } @$chunkz;

        my $prior   = shift @$chunkz;
        my $after   = pop   @$chunkz;

        my $total0  = $after->[1] - $prior->[3] + 1;
        my $total1  = $after->[2] - $prior->[4] + 1;

        printf 
        "\nChunk\t\t[ %-14.14s ] %7s [ %-14.14s ] %7s %7s\n",
        "$wc0"  ,
        'Size'  ,
        "$wc1"  ,
        'Size'  ,
        'Offset',
        ;

        printf 
        "\n\t\t[ %-14.14s ] (%5d) [ %-14.14s ] (%5d)\n",
        "$frag0"    ,
        $size0      ,
        "$frag1"    ,
        $size1      ,
        ;

        printf "\t%7.4f\t[ %5d .. %5d ] (%5d) [ %5d .. %5d ] (%5d)\n\n",
        $diff,
        $prior->[3] ,
        $after->[1] ,
        $total0     ,
        $prior->[4] ,
        $after->[2] ,
        $total1     ,
        ;

        my $i       = 0;
        my $offset  = 0;

        for my $chunk ( @$chunkz )
        {
            $chunk  or next;
            @$chunk or next;

            $total0     = $chunk->[3] - $chunk->[1];
            $total1     = $chunk->[4] - $chunk->[2];

            $offset     = $chunk->[1] - $chunk->[2];

            printf "(%3d)\t%7.4f\t[ %5d .. %5d ] (%5d) [ %5d .. %5d ] (%5d) (%5d)\n",
            ++$i,
            $chunk->[0],
            $chunk->[1] ,
            $chunk->[3] ,
            $total0     ,
            $chunk->[2] ,
            $chunk->[4] ,
            $total1     ,
            $offset     ,
            ;
        }
    }

    print "\n";

    return
}

sub multi_multi
{
    # stub
}


# keep require happy

1

__END__
