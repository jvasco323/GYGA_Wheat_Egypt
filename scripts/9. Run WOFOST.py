# ----------------------------------------------------------------------------------------------------------------------
# IMPORT GENERAL PACKAGES
# ----------------------------------------------------------------------------------------------------------------------

import os
import sys
import pandas as pd
import yaml
from itertools import product

# ----------------------------------------------------------------------------------------------------------------------
# IMPORT PCSE PACKAGES
# ----------------------------------------------------------------------------------------------------------------------

import openpyxl
import sqlalchemy
import traitlets_pcse
import requests
import xlrd

del sys.path[0:20]
path_to_the_model = os.path.abspath(os.path.join(os.getcwd(), './# pyWOFOST/pcse-master'))
sys.path.append(path_to_the_model)

import pcse
from pcse.fileinput import ExcelWeatherDataProvider
from pcse.fileinput import PCSEFileReader
from pcse.fileinput import YAMLCropDataProvider
from pcse.models import Wofost71_PP
from pcse.base import ParameterProvider

# ----------------------------------------------------------------------------------------------------------------------
# SPECIFY DIRECTORY
# ----------------------------------------------------------------------------------------------------------------------

input_dir = r'C:\# Jvasco\Working Papers\# Global Yield Gap Analysis\GYGA_Egypt_Wheat\data\wofost-inputs'
output_dir = r'C:\# Jvasco\Working Papers\# Global Yield Gap Analysis\GYGA_Egypt_Wheat\data\wofost-outputs'

# ----------------------------------------------------------------------------------------------------------------------
# DEFINE SIMULATIONS
# ----------------------------------------------------------------------------------------------------------------------

years = range(2009, 2020)
crops = ['wheat']
varie = ['Winter_wheat_107']
sites = ['NileDelta', 'UpperEgypt']
coord = [(31.00, 31.00), (32.65, 25.68)]   # lon, lat
locat = zip(sites, coord)
final = pd.DataFrame()

# ----------------------------------------------------------------------------------------------------------------------
# RUN WOFOST
# ----------------------------------------------------------------------------------------------------------------------

for year, crop, variety, site in product(years, crops, varie, sites):
    print("Running for . . . {year} - {crop} - {site}".format(year=year, crop=crop, site=site))
    # ----------------------------------------------------------------------------------------------------------
    # Load input data
    crop_parameters = YAMLCropDataProvider()
    crop_parameters.set_active_crop('{crop}'.format(crop=crop), '{variety}'.format(variety=variety))
    weather_data = ExcelWeatherDataProvider(os.path.join(input_dir, "weather_nasa_final_{site}.xlsx".format(site=site)), missing_snow_depth=0)
    weather_export = pd.DataFrame(weather_data.export()).set_index('DAY')
    soil_parameters = PCSEFileReader(os.path.join(input_dir, 'WOFOST_Soil_Wageningen2014.txt'))
    site_parameters = PCSEFileReader(os.path.join(input_dir, 'WOFOST_Site_Egypt.txt'))
    parameters = ParameterProvider(cropdata=crop_parameters, sitedata=site_parameters, soildata=soil_parameters)
    agromanager = yaml.load(open(os.path.join(input_dir, './Agrom_Wheat_{site}_{year}.txt'.format(site=site, year=year))))
    agromanager = agromanager['AgroManagement']
    # ----------------------------------------------------------------------------------------------------------
    # Run the model
    wofost = Wofost71_PP(parameters, weather_data, agromanager)
    wofost.run_till_terminate()
    # ----------------------------------------------------------------------------------------------------------
    # Get output and summary
    output_daily = pd.DataFrame(wofost.get_output()).set_index("day")
    output_daily = output_daily.join(weather_export)
    output_daily['year'] = year
    output_daily['crop'] = crop
    output_daily['site'] = site
    output_daily.to_csv(os.path.join(output_dir, './daily_{crop}_{site}_{year}.csv'.format(year=year, crop=crop, site=site)))
    output_summary = pd.DataFrame(wofost.get_summary_output())
    output_summary['year'] = year
    output_summary['crop'] = crop
    output_summary['site'] = site
    final = final.append(output_summary)
final.to_csv(os.path.join(output_dir, './summary_wheat_egypt.csv'))

# ----------------------------------------------------------------------------------------------------------------------
# THE END
# ----------------------------------------------------------------------------------------------------------------------
