#! /bin/bash

if [[ $1 == "test" ]]
then
  PSQL="psql --username=postgres --dbname=worldcuptest -t --no-align -c"
else
  PSQL="psql --username=freecodecamp --dbname=worldcup -t --no-align -c"
fi

# Do not change code above this line. Use the PSQL variable above to query your database.

echo $($PSQL "TRUNCATE TABLE games, teams;")
echo $($PSQL "ALTER SEQUENCE games_game_id_seq RESTART; ALTER SEQUENCE teams_team_id_seq RESTART;")

cat games.csv | while IFS=',' read YEAR ROUND WINNER OPPONENT WINNER_GOALS OPPONENT_GOALS
do
  if [[ $YEAR != year ]]
  then
    WINNER_ID=$($PSQL "SELECT team_id FROM teams WHERE name='$WINNER';")
    OPPONENT_ID=$($PSQL "SELECT team_id FROM teams WHERE name='$OPPONENT';")

    if [[ (-z $WINNER_ID) && (-z $OPPONENT_ID) ]]
    then
      TEAM_ADDED_RESULT=$($PSQL "INSERT INTO teams(name) VALUES ('$WINNER'), ('$OPPONENT');")
      if [[ $TEAM_ADDED_RESULT == "INSERT 0 2" ]]
      then
        echo Inserted into teams, "$WINNER" and "$OPPONENT"
        WINNER_ID=$($PSQL "SELECT team_id FROM teams WHERE name='$WINNER';")
        OPPONENT_ID=$($PSQL "SELECT team_id FROM teams WHERE name='$OPPONENT';")
      fi
    elif [[ -z $WINNER_ID ]]
    then
      read -d=' ' WINNER_ID TEAM_ADDED_RESULT <<< $($PSQL "INSERT INTO teams(name) VALUES ('$WINNER') RETURNING team_id;")
      if [[ $TEAM_ADDED_RESULT == "INSERT 0 1" ]]
      then
        echo Inserted into teams, "$WINNER"
      fi
    elif [[ -z $OPPONENT_ID ]]
    then
      read -d=' ' OPPONENT_ID TEAM_ADDED_RESULT <<< $($PSQL "INSERT INTO teams(name) VALUES ('$OPPONENT') RETURNING team_id;")
      if [[ $TEAM_ADDED_RESULT == "INSERT 0 1" ]]
      then
        echo Inserted into teams, "$OPPONENT"
      fi
    fi

    GAME_RESULT=$($PSQL "INSERT INTO games(year, round, winner_id, opponent_id, winner_goals, opponent_goals) VALUES ($YEAR, '$ROUND', $WINNER_ID, $OPPONENT_ID, $WINNER_GOALS, $OPPONENT_GOALS);")
    if [[ $GAME_RESULT == "INSERT 0 1" ]]
    then
      echo "Inserted into games, $YEAR : $WINNER : $OPPONENT"
    fi
  fi
done
