"""
Support functionality relating to the instance configuration.
"""

__author__ = "Daniel da Silva <daniel.dasilva@nasa.gov>"

import commands


class ConfigEnvironment:
    """An abstracted configuration environment.

    Provides access to the Giovanni configuration (giovanni.cfg) through
    Python. Abstracted so it can be mocked for testing.
    """

    def get(self, target):
        """Get a variable from giovanni.cfg using a Perl expression."""
        return commands.getoutput("giovanni_config.pl '%s'" % target)

    def getShapeFileUserDir(self):
        """Get the base directory for storing user shapefiles."""
        return self.get("$GIOVANNI::SHAPEFILES{user_dir}")
        
    def getShapeFileProvisionedDir(self):
        return self.get("$GIOVANNI::SHAPEFILES{provisioned_dir}")

    def getGeoJSONProvisionedDir(self):
        return self.get("$GIOVANNI::SHAPEFILES{geojson_dir}")

    def getAATSDownSamplingFactor(self):
        """Get the Area Averaged Time Series shapefile down sampling factor."""
        return float(self.get('$GIOVANNI::SHAPEFILES{down_sampling}{area_avg_time_series}'))

    def getTAMDownSamplingFactor(self):
        """Get the Time Averaged Map shapefile down sampling factor."""
        return float(self.get('$GIOVANNI::SHAPEFILES{down_sampling}{time_avg_map}'))
        
