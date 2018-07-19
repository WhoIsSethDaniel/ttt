if [[ -f "${GAME_TTT_DB_NAME}" ]]
then
  echo "The ttt database already exists. If you wish to rebuild it please"
  echo "remove it and run this script again."
else
  export PERL5LIB=$PWD/lib:$PERL5LIB
  export GAME_TTT_DB_NAME=$PWD/ttt.db
  ./bin/db_create
  ./bin/db_create_user mark
  ./bin/db_create_user jeff
  ./bin/db_create_user nathan
fi
