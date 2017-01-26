## Author: Ryan McMahon 
## Date Created: 04/28/16
## Date Last Modified: 04/28/16
## File: "~/IST597k/NBA/code/elo-rating-functions.R"

## Purpose: 
##         Write the functions to calculate new Elo ratings for teams using 
##         the 538 methodology (with a home-court advantage of 100 Elo points)
##         and without that advantage.

## Program and Hardware Information:
# R 3.1.3 "Smooth Sidewalk"; 64-bit
# Windows 8.1; MSi GE60 2PL Apache Laptop

################################################################################

rm(list=ls())

## Generate 538 function:

gen_new_elo_538 <- function(elo_i_tm, elo_i_opp, loc, MOV, K = 20){
  if(loc == "H"){
    elo_diff <- (elo_i_tm - elo_i_opp) + 100
    inv_elo_diff <- elo_i_opp - elo_i_tm - 100
  } else{
    elo_diff <- (elo_i_tm - elo_i_opp) - 100
    inv_elo_diff <- elo_i_opp - elo_i_tm + 100
  }
  win <- ifelse(MOV > 0, yes = 1, no = 0)
  z <- MOV + 3
  if(z < 0){
    z <- abs(z)
    multiplier <- (z^0.8) / (7.5 + (0.006 * elo_diff))
  } else{
    multiplier <- (z^0.8) / (7.5 + (0.006 * elo_diff))
  }
  
  
  E_a <- 1 / (1 + (10^(inv_elo_diff / 400)))
  
  elo_n_tm <- elo_i_tm + (K*multiplier*(win - E_a))
  
  ret_obj <- list(elo_n_tm, E_a)
  return(ret_obj)
}

# test:
gen_new_elo_538(elo_i_tm = 1627.9, elo_i_opp = 1511.5, loc = "H", MOV = 5, K = 20)



## Generate function without home court advantage:
gen_new_elo_no_HC <- function(elo_i_tm, elo_i_opp, loc, MOV, K = 20){
  if(loc == "H"){
    elo_diff <- (elo_i_tm - elo_i_opp) 
    inv_elo_diff <- elo_i_opp - elo_i_tm 
  } else{
    elo_diff <- (elo_i_tm - elo_i_opp)
    inv_elo_diff <- elo_i_opp - elo_i_tm
  }
  win <- ifelse(MOV > 0, yes = 1, no = 0)
  z <- MOV + 3
  if(z < 0){
    z <- abs(z)
    multiplier <- (z^0.8) / (7.5 + (0.006 * elo_diff))
  } else{
    multiplier <- (z^0.8) / (7.5 + (0.006 * elo_diff))
  }
  
  
  E_a <- 1 / (1 + (10^(inv_elo_diff / 400)))
  
  elo_n_tm <- elo_i_tm + (K*multiplier*(win - E_a))
  
  ret_obj <- list(elo_n_tm, E_a)
  return(ret_obj)
}

# test
gen_new_elo_no_HC(elo_i_tm = 1627.9, elo_i_opp = 1511.5, loc = "H", MOV = 5, K = 20)



## Save functions to be called in another script:
setwd("C://Users/rbm166/Dropbox/IST597k/NBA/data/")
save.image(file = "elo-rating-functions.RData")
