package Game::TTT::DB::Result::Cell;

use strict;
use warnings;

use Game::TTT::DB::Candy -components => [
    '+Game::TTT::DB::ResultRole::Game'
  ];

table 'cells';

primary_column 'id' => {
  data_type => 'integer',
  is_auto_increment => 1
};

# numeric value for the cell w/i the particular game
column 'index' => {
  data_type => 'integer',
  is_nullable => 0
};

# x, o, or NULL
column 'value' => {
  data_type => 'varchar',
  length    => 1,
  is_nullable => 1
};

column 'game_id' => {
  data_type => 'integer',
  is_foreign_key => 1,
  is_nullable => 0
};

column 'created_at' => {
  data_type       => 'datetime',
  is_nullable     => 0,
  set_on_create   => 1,
  timezone        => 'UTC'
};

belongs_to 'game' => '::Game', 'game_id';

sub before_update {
  my( $self, $changed ) = @_;

  if( ! defined $self->value ) {
    $self->throw_error( "field 'value' must be present and non-null" );
  }

  if( $self->value ne 'x' && $self->value ne 'o' ) {
    $self->throw_error( "field 'value' must be either 'x' or 'o'" );
  }
}

1;

__END__
