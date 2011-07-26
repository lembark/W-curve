########################################################################
# housekeeping
########################################################################

package WCurve::Test::RandomDNA::Munge;

use v5.10;
use strict;

use Carp;

use List::Util      qw( shuffle );
use Scalar::Util    qw( looks_like_number );

use Exporter::Proxy
qw
(
    single_snp
    multiple_snp
    random_snp
    offset_replace
    random_replace
    insert_gap
);

use WCurve::Test::RandomDNA::Constants;
use WCurve::Test::RandomDNA::Generate;

our $verbose    = '';

########################################################################
# public interface
########################################################################

sub single_snp
{
    my $offset      = $_[1];

    looks_like_number $offset
    or croak "Bogus single_snp: non-numeric '$offset'";

    $offset >= 0
    or croak "Bogus single_snp: negative '$offset'";

    for( $_[0] )
    {
        my $base    = substr $_, $offset, 1
        or croak "Bogus single_snp: $offset > length seq", "\n$_\n";

        my $snpz    = $snp{ $base };

        substr $_, $offset, 1, $snpz->[ rand @$snpz ];
    }

    return
}

sub multiple_snp
{
    print "SNP:\n"
    if $verbose;

    for( $_[0] )
    {
        for my $offset ( @_[ 1 .. $#_ ] )
        {
            my $base    = substr $_, $offset, 1;
            my $snpz    = $snp{ $base };
            my $alt     = $snpz->[ rand @$snpz ];
            
            print " $offset-$base-$alt"
            if $verbose;

            substr $_, $offset, 1, $alt;
        }
    }

    print "\n"
    if $verbose;

    return
}

sub random_snp
{
    my $count   = $_[1];

    $count  or return;

    looks_like_number $count
    or croak "Bogus uniform_random: non-numeric '$count'";

    $count > 0
    or croak "Bogus uniform_random: negative '$count'";

    for( $_[0] )
    {
        my $i   = length;
        my $p   = $count / $i;

        my @offsetz = grep { $p > rand } ( 0 .. $i - 1 );

        multiple_snp $_, @offsetz;
    }

    return
}

sub offset_replace
{
    my ( $offset, $size ) = @_[1,2];

    $size   or return;

    looks_like_number $size 
    or croak "Bogus uniform_random: non-numeric '$size'";

    $size > 0
    or croak "Bogus uniform_random: negative '$size'";

    looks_like_number $offset 
    or croak "Bogus uniform_random: non-numeric '$offset'";

    $offset >= 0
    or croak "Bogus uniform_random: negative '$offset'";

    for( $_[0] )
    {
        my $replace = uniform_random $size;

        substr $_, $offset, $size, $replace;
    }

    return
}

sub random_replace
{
    my $size    = $_[1];

    $size   or return;

    looks_like_number $size 
    or croak "Bogus uniform_random: non-numeric '$size'";

    $size > 0
    or croak "Bogus uniform_random: negative '$size'";

    for( $_[0] )
    {
        my $length  = length;
        my $offset  = rand ( $length - $size - 1 );

        offset_replace $offset, $size, $_
    }

    return
}

sub generate_gap
{
    my ( $offset, $size ) = @_[1,2];

    $size or return;

    # sequence(s) to munge are on the stack.
    # process ensures that the gap does not 
    # match the string;

    map 
    {
        my $gap = substr $_, $offset, $size;

        $gap    =~ s{(.)}{$snp{$1}[rand 3]}g;

        $gap
    }
    $_[0]
}

sub insert_gap
{
    my ( $offset, $size ) = @_[1,2];

    $size or return;

    my ( $gap ) = &generate_gap;

    for( $_[0] )
    {
        if( $verbose )
        {
            # convert offset to count for base numbers.

            my $size    = length $_[0];
            my $top     = $offset + 1;
            my $end     = $top + $size;

            print "Gap: $gap ($size)($top - $end)\n";
        }

        substr $_, $offset, 0, $gap;
    }

    $gap
}

sub gap_list
{
    map { insert_gap $_[0], @$_ } @_[1..$#_]
}

sub random_gap
{
    my ( $count, $max ) = splice @_, 1;

    $count or return;

    my $size    = length $_[0];
    my $p       = $count / $size;

    push @_, 
    map
    {
        $p > (rand)
        ? [ $_, int rand $max ]
        : ()
    }
    reverse ( 0 .. --$size );

    goto &gap_list
}

# keep require happy

1

__END__
