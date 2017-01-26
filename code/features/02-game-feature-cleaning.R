## Author: Ryan McMahon 
## Date Created: 04/30/16
## Date Last Modified: 05/01/16
## File: "~/IST597k/NBA/code/features/02-game-feature-cleaning.R"

## Purpose: 
##         Clean the game and player level data so that the features can be  
##         added to the elo-plus data
##         (see, '~/01-elo-plus-features-538-method-1516.csv').

## Program and Hardware Information:
# R 3.1.3 "Smooth Sidewalk"; 64-bit
# Windows 8.1; MSi GE60 2PL Apache Laptop

################################################################################

rm(list=ls())
library(stringr)
set.seed(11769)
options(stringsAsFactors = F)

######################
## OFFICIATING DATA
######################

## Read in game ids so they can be merged with the officials data. 
setwd("C:/Users/rbm166/Dropbox/IST597k/NBA/data/")
games <- read.csv("unique_GameIDs.csv")

## Read in the officials data to clean:
offs <- read.csv(file = "game_officials_data.csv")
table(offs$X)
# There is one game with only two refs

## Find the game with just two refs:
bythree <- seq(from = 1, to = 3690, by = 3)
ref_gms <- list()
for(i in 1:length(bythree)){
  ref_gms[[i]] <- offs$X[bythree[i]:(bythree[i]+2)]
}

lapply(ref_gms,table)
ref_gms <- do.call(rbind, ref_gms)

for(i in 1:nrow(ref_gms)){
  temp <- ref_gms[i,] == c(0,1,2)
  if(F %in% temp == T){
    print(i)
    stop()
  }
}
# 1064
# Error

# Okay, so the 1064th game is the issue

## Put in the game ids to the offs data frame up to the weird one:
offs$game_id <- NA
end1 <- 1063*3
bythree <- seq(from = 1, to = end1, by = 3)
for(i in 1:length(bythree)){
  offs$game_id[bythree[i]:(bythree[i]+2)] <- games$GAME_ID[i]
}

## Deal with the weird one:
offs$game_id[(end1+1):(end1+2)] <- games$GAME_ID[i+1]
j <- i + 2

## Put in the remaining game ids:
end2 <- nrow(offs)
bythree <- seq(from = end1+3, to = end2, by = 3)
for(i in 1:length(bythree)){
  offs$game_id[bythree[i]:(bythree[i]+2)] <- games$GAME_ID[j]
  j <- j + 1
}

## Put name variables into one cell:
offs$name <- paste(offs$FIRST_NAME, offs$LAST_NAME)

## Make all colnames lowercase and remove old name vars:
colnames(offs) <- tolower(colnames(offs))
offs <- offs[,-c(3,4)]

## Transform from long to wide format:
offs <- reshape(data = offs, v.names = colnames(offs)[c(2,3,5)], idvar = "game_id", 
                 timevar = "x", direction = "wide")

## Fix the new wide colnames:
colnames(offs)[c(2,5,8)] <- paste0("ref_id",1:3)
colnames(offs)[c(3,6,9)] <- paste0("ref_jersey",1:3)
colnames(offs)[c(4,7,10)] <- paste0("ref_name",1:3)


## Write to new csv:
setwd("C:/Users/rbm166/Dropbox/IST597k/NBA/data/elo-plus-features/clean-features/")
write.csv(x = offs, file = "02a-clean_game_officials_data.csv", row.names = F)

################################################################################

rm(list=ls())
gc()
library(stringr)
set.seed(11769)
options(stringsAsFactors = F)

######################
## TEAM GAME DATA
######################

setwd("C:/Users/rbm166/Dropbox/IST597k/NBA/data/")
tm.adv <- read.csv("game_adv_team_data.csv")
tm.norm <- read.csv("game_norm_team_data.csv")

## Make colnames lowercase:
colnames(tm.adv) <- tolower(colnames(tm.adv))
colnames(tm.norm) <- tolower(colnames(tm.norm))


