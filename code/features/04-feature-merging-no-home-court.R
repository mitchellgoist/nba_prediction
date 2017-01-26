## Author: Ryan McMahon 
## Date Created: 05/01/16
## Date Last Modified: 05/01/16
## File: "~/IST597k/NBA/code/features/04-feature-merging-no-home-court.R"

## Purpose: 
##         Substitute in the no-HC elo ratings for the 538 elos so that we can
##         compare the four models: 1) pure 538; 2) 538 minus home-court 
##         advantage; 3) pure 538 + features; and 4) 538 w/o home-court plus 
##         features.

## Program and Hardware Information:
# R 3.1.3 "Smooth Sidewalk"; 64-bit
# Windows 8.1; MSi GE60 2PL Apache Laptop

################################################################################

rm(list=ls())
gc()
library(stringr)
set.seed(11769)
options(stringsAsFactors = F)

## Read in pure 538 elo plus features data:
setwd("C:/Users/rbm166/Dropbox/IST597k/NBA/data/")
df.538 <- read.csv("elo-plus-features/02-elo-plus-all-features-538-method-1516.csv")

## Read in no home court elo ratings:
df.nohc <- read.csv("elo-rating-cleaned-no-home-court-method-2015-16.csv")

## Subset nohc to just game id, team, and ratings:
df.nohc <- df.nohc[,c(2,9,12,13,18,19)]

## Remove elos from df.538:
to.remove <- grep("elo", colnames(df.538))
df.538merge <- df.538[,-to.remove]

## Make sure the games and teams are in the same order:
df <- merge(df.538merge, df.nohc, by = c("game_id", "team_id"))

col.ord <- colnames(df.538)
df <- df[,col.ord]
colnames(df) == colnames(df.538)
# All = TRUE

## Write out to CSV
setwd("C:/Users/rbm166/Dropbox/IST597k/NBA/data/elo-plus-features/")
write.csv(df, "03-elo-plus-all-features-no-home-court-1516.csv", row.names = F)
