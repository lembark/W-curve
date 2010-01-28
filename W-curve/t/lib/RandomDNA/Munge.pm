########################################################################
# housekeeping
########################################################################

package RandomDNA::Munge;

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

use RandomDNA::Constants;
use RandomDNA::Generate;

########################################################################
# public interface
########################################################################

sub single_snp
{
    my $offset      = shift;

    @_ or return;

    looks_like_number $offset
    or croak "Bogus single_snp: non-numeric '$offset'";

    $offset >= 0
    or croak "Bogus single_snp: negative '$offset'";

    for( @_ )
    {
        my $base    = substr $_, $offset, 1
        or croak "Bogus single_snp: $offset > length seq", "\n$_\n";

        my $snpz    = $snp{ $base };
        my $alt     = $snpz->[ rand @$snpz ];

        substr $_, $offset, 1, $alt;
    }

    return
}

sub multiple_snp
{
    for my $offset ( @_[ 1 .. $#_ ] )
    {
        my $base    = substr $_[0], $offset, 1;
        my $snpz    = $snp{ $base };
        my $alt     = $snpz->[ rand @$snpz ];

        substr $_[0], $offset, 1, $alt;
    }

    return
}

sub random_snp
{
    my $count   = shift;

    @_      or return;
    $count  or return;

    looks_like_number $count
    or croak "Bogus uniform_random: non-numeric '$count'";

    $count > 0
    or croak "Bogus uniform_random: negative '$count'";

    for( @_ )
    {
        for( 1 .. $count )
        {
            my $i   = int rand length;

            single_snp $i, $_
        }
    }

    return
}

sub offset_replace
{
    my ( $offset, $size ) = splice @_, 0, 2;

    @_      or return;
    $size   or return;

    looks_like_number $size 
    or croak "Bogus uniform_random: non-numeric '$size'";

    $size > 0
    or croak "Bogus uniform_random: negative '$size'";

    looks_like_number $offset 
    or croak "Bogus uniform_random: non-numeric '$offset'";

    $offset >= 0
    or croak "Bogus uniform_random: negative '$offset'";

    for( @_ )
    {
        my $replace = uniform_random $size;

        substr $_, $offset, $size, $replace;
    }

    return
}

sub random_replace
{
    my $size    = shift;

    @_      or return;
    $size   or return;

    looks_like_number $size 
    or croak "Bogus uniform_random: non-numeric '$size'";

    $size > 0
    or croak "Bogus uniform_random: negative '$size'";

    for( @_ )
    {
        my $length  = length;
        my $offset  = rand ( $length - $size - 1 );

        offset_replace $offset, $size, $_
    }

    return
}

sub insert_gap
{
    my ( $offset, $size ) = splice @_, 0, 2;

    # sequence(s) to munge are on the stack.

    for( @_ )
    {
        my $gap = uniform_random $size;

        ref $_
        ? substr $$_, $offset, 0, $gap
        : substr  $_, $offset, 0, $gap
        ;
    }

    return
}

# keep require happy

1

__END__
