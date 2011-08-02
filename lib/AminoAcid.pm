##############################}##########################################
# housekeeping
########################################################################

package AminoAcid;
use v5.12;

use Exporter::Proxy
qw
(
    id2name
    name2id
    id2seqz
    seq2id

    aa_table
    aa_seqs
    aa2dna
    aa2rand_dna
);

########################################################################
# package variables
########################################################################

our %id2name    = ();
our %name2id    = ();
our %id2seqz    = ();
our %seq2id     = ();

for( <DATA> )
{
    $_ && /^\w/
    or next;

    my ( $id, $name, @seqz ) = split;

    $id2name{ $id   } = $name;

    $id2seqz{ $id   } = [ sort @seqz ];
    $seq2id{ @seqz  } = ( $id ) x @seqz;
}

%name2id    = reverse %id2name;

########################################################################
# exported interface
########################################################################

sub aa_table
{
    wantarray
    ?   %id2seqz
    : { %id2seqz }
}

sub aa_seqs
{
    my $aa_id   = shift;
    my $seqz    = $id2seqz{ $aa_id }
    or die "Unknown AA id: '$aa_id'";

    wantarray
    ?   @$seqz
    : [ @$seqz ]
}

sub aa2dna
{
    my @dnaz
    = map
    {
        $id2seqz{ uc $_ }->[0]
    }
    @_;

    wantarray
    ? @dnaz
    : join '', @dnaz
}

sub aa2rand_dna
{
    my @dnaz
    = map
    {
        my $dnaz    = $id2seqz{ uc $_ };

        $dnaz->[ rand @$dnaz ]
    }
    @_;

    wantarray
    ? @dnaz
    : join ' ', @dnaz
}

sub dna2aa
{
    my $dna_seq = shift;
    my $aa_seq  = ' ' x ( length( $dna_seq ) / 3 );
    my $dna     = '';

    my @aaz
    = map
    {
        $seq2id{ $_ };
    }
    split //, $aa_seq;

    wantarray
    ? @aaz
    : "@aaz"
}

# keep require happy

1

__DATA__
I   Isoleucine      ATT ATC ATA
L   Leucine         CTT CTC CTA CTG TTA TTG
V   Valine          GTT GTC GTA GTG
F   Phenylalanine   TTT TTC
M   Methionine      ATG
C   Cysteine        TGT TGC
A   Alanine         GCT GCC GCA GCG
G   Glycine         GGT GGC GGA GGG
P   Proline         CCT CCC CCA CCG
T   Threonine       ACT ACC ACA ACG
S   Serine          TCT TCC TCA TCG AGT AGC
Y   Tyrosine        TAT TAC
W   Tryptophan      TGG
Q   Glutamine       CAA CAG
N   Asparagine      AAT AAC
H   Histidine       CAT CAC
E   Glutamic_acid   GAA GAG
D   Aspartic_acid   GAT GAC
K   Lysine          AAA AAG
R   Arginine        CGT CGC CGA CGG AGA AGG
_   Stop            TAA TAG TGA
