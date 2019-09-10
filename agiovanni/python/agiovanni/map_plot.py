"""
Visualizes a map. Either pixelates the image (plot) or draws filled contours
(contour).

Created on Aug 12, 2015

@author: Christine Smit
"""
import os
import stat
import subprocess
import tempfile
from timeit import itertools
import shutil

from lxml import etree
import matplotlib

matplotlib.use('Agg')  # needed to use matplotlib in a cgi (no display)
import matplotlib.pylab as plt
import matplotlib.colors as colors
import numpy as np
import numpy.ma as ma
from netCDF4 import Dataset
import cv2

import agiovanni.lon as lon


class VisualizationError(Exception):
    pass


class Visualize(object):
    """
    Visualizes a netcdf file to a png.
    """

    def __init__(self, data_file, sld=None, width=None, height=None,
                 variable_name=None, north=90, south=-90, east=180, west=-180,
                 inflation_factor=None, extend_for_map_server=False):
        """
        Constructor. Takes the file to visualize as input. Optionally takes
        an sld file for the colors, a width in pixels, and a height in pixels.
        """
        nc = Dataset(data_file, 'r')
        lons = nc.variables['lon'][:]
        lats = nc.variables['lat'][:]

        # figure out which indexes we want
        lons_in_bbox = np.logical_and(lons >= west, lons <= east)
        self.lons = lons[lons_in_bbox]
        lats_in_bbox = np.logical_and(lats >= south, lats <= north)
        self.lats = lats[lats_in_bbox]

        if variable_name is None:
            self.data = None
            for vn in nc.variables:
                if 'quantity_type' in nc.variables[vn].ncattrs():
                    variable_name = vn

            if variable_name is None:
                raise VisualizationError(
                    "Unable to find data variable in datafile %s" % data_file)

        num_dim = len(nc.variables[variable_name].shape)
        if num_dim == 2:
            self.data = nc.variables[variable_name][lats_in_bbox, lons_in_bbox]
        elif num_dim == 3:
            # there should only be one value for the time dimension
            self.data = nc.variables[variable_name][
                0, lats_in_bbox, lons_in_bbox]
        else:
            msg = "Unexpected number of dimensions for data variable in %s" % data_file
            raise VisualizationError(msg)

        # Get out the variable resolution from the metadata, if it is there.
        # This is for point source plots.
        if 'latitude_resolution' in nc.variables[variable_name].ncattrs():
            self.latitude_resolution = float(
                nc.variables[variable_name].latitude_resolution)
        else:
            self.latitude_resolution = None
        if 'longitude_resolution' in nc.variables[variable_name].ncattrs():
            self.longitude_resolution = float(
                nc.variables[variable_name].longitude_resolution)
        else:
            self.longitude_resolution = None

        nc.close()

        # make sure this is a masked array
        self.data = np.ma.masked_array(self.data)

        # if we are visualizing for map server, we need to make sure the image
        # has data for [-180,180). [-180.5, 179.5] won't hack it!
        if extend_for_map_server:
            (self.lons, self.data) = lon.extend_for_map_server(
                self.lons, self.data, self.data.fill_value)

        if sld is not None:
            (self.cmap,
             self.norm,
             self.thresholds,
             self.fallback_color,
             self.hex_colors) = sld_to_colormap(sld)
        else:
            self.cmap = None
            self.norm = None

        self._calculate_size(height, width, inflation_factor)

    def _calculate_size(self, height, width, inflation_factor):
        """
        Calculates the height and width of the final image based on the inputs
        """
        if height is not None:
            self.height = height
            if width is not None:
                self.width = width
            else:
                # if we have height and not width, make width proportional
                self.width = height * \
                    float(len(self.lons)) / float(len(self.lats))

        elif width is not None:
            self.width = width
            # if we have width and not height, make things proportional
            self.height = width * \
                float((len(self.lats))) / float(len(self.lons))
        elif inflation_factor is not None:
            # we have an inflation factor
            self.inflation_factor = inflation_factor
            self.width = len(self.lons) * inflation_factor
            self.height = len(self.lats) * inflation_factor
        else:
            # This 'oversample' logic is from Giovanni::Visualizer::GrADSMap. I have
            # no idea how this formula was arrived at.
            longer = len(self.lons) if len(self.lons) > len(
                self.lats) else len(self.lats)
            oversample = int(1024 / longer)
            oversample = 1 if oversample == 0 else oversample

            self.inflation_factor = oversample
            self.width = len(self.lons) * oversample
            self.height = len(self.lats) * oversample

        # Calculate from the resulting height and width what the effective
        # inflation factor is per data point in the x and y directions. If
        # either the height or the width were set externally, the inflation may
        # not be an integer.
        self.x_inflation = self.width / float(len(self.lons))
        self.y_inflation = self.height / float(len(self.lats))

        # see if the image size is the same as the number of pixels
        if (self.width == len(self.lons) and self.height == len(self.lats)):
            self.isScaled = False
        else:
            self.isScaled = True

    def contour(self, output_file):
        """
        Plot data to filled contour in output_file.
        """

        fig = plt.figure(frameon=False)
        fig.set_size_inches(self.width, self.height)

        ax = plt.Axes(fig, [0., 0., 1., 1.])
        ax.set_axis_off()
        fig.add_axes(ax)

        extent = (0, 1, 0, 1)

        # draw the regular map underneath to fill in the pixels at the edges
        if self.cmap is None:
            ax.contourf(self.data)
        else:
            # create a masked array where everything is masked
            mask = np.empty(self.data.shape, bool)
            mask.fill(True)
            allFill = np.ma.MaskedArray(data=np.zeros(self.data.shape),
                                        mask=mask)

            # plot this first, under the real data, so we get the fill value
            # color
            ax.imshow(allFill,
                      cmap=self.cmap,
                      norm=self.norm,
                      aspect='auto',
                      origin='lower',
                      extent=extent)

            # set the levels to the thresholds. Add in -infinite at the bottom
            # and +infinite at the top so we get the gutters
            levels = list(
                itertools.chain.from_iterable([[float('-inf')],
                                               self.thresholds,
                                               [float('inf')]]))

            ax.contourf(
                self.data,
                cmap=self.cmap,
                norm=self.norm,
                levels=levels,
                aspect='auto',
                origin='lower',
                extent=extent
            )

        fig.savefig(output_file, dpi=1, transparent=True)

        self._convert_to_colormapped_png(output_file)

    def plot(self, output_file):
        """
        Plot data to output_file.
        """

        # Define a function that converts a hex color like '#01ff05' in
        # '#RRGGBB' format to a list in (b,g,r,alpha) format. I realize it
        # looks a little weird to convert a string to int since this is really
        # an unsigned byte, but there is no equivalent 'ubyte' function in
        # python.
        hex_to_bgra = lambda hex_, alpha: (int(hex_[5:], 16),
                                           int(hex_[3:5], 16),
                                           int(hex_[1:3], 16),
                                           alpha)

        # convert the colors in the colorbar
        bgra_colors = [hex_to_bgra(color, 255) for color in self.hex_colors]
        # convert the fallback color to a color that is 100% transparent
        bgra_fallback = hex_to_bgra(self.fallback_color, 0)

        # Data is (lat,lon). We want (lat,lon,color).
        num_lat = len(self.lats)
        num_lon = len(self.lons)
        imdata = np.empty((num_lat, num_lon, 4), dtype=np.ubyte)

        # We also need to flip the data because the image is 'upside-down'
        # relative to the data. The last latitude row needs to be the first
        # image row
        data = self.data[np.arange(num_lat - 1, -1, - 1), :]

        # the first color is for data less than the first threshold
        imdata[data < self.thresholds[0], :] = bgra_colors[0]

        # set colors for data in the middle of the colorbar
        for i in range(len(self.thresholds) - 1):
            imdata[
                np.logical_and(
                    data >= self.thresholds[i],
                    data < self.thresholds[
                        i + 1]),
                :] = bgra_colors[
                i + 1]

        # set colors for data above the top threshold
        imdata[data >= self.thresholds[-1]] = bgra_colors[-1]

        # set the masked data to fallback color
        imdata[ma.getmaskarray(data), :] = bgra_fallback

        # create a temporary file for the png
        (fd, intermediate) = tempfile.mkstemp(suffix=".png", prefix="map",
                                              dir=tempfile.gettempdir())
        os.close(fd)
        os.chmod(
            intermediate,
            stat.S_IWUSR | stat.S_IRUSR | stat.S_IRGRP)

        # write the png with one pixel per data point
        cv2.imwrite(intermediate, imdata)

        # resize if necessary
        self._make_final_size(intermediate, output_file)

        # make sure this is colormapped
        self._convert_to_colormapped_png(output_file)

    @staticmethod
    def _convert_to_colormapped_png(current_png):
        """
        For some reason, cv2.imwrite sometimes creates a palette/colormapped
        png and sometimes it creates a file that specifies r,g,b,a for each
        pixel separately. I have no idea why! Unfortunately, the map server
        does not like rgba png files. It only likes colormapped files. This
        function makes sure the output png is definitely colormapped!
        :param current_png: the location of the png to convert
        """

        # The convert command seems to do the trick. Specifying the output type
        # as png8 seems to do the conversion.
        cmd = ["convert", current_png, "png8:%s" % current_png]
        subprocess.check_call(cmd)

    def _make_final_size(self, intermediate_file, output_file):
        """
        Scale the image to the right size using imagemagick's convert tool.
        """
        if (self.isScaled):
            # Use imagemagick's convert to make this image the right size. NOTE:
            # When I tried creating a figure of the correct size and using
            # 'nearest' interpolation, the image was incorrect.
            cmd = ["convert", "-sample", "%dx%d!" % (self.width, self.height),
                   intermediate_file, output_file]
            subprocess.check_call(cmd)
            os.remove(intermediate_file)
        else:
            # Just move the file over. No need to run convert because the image
            # is already the correct size.
            shutil.move(intermediate_file, output_file)

    def plot_imshow(self, output_file):
        """
        Plot data to output_file using imshow. Note: This can produce a file
        with extra colors due to a bug in imshow.
        """

        # Create an image that has one data point per pixel.
        fig = plt.figure(frameon=False)
        fig.set_size_inches(len(self.lons), len(self.lats))

        ax = plt.Axes(fig, [0., 0., 1., 1.])
        ax.set_axis_off()
        fig.add_axes(ax)

        extent = (0, 1, 0, 1)

        if self.cmap is None:
            ax.imshow(self.data,
                      interpolation='none',
                      aspect='auto',
                      origin='lower',
                      extent=extent,
                      )
        else:
            ax.imshow(self.data,
                      interpolation='none',
                      cmap=self.cmap,
                      norm=self.norm,
                      aspect='auto',
                      origin='lower',
                      extent=extent,
                      )

        (fd, intermediate) = tempfile.mkstemp(suffix=".png", prefix="map",
                                              dir=tempfile.gettempdir())
        os.close(fd)
        os.chmod(
            intermediate,
            stat.S_IWUSR | stat.S_IRUSR | stat.S_IRGRP)
        fig.savefig(intermediate, dpi=1, transparent=True)

        if (self.isScaled):

            # Use imagemagick's convert to make this image the right size. NOTE:
            # When I tried creating a figure of the correct size and using
            # 'nearest' interpolation, the image was incorrect.
            cmd = ["convert", "-sample", "%dx%d!" % (self.width, self.height),
                   intermediate, output_file]
            subprocess.check_call(cmd)
            os.remove(intermediate)
        else:
            # Just move the file over. No need to run convert because the image
            # is already the correct size.
            shutil.move(intermediate, output_file)

    def create_world_file(self, world_file):
        """
        Write the world file for the map server.
        """

        # Figure out where the data is.
        # Note: calculating this from the longitude and latitude variables is
        # more accurate than getting it from a data attribute, which is a
        # string.
        if len(self.lons) > 1:
            x_delta = np.double(
                self.lons[-1] - self.lons[0]) / (len(self.lons) - 1)
        elif self.longitude_resolution is not None:
            x_delta = self.longitude_resolution
        else:
            raise VisualizationError(
                "Unable to determine longitude resolution from data file.")

        if len(self.lats) > 1:
            y_delta = np.double(
                self.lats[-1] - self.lats[0]) / (len(self.lats) - 1)
        elif self.latitude_resolution is not None:
            y_delta = self.latitude_resolution
        else:
            raise VisualizationError(
                "Unable to determine latitude resolution from data file.")

        west_edge = self.lons[0] - x_delta / 2.0
        north_edge = self.lats[-1] + y_delta / 2.0

        # figure out how big each pixel is
        x_pixel_width = x_delta / self.x_inflation
        y_pixel_width = -y_delta / self.y_inflation

        # calculate the center of the west-most and north-most pixels
        west = west_edge + x_pixel_width / 2
        north = north_edge + y_pixel_width / 2

        # Write the world file. Format:
        #
        #   x pixel width in degrees
        #   0
        #   0
        #   y pixel width in degrees (negative)
        #   center of west-most pixel in degrees
        #   center or north-most pixel in degrees
        handle = open(world_file, 'w')
        handle.write("%f\n0\n0\n%f\n" % (x_pixel_width, y_pixel_width))
        handle.write("%f\n%f\n" % (west, north))
        handle.close()


