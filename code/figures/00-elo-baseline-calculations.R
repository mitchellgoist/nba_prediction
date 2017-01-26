## Author: Ryan McMahon
## Date Created: 05/04/2016
## Date Last Modified: 05/04/2016
## File: "~/code/figures/00-elo-baseline-calculations.R"
## Purpose: 
##         Calculate the baseline accuracy and precision of elo forecasts so 
##         those metrics can be added to the plots.

## NOTES:
##

################################################################################
rm(list=ls())
gc()
library(stringr)
set.seed(11769)
options(stringsAsFactors = T)

## Read in 538 clean elo data:
setwd("C:/Users/rbm166/Dropbox/IST597k/NBA/data/elo-plus-features/")
df <- read.csv("04-clean-sampled-elo-plus-538-method.csv")

elo.preds <- df$forecast
actual <- df$win_dum

elo.preds <- ifelse(test = elo.preds >= 0.5, 1, 0)

(tab1 <- table(elo.preds, actual, dnn = c("Preds", "True")))

(acc1 <- sum(diag(tab1))/sum(tab1))
# 0.6902
(prec1 <- tab1[2,2]/ sum(tab1[2,]))
# 0.6851


## Read in no home-court clean elo data:
df <- read.csv("05-clean-sampled-elo-plus-no-home-court.csv")

elo.preds <- df$forecast
actual <- df$win_dum

elo.preds <- ifelse(test = elo.preds >= 0.5, 1, 0)

(tab1 <- table(elo.preds, actual, dnn = c("Preds", "True")))

(acc1 <- sum(diag(tab1))/sum(tab1))
# 0.6844
(prec1 <- tab1[2,2]/ sum(tab1[2,]))
# 0.6775


