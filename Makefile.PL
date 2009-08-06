
use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
  DISTNAME  => 'Catalyst-Plugin-AccessLog',
  NAME      => 'Catalyst::Plugin::AccessLog',
  AUTHOR    => 'Andrew\ Rodland\ \<andrew\@hbslabs\.com\>\,\ Murray\ \<sysmon\@cpan\.org\>',
  ABSTRACT  => 'Request\ logging\ from\ within\ Catalyst',
  VERSION   => '0.02',
  EXE_FILES => [ qw() ],
  (eval { ExtUtils::MakeMaker->VERSION(6.31) } ? (LICENSE => 'perl') : ()),
  PREREQ_PM    => {
    "Scalar::Util" => '0',
    "DateTime" => '0',
    "namespace::autoclean" => '0',
    "Catalyst::Runtime" => '5.8004',
    "Moose" => '0',
  },
);
