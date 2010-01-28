########################################################################
# housekeeping
########################################################################

package WCurve::Util;

use v5.10;
use strict;

use Exporter::Proxy 
qw
(
    format_dump
    print_dump
    output_dump
);

sub format_dump
{
    use Data::Dumper;

    local $Data::Dumper::Terse        = 1;
    local $Data::Dumper::Indent       = 1;
    local $Data::Dumper::Purity       = 0;
    local $Data::Dumper::Deepcopy     = 0;
    local $Data::Dumper::Quotekeys    = 0;

    map { ref $_ ? Dumper $_ : $_ } @_
}

sub print_dump
{
    my $fh  = shift;

    local $,    = "\n";
    local $\    = "\n";

    print $fh &format;

    return
}

sub output_dump
{
    unshift @_, *STDOUT{ IO };

    goto &print_dump
}

# keep require happy

1

__END__
