use strict;
use warnings;
use feature ':5.20';

use Test::More;
use Test::Fatal;
use Test::Deep;
use Test::TempDir::Tiny;

use Game::TTT::Service;

delete $ENV{ GAME_TTT_DB_NAME };

# vertical
{
  # x is winner along left vertical
  ok(
      Game::TTT::Service::check_vertical_wins(
        'x',
        1,
        3,
        ( 'x', 'o', undef, 'x', 'o', undef, 'x', undef, undef )
      ),
      "x wins along left vertical"
    );
     
  # x is winner along middle vertical
  ok(
      Game::TTT::Service::check_vertical_wins(
        'x',
        2,
        3,
        ( 'o', 'x', undef, 'o', 'x', undef, undef, 'x', undef )
      ),
      "x wins along middle vertical"
    );
     
  # x is winner along right vertical
  ok(
      Game::TTT::Service::check_vertical_wins(
        'x',
        3,
        3,
        ( 'o', undef, 'x', 'o', undef, 'x', undef, undef, 'x' )
      ),
      "x wins along right vertical"
    );

  # no winner, yet
  ok(
      !Game::TTT::Service::check_vertical_wins(
        'x',
        3,
        3,
        (qw( o x o x o x ), undef, undef, undef )
      ),
      "enough plays to win, but no winner"
    );
} 

# horizontal
{
  # x is winner along top horizontal
  ok(
      Game::TTT::Service::check_horizontal_wins(
        'x',
        1,
        3,
        ( 'x', 'x', 'x', 'o', 'o', undef, undef, undef, undef )
      ),
      "x wins along top horizontal"
    );
     
  # x is winner along middle horizontal
  ok(
      Game::TTT::Service::check_horizontal_wins(
        'x',
        4,
        3,
        ( 'o', 'o', undef, 'x', 'x', 'x', undef, undef, undef )
      ),
      "x wins along middle horizontal"
    );

  # x is winner along bottom horizontal
  ok(
      Game::TTT::Service::check_horizontal_wins(
        'x',
        7,
        3,
        ( 'o', 'o', undef, undef, undef, undef, 'x', 'x', 'x' )
      ),
      "x wins along bottom horizontal"
    );
     
  # no winner, yet
  ok(
      !Game::TTT::Service::check_vertical_wins(
        'x',
        3,
        3,
        (qw( o x o x o x ), undef, undef, undef )
      ),
      "enough plays to win, but no winner"
    );
}

# diagonal
{
  # x is winner along tl-br diagonal
  ok(
      Game::TTT::Service::check_diagonal_wins(
        'x',
        1,
        3,
        ( 'x', 'o', undef, 'o', 'x', undef, undef, undef, 'x' )
      ),
      "x wins along tl-br diagonal"
    );

  # x is winner along tr-bl diagonal
  ok(
      Game::TTT::Service::check_diagonal_wins(
        'x',
        3,
        3,
        ( 'o', undef, 'x', 'o', 'x', undef, 'x', undef, undef )
      ),
      "x wins along tr-bl diagonal"
    );
     
  # no winner, yet
  ok(
      !Game::TTT::Service::check_vertical_wins(
        'x',
        3,
        3,
        (qw( o x o x o x ), undef, undef, undef )
      ),
      "enough plays to win, but no winner"
    );
}

# too few plays to have a winner
{
  is(
      Game::TTT::Service::game_is_over(
        1,
        3,
        qw( x )
      ),
      0,
      "only one play, no winner yet"
    );
     
  is(
      Game::TTT::Service::game_is_over(
        1,
        3,
        qw( x o x o )
      ),
      0,
      "only four plays, no winner yet"
    );
}

# games not yet finished
{

  is(
      Game::TTT::Service::game_is_over(
        1,
        3,
        qw( x o x o x )
      ),
      0,
      "not done yet (5 plays)"
    );

  is(
      Game::TTT::Service::game_is_over(
        1,
        3,
        qw( x o x o x o )
      ),
      0,
      "not done yet (6 plays)"
    );
}

# draw
{
  is(
      Game::TTT::Service::game_is_over(
        1,
        3,
        qw( x o x o o x o x o ) 
      ),
      'draw',
      "board is full; ends in draw"
    );
}


done_testing;
