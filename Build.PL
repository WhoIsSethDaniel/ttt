#!/usr/bin/env perl

use strict;
use warnings;

use Module::Build;

Module::Build->new(
  module_name        => 'Game::TTT::Service',
  dist_abstract      => 'tic-tac-toe service',
  dist_author        => 'Seth Daniel <seth@sethdaniel.org>',
  build_requires     => {
    'Test::More'           => 0,
    'Test::Fatal'          => 0,
    'Test::TempDir::Tiny'  => 0,
    'Test::Deep'           => 0
  },
  requires           => {
    'DBIx::Class'            => 0,
    'DBIx::Class::Candy'     => 0,
    'DBIx::Class::TimeStamp' => 0,
    'DBIx::Class::Helper::Row::RelationshipDWIM' => 0,
    'DBIx::Class::Helper::ResultSet::Me' => 0,
    'DBIx::Class::Helper::ResultSet::IgnoreWantarray' => 0,
    'DBD::SQLite'            => 0,
    'DateTime::Format::SQLite' => 0,
    'Dancer2'                => 0,
    'JSON'                   => 0,
    'MIME::Base64'           => 0,
    'Getopt::Long::Descriptive' => 0,
    'Moo'                    => 0
  }
)->create_build_script;
