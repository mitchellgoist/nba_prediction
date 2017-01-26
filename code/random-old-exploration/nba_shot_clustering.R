rm(list=ls())
setwd("C:/Users/rbm166/Dropbox/Python")
library(fpc)
library(stringr)
set.seed(11769)
df <- read.csv("2014-15_shot_data.csv", stringsAsFactors = F)

df <- df[,-1]
df[which(is.na(df)==T),]
df <- na.omit(df)
colnames(df) <- tolower(colnames(df))
df <- df[-which(df$touch_time < 0), ]

mydata1 <- scale(df[,c(5:7,9:13,17)])
mydata2 <- df[,c(5:7,9:13,17)]


wss <- (nrow(mydata1)-1)*sum(apply(mydata1,2,var))
for (i in 2:15) wss[i] <- sum(kmeans(mydata1,
                                     centers=i)$withinss)
plot(1:15, wss, type="b", xlab="Number of Clusters",
     ylab="Within groups sum of squares") 

k_est <- pamk(data = mydata2, krange = 1:50, usepam = F,scaling = T)
n_clusts <- k_est$nc #10


fit <- kmeans(x = mydata1,iter.max = 50, centers = n_clusts, algorithm = "MacQueen")
aggregate(mydata1,by=list(fit$cluster),FUN=mean)


df$cluster <- fit$cluster
par(mfrow = c(2,1))
hist(df$cluster[which(df$player=="Stephen Curry")], breaks = 15, freq = F)
hist(df$cluster[which(df$player=="Anthony Davis")], breaks = 15, freq = F)

library(lattice)
# Each group in a separate mini plot
xyplot(shot_dist ~ shot_clock| cluster, data = df)
xyplot(dribbles ~ shot_clock| cluster, data = df)
xyplot(touch_time ~ shot_clock| cluster, data = df)
xyplot(touch_time ~ dribbles| cluster, data = df)
xyplot(shot_dist ~ shot_clock| player, data = df)


fgperc <- aggregate(x = df$fgm, by = list(df$player, df$cluster), FUN = mean)
xyplot(fgperc$x ~ fgperc[,2]|fgperc[,1])


table(df$cluster, df$player)

aggregate(x = df, by = list(df$cluster),FUN = summary) 
steph <- df[which(df$player=="Stephen Curry"),]
aggregate(steph$fgm, by = list(steph$cluster), mean)
plot(df$cluster[which(df$fgm==0)], df$shot_dist[which(df$fgm==0)])
points(df$cluster[which(df$fgm==1)], df$shot_dist[which(df$fgm==1)], col ="red", pch = 22)
