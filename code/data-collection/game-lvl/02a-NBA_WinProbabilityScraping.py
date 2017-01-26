# -*- coding: utf-8 -*-
"""
Created on Sat Apr 23 17:01:46 2016

@author: rbm166
"""

###############################################################################
############# GETTING THE WIN PROBABILITY DATA FOR EACH GAME ##################
###############################################################################

## There is no function/class for retrieving the win probability second by 
## second information in the package.

## Solution: Write a scraper.

# Notes: Tried just going through with 'requests.get()', but it gets kicked 
#        pretty quickly (like 2 or 3 iterations in), even with a 30 second 
#        sleep between iterations.
#
#       Solved, below, by using selenium and chromedriver.exe.      

import os
import pandas as pd
import time
from selenium import webdriver
import json
import random

os.chdir('C:\\Users\\rbm166\\Box Sync\\NBA_DATA_Project\\Basketball\\nba_py\\nba_py')

execfile('constants.py')
execfile('__init__.py')
execfile('player.py')
execfile('game.py')
execfile('league.py')
execfile('team.py')

# Pull game ids:
game_obj = GameLog(season = '2015-16')
games = game_obj.overall()

unique_games = pd.unique(games['GAME_ID'])


# Link python to the driver program:
chromedriver = "C:\\Users\\rbm166\\Desktop\\chromedriver"
os.environ["webdriver.chrome.driver"] = chromedriver
driver = webdriver.Chrome(chromedriver)

# Create list to hold the data:
winprobs = []

# Set working directory to write each game to as a new .txt file:
os.chdir('C:\\Users\\rbm166\\Box Sync\\NBA_DATA_Project\\Basketball\\data\\WinProbs')


# Loop through unique games, generating url, going to that url with the driver,
# downloading the page encoding (which means that it has some xml/html shit 
# included) and putting it in the list. Then sleep, go back a 
# page -- to the nothing start page -- clear cookies, and repeat: 
for i in range(len(unique_games)):        
    url_1 = 'http://stats.nba.com/stats/winprobabilitypbp?GameID=%s&RunType=each+second' % unique_games[i]
    driver.get(url_1)
    a = driver.find_element_by_tag_name('pre')
    data = json.loads(a.text)
    filename = 'winprobs_' + str(i) + '.txt'
    with open(filename, 'w') as out_file:
        json.dump(data, out_file)
     
    time.sleep(1) 
    driver.delete_all_cookies()   
    time.sleep(random.uniform(4,7))


