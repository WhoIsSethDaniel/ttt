package Game::TTT::DB::Result::User;

use strict;
use warnings;

use Game::TTT::DB::Candy;

table 'users';

primary_column 'id' => {
  data_type => 'integer',
  is_auto_increment => 1
};

column 'name' => {
  data_type => 'varchar',
  is_nullable => 0,
  size => 25
};

column 'created_at' => {
  data_type       => 'datetime',
  is_nullable     => 0,
  set_on_create   => 1,
  timezone        => 'UTC'
};

unique_constraint 'name' => [ 'name' ];

sub before_change {
  my( $self, $changed ) = @_;

  if( ! defined $self->name ) {
    $self->throw_error( "field 'name' must have a value\n" );
  }

  if( length($self->name) > 25 ) {
    $self->throw_error( "field 'name' may be no more than 25 characters\n" );
  }
}

1;

__END__
