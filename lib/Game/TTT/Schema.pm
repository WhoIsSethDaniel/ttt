package Game::TTT::Schema;

our $VERSION = '1.0';

use Moo;
extends 'DBIx::Class::Schema';

use File::Basename qw( dirname );

__PACKAGE__->load_namespaces(
  result_namespace        => '+Game::TTT::DB::Result',
  resultset_namespace     => '+Game::TTT::DB::ResultSet',
  default_resultset_class => '+Game::TTT::DB::ResultSet'
);

sub dbname {
  if( exists $ENV{ GAME_TTT_DB_NAME } ) {
    my $dbname = $ENV{ GAME_TTT_DB_NAME };
    if( ! -d dirname( $dbname ) ) {
      die "Environment variable GAME_TTT_DB_NAME does not refer to an existing directory\n"
    }
    return $dbname;

  } else {
    die "Environment variable GAME_TTT_DB_NAME *must* be set to a valid path and file name\n";
  }
}

sub dsn {
  my $class = shift;

  my $dbname = $class->dbname;
  return sprintf 'dbi:SQLite:dbname=%s;host=localhost', $dbname;
}

sub extra_connect_info {
 return { quote_names => 1, mysql_enable_utf8 => 1 };
}

sub connect {
  my $class = shift;
  return
    $class->SUPER::connect(
      $class->dsn,
      undef,
      undef,
      $class->extra_connect_info
    );
}


1;

__END__
