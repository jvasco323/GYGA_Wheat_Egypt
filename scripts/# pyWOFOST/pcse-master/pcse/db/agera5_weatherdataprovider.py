import os
import logging
import requests
import yaml

from ..base import WeatherDataContainer, WeatherDataProvider
from ..util import reference_ET
from ..exceptions import PCSEError


mm_to_cm = lambda x: x/10.
kJ_to_J = lambda x: x*1000.

class AgERA5WeatherDataProvider(WeatherDataProvider):
    variable_renaming = [("temperature_max", "TMAX", None),
                         ("temperature_min", "TMIN", None),
                         ("temperature_avg",  "TEMP", None),
                         ("vapourpressure", "VAP", None),
                         ("windspeed", "WIND", None),
                         ("precipitation", "RAIN",mm_to_cm),
                         ("radiation", "IRRAD",kJ_to_J),
                         ("snowdepth", "SNOWDEPTH", None),
                         ("day", "DAY", None)]
    angstA = 0.25
    angstB = 0.45
    ETmodel = "PM"

    def __init__(self, **inputs):
        WeatherDataProvider.__init__(self)
        url = f'http://wofost-dp.apps.ocp.wurnet.nl:80/api/v1/get_weatherdata'
        r = requests.get(url, params=inputs)
        r_data = yaml.safe_load(r.text.replace('"', ''))
        self.elevation = r_data["data"]["location_info"]["grid_elevation"]
        self.longitude = inputs["longitude"]
        self.latitude = inputs["latitude"]
        for daily_weather in r_data["data"]["weather_variables"]:
            self._make_WeatherDataContainer(daily_weather)

    def _make_WeatherDataContainer(self, daily_weather):

        thisdate = daily_weather["day"]
        t = {"LAT": self.latitude, "LON": self.longitude, "ELEV": self.elevation}
        for old_name, new_name, conversion in self.variable_renaming:
            if conversion is not None:
                t[new_name] = conversion(daily_weather[old_name])
            else:
                t[new_name] = daily_weather[old_name]

        # Reference evapotranspiration in mm/day
        try:
            E0, ES0, ET0 = reference_ET(t["DAY"] , t["LAT"], t["ELEV"], t["TMIN"], t["TMAX"], t["IRRAD"],
                                        t["VAP"], t["WIND"], self.angstA, self.angstB, self.ETmodel)
        except ValueError as e:
            msg = (("Failed to calculate reference ET values on %s. " % thisdate) +
                   ("With input values:\n %s.\n" % str(t)) +
                   ("Due to error: %s" % e))
            raise PCSEError(msg)

        # update record with ET values value convert to cm/day
        t.update({"E0": E0 / 10., "ES0": ES0 / 10., "ET0": ET0 / 10.})

        # Build weather data container from dict 't'
        wdc = WeatherDataContainer(**t)

        # add wdc to dictionary for thisdate
        self._store_WeatherDataContainer(wdc, thisdate)
