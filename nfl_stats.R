#' Access Postgres db with the NextGen and ESPN API data
#' TODO Predict player with most receiving yards
#' among WRs with 3 or more seasons of data available
#' TODO Predict team with most receiving yards
#' (predict 2023/2024 season using historical data, test against last season's actual)
#' 

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
nrow(filter(check_seasons,n >= 3)) # 375 players out of 716 have at least 3 seasons of data

rec_complete <- rec_df %>% 
  inner_join(filter(check_seasons,n >= 3), by = "player_id")

# convert to time series

# forecast methods

# predict function



