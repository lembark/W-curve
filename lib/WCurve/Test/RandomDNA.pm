########################################################################
# housekeeping
########################################################################

package WCurve::Test::RandomDNA;

use v5.10;
use strict;

use Carp;
use Symbol  qw( qualify qualify_to_ref );

use WCurve::Test::RandomDNA::Generate qw();
use WCurve::Test::RandomDNA::Munge    qw();

use Exporter::Proxy     qw( generate_seq munge_seq );

########################################################################
# package variables
########################################################################

my $generate    = qualify 'Generate';
my $munge       = qualify 'Munge';

########################################################################
# dispatchers
########################################################################

# methods avoid polluting the caller's namespace.
# they just have to discard the package and re-
# dispatch to the correct handler.

sub generate
{
    shift;

    goto &generate_seq
}

sub munge
{
    shift;

    goto &munge_seq
}

sub generate_seq
{
    my $op  = shift;

    my $handler = $generate->can( $op )
    or croak "Bogus RandomDNA: '$op' unknown in $generate";

    goto &$handler
}

sub munge_seq
{
    my $op  = shift;

    my $handler = $munge->can( $op )
    or croak "Bogus RandomDNA: '$op' unknown in $munge";

    goto &$handler
}

1

__END__
