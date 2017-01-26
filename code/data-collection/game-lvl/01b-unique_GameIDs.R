# set working directory
setwd("C:/Users/Rubin/Box Sync/NBA_DATA_Project/Basketball/data")

# read csv
df <- read.csv("Entire_Game_Log.csv", header=TRUE)

# subset to relevant variables
SubDF <- df[,6:9]
head(SubDF)

# string split
split.matchup <- strsplit(as.character(df[,"MATCHUP"]), split=" ")
splitMatch <- t(as.data.frame(split.matchup))
row.names(splitMatch) <- NULL
head(splitMatch)

# combine relevant variables with string split
combDF <- cbind(SubDF,splitMatch)
HomeIndex <- which(splitMatch[,2]=="vs.")
combDF <- combDF[HomeIndex,]
colnames(combDF)[4:7] <- c("HomeTeam_WL","HomeTeam", "Type", "AwayTeam")
combDF <- combDF[,c(1,2,3,5,7,4)]
head(combDF)

# dedupe by GAME_ID
GameDups <- duplicated(combDF[,"GAME_ID"])
UniqueDF <- combDF[!GameDups,]
UniqueDF <- UniqueDF[order(UniqueDF[,"GAME_ID"]),]
row.names(UniqueDF) <- NULL
head(UniqueDF)

# output to csv
write.csv(UniqueDF, file="unique_GameIDs.csv", row.names=FALSE)
  