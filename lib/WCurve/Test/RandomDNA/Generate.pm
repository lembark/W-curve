########################################################################
# housekeeping
########################################################################

package WCurve::Test::RandomDNA::Generate;

use v5.10;
use strict;

use Carp;

use Scalar::Util    qw( looks_like_number );

use Exporter::Proxy
qw
(
    uniform_random
    skewed_random
);

use WCurve::Test::RandomDNA::Constants;

########################################################################
# public interface
########################################################################

sub uniform_random
{
    my $length  = shift;

    $length
    or croak "Bogus uniform_random: false '$length'";

    looks_like_number $length
    or croak "Bogus uniform_random: non-numeric '$length'";

    $length > 0
    or croak "Bogus uniform_random: negative '$length'";

    my @basz    = @_ ? @_ : @dna;

    my $seq = ' ' x ( $length + 1 );
    $seq    = '';

    $seq    .= $basz[ rand @basz ]
    for ( 1 .. $length );

    lc $seq
}

sub skewed_random
{
    my @domain 
    = do
    {
        # i.e., duplicate the letters however 
        # many times the arguments tell us to.
        #
        # if the base doesn't show up in the args
        # then it won't show up in the output.

        my %argz    = @_;

        map
        {
            ( $_ ) x ( $argz{ $_ } || 0 )
        }
        keys %argz
    };

    splice @_, 1, $#_, @domain;

    goto &uniform_random
}

# keep require happy

1

__END__
