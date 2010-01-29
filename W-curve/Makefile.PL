use 5.010;
use ExtUtils::MakeMaker;

WriteMakefile
(

  NAME          => 'WCurve',
  VERSION       => 0.001,
  ABSTRACT_FROM => 'lib/WCurve.pm',
  PREREQ_PM     =>
  {
    # standard distro, particular versions 
    # are unlikely to cause pain.

    overload                => 0,
    parent                  => 0,
    strict                  => 0,
    vars                    => 0,

    Benchmark               => 0,
    Carp                    => 0,
    Data::Dumper            => 0,
    Exporter::Proxy         => 0,
    ExtUtils::MakeMaker     => 0,
    File::Basename          => 0,
    Getopt::Long            => 0,
    IO::File                => 0,
    List::Util              => 0,
    Pod::Usage              => 0,
    Scalar::Util            => 0,
    Storable                => 0,
    Test::More              => 0,

    # these may not be around everywhere but
    # simplify for testing or the executables.

    FindBin::libs           => 1.40,
    Parallel::Queue         => 0,
    Test::Deep              => 0,
  },

);
