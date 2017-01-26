## Author: Ryan McMahon 
## Date Created: 04/30/16
## Date Last Modified: 04/30/16
## File: "~/IST597k/NBA/code/features/01-feature-engineering.R"

## Purpose: 
##         Fill in the new Elo ratings data frame for 
##         the 2015-16 season.

## Program and Hardware Information:
# R 3.1.3 "Smooth Sidewalk"; 64-bit
# Windows 8.1; MSi GE60 2PL Apache Laptop

################################################################################

rm(list=ls())
library(stringr)
library(colorRamps)
set.seed(11769)
options(stringsAsFactors = F)

## Read in 2015/16 elo ratings (538 method):
setwd("C:/Users/rbm166/Dropbox/IST597k/NBA/data/")
df <- read.csv("elo-rating-cleaned-538-method-2015-16.csv")

uni.tms <- unique(df$team_id)
uni.tms <- sort(uni.tms)

east <- c("ATL", "BKN", "BOS", "CHA", "CHI", "CLE", "DET", "IND", "MIA", "MIL",
          "NYK", "ORL", "PHI", "TOR", "WAS")
west <- uni.tms[-which(uni.tms %in% east == T)]

df$tm_conference <- NA
df$tm_conference[which(df$team_id %in% east == T)] <- "E"
df$tm_conference[which(df$team_id %in% west == T)] <- "W"

df$opp_conference <- NA
df$opp_conference[which(df$opp_id %in% east == T)] <- "E"
df$opp_conference[which(df$opp_id %in% west == T)] <- "W"

df$win_dum <- ifelse(test = df$game_result =="W", yes = 1, no = 0)
df$prev_avg_pts <- df$pts

for(i in 1:length(uni.tms)){
  temp <- df[which(df$team_id == uni.tms[i]),]
  temp <- temp[order(temp$seasongame),]
  for(j in 2:nrow(temp)){
    temp$prev_avg_pts[j] <- mean(temp$pts[1:j-1])
  }
  df[which(df$team_id == uni.tms[i]),] <- temp
}

cor(df$prev_avg_pts, df$elo_i)
# 0.5881

df$opp_prev_avg_pts <- df$opp_pts

for(i in 2:82){
  temp <- df[which(df$seasongame == i),]
  for(j in 1:length(uni.tms)){
    temp$opp_prev_avg_pts[which(temp$opp_id == uni.tms[j])] <- 
      temp$prev_avg_pts[which(temp$team_id == uni.tms[j])]
  }
  df[which(df$seasongame == i),] <- temp
}

## Test model including team and location features:
mod1 <- glm(win_dum ~ elo_i*opp_elo_i + 
              factor(team_id):factor(game_location), data = df, family = binomial('logit'))
summary(mod1)

preds <- predict(object = mod1, type = "response")
preds <- ifelse(test = preds >= 0.5, yes = 1, no = 0)
z <- ifelse(test = df$forecast >= 0.5, yes = 1, no = 0)
(tab.new <- table(preds, df$win_dum, dnn = c("preds", "actual")))
(tab.old <- table(z, df$win_dum, dnn = c("preds_elo", "actual")))

(acc.new <- sum(diag(tab.new))/sum(tab.new))
# 0.698374
(acc.old <- sum(diag(tab.old))/sum(tab.old))
# 0.6902439

# Those features marginally improve in-sample accuracy.


## What happens when we don't violate the shit out of our IID assumption:
samp <- sample(x = c(0,1), size = nrow(df)/2, replace = T)
dfseq <- seq(1,nrow(df),by=2)
df2 <- df[1:2,]
df2 <- df2[which(df2$X_iscopy == samp[1]),]
for(i in 2:length(dfseq)){
  temp <- df[dfseq[i]:(dfseq[i]+1),]
  temp <- temp[which(temp$X_iscopy == samp[i]),]
  df2 <- rbind(df2,temp)
}

## Test model including team and location features:
mod2 <- glm(win_dum ~ elo_i*opp_elo_i + factor(team_id):factor(game_location), 
            data = df2, family = binomial('logit'))
summary(mod2)

preds <- predict(object = mod2, type = "response")
preds <- ifelse(test = preds >= 0.5, yes = 1, no = 0)
z <- ifelse(test = df2$forecast >= 0.5, yes = 1, no = 0)
(tab.new <- table(preds, df2$win_dum, dnn = c("preds", "actual")))
(tab.old <- table(z, df2$win_dum, dnn = c("preds_elo", "actual")))

(acc.new <- sum(diag(tab.new))/sum(tab.new))
# 0.704065
(acc.old <- sum(diag(tab.old))/sum(tab.old))
# 0.6902439


## Write out to csv:
setwd("C:/Users/rbm166/Dropbox/IST597k/NBA/data/elo-plus-features/")
write.csv(df, file = "01-elo-plus-features-538-method-1516.csv", row.names = F)
