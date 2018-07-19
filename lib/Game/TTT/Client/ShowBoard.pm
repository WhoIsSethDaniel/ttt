package Game::TTT::Client::ShowBoard;

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
  'ttt-show-board %o',
  [ 'host=s', 'the server to connect to', { default => 'localhost' } ],
  [ 'port|p=i', 'the port to connect to', { default => 5000 } ],
  [ 'user|u=s', 'user to connect as', { required => 1 } ],
  [ 'game=i', 'game id to show', { required => 1 } ],
  [ 'verbose|v', 'show full response' ],
  [ 'help|h', 'show help' ]
);

print($usage->text), exit if $opt->help;

sub run {
  my $ua = LWP::UserAgent->new;

  my $url = sprintf "http://%s:%d/games/%d", $opt->host, $opt->port, $opt->game;
  my $req = GET $url, 'Content-Type' => 'application/json';
  $req->authorization_basic( $opt->user, 'fake' );
  my $resp = $ua->request( $req );
  if( exists $resp->{ message } ) {
    die $resp->{ message } . "\n";
  } 

  my $deserial = decode_json $resp->content;
  if( exists $deserial->{ game } ) {
    my $game = $deserial->{ game };
    my $width = $game->{ width };
    my $board = $game->{ board };
    printf "%d width: %d, p1: %s [%s], p2: %s [%s], turn: %s, status: %s\n",
           $game->{ id }, $width,
           $game->{ player1 }, $game->{ player1_token },
           $game->{ player2 }, $game->{ player2_token },
           $game->{ turn } // '-', $game->{ status };

    foreach my $n (1..$width*$width) {
      my $tok = $board->[ $n-1 ];
      printf "%4.4s", ( $tok eq '-' ? $n : $tok );
      print "\n" if( $n % $width == 0 );
    }

  } elsif( exists $deserial->{ message } ) {
    say $deserial->{ message };
  }

  say Dumper($deserial) if $opt->verbose;
}

1;

__END__
