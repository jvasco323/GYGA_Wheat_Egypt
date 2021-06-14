# ----------------------------------------------------------------------------------------------------------------------
# ----------------------------------------------------------------------------------------------------------------------
# Import general packages

import os
import numpy as np
import pandas as pd

# ----------------------------------------------------------------------------------------------------------------------
# Specify directory

output_dir = r'D:\# Jvasco\Working Papers\# CIMMYT Database\GYGA Global Yield Gap Atlas\GYGA_Egypt_Wheat\data\wofost-inputs'

# ----------------------------------------------------------------------------------------------------------------------
# Agromanager template

Agrom = """
Version: 1.0
AgroManagement:

{Season} 
"""

Season = """- {year_start}-{month_start_season}-{day_start_season}:
    CropCalendar:
       crop_name: 'wheat'
       variety_name: 'Winter_wheat_107'
       crop_start_date: {sowing_date}
       crop_start_type: sowing
       crop_end_date: {harvest_date}
       crop_end_type: maturity
       max_duration: 340
    TimedEvents: null
    StateEvents: null"""

# ----------------------------------------------------------------------------------------------------------------------
# Spring wheat, Nile Delta

year_start = np.arange(2009, 2018, 1)
month_start_season = "%02d" % 8
day_start_season = "%02d" % 1

sowing_date = pd.DataFrame(data={'Year': year_start})
sowing_date['Month'] = 11
sowing_date['Day'] = 15
sowing_date['dt'] = pd.to_datetime([f'{y}-{m}-{d}' for y, m, d in zip(sowing_date.Year, sowing_date.Month, sowing_date.Day)])
sowing_date['dt'] = sowing_date['dt'].astype(str)

harvest_date = pd.DataFrame(data={'Year': year_start+1})
harvest_date['Month'] = 5
harvest_date['Day'] = 1
harvest_date['dt'] = pd.to_datetime([f'{y}-{m}-{d}' for y, m, d in zip(harvest_date.Year, harvest_date.Month, harvest_date.Day)])
harvest_date['dt'] = harvest_date['dt'].astype(str)

for year in np.nditer(year_start):
    sowing_date_subset = sowing_date[sowing_date.Year == year].reset_index()
    harvest_date_subset = harvest_date[harvest_date.Year == year+1].reset_index()
    Nile_delta = Agrom.format(
        Season=Season.format(year_start=year,
                             month_start_season=month_start_season,
                             day_start_season=day_start_season,
                             sowing_date=sowing_date_subset.dt[0],
                             harvest_date=harvest_date_subset.dt[0]))
    output = os.path.join(output_dir, "Agrom_Wheat_NileDelta_{year}.txt".format(year=year))
    with open(output, "w") as fp:
        fp.write(Nile_delta)

# ----------------------------------------------------------------------------------------------------------------------
# Spring wheat, Upper Egypt

year_start = np.arange(2009, 2018, 1)
month_start_season = "%02d" % 8
day_start_season = "%02d" % 1

sowing_date = pd.DataFrame(data={'Year': year_start})
sowing_date['Month'] = 11
sowing_date['Day'] = 15
sowing_date['dt'] = pd.to_datetime([f'{y}-{m}-{d}' for y, m, d in zip(sowing_date.Year, sowing_date.Month, sowing_date.Day)])
sowing_date['dt'] = sowing_date['dt'].astype(str)

harvest_date = pd.DataFrame(data={'Year': year_start+1})
harvest_date['Month'] = 4
harvest_date['Day'] = 27
harvest_date['dt'] = pd.to_datetime([f'{y}-{m}-{d}' for y, m, d in zip(harvest_date.Year, harvest_date.Month, harvest_date.Day)])
harvest_date['dt'] = harvest_date['dt'].astype(str)

for year in np.nditer(year_start):
    sowing_date_subset = sowing_date[sowing_date.Year == year].reset_index()
    harvest_date_subset = harvest_date[harvest_date.Year == year+1].reset_index()
    Upper_Egypt = Agrom.format(
        Season=Season.format(year_start=year,
                             month_start_season=month_start_season,
                             day_start_season=day_start_season,
                             sowing_date=sowing_date_subset.dt[0],
                             harvest_date=harvest_date_subset.dt[0]))
    output = os.path.join(output_dir, "Agrom_Wheat_UpperEgypt_{year}.txt".format(year=year))
    with open(output, "w") as fp:
        fp.write(Upper_Egypt)

# ----------------------------------------------------------------------------------------------------------------------
# ----------------------------------------------------------------------------------------------------------------------
