# -*- coding: utf-8 -*-
"""
Created on Sun Apr 24 16:04:18 2016

@author: rbm166
"""

## This script pull player traits from the NBA API. Goes through Player IDs 
## one by one and requests the info (a 1 X 26 row vector), and creates a 
## CSV file ('player_trait_summaries.csv') in the '~/Basketball/data/' folder.

import os
import pandas as pd
import csv

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

f = open('player_IDs_names.csv', 'rb')
reader = csv.reader(f)
reader.next()
player_ids= []
player_names = []
for row in reader:
    player_ids.append(int(row[0])) 
    player_names.append(row[1])
    
profiles = []
for i in range(len(player_ids)):
    temp = PlayerSummary(player_ids[i]).info()
    profiles.append(temp)
    
data = pd.concat(profiles)
heights = pd.DataFrame(list(data.HEIGHT.str.split('-')))
heights.rename(columns={0: 'ht_feet', 1: 'ht_inches'}, inplace=True)

data = data.join(heights, how='right')
data.drop('HEIGHT', axis=1, inplace=True)

data.to_csv('player_trait_summaries.csv', index = 0)