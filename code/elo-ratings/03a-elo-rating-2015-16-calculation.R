## Author: Ryan McMahon 
## Date Created: 04/28/16
## Date Last Modified: 04/28/16
## File: "~/IST597k/NBA/code/elo-rating-2015-16-calculation.R"

## Purpose: 
##         Fill in the new Elo ratings data frame for 
##         the 2015-16 season.

## Program and Hardware Information:
# R 3.1.3 "Smooth Sidewalk"; 64-bit
# Windows 8.1; MSi GE60 2PL Apache Laptop

################################################################################

rm(list=ls())
library(stringr)
set.seed(11769)
options(stringsAsFactors = F)

## Read in saved RData elo functions:
setwd("C:/Users/rbm166/Dropbox/IST597k/NBA/data/")
load("elo-rating-functions.RData")

## Read in our new elo data frame:
df <- read.csv("elo-rating-2015-16-df.csv")

## Read in the 538 elo data:
old <- read.csv("538-elo-to-2014-15.csv")



###################################
### Preliminary Data Manipulation:
###################################

## Subset 538 data to just the 2014-15 season:
old <- old[which(old$year_id == 2015),]
gc()


## Find the last Elo rating from previous year for each team:
uni.tm.538 <- unique(old$team_id)

old.last.rating <- data.frame(matrix(NA, nrow = length(uni.tm.538), ncol = 2))
colnames(old.last.rating) <- c("team_id", "rating")

for(i in 1:length(uni.tm.538)){
  temp <- old[which(old$team_id == uni.tm.538[i]),]
  temp <- temp[order(temp$gameorder),]
  
  old.last.rating[i,1] <- uni.tm.538[i]
  old.last.rating[i,2] <- temp$elo_n[nrow(temp)]
}

old.last.rating <- old.last.rating[order(old.last.rating$team_id),]

## Fix team names for Brooklyn, Charlotte, and Phoenix:
old.last.rating$team_id[c(3,5,24)] <- c("BKN", "CHA", "PHX")
old.last.rating <- old.last.rating[order(old.last.rating$team_id),]

## Substitute the last rating into the "elo_i" column for each team's 
## first game:
for(i in 1:nrow(old.last.rating)){
  df$elo_i[which(df$team_id == old.last.rating$team_id[i] & 
                   df$seasongame == 1)] <- old.last.rating$rating[i]
}


## Sanity check:
temp <- df[which(df$seasongame==1),c("team_id", "elo_i")]
temp <- temp[order(temp$team_id),]
temp == old.last.rating
# All = TRUE


## Adjust the ratings so that they follow the formula from 538:
## Starting rating = 0.75*rating_old + 0.25*1505
df$elo_i <- (0.75 * df$elo_i) + (0.25 * 1505)


###################################
### Calculating New Elo Ratings:
###################################

uni.gms <- 1:1230

for(i in 1:max(uni.gms)){
  
  temp <- df[which(df$gameorder==i),]

  temp$opp_elo_i[1] <- temp$elo_i[2]
  temp$opp_elo_i[2] <- temp$elo_i[1]
  new.elo1 <- gen_new_elo_538(elo_i_tm = temp$elo_i[1], 
                                   elo_i_opp = temp$opp_elo_i[1], 
                                   loc = temp$game_location[1], 
                                   MOV = (temp$pts[1] - temp$opp_pts[1]))
  
  temp$elo_n[1] <- new.elo1[[1]]
  temp$forecast[1] <- new.elo1[[2]]
  
  new.elo2 <- gen_new_elo_538(elo_i_tm = temp$elo_i[2], 
                              elo_i_opp = temp$opp_elo_i[2], 
                              loc = temp$game_location[2], 
                              MOV = (temp$pts[2] - temp$opp_pts[2]))
  
  temp$elo_n[2] <- new.elo2[[1]]
  temp$forecast[2] <- new.elo2[[2]]
  
  temp$opp_elo_n[1] <- new.elo2[[1]]
  temp$opp_elo_n[2] <- new.elo1[[1]]
  
  df[which(df$gameorder == i),] <- temp
  
  df$elo_i[which(df$team_id == temp$team_id[1] & 
                   df$seasongame == temp$seasongame[1] + 1)] <- temp$elo_n[1]
  df$elo_i[which(df$team_id == temp$team_id[2] & 
                   df$seasongame == temp$seasongame[2] + 1)] <- temp$elo_n[2]
  
}

################################################################################

#############################
### Checking It Out
#############################
par(mfrow = c(1,2))

gsw <- df[which(df$team_id == "GSW"),]
gsw <- gsw[order(gsw$seasongame),]
gsw$date_game <- as.Date(gsw$date_game)
plot(gsw$date_game, gsw$elo_i, type = "b", ylim = c(1200,2000))
lines(gsw$date_game, gsw$elo_n, col = "steelblue")

phi <- df[which(df$team_id == "PHI"),]
phi <- phi[order(phi$seasongame),]
phi$date_game <- as.Date(phi$date_game)
plot(phi$date_game, phi$elo_i, type = "b", ylim = c(1200,2000))
lines(phi$date_game, phi$elo_n, col = "steelblue")


## Write out CSV:
write.csv(df, "elo-rating-cleaned-538-method-2015-16.csv", row.names = F)