## Read in game ids so we can use the game dates to generate rolling values: 
games <- read.csv("unique_GameIDs.csv")
colnames(games) <- tolower(colnames(games))

## Put game dates into the team data frames:
tm.adv$game_date <- tm.norm$game_date <- NA

for(i in 1:nrow(games)){
  tm.adv$game_date[which(tm.adv$game_id == games$game_id[i])] <- 
    games$game_date[i]
  
  tm.norm$game_date[which(tm.norm$game_id == games$game_id[i])] <- 
    games$game_date[i]
}

## Format dates:
tm.adv$game_date <- as.Date(tm.adv$game_date)
tm.norm$game_date <- as.Date(tm.adv$game_date)


## Insert a seasongame variable and calculate pregame season avgs:
uni.tms <- unique(tm.adv$team_id)
tm.adv$seasongame <- tm.norm$seasongame <- NA

for(i in 1:length(uni.tms)){
  temp1 <- tm.adv[which(tm.adv$team_id == uni.tms[i]),]
  temp2 <- tm.norm[which(tm.norm$team_id == uni.tms[i]),]
  
  temp1 <- temp1[order(temp1$game_date),]
  temp2 <- temp2[order(temp2$game_date),]
  
  # Put in seasongame variable
  temp1$seasongame <- 1:nrow(temp1)
  temp2$seasongame <- 1:nrow(temp2)
  
  # calculate expanding window season averages
  a <- b <- list()
  for(j in 2:nrow(temp1)){
    
    a[[j]] <- unlist(apply(temp1[which(temp1$seasongame < j), c(7:21)], 
                                  2, mean))
    b[[j]] <- unlist(apply(temp2[which(temp2$seasongame < j),7:25], 
                                  2, mean))
  }
  # Put the expanding window data back into the temp data frames
  temp1[2:nrow(temp1),7:21] <- do.call(rbind, a)
  temp2[2:nrow(temp2),7:25] <- do.call(rbind, b)
  
  # Substitute the subset in for the original data
  tm.adv[which(tm.adv$team_id == uni.tms[i]),] <- temp1
  tm.norm[which(tm.norm$team_id == uni.tms[i]),] <- temp2
  
}


## Merge the two data sets together and clean:
df <- merge(tm.norm, tm.adv, by = c("game_id", "team_id"))

rpt.cols <- grep(pattern = "*[.]y", x = colnames(df))
df <- df[,-rpt.cols]

new.cols <- gsub(pattern = "[.]x", replacement = "", x = colnames(df))
colnames(df) <- new.cols

## Write to new csv:
setwd("C:/Users/rbm166/Dropbox/IST597k/NBA/data/elo-plus-features/clean-features/")
write.csv(x = df, file = "02b-clean_game_team_adv_norm_data.csv", row.names = F)


################################################################################

rm(list=ls())
gc()
library(stringr)
set.seed(11769)
options(stringsAsFactors = F)

######################
## PLAYER GAME DATA
######################

setwd("C:/Users/rbm166/Dropbox/IST597k/NBA/data/")
adv <- read.csv("game_adv_player_data.csv")

colnames(adv) <- tolower(colnames(adv))

## Read in game ids so we can use the game dates to generate rolling values: 
games <- read.csv("unique_GameIDs.csv")
colnames(games) <- tolower(colnames(games))


## Put game dates into the player data frames:
adv$game_date <- NA

for(i in 1:nrow(games)){
  adv$game_date[which(adv$game_id == games$game_id[i])] <- 
    games$game_date[i]

}

## Format dates:
adv$game_date <- as.Date(adv$game_date)


## Insert a seasongame variable and calculate pregame season avgs:
uni.tms <- unique(adv$team_id)
adv$seasongame <- NA

## New data frame w/o non-starting player rows:
adv.new <- adv[-which(adv$start_position == ""), ]


