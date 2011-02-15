
use strict;
use warnings;



use ExtUtils::MakeMaker 6.31;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'Request logging from within Catalyst',
  'AUTHOR' => 'Andrew Rodland <andrew@hbslabs.com>, Murray <sysmon@cpan.org>',
  'BUILD_REQUIRES' => {},
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.31'
  },
  'DISTNAME' => 'Catalyst-Plugin-AccessLog',
  'EXE_FILES' => [],
  'LICENSE' => 'perl',
  'NAME' => 'Catalyst::Plugin::AccessLog',
  'PREREQ_PM' => {
    'Catalyst::Runtime' => '5.80008',
    'DateTime' => '0',
    'Moose' => '0',
    'Scalar::Util' => '0',
    'namespace::autoclean' => '0'
  },
  'VERSION' => '1.04',
  'test' => {
    'TESTS' => 't/*.t'
  }
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.56) } ) {
  my $br = delete $WriteMakefileArgs{BUILD_REQUIRES};
  my $pp = $WriteMakefileArgs{PREREQ_PM};
  for my $mod ( keys %$br ) {
    if ( exists $pp->{$mod} ) {
      $pp->{$mod} = $br->{$mod} if $br->{$mod} > $pp->{$mod};
    }
    else {
      $pp->{$mod} = $br->{$mod};
    }
  }
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);



