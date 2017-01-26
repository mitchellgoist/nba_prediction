# -*- coding: utf-8 -*-
"""
Created on Fri Apr 29 20:06:01 2016

@author: rbm166
"""
## This script connects to the NBA Stats API and grabs game specific info.
## The info obtained includes basic and advanced player stats, the starting 
## line-ups, who the refs were, and how many people attended.

import os
import pandas as pd
import csv

## Run edited nba_py module scripts:
os.chdir('C:\\Users\\rbm166\\Dropbox\\IST597k\\NBA\\code\\nba_py\\nba_py')

execfile('constants.py')
execfile('__init__.py')
execfile('player.py')
execfile('game.py')
execfile('league.py')
execfile('team.py')

os.chdir('C:\\Users\\rbm166\\Dropbox\\IST597k\\NBA\\data')

f = open('unique_GameIDs.csv', 'rb')
reader = csv.reader(f)
reader.next()
game_ids= []

for row in reader:
    game_ids.append('00' + str(row[0])) 


norm_player_stats =[]
adv_player_stats = []
officials = []
attendance = []
norm_team_stats = []
adv_team_stats = []

i = 0
endpt = str(len(game_ids))

for game in game_ids:
    temp = BoxscoreAdvanced(game)
    norm_player_stats.append(temp.player_stats())
    adv_player_stats.append(temp.sql_players_advanced())
    officials.append(temp.officials())
    attendance.append(temp.game_info())
    norm_team_stats.append(temp.team_stats())
    adv_team_stats.append(temp.sql_team_advanced())
    
    if i % 10 == 0:
        print str(i) + '/' + endpt + ' games complete\n'
    
    i += 1
    
norm_player_data = pd.concat(norm_player_stats)
adv_player_data = pd.concat(adv_player_stats)

officials = pd.concat(officials) # Need to mark w/ game id's, new game every 3 rows

games = pd.DataFrame(game_ids)
games.rename(columns={0: 'game_id'}, inplace=True)

attendance = pd.concat(attendance)
attendance = attendance.join(games, how='left')

norm_team_data = pd.concat(norm_team_stats)
adv_team_data = pd.concat(adv_team_stats)

##################################################

norm_player_data.to_csv('game_norm_player_data.csv', index = 0)
adv_player_data.to_csv('game_adv_player_data.csv', index = 0)

officials.to_csv('game_officials_data.csv', index = True)

attendance.to_csv('game_attendance_data.csv', index = 0)

norm_team_data.to_csv('game_norm_team_data.csv', index = 0)
adv_team_data.to_csv('game_adv_team_data.csv', index = 0)