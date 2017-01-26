# -*- coding: utf-8 -*-
"""
Created on Thu Jan 14 16:26:21 2016

@author: rbm166
"""
## This runs the nba_py module scripts edited to actually work, then 
## pulls the player and team info before moving on to scrape the win 
## probabilities.

import os
import requests
import pandas as pd

## Run edited nba_py module scripts:
#os.chdir('C:\\Users\\rbm166\\Box Sync\\NBA_DATA_Project\\Basketball\\nba_py\\nba_py')
os.chdir('/Users/carolynne/Documents/Box Sync/NBA_DATA_Project/Basketball/nba_py/nba_py')

execfile('constants.py')
execfile('__init__.py')
execfile('player.py')
execfile('game.py')
execfile('league.py')
execfile('team.py')

## Now go collect data:
#os.chdir('C:\\Users\\rbm166\\Box Sync\\NBA_DATA_Project\\Basketball\\data')
os.chdir('/Users/carolynne/Documents/Box Sync/NBA_DATA_Project/Basketball/data')


players_ids = []
players_names = []
passes_ShotsList = []
passes_ByList = []
i = 0


import csv
f= open('player_IDs_names.csv', 'rb')
reader = csv.reader(f)

reader.next()

for row in reader:
    players_ids.append(int(row[0]))
    players_names.append(row[1])
    
    
for i in range(0,len(players_ids)):
    test = PlayerPassTracking(players_ids[i])
    passes_madeList.append(test.passes_made())
    passes_recievedList.append(test.passes_recieved())
    

dataMade = pd.concat(passes_madeList)
dataRecieved = pd.concat(passes_recievedList)

dataMade.to_csv('NBA_PlayersAssistMade.csv', index = 0)
dataRecieved.to_csv('NBA_PlayersAssistRecieved.csv', index = 0)

#####


for i in range(0,len(players_ids)):
    test = PlayerShootingSplits(players_ids[i])
    passes_ShotsList.append(test.assisted_shots())
    #passes_ByList.append(test.assissted_by())
    

dataShots = pd.concat(passes_ShotsList)
#dataBy = pd.concat(passes_ByList)

dataShots.to_csv('NBA_PlayersAssistShots.csv', index = 0)
#dataBy.to_csv('NBA_PlayersAssistBy.csv', index = 0)

