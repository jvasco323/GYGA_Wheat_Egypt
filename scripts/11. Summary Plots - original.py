# ----------------------------------------------------------------------------------------------------------------------
# IMPORT GENERAL PACKAGES
# ----------------------------------------------------------------------------------------------------------------------

import os
import pandas as pd
import matplotlib.pyplot as plt
import numpy as np
from itertools import product

# ----------------------------------------------------------------------------------------------------------------------
# SPECIFY DIRECTORY
# ----------------------------------------------------------------------------------------------------------------------

input_dir = r'D:\# Jvasco\Working Papers\# CIMMYT Database\GYGA Global Yield Gap Atlas\GYGA_Egypt_Wheat\data\wofost-outputs'
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
# PLOT DAILY
# ----------------------------------------------------------------------------------------------------------------------

all_daily = pd.DataFrame()
for year, site in product(years, sites):
    print("Running for . . . {year} - {site}".format(year=year, site=site))
    # ----------------------------------------------------------------------------------------------------------
    # Load input data
    daily = pd.read_csv(os.path.join(input_dir, r'./daily_wheat_{site}_{year}.csv'.format(site=site, year=year)))
    daily = daily[['day', 'DVS', 'LAI', 'TAGP', 'TWSO', 'TWLV', 'TWST', 'year', 'crop', 'site']].dropna()
    all_daily = all_daily.append(daily)

for site in sites:
    daily_subset = all_daily[all_daily.site == site]
    daily_subset['day'] = pd.to_datetime(daily_subset['day'], format='%Y-%m-%d')
    # ----------------------------------------------------------------------------------------------------------------------
    left, width = .10, .71
    bottom, height = .25, .71
    right = left + width
    top = bottom + height
    wspace = 0.225
    hspace = 0.150
    kws_points = dict(alpha=0.7, linewidth=0.7)
    # ------------------------------------------------------------------------------------------------------------------
    f, (ax1, ax2) = plt.subplots(nrows=2, ncols=1, figsize=(25, 11))
    axes = plt.gca()
    f.subplots_adjust(wspace=wspace, hspace=hspace)
    # Crop development -------------------------------------------------------------------------------------------------
    LAI = ax1.scatter(daily_subset['day'], daily_subset['LAI'], marker='o', s=50, edgecolor='orangered', color='orange', zorder=1, label='LAI')
    ax1.set_xlabel('', family='sans-serif', fontsize=14, color='black')
    ax1.set_ylabel('Leaf area index (LAI, cm2/cm2)', family='sans-serif', fontsize=14, color='black')
    ax1.set_ylim([0, 10])
    ax1.set_yticklabels([0, 2, 4, 6, 8, 10], family='sans-serif', fontsize=13, color='black')
    ax3 = ax1.twinx()
    DVS = ax3.scatter(daily_subset['day'], daily_subset['DVS'], marker='o', s=50, edgecolor='darkblue', color='royalblue', zorder=1, label='DVS')
    ax3.set_ylabel('Development stage (DVS, -)', family='sans-serif', fontsize=14, color='black')
    ax3.set_ylim([0, 4])
    ax3.set_yticklabels([0, 0.5, 1, 1.5, 2, 2.5, 3, 3.5, 4], family='sans-serif', fontsize=13, color='black')
    ax1.set_facecolor('whitesmoke')
    ax1.legend(loc='upper left', ncol=1, fancybox=True, fontsize=14, framealpha=1)
    ax3.legend(loc='upper right', ncol=1, fancybox=True, fontsize=14, framealpha=1)
    # Crop yield -------------------------------------------------------------------------------------------------------
    ax2.scatter(daily_subset['day'], daily_subset['TAGP']/1000, s=50, edgecolor='darkblue', color='royalblue', zorder=1, label='Total')
    ax2.scatter(daily_subset['day'], daily_subset['TWST']/1000, s=50, edgecolor='orangered', color='orange', zorder=1, label='Stems')
    ax2.scatter(daily_subset['day'], daily_subset['TWLV']/1000, s=50, edgecolor='darkgreen', color='forestgreen', zorder=1, label='Leaves')
    ax2.scatter(daily_subset['day'], daily_subset['TWSO']/1000, s=50, edgecolor='darkred', color='salmon', zorder=1, label='Grains')
    ax2.set_ylabel('Weight of crop organs (t DM/ha)', family='sans-serif', fontsize=14, color='black')
    ax2.set_xlabel('Year of simulation (-)', family='sans-serif', fontsize=14, color='black')
    ax2.set_ylim([0, 25])
    ax2.set_yticklabels([0, 5, 10, 15, 20, 25], family='sans-serif', fontsize=13, color='black')
    ax2.set_facecolor('whitesmoke')
    ax2.legend(loc='upper center', bbox_to_anchor=(0.5, 0.95), ncol=4, fancybox=True, fontsize=14, framealpha=1)
    # ------------------------------------------------------------------------------------------------------------------
    plt.savefig(os.path.join(output_dir, r"./daily_wheat_{site}_improved_TSUM_AMAX2.pdf".format(site=site)), bbox_inches='tight')

