
use strict;
use warnings;



use ExtUtils::MakeMaker 6.31;



my %WriteMakefileArgs = (
                       'test' => {
                                   'TESTS' => 't/*.t'
                                 },
                       'NAME' => 'Catalyst::Plugin::AccessLog',
                       'DISTNAME' => 'Catalyst-Plugin-AccessLog',
                       'CONFIGURE_REQUIRES' => {
                                                 'ExtUtils::MakeMaker' => '6.31'
                                               },
                       'AUTHOR' => 'Andrew Rodland <andrew@hbslabs.com>, Murray <sysmon@cpan.org>',
                       'BUILD_REQUIRES' => {},
                       'ABSTRACT' => 'Request logging from within Catalyst',
                       'EXE_FILES' => [],
                       'VERSION' => '1.02',
                       'PREREQ_PM' => {
                                        'DateTime' => '0',
                                        'Scalar::Util' => '0',
                                        'namespace::autoclean' => '0',
                                        'Catalyst::Runtime' => '5.80008',
                                        'Moose' => '0'
                                      },
                       'LICENSE' => 'perl'
                     );


delete $WriteMakefileArgs{BUILD_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.56) };

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);



