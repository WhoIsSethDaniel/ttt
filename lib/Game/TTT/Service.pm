package Game::TTT::Service;

use strict;
use warnings;
use feature ':5.20';

use Dancer2;
set serializer => 'JSON';
use Dancer2::Core::Error;

use Try::Tiny;
use Game::TTT::Schema;
# use Game::TTT::DB::Exception;
use MIME::Base64 'decode_base64';

hook before => sub {
  my( $app ) = @_;

  # This service assumes that the user has been authenticated
  #   and that the username continues to be in the Authorization
  #   header.

  # should probably use a Plugin for this. 
  my $header = $app->request->header( 'Authorization' );
  if( ! defined $header ) {
    send_error( "Must have authorization header", 400 );
  }
  my( $auth_method, $auth_hash ) = split( ' ', $header );
  if( $auth_method ne 'Basic' || ! defined $auth_hash ) {
    send_error( "Must have authorization header", 400 );
  }
  my( $username ) = split( ':', decode_base64($auth_hash));
  if( ! defined $username ) {
    send_error( "No username given in authorization header", 401);
  }

  if( ! defined $username ) {
    send_error( "You must supply a valid user", 404 );
  }

  my $db = Game::TTT::Schema->connect;

  my $user =
    $db->resultset( 'User' )
       ->find( { name => $username } );

  if( ! defined $user ) {
    send_error( "The given user does not exist", 404 );
  }

  var db   => $db;
  var user => $user;
};

get '/users' => sub {
  my @users =
    map { $_->name }
    vars->{db}
        ->resultset( 'User' )
        ->all;
  return { users => \@users };
};

get '/users/:name' => sub {
  my $username = route_parameters->get( 'name' );
  my $user = 
    vars->{db}
        ->resultset( 'User' )
        ->find( { name => $username } );
  return {
    name   => $username,
    exists => defined $user ? 1 : 0
  };
};

post '/users/:name' => sub {
  my $username = route_parameters->get( 'name' );

  my $user = 
    model_guard( sub {
      vars->{db}
          ->resultset( 'User' )
          ->create( {
              name => $username
            } );
    } );

  return { 
    name  => $username,
    created => 1
  };
};

# only show the games in which the requester is a player
get '/games' => sub {
  my $games =
    vars->{ db }
        ->resultset( 'Game' )
        ->search( { 
            -or => {
                     p1 => vars->{ user }->id,
                     p2 => vars->{ user }->id
                   }
          },
          {
            prefetch => [ qw( player1 player2 ) ]
          } );
  my @games;
  while( my $game = $games->next ) {
    push @games, {
      id => $game->id,
      width => $game->width,
      player1 => $game->player1->name,
      player2 => $game->player2->name,
      player1_token => $game->p1tok,
      player2_token => $game->p2tok,
      status => $game->status,
      turn => $game->turn,
      created_at => $game->created_at->ymd
    }
  }

  return {
    username => vars->{ user }->name,
    games => \@games
  };
};

