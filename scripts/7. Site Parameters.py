# ----------------------------------------------------------------------------------------------------------------------
# ----------------------------------------------------------------------------------------------------------------------
# Import general packages

import os

# ----------------------------------------------------------------------------------------------------------------------
# Specify directory

output_dir = r'C:\# Jvasco\Working Papers\# Global Yield Gap Analysis\GYGA_Egypt_Wheat\data\wofost-inputs'

# ----------------------------------------------------------------------------------------------------------------------
# Site template

Site = """##
## Site characteristics file for Running WOFOST N/P/K
## Derived from management data file for use with LINTUL model (May 2011)
##


# Site parameters

SMLIM  = 0.3  	       # Limiting amount of volumetric moisture in upper soil layer [-]
IFUNRN = 0.0 	       # Rain infiltration as function of storm size [0/1]
SSMAX  = 0.0  	       # Maximum surface storage [cm]
SSI    = 0.0           # Initial surface storage [cm]
WAV    = 100.0         # Initial amount of soil water [cm]
NOTINF = 0.0 	       # Not infiltrating fraction of rainfall [0..1]
CO2    = 360           # Atmospheric CO2 concentration

# Atmospheric and soil N mineralization

BG_N_SUPPLY  = 0.091   # Atmospheric N deposition [kg N/ha/day]
NSOILBASE    = 38.8    # Total mineral soil N available at start of growth period [kg N/ha]
NSOILBASE_FR = 0.025   # Fraction of soil mineral coming available per day [day-1]


# Atmospheric and soil P mineralization

BG_P_SUPPLY  = 0.091   # Atmospheric P deposition [kg P/ha/day]
PSOILBASE    = 100.0   # Total mineral soil N available at start of growth period [kg P/ha]
PSOILBASE_FR = 0.025   # Fraction of soil mineral coming available per day [day-1]


# Atmospheric and soil K mineralization

BG_K_SUPPLY  = 0.091   # Atmospheric K deposition [kg P/ha/day]
KSOILBASE    = 100.0   # Total mineral soil K available at start of growth period [kg K/ha]
KSOILBASE_FR = 0.025   # Fraction of soil mineral coming available per day [day-1]
"""

# ----------------------------------------------------------------------------------------------------------------------
# Save data

output = os.path.join(output_dir, "WOFOST_Site_Egypt.txt")
with open(output, "w") as fp:
    fp.write(Site)

# ----------------------------------------------------------------------------------------------------------------------
# ----------------------------------------------------------------------------------------------------------------------
