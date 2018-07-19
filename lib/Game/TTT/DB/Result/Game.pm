package Game::TTT::DB::Result::Game;

use strict;
use warnings;
use feature ':5.20';

use Game::TTT::DB::Candy -components => [ 
    '+Game::TTT::DB::ResultRole::GamePlayers'
  ];

table 'games';

my @statuses = qw( draw abandoned inprogress complete );
my @required_cols = qw( p1 p2 p1tok p2tok );  # can be built dynamically

primary_column 'id' => {
  data_type => 'integer',
  is_auto_increment => 1
};

column 'status' => {
  data_type => 'enum',
  is_nullable => 0,
  default_value => 'inprogress',
  extra => { list => \@statuses }
};

column 'width' => {
  data_type => 'integer',
  is_nullable => 0,
  dynamic_default_on_create => sub { 3 }
};

column 'p1' => {
  data_type => 'integer',
  is_nullable => 0,
  is_foreign_key => 1
};

column 'p1tok' => {
  data_type => 'varchar',
  is_nullable => 0
};

column 'p2' => {
  data_type => 'integer',
  is_nullable => 0,
  is_foreign_key => 1
};

column 'p2tok' => {
  data_type => 'varchar',
  is_nullable => 0
};

# what player has the current turn
column 'turn' => {
  data_type => 'varchar',
  length => 25,
  is_nullable => 1
};

column 'created_at' => {
  data_type       => 'datetime',
  is_nullable     => 0,
  set_on_create   => 1,
  timezone        => 'UTC'
};

has_one 'player1' => '::User',
        { 'foreign.id' => 'self.p1' },
        { cascade_delete => 0 };

has_one 'player2' => '::User',
        { 'foreign.id' => 'self.p2' },
        { cascade_delete => 0 };

has_many cells => '::Cell', 'game_id';


# we really only care about insert, but just in case someone tries
# to perform an update we'll catch it here
sub before_insert {
  my( $self, $changed ) = @_;

  # first, make certain all non-nullable fields are in the list --
  #    this can be done automatically using another plugin, but
  #    only so much time can be allotted to working on this

  foreach my $reqcol (@required_cols) {
    $self->throw_error( 
      sprintf( "Required field '%s' is not specified\n", $reqcol ) )
        if ! grep /^$reqcol$/, @$changed;
    $self->throw_error(
      sprintf( "field '%s' may not be undef or NULL\n", $reqcol ) )
        if ! defined $self->$reqcol;
  }

  # validate each field

  if( defined $self->width ) {
    if( $self->width !~ /^[0123456789]+/ ||
        $self->width < 3 || $self->width > 20 ) {
      $self->throw_error( "field 'width' must be an integer between 3 and 20\n" );
    }
  }

  if( ( $self->p1tok ne 'x' && $self->p2tok ne 'x' ) ||
      ( $self->p1tok ne 'o' && $self->p2tok ne 'o' ) ) {
    $self->throw_error( "player tokens must be either 'x' or 'o'\n" );
  }

  if( $self->p1tok eq $self->p2tok ) {
    $self->throw_error( "player tokens may not be the same\n" );
  }

  if( $self->p1 == $self->p2 ) {
    $self->throw_error( "A player may not play against himself\n" );
  }
}

sub before_update {
  my( $self, $changed ) = @_;

  return if( ! grep /^status$/, @$changed );

  my $old_status = $self->get_storage_value( 'status' );
  my $new_status = $self->get_column( 'status' );

  if( $old_status ne 'inprogress' ) {
    $self->throw_error( "Cannot change the status of a game no longer in progress\n" );
  }
}

# create the game cells
sub after_insert {
  my( $self ) = @_;

  my $size = $self->width * $self->width;
  foreach my $cell_ndx (1..$size) {
    $self->create_related( 'cells', { 
        index => $cell_ndx, 
        value => undef
    } );
  }
}

1;

__END__
