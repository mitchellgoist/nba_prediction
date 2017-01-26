## Author: Ryan McMahon 
## Date Created: 05/01/16
## Date Last Modified: 05/01/16
## File: "~/IST597k/NBA/code/features/03-feature-merging.R"

## Purpose: 
##         Add all of the game and player level feature data to the elo data:
##         (see, '~/01-elo-plus-features-538-method-1516.csv').

## Program and Hardware Information:
# R 3.1.3 "Smooth Sidewalk"; 64-bit
# Windows 8.1; MSi GE60 2PL Apache Laptop

################################################################################

rm(list=ls())
gc()
library(stringr)
set.seed(11769)
options(stringsAsFactors = F)

## Read in elo data:
setwd("C:/Users/rbm166/Dropbox/IST597k/NBA/data/elo-plus-features/")
elo <- read.csv("01-elo-plus-features-538-method-1516.csv")

## Read in features data:
setwd("C:/Users/rbm166/Dropbox/IST597k/NBA/data/elo-plus-features/clean-features/")

# officials
off.df <- read.csv("02a-clean_game_officials_data.csv")

# team level
tm.df <- read.csv("02b-clean_game_team_adv_norm_data.csv")

# player level
player.df <- read.csv("02c-clean_game_player_adv_data.csv")

# streaks
streak.df <- read.csv("02d-clean_game_streak_attend_data.csv")
colnames(streak.df) <- gsub("team_abbreviation", "team_id", colnames(streak.df))
streak.df <- streak.df[,c(1,2,10:16)]

#######################
## MERGE SEQUENTIALLY
#######################

# officials
df <- merge(elo, off.df, by = "game_id")
rm(off.df)
rm(elo)
gc()


## team level
tm.df <- tm.df[,-2] # remove the team id column that is numeric
df <- merge(df, tm.df, by.x = c("game_id", "team_id"), by.y = c("game_id", "team_abbreviation"))
rm(tm.df)
gc()


## player level
df <- merge(df, player.df, by = c("game_id", "team_id"))
rm(player.df)
gc()


## streak
df <- merge(df, streak.df, by = c("game_id", "team_id"))
rm(streak.df)
gc()


#######################
## CLEAN COLUMNS
#######################

## Fix the second points column:
colnames(df) <- gsub("pts[.]y", "tm_pts_avg", colnames(df))

## Remove duplicates
to.remove <- grep(pattern = "*[.]y", colnames(df))
df <- df[,-to.remove]

## Fix the var.x names
colnames(df) <- gsub("[.]x", "", colnames(df))


## Remove team name, team city, and ref name/jersey variables
df <- df[,-c(37,38)] # tm name and city

to.remove <- grep("ref_name*", colnames(df))
df <- df[,-to.remove]

to.remove <- grep("ref_jersey*", colnames(df))
df <- df[,-to.remove]


## Turn ref ids into factors via character conversion:
to.fac <- grep("ref_id*", colnames(df))
df[,to.fac] <- apply(df[,to.fac], 2, as.character)


## Fix the time variables to be numeric:

# 'min' to number of minutes in the game
# 'game_time' to number of hours long
for(i in 1:nrow(df)){
  temp1 <- unlist(str_split(df$min[i], ":"))
  temp2 <- unlist(str_split(df$game_time[i], ":"))               
  df$min[i] <- as.numeric(temp1[1])/5
  df$game_time[i] <- as.numeric(temp2[1]) + as.numeric(temp2[2])/60
}

df$min <- as.numeric(df$min)
df$game_time <- as.numeric(df$game_time)


## Remove 'game_result' since we have 'win_dum'
to.remove <- grep("game_result", colnames(df))
df <- df[,-to.remove]


## Remove the franchise and win equivalent columns that are all NA:
to.remove <- grep("fran", colnames(df))
df <- df[,-to.remove]

to.remove <- grep("win_equiv", colnames(df))
df <- df[,-to.remove]

## Remove extra game date variable:
to.remove <- grep("game_date", colnames(df))
df <- df[,-to.remove]

## Remove extra seasongame variable:
to.remove <- grep("seasongame[.]1", colnames(df))
df <- df[,-to.remove]

####################
## WRITE OUT CSV
####################

setwd("C:/Users/rbm166/Dropbox/IST597k/NBA/data/elo-plus-features/")
write.csv(df, "02-elo-plus-all-features-538-method-1516.csv", row.names = F)