# ----------------------------------------------------------------------------------------------------------------------
# PLOT SUMMARY
# ----------------------------------------------------------------------------------------------------------------------

summary = pd.read_csv(os.path.join(input_dir, r'./summary_wheat_egypt.csv'))
summary['DOS'] = pd.to_datetime(summary['DOS'], format='%Y-%m-%d')
summary['DOE'] = pd.to_datetime(summary['DOE'], format='%Y-%m-%d')
summary['DOA'] = pd.to_datetime(summary['DOA'], format='%Y-%m-%d')
summary['DOM'] = pd.to_datetime(summary['DOM'], format='%Y-%m-%d')

for site in sites:
    summary_subset = summary[summary.site == site]
    # ----------------------------------------------------------------------------------------------------------------------
    left, width = .10, .71
    bottom, height = .25, .71
    right = left + width
    top = bottom + height
    wspace = 0.225
    hspace = 0.095
    kws_points = dict(alpha=0.7, linewidth=0.7)
    # ------------------------------------------------------------------------------------------------------------------
    f, (ax1, ax2) = plt.subplots(nrows=1, ncols=2, figsize=(12, 5))
    axes = plt.gca()
    f.subplots_adjust(wspace=wspace, hspace=hspace)
    # Crop development -------------------------------------------------------------------------------------------------
    ax1.plot(summary_subset['year'], summary_subset['DOS'].dt.dayofyear, color='royalblue', zorder=0, label='')
    ax1.plot(summary_subset['year'], summary_subset['DOE'].dt.dayofyear, color='royalblue', zorder=0, label='')
    ax1.plot(summary_subset['year'], summary_subset['DOA'].dt.dayofyear+365, color='orange', zorder=0, label='')
    ax1.plot(summary_subset['year'], summary_subset['DOM'].dt.dayofyear+365, color='forestgreen', zorder=0, label='')
    ax1.scatter(summary_subset['year'], summary_subset['DOS'].dt.dayofyear, marker='o', s=120, edgecolor='darkblue', color='royalblue', zorder=1, label='Sowing')
    ax1.scatter(summary_subset['year'], summary_subset['DOE'].dt.dayofyear, marker='s', s=110, edgecolor='darkblue', color='royalblue', zorder=3, label='Emergence')
    ax1.scatter(summary_subset['year'], summary_subset['DOA'].dt.dayofyear+365, marker='o', s=120, edgecolor='orangered', color='orange', zorder=1, label='Anthesis')
    ax1.scatter(summary_subset['year'], summary_subset['DOM'].dt.dayofyear+365, marker='o', s=120, edgecolor='darkgreen', color='forestgreen', zorder=2, label='Maturity')
    ax1.set_ylabel('Date of crop development stages (DOY)', family='sans-serif', fontsize=14, color='black')
    ax1.set_xlabel('Year of simulation (-)', family='sans-serif', fontsize=14, color='black')
    ax1.set_xlim([2008, 2018])
    ax1.set_xticklabels([2008, 2010, 2012, 2014, 2016, 2018], family='sans-serif', fontsize=13, color='black')
    ax1.set_ylim([300, 600])
    ax1.set_yticklabels([300, 350, 400-365, 450-365, 500-365, 550-365, 600-365], family='sans-serif', fontsize=13, color='black')
    ax1.axhline(366, color='black', zorder=0, label='DOY = 1')
    # ax1.axhline(365+100, color='black', linestyle='--', zorder=0, label='DOY = 100')
    # ax1.axhline(365+150, color='black', linestyle='-.', zorder=0, label='DOY = 150')
    # ax1.axhline(365+200, color='black', linestyle='-.', zorder=0, label='DOY = 150')
    ax1.set_facecolor('whitesmoke')
    ax1.legend(loc='upper right', ncol=2, fancybox=True, shadow=False, fontsize=10, framealpha=1) # bbox_to_anchor=(0.5, 1.1)
    ax1.text(left, top - 0.015, 'A)', bbox=dict(facecolor='whitesmoke', edgecolor='none'), horizontalalignment='right', verticalalignment='top', transform=ax1.transAxes, family='sans-serif', fontsize=16)
    # Crop yield -------------------------------------------------------------------------------------------------------
    ax2.plot(summary_subset['year'], summary_subset['TAGP']/1000, color='royalblue', zorder=0, label='')
    ax2.plot(summary_subset['year'], summary_subset['TWST']/1000, color='orange', zorder=0, label='')
    ax2.plot(summary_subset['year'], summary_subset['TWLV']/1000, color='forestgreen', zorder=0, label='')
    ax2.plot(summary_subset['year'], summary_subset['TWSO']/1000, color='salmon', zorder=0, label='')
    ax2.scatter(summary_subset['year'], summary_subset['TAGP']/1000, s=120, edgecolor='darkblue', color='royalblue', zorder=1, label='Total')
    ax2.scatter(summary_subset['year'], summary_subset['TWST']/1000, s=120, edgecolor='orangered', color='orange', zorder=1, label='Stems')
    ax2.scatter(summary_subset['year'], summary_subset['TWLV']/1000, s=120, edgecolor='darkgreen', color='forestgreen', zorder=1, label='Leaves')
    ax2.scatter(summary_subset['year'], summary_subset['TWSO']/1000, s=120, edgecolor='darkred', color='salmon', zorder=1, label='Grains')
    ax2.set_ylabel('Weight of crop organs (t DM/ha)', family='sans-serif', fontsize=14, color='black')
    ax2.set_xlabel('Year of simulation (-)', family='sans-serif', fontsize=14, color='black')
    ax2.set_xlim([2008, 2018])
    ax2.set_xticklabels([2008, 2010, 2012, 2014, 2016, 2018], family='sans-serif', fontsize=13, color='black')
    ax2.set_ylim([0, 25])
    ax2.set_yticklabels([0, 5, 10, 15, 20, 25], family='sans-serif', fontsize=13, color='black')
    ax2.set_facecolor('whitesmoke')
    ax2.legend(loc='upper right', ncol=2, fancybox=True, fontsize=10, framealpha=1) # bbox_to_anchor=(0.5, 1.1)
    ax2.text(left, top - 0.015, 'B)', bbox=dict(facecolor='whitesmoke', edgecolor='none'), horizontalalignment='right', verticalalignment='top', transform=ax2.transAxes, family='sans-serif', fontsize=16)
    # ------------------------------------------------------------------------------------------------------------------
    plt.savefig(os.path.join(output_dir, r"./summary_wheat_{site}_improved_TSUM_AMAX2.pdf".format(site=site)), bbox_inches='tight')

# ----------------------------------------------------------------------------------------------------------------------
# THE END
# ----------------------------------------------------------------------------------------------------------------------
