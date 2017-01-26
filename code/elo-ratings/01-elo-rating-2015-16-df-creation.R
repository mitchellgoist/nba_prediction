## Author: Ryan McMahon 
## Date Created: 04/28/16
## Date Last Modified: 04/28/16
## File: "~/IST597k/NBA/code/elo-rating-2015-16-df-creation.R"

## Purpose: 
##         Create the data frame to hold the new Elo ratings data for 
##         the 2015-16 season.

## Program and Hardware Information:
# R 3.1.3 "Smooth Sidewalk"; 64-bit
# Windows 8.1; MSi GE60 2PL Apache Laptop

################################################################################

rm(list=ls())
library(stringr)
set.seed(11769)
options(stringsAsFactors = F)

## Read in saved RData file:
setwd("C:/Users/rbm166/Dropbox/IST597k/NBA/data/")
load(file = "Cleaned_WinProbability_List.RData")

gms <- read.csv("unique_GameIDs.csv")


gms$h_score_margin <- NA
gms$h_score <- NA
gms$a_score <- NA


for(i in 1:length(data.ll)){
  game <- data.ll[[i]]$GAME_ID[1]
  margin <- data.ll[[i]]$HOME_SCORE_MARGIN[nrow(data.ll[[i]])]
  h_score <- data.ll[[i]]$HOME_PTS[nrow(data.ll[[i]])]
  a_score <- data.ll[[i]]$VISITOR_PTS[nrow(data.ll[[i]])]
  
  gms$h_score_margin[which(gms$GAME_ID == game)] <- margin
  gms$h_score[which(gms$GAME_ID == game)] <- h_score
  gms$a_score[which(gms$GAME_ID == game)] <- a_score
}

head(gms)

## New data frame with each game occupying two rows;
## The columns are made to match the first 22/23 columns from the 
## 538 elo data:
df <- data.frame(matrix(data = NA, nrow = 2*nrow(gms), ncol = 22))
colnames(df) <- c("gameorder", "game_id", "lg_id", "_iscopy",	"year_id", 
"date_game", "seasongame", "is_playoffs", "team_id", "fran_id", "pts", "elo_i", 
"elo_n", "win_equiv", "opp_id",	"opp_fran",	"opp_pts", "opp_elo_i", "opp_elo_n", 
"game_location", "game_result", "forecast")

df$gameorder <- NA
df$forecast <- NA

df.seq <- seq(1,2*nrow(gms), by = 2)
j <- 1

for(i in df.seq){
  df[c(i,i+1),2] <- gms$GAME_ID[j] # game id
  df[c(i,i+1),3] <- "NBA" # league id
  df[c(i,i+1),4] <- c(0,1) # if the game has already been shown for opposing team
  df[c(i,i+1),5] <- as.integer(unlist(str_split(gms$GAME_DATE[j], "-"))[1]) # yr
  df[c(i,i+1),6] <- gms$GAME_DATE[j] # date
  df[c(i,i+1),7] <- NA # game number for team in season
  df[c(i,i+1),8] <- 0 # playoff marker
  df[c(i,i+1),9] <- c(gms$HomeTeam[j], gms$AwayTeam[j]) # team ids
  df[c(i,i+1),10] <- NA # franchise id 
  df[c(i,i+1),11] <- c(gms$h_score[j], gms$a_score[j]) # Points scored
  df[c(i,i+1),12] <- NA # tm elo before game
  df[c(i,i+1),13] <- NA # tm elo after game
  df[c(i,i+1),14] <- NA # Equivalent number of wins in a 82-game season for a team of elo_n quality
  df[c(i,i+1),15] <- c(gms$AwayTeam[j], gms$HomeTeam[j]) # opponent ids
  df[c(i,i+1),16] <- NA # opponent franchise id
  df[c(i,i+1),17] <- c(gms$a_score[j], gms$h_score[j]) # opponent scores
  df[c(i,i+1),18] <- NA # opponent elo before game
  df[c(i,i+1),19] <- NA # opponent elo after game
  df[c(i,i+1),20] <- c("H", "A") # game location
  df[c(i,i+1),21] <- c(gms$HomeTeam_WL[j], ifelse(test = gms$HomeTeam_WL[j] == "W", yes = "L", no = "W"))
  
  j <- j+1
}

## Put date into date format and order observations
df$date_game <- as.Date(df$date_game)
df <- df[order(df$date_game),]

## Generate game order sequence:
df$gameorder <- sort(rep(1:nrow(gms), times = 2))


## Put in season game variable w/ new data frame:
uni.tm <- unique(df$team_id)

df1 <- df[which(df$team_id == uni.tm[1]),]
df1 <- df1[order(df1$date_game),]
df1$seasongame <- 1:82

for(i in 2:length(uni.tm)){
  temp <- df[which(df$team_id == uni.tm[i]),]
  temp <- temp[order(temp$date_game),]
  temp$seasongame <- 1:82
  
  df1 <- rbind(df1, temp)
}

df1 <- df1[order(df1$gameorder),]

## Remove old data frame:
rm(df)
gc()

## Write new df to csv:
write.csv(x = df1, file = "elo-rating-2015-16-df.csv", row.names = F)



