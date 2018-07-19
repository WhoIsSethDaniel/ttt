# Tic-Tac-Toe Web Service

## PURPOSE

This was a programming task I was given during an interview. It is not the
greatest code, the cleanest code, or the best code. It was written in a very
short amount of time (a few hours). But it works!

## HOW TO GET IT

It is hosted on my GitHub account. Any Git client should be able to clone it, 
but when you want to run it it's best if it's a Linux host with access to 
plenty of Perl distributions/modules.

```
https://github.com/WhoIsSethDaniel/ttt
```

To clone it simply run the following from the command-line:

```
git clone git@github.com:WhoIsSethDaniel/ttt.git
```

## SETTING UP THE ENVIRONMENT

The Build.PL contains a list of known high-level dependencies for this 
service. You will need to install them. It is very possible that some 
dependencies were left off the list. I tried to determine any soft dependencies
and place them in the Build.PL, but I may well have missed a few.

Change to the 'ttt' directory that was created when you cloned the repository.
Assuming you are on a typical Linux host you can now run the following:

```
. ./bin/env.sh
```

This will setup the environment needed to run the application. env.sh modifies
or creates two environment variables: PERL5LIB and GAME_TTT_DB_NAME. The former
is likely familiar to any Perl developer. The latter is a path and filename
for where to look for the SQLite database that will contain all the data
stored by this service.

env.sh will also create the SQLite database and schema by running the db_create
script. This database is only used during 'production' runs of the service or
when you need to perform testing beyond the actual tests. Unless you changed
env.sh the database will be in the 'ttt' directory and will be named ttt.db.
Three users (named 'mark', 'nathan', and 'jeff') were also created.

You can view the contents of the file using 

```
sqlite3 ttt.db
```

The name of the SQLite client varies so it may not be exactly what I typed
above. Once you have a SQLite prompt you can type

```
.tables
```

To see a list of tables. You can type

```
.schema <table>
```

To get a look at the schema for a particular table.

To exit type

```
.quit
```

## HOW TO RUN THE TESTS

If you are within the 'ttt' directory and you have performed the above step
you can now run the tests. Simply do

```
perl ./Build.PL
./Build test verbose=1
```

This will run all the tests. Failures may represent a problem with the 
local Perl environment (missing modules being a primary cause of failure).

### TESTS

I test the model layer and the service itself. The tests that are there are
pretty straightforward. My intention was to show how I would go about writing
tests and not the quantity of the tests themselves. 

There are no tests for the command-line tools. They are pretty simple tools,
but such code should have tests in any real-life deployment.

## DESIGN

The TTT is a state-ful, session-less web service written in Perl using Dancer2,
DBIx::Class, and a host of other modules. All known high-level dependencies are
recorded in the Build.PL file in the root of the repository.

The service is designed to allow a registered user to create Tic-Tac-Toe games
for either himself and another player, or for creating games for two other
players. There are a set of command-line tools you can use to talk to the
service. These tools allow a user to list users, list games they own, create
new games, abandon old games, and also allows the user to play games. The
command-line tools are described in more detail later.

All state for the users and games is stored in a database. Currently this is 
a SQLite database (this was briefly described earlier). Given that the model
is written using DBIx::Class it can be any database that DBI supports.

TTT is a "thick model - thin controller" application. Much of the logic (but
not currently all) is in the model. Nearly all validation is in the model.

### AUTH & AUTHZ

The web service assumes that authentication has already taken place. As of
right now it expects the user to be transmitted via basic HTTP authentication.
No actual authentication is performed. However authz is performed.

There is a table of users. These are the users allowed to use the service. 
There is not currently any concept of a super user. 

Every user can:
* view all users
* view games he is a player in
* create games
* play games in which he is a player

## STARTING THE SERVER

If you are in the 'ttt' directory and have already run env.sh (as mentioned
earlier) you can start the server in a terminal

```
plackup -p 5000 share/ttt.psgi
```

This will start to log to the terminal you are in. You may want to run the
server in screen or tmux. Or perhaps just have another terminal handy for
after you've started the server.

All logging is to standard out.

There is no configuration file but adding one via Dancer2 seems pretty 
straightforward. There is no need for one while running the tests or
seeing how the app functions in your personal environment.

## COMMAND-LINE TOOLS

There are six command-line tools. They all start with the 'ttt-' prefix.
The tools are

* ttt-list-users
* ttt-list-games
* ttt-create-game
* ttt-leave-game
* ttt-show-board
* ttt-play

### COMMON OPTIONS

#### -u

