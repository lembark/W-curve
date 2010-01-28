########################################################################
# housekeeping
########################################################################

package RandomDNA;

use v5.10;
use strict;

use Carp;

use Exporter::Proxy qw( generate_seq munge_seq );

use RandomDNA::Generate qw();
use RandomDNA::Munge    qw();

sub generate_seq
{
    my ( undef, $op )  = splice @_, 0, 2;

    my $handler = RandomDNA::Generate->can( $op )
    or croak "Bogus RandomDNA: '$op' unknown";

    goto &$handler
}

sub munge_seq
{
    my ( undef, $op )  = splice @_, 0, 2;

    my $handler = RandomDNA::Munge->can( $op )
    or croak "Bogus RandomDNA: '$op' unknown";

    goto &$handler
}

1

__END__
