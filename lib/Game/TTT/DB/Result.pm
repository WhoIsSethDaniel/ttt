package Game::TTT::DB::Result;

use strict;
use warnings;
use feature ':5.22';

use parent 'DBIx::Class::Core';

use Game::TTT::DB::Exception;

__PACKAGE__->load_components( qw/
                                  TimeStamp
                                  DynamicDefault
                                  Helper::Row::RelationshipDWIM
                                  OnChanges
                                / );

sub default_result_namespace { 'Game::TTT::DB::Result' }

sub throw_error { 
  my( $self, $msg ) = @_;
  Game::TTT::DB::Exception->throw( $msg );
}

1;

__END__