get '/games/:id' => sub {
  my $game_id = route_parameters->get( 'id' );

  debug "looking up game id: $game_id";
  my $game =
    vars->{ db }
        ->resultset( 'Game' )
        ->search( {
            'me.id' => $game_id,
            -or => {
                     p1 => vars->{ user }->id,
                     p2 => vars->{ user }->id
                   }
          },
          {
            prefetch => [ qw( player1 player2 cells ) ]
          } )
        ->first; # should only be one (or zero)


  if( defined $game ) {
    my @board = map { $_->value // '-' } $game->cells->all;
    return {
      username => vars->{ user }->name,
      game => {
        id => $game->id,
        width => $game->width,
        player1 => $game->player1->name,
        player2 => $game->player2->name,
        player1_token => $game->p1tok,
        player2_token => $game->p2tok,
        status => $game->status,
        turn => $game->turn,
        created_at => $game->created_at->ymd,
        board => \@board
      }
    };
  } else {
    # the game may not exist, but we won't tell the user this
    send_error( 'Unauthorized to view this game', 401 );
  }
};

# Right now a user can create a game for any other two users. 
# Is that wrong? :-(
post '/games' => sub {
  my $width = body_parameters->get( 'width' );
  my $p1    = body_parameters->get( 'player1' );
  my $p2    = body_parameters->get( 'player2' );
  my $p1tok = body_parameters->get( 'player1_token' );
  my $p2tok = body_parameters->get( 'player2_token' );

  my $grs =
    vars->{db}
        ->resultset( 'Game' )
        ->new_result( {
            p1tok => $p1tok,
            p2tok => $p2tok,
            defined $width
              ? ( width => $width )
              : ()
          } );
  $grs->_player1($p1);
  $grs->_player2($p2);
  my $created = model_guard( sub { $grs->insert } );
  return {
    defined $created
      ? ( created => 1, id => $created->id )
      : ( created => 0 ),
  };
};

put '/games/:game/status/:status' => sub {
  my $game_id     = route_parameters->get( 'game' );
  my $status_name = route_parameters->get( 'status' );
  my $user    = vars->{ user };
  my $db      = vars->{ db };

  if( $status_name ne 'abandoned' ) {
    send_error( "A user may only change game status to abandoned", 400 );
  }

  my $change_status = 
    model_guard( sub {
      $db->resultset( 'Game' )
         ->search( {
             id => $game_id,
             -or => {
                      p1 => $user->id,
                      p2 => $user->id
                    }
           } )
         ->update( { status => $status_name } );
    } );

  if( ! defined $change_status ) {
    send_error( 'Unauthorized to view this game', 401 );
  }

  return {
    message => 'game status changed'
  };
};

# Likely continues to have a race condition.
put '/games/:game/play/:cell' => sub {
  my $game_id = route_parameters->get( 'game' );
  my $cell_id = route_parameters->get( 'cell' );
  my $user    = vars->{ user };
  my $db      = vars->{ db };

  # Get current status for the game.  Things can change between
  # our observation of the game state and when we start to update
  # the game state, but this gives us a way to report back to the user
  # if something is definitely not as expected.

  return 
    $db->txn_do( sub {
      my $game =
        $db->resultset( 'Game' )
           ->search( {
               'me.id' => $game_id,
               -or => {
                        p1 => $user->id,
                        p2 => $user->id
                      }
             },
             {
               prefetch => [ 'cells' ]
             } )
           ->first;

      if( ! defined $game ) {
        send_error( 'Unauthorized to view this game', 401 );
      }

      my %return = (
        username => $user->name,
        game => {
          id => $game->id,
          width => $game->width,
          player1 => $game->player1->name,
          player2 => $game->player2->name,
          player1_token => $game->p1tok,
          player2_token => $game->p2tok,
          status => $game->status,
          turn => $game->turn,
          created_at => $game->created_at->ymd
        }
      );

      if( $game->status ne 'inprogress' ) {
        return {
          %return,
          message => 'game is over'
        };

      } elsif( $game->turn ne $user->name ) {
        return {
          %return,
          message => 'it is not your turn',
        };
      }

      # Change the turn to undef, only continue if this works.
      my $turn_un =
        model_guard( sub {
          $db->resultset( 'Game' )
             ->search( { 
                 id      => $game_id,
                 status  => 'inprogress',
                 turn    => $user->name,
                 -or => {
                          p1 => $user->id,
                          p2 => $user->id
                        }
               } )
             ->update( { turn => undef } );
        } );

      # if it errored, or there were no rows updated
      if( ! defined $turn_un || $turn_un == 0 ) {
        $return{ message } = 'cell has already been taken';
      }

      my $next_turn = 
        ( $game->p1 == $user->id ) 
          ? $game->player2->name 
          : $game->player1->name;

      my $user_token = ( $user->id == $game->p1 ) ? $game->p1tok : $game->p2tok;
      my $up_cell = 
        model_guard( sub {
          $db->resultset( 'Game' )
             ->search( { 
                 'me.id' => $game_id,
                 status  => 'inprogress',
                 turn    => undef,
                 -or => {
                          p1 => $user->id,
                          p2 => $user->id
                        }
                 } )
             ->related_resultset( 'cells' )
             ->search( { 
                 index => $cell_id,
                 value => undef
               } )
             ->update( { value => $user_token } );
        } );

      if( ! defined $up_cell ) {
        $return{ message } = 'unknown error';

      } elsif( $up_cell == 0 ) {
        $return{ message } = 'cell has already been taken';
      }

      if( exists $return{ message } ) {
        $next_turn = $user->name;

      } else {
        # the game ends in a draw or win
        my @board = map { $_->value } $game->cells->all;
        $board[$cell_id-1] = $user_token;
        if( my $status = game_is_over($cell_id, $game->width, @board) ) {
          model_guard( sub {
            $db->resultset( 'Game' )
               ->search( { id => $game_id } ) # just to be sure
               ->update( { status => $status } );
          } );
          return {
            %return,
            status  => $status,
            message => 'game is over'
          };
        }
      }

      # change turn to the next player
      my $turn_next =
        model_guard( sub {
          $db->resultset( 'Game' )
             ->search( { id => $game_id } ) # just to be sure
             ->update( { turn => $next_turn } );
        } );
       
       return { 
         %return,
         message => 'turn played'
       };
    } );
};


### not route-related

sub check_vertical_wins {
  my( $token, $last_play, $width, @board ) = @_;

  # vertical
  my $match = 1;
  foreach my $n (1..$width) {
    my $ndx = $last_play - $width*$n;
    last if $ndx < 0;
    if( defined $board[$ndx-1] && $board[$ndx-1] eq $token ) {
      $match = 1;
    } else {
      $match = 0;
      last;
    } 
  }
  return 0 if $match == 0;

  foreach my $n (1..$width) {
    my $ndx = $last_play + $width*$n;
    last if $ndx > $width*$width;
    if( defined $board[$ndx-1] && $board[$ndx-1] eq $token ) {
      $match = 1;
    } else {
      $match = 0;
      last;
    } 
  }
  return $match;
}

sub check_horizontal_wins {
  my( $token, $last_play, $width, @board ) = @_;

  # horizontal
  my $match = 1;
  foreach my $n (1..$width-1) {
    my $ndx = ($last_play-1) + $n;
    last if $ndx % $width == 0;
    if( defined $board[$ndx] && $board[$ndx] eq $token ) {
      $match = 1;
    } else {
      $match = 0;
      last;
    } 
  }
  return 0 if $match == 0;

  foreach my $n (1..$width-1) {
    my $ndx = ($last_play-1) - $n;
    last if $ndx % $width == 2;
    if( defined $board[$ndx] && $board[$ndx] eq $token ) {
      $match = 1;
    } else {
      $match = 0;
      last;
    } 
  }
  return $match;
}

sub check_diagonal_wins {
  my( $token, $last_play, $width, @board ) = @_;

  # diagonal
  # tl -> br
  my $match = 0;
  my $ndx   = 0;
  foreach my $n (1..$width) {
    if( defined $board[$ndx] && $board[$ndx] eq $token ) {
      $match = 1;
    } else {
      $match = 0;
      last;
    } 
    last if $ndx >= ($width*$width)-1;
    $ndx += ($width+1);
  }
  return 1 if $match == 1;

  # bl -> tr
  $ndx = ($width*$width-$width);
  foreach my $n (1..$width) {
    if( defined $board[$ndx] && $board[$ndx] eq $token ) {
      $match = 1;
    } else {
      $match = 0;
      last;
    } 
    last if $ndx == 0;
    $ndx -= ($width - 1);
  }
  return $match;
}

sub game_is_over {
  my( $last_play, $width, @board ) = @_;

  # quick check to see if we need to check for a winner/draw
  my @all_plays = grep { defined $_ } @board;
  my $total_plays = scalar @all_plays;
  return 0 if( $total_plays < ($width*2)-1 );

  my $token = $board[ $last_play-1 ];

  # board is full, no winner, it's a draw
  my $return = ( $total_plays >= $width*$width ) ? 'draw' : 0;

  return 'complete' 
    if check_diagonal_wins( $token, $last_play, $width, @board );
  return 'complete' 
    if check_vertical_wins( $token, $last_play, $width, @board );
  return 'complete' 
    if check_horizontal_wins( $token, $last_play, $width, @board );

  return $return;
}

# I cannot figure out how to throw exceptions from DBIx::Class into
# Dancer without Dancer stripping the name of the exception class 
# and therefore losing the fact that it's coming from the model.
# This is my gross attempt to work around this.
sub model_guard {
  my( $sub ) = @_;

  return 
    try {
      return $sub->();
    } catch {
      if( ref $_ eq 'Game::TTT::DB::Exception' ) {
        send_error( $_->{ message }, 400 );
      } else {
        die $_;
      }
    };
}

1;

__END__