def sld_to_colormap(sld_file):
    """
    Reads an SLD file to get out the colors, thresholds, and fallback color.
    Returns a tuple with:
    cmap - a ListedColormap object with colors and fallback set
    norm - a BoundaryNorm object with the thresholds
    fallback_color - the fall back color in hex (a.k.a. the 'bad' color)
    thresholds - a list of threshold values
    hex_colors - a list of the colormap colors in hex
    """
    xml = etree.parse(sld_file)
    namespaces = {"se": "http://www.opengis.net/se"}

    nodes = xml.xpath("//se:Threshold", namespaces=namespaces)
    thresholds = [node.text for node in nodes]
    nodes = xml.xpath("//se:Value", namespaces=namespaces)
    hex_colors = [node.text for node in nodes]

    if len(hex_colors) != (len(thresholds) + 1):
        raise VisualizationError(
            "Expected to get one more threshold than color value")

    # remove any empty thresholds. This is a work around for FEDGIOVANNI-1333.
    thresholds = [t for t in thresholds if t]
    while len(hex_colors) != (len(thresholds) + 1) and len(hex_colors) > 0:
        hex_colors.pop()

    # convert to float values
    thresholds = [float(t) for t in thresholds]

    if len(hex_colors) == 0:
        raise VisualizationError("Unable to find any thresholds in sld")
    cmap = colors.ListedColormap(hex_colors[1:-1])
    cmap.set_under(hex_colors[0])
    cmap.set_over(hex_colors[-1])

    fallback_color = None
    nodes = xml.xpath("//se:Categorize", namespaces=namespaces)
    if len(nodes) > 0:
        fallback_color = nodes[0].get("fallbackValue")
        cmap.set_bad(fallback_color, alpha=0)

    norm = colors.BoundaryNorm(thresholds, cmap.N)

    return (cmap, norm, thresholds, fallback_color, hex_colors)