## Create data frame to have one row for all games:
df <- data.frame(matrix(data = NA, nrow = nrow(games)*2, ncol = 11))
colnames(df) <- c("game_id", "team_id", "seasongame", "avg_pie", "max_usg", 
                  "all_start", "p1_start", "p2_start", "p3_start", "p4_start", 
                  "p5_start")

dfseq <- seq(1,nrow(games)*2, by = 82)
gmidseq <- seq(1, 410, by = 5)

for(i in 1:length(uni.tms)){
  temp1 <- adv.new[which(adv.new$team_id == uni.tms[i]),]
  temp2 <- adv[which(adv$team_id == uni.tms[i]),]
  
  temp1 <- temp1[order(temp1$game_date),]
  temp2 <- temp2[order(temp2$game_date),]
  
  
  uni.gms <- unique(temp2$game_id)
  for(j in 1:82){
    temp2$seasongame[which(temp2$game_id == uni.gms[j])] <- j
  }
  
  # Put in seasongame variable
  temp1$seasongame <- sort(rep(1:82, times = 5))
  
  df[dfseq[i]:(dfseq[i]+81), 1] <- temp1$game_id[gmidseq]             # id
  df[dfseq[i]:(dfseq[i]+81), 2] <- temp1$team_abbreviation[gmidseq]   # team
  df[dfseq[i]:(dfseq[i]+81), 3] <- 1:82                               # seasongame
  df[dfseq[i], 4] <- mean(temp1$pie[which(temp1$seasongame == 1)])    # avg pie
  df[dfseq[i], 5] <- max(temp1$usg_pct[which(temp1$seasongame == 1)]) # max usg
  df[dfseq[i], 6:11] <- 0                                             # line-up counts
  
  
  a <- matrix(NA, nrow = 82, ncol = 6)
  a[1,] <- c(1, temp1$player_id[which(temp1$seasongame == 1)])
  
  # Calculate expanding window starting line-up counts
  for(j in 2:82){
    
    # Starting line-up shit
    temp3 <- temp1[which(temp1$seasongame==j),]
    a[j,] <- c(j, temp3$player_id)
    count <- 0
    
    for(k in 1:(j-1)){
      test.all <- length(which(temp3$player_id %in% a[k,2:6] == T))
      if(test.all == 5) count <- count + 1
    }
    
    df[(dfseq[i]+j-1),6] <- count
    df[(dfseq[i]+j-1),7] <- length(which(temp3$player_id[1] == a[1:(j-1),2:6]))
    df[(dfseq[i]+j-1),8] <- length(which(temp3$player_id[2] == a[1:(j-1),2:6]))
    df[(dfseq[i]+j-1),9] <- length(which(temp3$player_id[3] == a[1:(j-1),2:6]))
    df[(dfseq[i]+j-1),10] <- length(which(temp3$player_id[4] == a[1:(j-1),2:6]))
    df[(dfseq[i]+j-1),11] <- length(which(temp3$player_id[5] == a[1:(j-1),2:6]))
    
    
    # Average pie and max usage
    df[(dfseq[i]+j-1),4] <-
      mean(temp2$pie[which(temp2$player_id %in% temp3$player_id == T & 
                             temp2$seasongame < j)], na.rm = T)
    
    usg <- NA
    for(k in 1:5){
      usg[k] <- mean(temp2$usg_pct[which(temp2$player_id == temp3$player_id[k] & 
                                           temp2$seasongame < j)], na.rm = T)
    }
    df[(dfseq[i]+j-1),5] <- max(usg)
    
  }
  
}

setwd("C:/Users/rbm166/Dropbox/IST597k/NBA/data/elo-plus-features/clean-features/")
write.csv(x = df, file = "02c-clean_game_player_adv_data.csv", row.names = F)



################################################################################

rm(list=ls())
gc()
library(stringr)
set.seed(11769)
options(stringsAsFactors = F)

#################################
## Home/Away and W/L Streaks Data
#################################

setwd("C:/Users/rbm166/Dropbox/IST597k/NBA/data/")
df <- read.csv("Entire_Game_Log.csv")
colnames(df) <- tolower(colnames(df))

