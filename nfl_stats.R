#' Access Postgres db with the NextGen and ESPN API data
#' TODO Predict player with most receiving yards
#' among WRs with 3 or more seasons of data available
#' TODO Predict team with most receiving yards
#' (predict 2023/2024 season using historical data, test against last season's actual)
#' Predict highest scoring team, longest reception (not specific person)? Team with most yards? 
#' Injury trends? Higher/lower scoring trends after certain regulations/rules changes?
  
  

library(dplyr)
library(DBI)


setwd("/Users/lissacallahan/Projects/sports")

#' load .env file with credentials
dotenv::load_dot_env()

sql_conn <- dbConnect(
  RPostgres::Postgres(),
  dbname = Sys.getenv("DB_NAME"),
  host = Sys.getenv("DB_HOST"),
  port = Sys.getenv("DB_PORT"),
  user = Sys.getenv("DB_USER"),
  password = Sys.getenv("DB_PASS")
)

#' list table names in this db
dbListTables(sql_conn)

#' *Some* players have multiple rows for each team played on--
#' example: JuJu Smith-Schuster has two rows, Teams '12' and '17 (Chiefs and Pats, resp.) but none for Steelers
#' even though he played for Steelers thr 2021. Inconsistent but could be helpful. 
#' TODO dedup for most recent team played on if team names needed.
players <- dbSendQuery(conn = sql_conn, statement = "SELECT * FROM players")
players_df <- dbFetch(players)

teams <- dbSendQuery(conn = sql_conn, statement = "SELECT * FROM teams")
teams_df <- dbFetch(teams)

#' TODO examine season == "all" later -- some appear to be sums of the seasons listed for each player (e.g. 4 seasons), 
#' others are not, but also not an average, could be an average/sum of whole career inc 0's (not just 2019- data included here)
#' but unsure at this point. 
# rec_df <- dbFetch(dbSendQuery(sql_conn, "SELECT * FROM espn_receiving_stats"))
rec <- dbSendQuery(sql_conn, "SELECT * FROM espn_receiving_stats WHERE season != 'all'")
rec_df <- dbFetch(rec)
check_seasons <- rec_df %>% group_by(player_id) %>% count()
check_seasons_team <- rec_df %>% group_by(player_id) %>% count()
nrow(filter(check_seasons,n >= 3)) # 375 players out of 716 have at least 3 seasons of data

rec_complete <- rec_df %>% 
  inner_join(filter(check_seasons,n >= 3), by = "player_id")

players_team <- players_df %>% 
  select(-season) %>% 
  inner_join(teams_df[,c("id", "name")], by=c("team_id"="id")) %>% 
  rename(team_name = name)



#' * Predict player yards after reception using total offensive plays and team games played per season *

players_team_rec_df <- players_team %>% 
  select(-c(created_at, updated_at)) %>% # ref the receiving yards updated times, not player dataset
  inner_join(rec_df, by=c("id"="player_id")) %>% 
  rename(player_id = id) 
#' check all 32 teams have 3 or more seasons of data (all have 4)
players_team_rec_df %>% group_by(team_id, team_name) %>% count() %>% filter(n >= 3) %>% nrow()
check <- players_team_rec_df %>% filter(!is.na(receiving_yards)) %>% group_by(team_id, team_name, season) %>% count()
#' team with fewest receivers with stats included is the 2019 Rams, so not necessarily just low individual contrib that bring these down due to missing data.

#' keep necessary columns and only players with at least 3 seasons of data
rec_players <- players_team_rec_df %>% 
  inner_join(filter(check_seasons,n >= 3), by = "player_id") %>% 
  select(1:6,15,30,34,35) 
  
rec_data <- rec_players %>% 
  select(receiving_yards_after_catch, team_games_played, total_offensive_plays) 

fit <- lm(receiving_yards_after_catch ~ team_games_played + total_offensive_plays, data=rec_data)
summary(fit)

games_plays <- rec_data %>% select(team_games_played, total_offensive_plays)

predict(fit, games_plays)

#' TODO continue... 


#' prepare dataset for team stats compared season over season
#' TODO only 2019-2022 data (find missing 2023 season)

team_rec_df <- players_team_rec_df %>% 
  group_by(team_id, team_name, season) %>% 
  summarise(total_rec_yards_season = sum(receiving_yards, na.rm=TRUE)) 
# obviously NA's aren't 0's here (some players have numeric 0, and no team would have 0 total for season), 
# they're just missing, but need to control for this somehow since some are artificially low, but see note above.




#' convert to time series (if makes sense with so few years as time series)
#' TODO can I get game-level data?

#' statistical forecast methods and checks for chance

#' predict function



