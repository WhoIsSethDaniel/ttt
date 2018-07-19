package Game::TTT::Client::ListGames;

use strict;
use warnings;
use feature ':5.20';

use Data::Dumper::Concise;
use Getopt::Long::Descriptive;

use JSON;
# these days there are better agents, but this one is very common
use HTTP::Request::Common;
use LWP::UserAgent;

my( $opt, $usage ) = describe_options(
  'ttt-list-games %o',
  [ 'host=s', 'the server to connect to', { default => 'localhost' } ],
  [ 'port|p=i', 'the port to connect to', { default => 5000 } ],
  [ 'user|u=s', 'user to connect as', { required => 1 } ],
  [ 'verbose|v', 'show full response' ],
  [ 'help|h', 'show help' ]
);

print($usage->text), exit if $opt->help;

sub run {
  my $ua = LWP::UserAgent->new;

  my $url = sprintf "http://%s:%d/games", $opt->host, $opt->port;
  my $req = GET $url, 'Content-Type' => 'application/json';
  $req->authorization_basic( $opt->user, 'fake' );
  my $resp = $ua->request( $req );
  if( exists $resp->{ message } ) {
    die $resp->{ message } . "\n";
  } 

  my $deserial = decode_json $resp->content;
  if( exists $deserial->{ games } ) {
    foreach my $game (sort { $a->{ id } <=> $b->{ id } } @{ $deserial->{ games } }) {
      printf "%d width: %d, p1: %s [%s], p2: %s [%s], turn: %s, status: %s\n",
             $game->{ id }, $game->{ width },
             $game->{ player1 }, $game->{ player1_token },
             $game->{ player2 }, $game->{ player2_token },
             $game->{ turn }, $game->{ status };
    }
  }

  say Dumper($deserial) if $opt->verbose;
}

1;

__END__
