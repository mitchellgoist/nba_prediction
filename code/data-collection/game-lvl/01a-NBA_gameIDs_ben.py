# -*- coding: utf-8 -*-
"""
Created on Sat Apr 23 2016

@author: bxs416
"""
## This pulls the GameIDs and related info

import os
import requests
import pandas as pd

## Run edited nba_py module scripts:
os.chdir('C:\\Users\\Rubin\\Box Sync\\NBA_DATA_Project\\Basketball\\nba_py\\nba_py')

execfile('constants.py')
execfile('__init__.py')
execfile('player.py')
execfile('game.py')
execfile('league.py')
execfile('team.py')

## Now go collect data:
os.chdir('C:\\Users\\Rubin\\Box Sync\\NBA_DATA_Project\\Basketball\\data')

# get the entire game log
AllGames = GameLog()
AllGames = AllGames.overall()

# output entire game log to csv
AllGames.to_csv('Entire_Game_Log.csv', index = 0)