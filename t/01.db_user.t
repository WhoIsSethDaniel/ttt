use strict;
use warnings;
use feature ':5.20';

use Test::More;
use Test::Fatal;
use Test::TempDir::Tiny;

use Game::TTT::Schema;

my $class = 'Game::TTT::DB::Result::User';

# Test::DBIx::Class would be better, but takes more effort to setup. 

delete $ENV{ GAME_TTT_DB_NAME };

{
  in_tempdir "check user validation" => sub {
    my( $cwd ) = @_;

    local $ENV{ GAME_TTT_DB_NAME } = $cwd . '/ttt01.db';

    my $db = Game::TTT::Schema->connect;

    is( 
      exception { $db->deploy },
      undef,
      "deployed ok" );

    like( 
      exception { 
        $db->resultset( 'User' )
           ->create( {
               name => 'this_name_is_far_too_long_for_the db'
             } )
      },
      qr/field 'name' may be no more than 25 characters/,
      "exception: 'name' is too long" );

    is( 
      exception { 
        $db->resultset( 'User' )
           ->create( {
               name => 'acceptable_name'
             } )
      },
      undef,
      "can create a well-formed user" );
  };
}

done_testing;
