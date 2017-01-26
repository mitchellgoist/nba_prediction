## Author: Ryan McMahon 
## Date Created: 04/23/16
## Date Last Modified: 04/24/16
## File: "~/Basketball/NBA_WinProbability_Cleaning.R"

## Purpose: 
##         Put all of the individual text files into a large list object

## Program and Hardware Information:
# R 3.1.3 "Smooth Sidewalk"; 64-bit
# Windows 8.1; MSi GE60 2PL Apache Laptop


################################################################################
rm(list=ls())
library(rjson)
set.seed(11769)
options(stringsAsFactors = F)

## Set working directory:
setwd("C:/Users/rbm166/Box Sync/NBA_DATA_Project/Basketball/data/WinProbs/")

## Find all the game files & generate list to hold data:
files <- list.files()
data.ll <- list()


for(i in 1:length(files)){
  # read in json file:
  json.txt <- fromJSON(file = files[i], method="C")
  
  # convert to data frame:
  df <- rbindlist(lapply(json.txt$resultSets[[1]][[2]], 
                         function(x) ifelse(x == "NULL", NA, x)))
  
  # rename columns:
  colnames(df) <- json.txt$resultSets[[1]]$headers
  
  # put data frame into list:
  data.ll[[i]] <- df
}

setwd("C:/Users/rbm166/Box Sync/NBA_DATA_Project/Basketball/data/")
save.image(file = "Cleaned_WinProbability_List.RData")

################################################################################

####################
### Pick up here ###
####################

rm(list=ls())
library(rlist)
set.seed(11769)
options(stringsAsFactors = F)

## Read in saved RData file:
setwd("C:/Users/rbm166/Box Sync/NBA_DATA_Project/Basketball/data/")
load(file = "Cleaned_WinProbability_List.RData")

## Read in Game ID data:
gameid <- read.csv("unique_GameIDs-tm1tm2.csv")


## Go through games list and change game IDs to integers:
for(i in 1:length(data.ll)){
  data.ll[[i]]$GAME_ID <- as.integer(data.ll[[i]]$GAME_ID)
}


## Go through games list and add in teams by gameid:
for(i in 1:length(data.ll)){
  mat.id <- which(gameid$GAME_ID == data.ll[[i]]$GAME_ID[1])
  home <- gameid$HomeTeam[mat.id]
  home.mark <- grep(home, x = c(gameid$Team1[mat.id], gameid$Team2[mat.id]))
  
  if(home.mark ==1){
    away <- gameid$Team2[mat.id]
  } else{
    away <- gameid$Team1[mat.id]
  }
  
  data.ll[[i]]$home_tm <- home
  data.ll[[i]]$away_tm <- away
  data.ll[[i]]$game_name <- gameid$MATCHUP[mat.id]
  data.ll[[i]]$game_date <- gameid$GAME_DATE[mat.id]
}


## Go through games list and create metric for total time elapsed
for(i in 1:length(data.ll)){
  data.ll[[i]]$total_secs_left <- NA
  uni.per <- unique(data.ll[[i]]$PERIOD)
  total.time <- 720*4
  if(max(uni.per)>4) total.time <- total.time + 300*(max(uni.per)-4)
    
  for(j in 1:length(uni.per)){
    per <- which(data.ll[[i]]$PERIOD == j)
    
    if(j <= 4){
      data.ll[[i]]$total_secs_left[per] <- total.time - 
        (720*j - data.ll[[i]]$SECONDS_REMAINING[per])
    
    } else{
      count <- j - 4
      data.ll[[i]]$total_secs_left[per] <- total.time - 2880 - 
        (300*count - data.ll[[i]]$SECONDS_REMAINING[per])
    
    }
    
  }
  
}


## Sort list object by game date:
data.ll <- list.sort(data.ll, game_date[1])

## Save RData again, overwrite old file:
save.image(file = "Cleaned_WinProbability_List.RData")


################################################################################
