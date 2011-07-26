########################################################################
# housekeeping
########################################################################

package WCurve::Util::Print;

use v5.10;
use strict;

use Carp    qw( confess );

use Exporter::Proxy 
qw
(
    format_dump
    print_dump
    output_dump
    stdout_dump
    stderr_dump
    nastygram
    fatal
);

our $fh = '';

sub format_dump
{
    use Data::Dumper;

    local $Data::Dumper::Terse        = 1;
    local $Data::Dumper::Indent       = 1;
    local $Data::Dumper::Purity       = 0;
    local $Data::Dumper::Deepcopy     = 0;
    local $Data::Dumper::Quotekeys    = 0;

    join "\n", map { ref $_ ? Dumper $_ : $_ } @_
}

# add embelleshments as necessary later.

*nastygram   = \&format_dump;

sub print_dump
{
    local $\    = "\n";

    $fh
    ? print $fh &format_dump
    : print &format_dump
}

sub output_dump { local $fh   = shift;          &print_dump }
sub stdout_dump { local $fh   = *STDOUT{ IO };  &print_dump }
sub stderr_dump { local $fh   = *STDERR{ IO };  &print_dump }

sub fatal
{
    confess &format_dump
}

# keep require happy

1

__END__
