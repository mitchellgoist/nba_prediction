# Author: Ryan McMahon 
# Date Created: 03/04/16
# Date Last Modified: 04/23/16
# Purpose: 
#         Test run of mass scrape.

# Number of Players Completed:
#     1-60 from the player_IDs_names.csv (03/04/16)
#     61-120 from the player_IDs_names.csv (03/07/16)
#     121-180 from the player_IDs_names.csv (03/07/16)

# EDITS:
#       04/23)
#             Re-run for all players b/c season ended; edit wait time to be 
#             random uniform instead of normal (shortens wait time).


## Concept in R from http://thedatagame.com.au/2015/09/27/how-to-create-nba-shot-charts-in-r/

## Program and Hardware Information:
# R 3.1.3 "Smooth Sidewalk"; 64-bit
# Windows 8.1; MSi GE60 2PL Apache Laptop


################################################################################
rm(list=ls())
library(rjson)
library(data.table)
set.seed(11769)
options(stringsAsFactors = F)
setwd("C:/Users/rbm166/Box Sync/NBA_DATA_Project/Basketball/")
players <- read.csv("data/player_IDs_names.csv")

#####


ll <- list()

## Loop Through Players:
for(i in 1:nrow(players)){
  playerID <- players[i,1]
  shotURL <- paste("http://stats.nba.com/stats/shotchartdetail?CFID=33&CFPARAMS=2015-16&ContextFilter=&ContextMeasure=FGA&DateFrom=&DateTo=&GameID=&GameSegment=&LastNGames=0&LeagueID=00&Location=&MeasureType=Base&Month=0&OpponentTeamID=0&Outcome=&PaceAdjust=N&PerMode=PerGame&Period=0&PlayerID=",playerID,"&PlusMinus=N&Position=&Rank=N&RookieYear=&Season=2015-16&SeasonSegment=&SeasonType=Regular+Season&TeamID=0&VsConference=&VsDivision=&mode=Advanced&showDetails=0&showShots=1&showZones=0", sep = "")
  
  # import from JSON
  shotData <- fromJSON(file = shotURL, method="C")
  if(length(shotData$resultSets[[1]][[3]])>1){
    shotDataf <- rbindlist(lapply(shotData$resultSets[[1]][[3]], 
                                  function(x) ifelse(x == "NULL", NA, x)))
    if(nrow(shotDataf) > 0 & ncol(shotDataf) > 1){
      # shot data headers
      colnames(shotDataf) <- shotData$resultSets[[1]][[2]]
      
      # Unlist the Columns
      shotDataf <- data.frame(apply(shotDataf,2,unlist))
      
      # covert x and y coordinates into numeric
      shotDataf$LOC_X <- as.numeric(as.character(shotDataf$LOC_X))
      shotDataf$LOC_Y <- as.numeric(as.character(shotDataf$LOC_Y))
      shotDataf$SHOT_DISTANCE <- as.numeric(as.character(shotDataf$SHOT_DISTANCE))
      
      ll[[i]] <- shotDataf
    }
  } else{
    ll[[i]] <- NULL
  }
  if(i %% 7 == 0){
    cat(paste0("Progress: ", i,"/",nrow(players),"\n"))
  }
  
  Sys.sleep(time = runif(n = 1,7,15))
  
}

# Remove Null list items:
ll <- ll[!sapply(ll, is.null)]

colnames(ll[[1]])
par(mfrow = c(2,5))
for(i in 1:length(ll)){
  plot(ll[[i]]$LOC_X, ll[[i]]$LOC_Y, panel.first = grid(), 
       xlim = c(-250,250), ylim = c(-50,420), main = ll[[i]]$PLAYER_NAME[1])
  
  with(ll[[i]], points(LOC_X[which(SHOT_MADE_FLAG == "1")], 
                       LOC_Y[which(SHOT_MADE_FLAG == "1")], 
                       col = "green", pch = 19, bg = "green"))
}


for(i in 1:length(ll)){
  cat(unique(ll[[i]]$PLAYER_NAME), "\n")
}

test <- rbindlist(ll)
summary(test)

save.image(file = "data/ShotCharts_Full_2015-16_04232016.RData")
