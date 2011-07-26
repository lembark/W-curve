########################################################################
# housekeeping
########################################################################

use v5.12;
use FindBin::libs;

use Test::More;

use List::Util  qw( first );
use Symbol      qw( qualify_to_ref );

########################################################################
# package variables
########################################################################

my $pkg = 'AminoAcid';

my @typz
= qw
(
    CODE
    ARRAY
    HASH
    SCALAR
);

########################################################################
# run tests
########################################################################

use_ok $pkg;

for my $name ( $pkg->exports )
{
    my $ref     = qualify_to_ref $name, $pkg;

    my $type    = first { *{ $ref }{ $_ } } @typz;

    ok $type, "Found: '$name' ($type)";
}

done_testing;

0

__END__
