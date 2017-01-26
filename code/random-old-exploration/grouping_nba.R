rm(list=ls())
setwd("C:/Users/rbm166/Dropbox/Python")

library(stringr)
set.seed(11769)

# Funcs
len_uni <- function(x, na_rem=T){
  if(na_rem != F){
    return(length(unique(x)))
  } else{
    return(length(unique(na.omit(x))))
  }
}

sturges <- function(x){
  return(1+3.3*log(len_uni(x)))
}

# Code
df <- read.csv("2014-15_shot_data.csv", stringsAsFactors = F)

df <- df[,-1]
df <- na.omit(df)

colnames(df) <- tolower(colnames(df))

df$location <- as.factor(df$location)
df$w <- as.factor(df$w)
df <- df[-which(df$fgm>1),]

min_left <- NA
sec_left <- NA
for(i in 1:nrow(df)){
  a <- unlist(str_split(string = df$game_clock[i], pattern = ":"))
  min_left[i] = as.integer(a[1])
  sec_left[i] = as.integer(a[2])
}

df$game_clock <- (min_left + (sec_left/60))

X <- cbind(df[,c(8:13,17)])
X <- X[-which(X$touch_time<0),]
#cuts <- apply(X, 2, sturges)
#cuts


summary(X)

X$game_clock <- cut(x = X$game_clock, 3)
X$shot_clock <- cut(x = X$shot_clock, 5)
X$dribbles <- cut(x = X$dribbles, 5)
X$touch_time <- cut(x = X$touch_time, 6)
X$shot_dist <- cut(x = X$shot_dist, 10)
X$close_def_dist <- cut(x = X$close_def_dist, 15)
z <- unique(X)
nrow(z)


bad_shots <- df[which(df$game_clock >= 1 & df$shot_dist > 30 & 
                        df$close_def_dist < 10 & df$period!=2 & df$period!=4),]
summary(bad_shots)
summary(as.factor(bad_shots$player))
