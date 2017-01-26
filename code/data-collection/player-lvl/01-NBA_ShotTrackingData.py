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
os.chdir('C:\\Users\\rbm166\\Box Sync\\NBA_DATA_Project\\Basketball\\nba_py\\nba_py')

execfile('constants.py')
execfile('__init__.py')
execfile('player.py')
execfile('game.py')
execfile('league.py')
execfile('team.py')

## Now go collect data:
os.chdir('C:\\Users\\rbm166\\Box Sync\\NBA_DATA_Project\\Basketball\\data')

teams = TeamList()
teams = teams.info()
counter = 0
data = []

for i in range(0,29):
    a = TeamPlayers(teams['TEAM_ID'][i])
    test = a.json
    players_ids = []
    players_names = []
    for x in range(len(test['resultSets'][1]['rowSet'])):
        players_ids.append(test['resultSets'][1]['rowSet'][x][1])
        players_names.append(test['resultSets'][1]['rowSet'][x][2])
     
    df = pd.DataFrame(players_ids)
    df[1] = players_names

    data.append(df)
    # PlayerShotLogTracking isn't on the NBA site anymore :(
    #for x in range(len(df)):
    #    pst = (PlayerShotLogTracking(df[0][x]))
    #    data.append(pst.overall())
    #    data[counter]['player'] = df[1][x]
    #    counter += 1
    #    print "Team: {} and player: {}".format(i, x)
        

data = pd.concat(data)


## Write Team IDs and Player Info to CSVs:
teams.to_csv('team_IDs_info.csv', index = 0)

data.to_csv('player_IDs_names.csv', index = 0)



# Get GameLogs, so we can get play-by-play:
game_obj = GameLog(season = '2015-16')
games = game_obj.overall()

unique_games = pd.unique(games['GAME_ID'])


