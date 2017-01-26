## Author: Ryan McMahon 
## Date Created: 04/24/16
## Date Last Modified: 04/24/16
## File: "~/Basketball/NBA_Scrape_Defensive_FG_PERC.R"

## Purpose: 
##         Pull individual defensive fg% differences

################################################################################

rm(list=ls())
library(rjson)
library(data.table)
set.seed(11769)
options(stringsAsFactors = F)
setwd("C:/Users/Rubin/Box Sync/NBA_DATA_Project/Basketball")
players <- read.csv("data/player_IDs_names.csv")

#####

# initialize list
ll <- list()

## Loop Through Players:
for(i in 1:nrow(players)){
  playerID <- players[i,1]
  shotURL <- paste("http://stats.nba.com/stats/playerdashptshotdefend?DateFrom=&DateTo=&GameSegment=&LastNGames=0&LeagueID=00&Location=&Month=0&OpponentTeamID=0&Outcome=&PerMode=PerGame&Period=0&PlayerID=",playerID,"&Season=2015-16&SeasonSegment=&SeasonType=Regular+Season&TeamID=0&VsConference=&VsDivision=", sep = "")
  
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
      
      # insert columns here
      shotDataf$DEF_PERSON_NAME <- players[i,2]
      
      # append to list
      ll[[i]] <- shotDataf
    }
  } else{
    ll[[i]] <- NULL
  }
  if(i %% 7 == 0){
    cat(paste0("Progress: ", i,"/",nrow(players),"\n"))
  }
  
  Sys.sleep(time = runif(n = 1,5,10))
  
}

# Remove Null list items:
ll <- ll[!sapply(ll, is.null)]

# convert list to data frame
df <- do.call(rbind,ll)

# output to csv
write.csv(df, file="Defensive_FG_PCT.csv", row.names=FALSE)