## Read in game ids so we can use the home/away values:
games <- read.csv("unique_GameIDs.csv")
colnames(games) <- tolower(colnames(games))

## Read in attendance data and substitute game ids 
## (same order as read in python and dates match so it's kosher):
attend <- read.csv("game_attendance_data.csv")
colnames(attend) <- tolower(colnames(attend))
attend$game_id <- games$game_id


## Remove player columns:
df <- df[,4:9]


## Run through the games and create 1 row for each team/game
uni.gms <- unique(df$game_id)

temp <- df[which(df$game_id == uni.gms[1]),]
uni.tms <- unique(temp$team_name)
df2 <- temp[which(temp$team_name == uni.tms[1])[1],]
df2 <- rbind(df2, temp[which(temp$team_name == uni.tms[2])[1],])


for(i in 2:length(uni.gms)){
  temp <- df[which(df$game_id == uni.gms[i]),]
  uni.tms <- unique(temp$team_name)
  temp2 <- temp[which(temp$team_name == uni.tms[1])[1],]
  temp2 <- rbind(temp2, temp[which(temp$team_name == uni.tms[2])[1],])
  df2 <- rbind(df2, temp2)
}

## Sanity check:
length(df2$wl[which(df2$wl=="W")]) == length(df2$wl[which(df2$wl=="L")])
# TRUE


## Put the games and the df2 data together:
df <- merge(df2, games, by = "game_id", all.x = T)
rm(df2)
rm(games)
rm(temp)
rm(temp2)
gc()


## Clean the new data frame for duplicate columns:
to.remove <- grep(pattern = "*[.]y", x = colnames(df))
df <- df[,-to.remove]
colnames(df) <- gsub(pattern = "*[.]x", replacement = "", x = colnames(df))


## Calculate the streaks variables:
df$game_date <- as.Date(df$game_date)
df$home_streak <- df$away_streak <- 0
df$win_streak <- df$loss_streak <- 0
df$back_to_back <- 0
uni.tms <- unique(df$team_name)

# Loop through teams
for(i in 1:length(uni.tms)){
  temp <- df[which(df$team_name == uni.tms[i]),]
  temp <- temp[order(temp$game_date),]
  temp$home_streak[1] <- ifelse(temp$hometeam[1] == temp$team_abbreviation[1], 
                                yes = 1, no = 0)
  temp$away_streak[1] <- ifelse(temp$home_streak[1] == 0, yes = 1, no = 0)
  # Loop through games:
  for(j in 2:nrow(temp)){
    home <- ifelse(temp$hometeam[j] == temp$team_abbreviation[j], 
                   yes = 1, no = 0)
    win <- ifelse(temp$wl[j-1] == "W", yes = 1, no = 0)
    
    temp$home_streak[j] <- ifelse(home == 1, temp$home_streak[j-1] + 1, 0)
    temp$away_streak[j] <- ifelse(home == 0, temp$away_streak[j-1] + 1, 0)
    
    temp$win_streak[j] <- ifelse(win == 1, temp$win_streak[j-1] + 1, 0)
    temp$loss_streak[j] <- ifelse(win == 0, temp$loss_streak[j-1] + 1, 0)
    
    temp$back_to_back[j] <- ifelse(temp$game_date[j] == temp$game_date[j-1] + 1, 
                                   1, 0)
  }
  df[which(df$team_name == uni.tms[i]),] <- temp
}


## Merge streaks and attendance data:
df <- merge(df, attend, by = "game_id", all.x = T)

## Clean up column names:
to.remove <- grep(pattern = "*[.]y", x = colnames(df))
df <- df[,-to.remove]
colnames(df) <- gsub(pattern = "[.]x", replacement = "", colnames(df))

## Write to csv:
setwd("C:/Users/rbm166/Dropbox/IST597k/NBA/data/elo-plus-features/clean-features/")
write.csv(x = df, file = "02d-clean_game_streak_attend_data.csv", row.names = F)