All tools require that a user name be given when you run the tool. For example, to retrieve a list of users run

```
./bin/ttt-list-users -u jeff
```

(when you ran env.sh three users were created: 'jeff', 'mark', and 'nathan',
use any of them)

#### -v

All tools have a -v option. This option will causae the tool to dump the JSON
returned from the service.

### ttt-list-users

The output should be all the users currently known to the service.

e.g.
```
ttt-list-users -u jeff
```

### ttt-list-games

The output will be all games for which your user is a player. It will provide
basic details about the game: the player names, their tokens, the width of the
game grid (currently artificially limited to 20), the next player to play, and
the status of the game.

e.g.
```
ttt-list-games -u jeff
```

### ttt-create-game

This tool allows you to create a new game. From the command-line you can specify
the width of the game grid (defaults to 3), the names of the two players, and what token each player will be using. 

e.g.
```
ttt-create-game -u jeff --p1 jeff --p2 mark --token1 o --token2 x
```

### ttt-leave-game

Don't like the game you're playing? Wuss out and abandon the game. This requires
passing a 'game id'.  This id is available when listing out the games using
ttt-list-games.

e.g.
```
ttt-leave-game -u jeff --game 1
```

### ttt-show-board

This requires a 'game id'. This id is simply a number that identifies the 
game you want to see. The 'id' is displayed when you use ttt-list-games.

This command will show you the game board, which cells in the board have been
played on, and the number of the cell(s) that have yet to be played on.

e.g.
```
ttt-show-board -u jeff --game 1
```

### ttt-play

Play your token on the given game and cell. Use ttt-show-board to see the
cell information. Once a user has won a game that game will end and will never
be playable again.

e.g.
```
ttt-play -u jeff --game 1 --cell 10
```

## CHALLENGES

I was originally using Mojolicious as my service framework, but somewhat
late in the development decided to use Dancer2. I had one small (but time
consuming) problem (since resolved), and one larger problem. Both explained
below.

### DANCER2 CHALLENGE #1

Since I hadn't used Dancer 1 in quite some time and never used Dancer 2 I spent
some time going through Dancer2::Manual, Dancer2::Tutorial, Dancer2::Cookbook,
and a few other perldocs. Since I wanted the service to serialize and deserialize to JSON I did as the documentation suggested. I placed the following in 
Service.pm:

```
set serializer => 'JSON';
```

This seemed to work. All GETs ran perfectly. However I was seeing problems
with PUT/POST. Eventually I discovered it was a problem with deserializing
the JSON content being passed in to the app. I spent a great deal of time 
trying different things to get it to work and eventually discovered that,
at least for *deserializing* the accessor Dancer2 uses for retrieving the
deserializer was undefined. After much more time I discovered there is a 
race condition. The ttt.psgi file looked like this:

```
use Dancer2;
use Game::TTT::Service;
use Plack::Builder;

dance();
```

I finally discovered that I had to place the "set serializer => 'JSON'" in
*this* file to get all serialization and deserialization to work. You can
see a comment about this in the ttt.psgi file as it is today.

### DANCER2 CHALLENGE #2

In most 'thick-model / thin-controller' apps, or at least the ones I have
worked on, the model is somewhat (logically) separated from the controller. The
'typical' (I assert this without proof beyond my own experience) way to get
DBIx::Class to notify the controller of a problem is for it to throw an
exception, have the controller catch it, identify it as a model problem (via
inspecting the exception class name, typically), and act accordingly. 

I have discovered no way to do this in Dancer2. And I have tried. In the end
it seems that the hooks init_error and begin_error both happen *after* the
exception has been wrapped in a Dancer2::Core::Error class. I could find
no way to inject extra metadata into this object. Things I tried:

* using DBIx::Class's exception_action to override how DBIx::Class throws exceptions
* sub-classing Dancer2::Core::Error
* using init_error and/or begin_error to capture the raw exception
* various combinations of the above 

Anyway, I had to abandon this idea and there is a nasty hack named
'model_guard' in the Service that does all the exception handling from the
model.

## KNOWN ISSUES

* not all error messages are very nice
* some tools will report nothing if you use a user not in the 'users' table
* no computer player
* the command-line tools print a confusing 'failed to compile' error message when you use -h, but don't supply all the required options. Haven't looked at this at all.
* test coverage
* could do with some refactoring. 
  * I didn't use ResultSets at all. There are a few places in the service where having a ResultSet method would make the code look better.
  * moving the tic-tac-toe 'winning' logic to a separate module seems like it would be a good idea
