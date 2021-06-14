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

# del sys.path[0:20]
# path_to_the_model = os.path.abspath(os.path.join(os.getcwd(), './# pyWOFOST/pcse-master'))
# sys.path.append(path_to_the_model)

import pcse
from pcse.fileinput import ExcelWeatherDataProvider
from pcse.fileinput import PCSEFileReader
from pcse.fileinput import YAMLCropDataProvider, CABOFileReader
from pcse.models import Wofost71_PP
from pcse.base import ParameterProvider

# ----------------------------------------------------------------------------------------------------------------------
# SPECIFY DIRECTORY
# ----------------------------------------------------------------------------------------------------------------------

input_dir = r'D:\# Jvasco\Working Papers\# CIMMYT Database\GYGA Global Yield Gap Atlas\GYGA_Egypt_Wheat\data\wofost-inputs'
output_dir = r'D:\# Jvasco\Working Papers\# CIMMYT Database\GYGA Global Yield Gap Atlas\GYGA_Egypt_Wheat\data\wofost-outputs'

# ----------------------------------------------------------------------------------------------------------------------
# DEFINE SIMULATIONS
# ----------------------------------------------------------------------------------------------------------------------

years = range(2009, 2018)
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
    # ------------------------------------------------------------------------------------------------------------------
    # Load input data
    crop_parameters = CABOFileReader(os.path.join(input_dir, r'./crop-parameters/WHE-med-Eth-GYGA.CAB'))
    crop_parameters['IOX'] = 0
    # crop_parameters = YAMLCropDataProvider()
    # crop_parameters.set_active_crop('{crop}'.format(crop=crop), '{variety}'.format(variety=variety))
    # crop_parameters['IDSL'] = 0
    weather_data = ExcelWeatherDataProvider(os.path.join(input_dir, "weather_actual_{site}.xlsx".format(site=site)), missing_snow_depth=0)  # weather_nasa_final_{site}.xlsx
    weather_export = pd.DataFrame(weather_data.export()).set_index('DAY')
    soil_parameters = PCSEFileReader(os.path.join(input_dir, 'WOFOST_Soil_Wageningen2014.txt'))
    site_parameters = PCSEFileReader(os.path.join(input_dir, 'WOFOST_Site_Egypt.txt'))
    parameters = ParameterProvider(cropdata=crop_parameters, sitedata=site_parameters, soildata=soil_parameters)
    parameters['CO2'] = 400
    agromanager = yaml.load(open(os.path.join(input_dir, './Agrom_Wheat_{site}_{year}.txt'.format(site=site, year=year))))
    agromanager = agromanager['AgroManagement']
    # ------------------------------------------------------------------------------------------------------------------
    # Override TSUMs per weather station
    if site == 'NileDelta':
        parameters.set_override("TSUM1", 1639)  # 1557)
        parameters.set_override("TSUM2", 1111)  # 1279)
        parameters.set_override("SLATB", [0.0, 0.0037, 0.3, 0.0037, 0.9, 0.0037, 1.45, 0.0037, 2.0, 0.0037])
        parameters.set_override("SPAN", 35)
        # parameters.set_override("AMAXTB", [0.00, 35.0, 1.30, 35.0, 2.00, 5.0])
        parameters.set_override("AMAXTB", [0.00, 45.0, 1.30, 45.0, 2.00, 7.5])
    else:
        parameters.set_override("TSUM1", 1387)  # 1405)
        parameters.set_override("TSUM2", 735 + 600)   # 937+500)
        parameters.set_override("SLATB", [0.0, 0.0037, 0.3, 0.0037, 0.9, 0.0037, 1.45, 0.0037, 2.0, 0.0037])
        parameters.set_override("SPAN", 35)
        # parameters.set_override("AMAXTB", [0.00, 35.0, 1.30, 35.0, 2.00, 5.0])
        parameters.set_override("AMAXTB", [0.00, 45.0, 1.30, 45.0, 2.00, 7.5])
    print('{site} . . . TSUM1 = {tsum1} . . . TSUM2 = {tsum2}'.format(site=site, tsum1=parameters['TSUM1'], tsum2=parameters['TSUM2']))
    # ------------------------------------------------------------------------------------------------------------------
    # Run the model
    wofost = Wofost71_PP(parameters, weather_data, agromanager)
    wofost.run_till_terminate()
    # ------------------------------------------------------------------------------------------------------------------
    # Get output and summary
    output_daily = pd.DataFrame(wofost.get_output()).set_index("day")
    output_daily = output_daily.join(weather_export)
    output_daily['year'] = year
    output_daily['crop'] = crop
    output_daily['site'] = site
    output_daily.to_csv(os.path.join(output_dir, './daily_{crop}_{site}_{year}_updated.csv'.format(year=year, crop=crop, site=site)))
    output_summary = pd.DataFrame(wofost.get_summary_output())
    output_summary['year'] = year
    output_summary['crop'] = crop
    output_summary['site'] = site
    final = final.append(output_summary)
final.to_csv(os.path.join(output_dir, './summary_wheat_egypt_updated.csv'))

# ----------------------------------------------------------------------------------------------------------------------
# PLOT PARAMETERS
# ----------------------------------------------------------------------------------------------------------------------

# # Default WOFOST partitioning coefficients -----------------------------------------------------------------------------
# WOFOST_FLTB = [0.000, 0.650, 0.100, 0.650, 0.250, 0.700, 0.500, 0.500, 0.646, 0.300, 0.950, 0.000, 2.000, 0.000]
# WOFOST_FSTB = [0.000, 0.350, 0.100, 0.350, 0.250, 0.300, 0.500, 0.500, 0.646, 0.700, 0.950, 1.000, 1.000, 0.000, 2.000, 0.000]
# WOFOST_FOTB = [0.000, 0.000, 0.950, 0.000, 1.000, 1.000, 2.000, 1.000]
#
# # Create linear interpolation objects ----------------------------------------------------------------------------------
# FL_int1d = interp1d(WOFOST_FLTB[0::2], WOFOST_FLTB[1::2])
# FS_int1d = interp1d(WOFOST_FSTB[0::2], WOFOST_FSTB[1::2])
# FO_int1d = interp1d(WOFOST_FOTB[0::2], WOFOST_FOTB[1::2])
#
# # Compute daily partitioning fractions ---------------------------------------------------------------------------------
# df_def = df.copy(deep=True)
# df_def["FL"] = df_def.DVS.apply(FL_int1d)
# df_def["FS"] = df_def.DVS.apply(FS_int1d)
# df_def["FO"] = df_def.DVS.apply(FO_int1d)
# fig, axes = plt.subplots()
# axes.plot(df_def.DVS, df_def.FL, label="Leaves")
# axes.plot(df_def.DVS, df_def.FS, label="Stems")
# axes.plot(df_def.DVS, df_def.FO, label="Storage organs")
# axes.set_title("WOFOST default partitioning")
# fig.legend(loc=5)


# ----------------------------------------------------------------------------------------------------------------------
# THE END
# ----------------------------------------------------------------------------------------------------------------------
