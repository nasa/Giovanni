#! /usr/bin/env python
"""
####################################################################
NAME
curtainPlot.py - Curtain Plot using Matplotlib

DESCRIPTION
Generates a curtain plot from the output of g4_curtain_lat.pl,
g4_curtain_lon.pl, and  g4_curtain_time.pl

SYNOPSIS
Usage: curtainPlot.py [options]

OPTIONS
  -h, --help       show this help message and exit
  -i INPUT_FILE    Input NetCDF file
  -o OUTPUT_FILE   Output file 
  -f OPTIONS_FILE  Plot options in a text file
  -v VARIABLE      Variable name in input dataset

DEPENDENCY
netCDF4, matplotlib

AUTHORS
Maksym Petrenko, 06/15/2015, Initial version
partially based on histogramPlot.py by Daniel da Silva

VERSION
$Revision: 1.11 $
####################################################################
"""
__author__ = 'Maksym Petrenko <maksym.petrenko@nasa.gov>'

import decimal
import math
import optparse
import os
import sys
import textwrap
import matplotlib.ticker as plticker
from scipy import interpolate
from matplotlib.colors import LinearSegmentedColormap
from matplotlib.patches import Rectangle
from matplotlib.ticker import FixedLocator
import simplejson as json
import ssl

import matplotlib as mpl
mpl.use('Agg')           # Force matplotlib to not use any Xwindows backend.
                         # Must be called before pyplot.

import matplotlib.pyplot as plt
import netCDF4 as nc
import numpy as np
import pylab
import matplotlib.colors as colors
import string

from lxml import etree
import urllib2

FONT = 'sans-serif'     # Font Family
FONT_SIZE = 10           # Font size
RENDER_SIZE = (12, 4)  # Inches
RENDER_DPI  = 100       # Dots per Inch
SCI_NOT_OFFSET = -.15   # Offset for scientific notation legend on Y axis
Y_AXIS_LOG_BASE = 2
Y_AXIS_TICK_SCALE = 20
LEVEL_BEGIN = 50
LEVEL_END = 1000

def parse_plot_options(cli_opts):
    """
    User-defined settings, passed to the script using -f option
    """
    options = {}
    if cli_opts.f:
        try:
            with open(cli_opts.f, 'rU') as f:
                content = '\n'.join(f.readlines())
            options = json.loads(content)
        except Exception:
            sys.stderr.write("Error: could not load plot options file")
    return options


def parse_cli_args(args):
    """Parses command line arguments.
    
    Returns
      options, an object whose attributes match the values of the
      specified in the command line. e.g. '-e xyz' <=> options.e
    Raises
      OptionError, error parsing options
      ValueError, invalid or missing argument
    """
    parser = optparse.OptionParser()

    parser.add_option("-i", metavar="INPUT_FILE", dest="i",
                      help="Input NetCDF file")
    parser.add_option("-o", metavar="OUTPUT_FILE", dest="o",
                      help="Output File")
    parser.add_option("-f", metavar="OPTIONS_FILE", dest="f",
                      help="Plot options in a text file")
    parser.add_option("-v", metavar="VARIABLE", dest="v",
                      help="Variable name in input dataset")
    parser.add_option("-t", metavar="TITLE", dest="t",action="store_true",
                      help="Use this program to draw title and subtitle")
    
    options, _ = parser.parse_args(args)
    
    # Verify required are present and not empty
    for required_opt in "iov":
        if not getattr(options, required_opt, None):
            raise ValueError("-%s missing" % required_opt)
        
    return options
    
def forceAspect(ax,aspect = 1):
    im = ax.get_images()
    extent = im[0].get_extent()
    ax.set_aspect(abs((extent[1]-extent[0])/(extent[3]-extent[2]))/aspect)
    
def truncate_colormap(cmap, minval = 0.0, maxval = 1.0, n = 100):
    new_cmap = colors.LinearSegmentedColormap.from_list(
        'trunc({n},{a:.2f},{b:.2f})'.format(n = cmap.name, a = minval, b = maxval),
        cmap(np.linspace(minval, maxval, n)))
    return new_cmap

def get_gray_colorbar():
    cdict = {'red': ((0, 0.75, 0.75),
                     (1, 0.75, 0.75)),
           'green': ((0, 0.75, 0.75),
                     (1, 0.75, 0.75)),
            'blue': ((0, 0.75, 0.75),
                     (1, 0.75, 0.75))}
    graycmap = LinearSegmentedColormap('custom_cmap', cdict)
    return graycmap

def get_keyless_ssl_opener():
    # Workaround for bad certificates. Credit: http://stackoverflow.com/questions/19268548/python-ignore-certicate-validation-urllib2
    ctx = ssl.create_default_context()
    ctx.check_hostname = False
    ctx.verify_mode = ssl.CERT_NONE
    return urllib2.build_opener(urllib2.HTTPSHandler(context=ctx), urllib2.HTTPHandler)

def get_sld(input_dir, sld_url):
    # Try to read SLD directly from the supplied URL. If that fails -
    # see if we have it in the same directory as input file
    try:
        opener = get_keyless_ssl_opener()
        request = urllib2.Request(sld_url)
        connection = opener.open(request)
        return connection
    except:
        pass
    sld_file_name = os.path.join(input_dir, os.path.basename(sld_url).split('?')[0])
    if os.path.exists(sld_file_name): return sld_file_name
    raise VisualizationError("Failed to read SLD")

def sld_to_colormap(sld_file):
    '''
    Reads an SLD file to get out the colors, thresholds, and fallback color.
    Returns a tuple with:
    cmap - a ListedColormap object with colors and fallback set
    norm - a BoundaryNorm object with the thresholds
    fallback_color - the fall back color in hex (a.k.a. the 'bad' color)
    thresholds - a list of threshold values
    hex_colors - a list of the colormap colors in hex
    '''
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

# Returns data converted according to provided scale
def rescale_data(data, scale = 'linear'):
    if scale == 'log':
        return math.log(data, Y_AXIS_LOG_BASE)
    return data

def get_exp(num):
    if not isinstance(num, basestring): num = '%g' % num
    if 'e-' in num:
        num_exp = 10**(int(num[num.index('e-')+1:])-1)
    elif 'e+' not in num:
        fraction_len = 0 if '.' not in num else len(num[num.index('.')+1:])
        num_exp = 10**(-1*(fraction_len+3))
    else:
        num_exp = 0.0000000001
    return num_exp

def write_curtain_plot(cli_opts, plot_opts, output_stream):
    """Writes a histogram plot from a histogram dataset."""

    dataset = nc.Dataset(cli_opts.i)
    variable = dataset.variables[cli_opts.v]
    fill_value = variable._FillValue
    dims = variable.dimensions
    # We expect the variable to have exactly two dimensions. 
    # One of them should be either lat, lon, or time. Another can be anything, 
    # but most likely it is going to be Height.
    valid_x_dims = ['lat','lon','time']
    
    if dims[1].lower() in valid_x_dims:
        dimY_is_first_dimension = True
        dimY_name = dims[0]
        dimX_name = dims[1]
    elif dims[0].lower() in valid_x_dims:
        dimY_is_first_dimension = False
        dimY_name = dims[1]
        dimX_name = dims[0]
    else:
        sys.stderr.write('Curtain plot script does not know how to work with the dimensions in the supplied .nc file.')
        exit(-1)
         
    dimY = dataset.variables[dimY_name]
    dimX = dataset.variables[dimX_name]
    
    levels = dimY[:]
    data = variable[:]
    x_var = dimX[:]

    data_min_complete = np.nanmin(data)
    data_max_complete = np.nanmax(data)

    # We use time_bnds if we are dealing with time dimension
    if dimX_name.lower() == 'time':
        time_bands=dataset.variables['time_bnds'][:]
        x_var = time_bands[:,0] # use a numpy array

    if not dimY_is_first_dimension: data = np.transpose(data)
    
    # By FEDGIANNI-2183, we should be able to render curtain plot even for a single time step.
    # Let's clone single-point data into 3 points, and adjust the time of the first
    # and last point by 1 (axis label would not be centered if created only 2 points)
    # Under these conditions, we expect time array to be of shape (1), time_bands
    # of shape (1, 2) and data of shape (N, 1), where N is the number of levels
    if dimX_name.lower() == 'time' and len(x_var) == 1:
        data = np.repeat(data, 3, axis = 1)
        x_var = np.repeat(x_var, 3)
        time_bands = np.repeat(time_bands, 3, axis = 0)
        x_var[0] -= 1
        x_var[2] += 1
        time_bands[0][0] -=1
        time_bands[0][1] -=1
        time_bands[2][0] +=1
        time_bands[2][1] +=1
        
    LEVEL_BEGIN = np.min(levels)
    LEVEL_END = np.max(levels)
    dimY_options = None
    if 'Y Axis' in plot_opts and 'Range' in plot_opts['Y Axis']:
        dimY_options = plot_opts['Y Axis']['Range']
        if 'Min' in dimY_options: LEVEL_BEGIN = float(dimY_options['Min'])
        if 'Max' in dimY_options: LEVEL_END   = float(dimY_options['Max'])
    idx_begin, LEVEL_BEGIN = min(enumerate(levels), key=lambda x: abs(x[1]-LEVEL_BEGIN)) 
    idx_end, LEVEL_END  = min(enumerate(levels), key=lambda x: abs(x[1]-LEVEL_END)) 
    upsidedown = False
    if levels[0]>levels[-1]:
        cut_begin = idx_end
        cut_end = idx_begin+1
        upsidedown = True
    else:
        cut_begin = idx_begin
        cut_end = idx_end+1
    levels = levels[cut_begin:cut_end]
    data = data[cut_begin:cut_end,:]
    data_min = np.nanmin(data)
    data_max = np.nanmax(data)
    
    mask = np.ma.masked_equal(data,fill_value).mask
    #np.copyto(data,np.NaN,where = mask) #supported since 2.7
    #data = np.ma.masked_equal(data,fill_value)
    #mask = data.mask
    
    # Process palette SLD
    cmap_extend = "neither"
    cmap = truncate_colormap(plt.cm.jet, 0.0, 0.90)
    norm = None
    thresholds = None
    data_min_o = None
    data_max_o = None
    if 'Palette' in plot_opts:
        sld = plot_opts['Palette']['sld']
        if sld.startswith('http'): sld = get_sld(os.path.abspath(cli_opts.i), sld)
        (cmap, norm, thresholds, fallback_color, hex_colors) = sld_to_colormap(sld)
        # Override data min/max with nominal min/max from SLD (if sld specified)
        # For this, let's just pretend these min/max came from user options
        data_min_o = thresholds[0]
        data_max_o = thresholds[-1]
        data_options = {}
        data_options['Min'] = thresholds[0]
        data_options['Max'] = thresholds[-1]
        data_options['min'] = "%g" % data_min_o
        data_options['max'] = "%g" % data_max_o
    
    # Process data min / max options
    user_min_max_available = False
    if 'Data' in plot_opts and 'Range' in plot_opts['Data']:
        data_options = plot_opts['Data']['Range']
        if 'Min' in data_options and data_options['Min'] != None:
            data_options['min'] = str(data_options['Min'])
            data_min_o = float(data_options['min'])
        if 'Max' in data_options and data_options['Max'] != None: 
            data_options['max'] = str(data_options['Max'])
            data_max_o = float(data_options['max'])       
            
    try:
        # Set min/max only if the provided min/max is not the same as the original data min/max.
        # - Original data min/max is passed through '%g' to imitate loss of precision during 
        #    serialization to plot options file
        # - A small 'salt' is computed and added to max / substracted from min to deal with loss
        #    of precision from GUI to the backend code
        if data_min_o != None:
            min_exp = min(get_exp(data_options['min']), get_exp(data_min_complete))
            
            if abs(float('%g' % data_min_complete) - float('%g' % data_min_o)) > min_exp:
                data_min_o = data_min_o-min_exp
                user_min_max_available = True
                if data_min_o > data_min: cmap_extend = "min"
            else:
                data_min_o = None
        if data_max_o != None:
            max_exp = min(get_exp(data_options['max']), get_exp(data_max_complete))
            
            if abs(float('%g' % data_max_complete) - float('%g' % data_max_o)) > max_exp:
                data_max_o = data_max_o+max_exp
                user_min_max_available = True
                if data_max_o < data_max: cmap_extend = "both" if cmap_extend == "min" else "max"
            else:
                data_max_o = None
    except:
        data_min_o = None
        data_max_o = None
        cmap_extend = "neither"
    
    if data_min_o != None: data_min = data_min_o
    if data_max_o != None: data_max = data_max_o
    
    # Normalized SLD thresholds to the current min/max so that we can have color bar ticks in right places
    if thresholds != None and data_max != None and data_min != None:
        thresholds = np.array(thresholds)
        thresholds = (thresholds-min(thresholds))/(max(thresholds)-min(thresholds))
        thresholds = thresholds * (data_max - data_min) + data_min
    
    # Choose Y-Axis scale (linear for layers/channels, log-scale for everything else)
    vertical_scale = 'log'
    if dimY.units != None and 'layer' in dimY.units.lower() or 'channel' in dimY.units.lower(): vertical_scale = 'linear'
    if 'Y Axis' in plot_opts and 'Display at log10 scale' in plot_opts['Y Axis']:
        vertical_scale = 'log' if plot_opts['Y Axis']['Display at log10 scale'] else 'linear'
    
    ylabel = "Out of range"
    data = np.ma.array(data, mask = mask)
    data_count = data.count()
    if len(levels) < 2:
        # Check whether we have enough data to make a plot
        fig = plt.figure()
        plt.axis([0, 10, 0, 10])
        t = "Need at least two vertical slices to create a plot. " \
            "Please adjust minimum and maximum values for the Y Axis" \
            " or reset to the default Y Axis range and try again."
        if (cli_opts.t):
            plt.title('\n'.join(textwrap.wrap(t, 60)), fontsize=18, ha='center', va='top')
        plt.axis('off') 
    else:
        data = data.filled(np.NaN)
     
        # Interpolate data to log-scale
        #http://stackoverflow.com/questions/5146025/python-scipy-2d-interpolation-non-uniform-data
    
        if upsidedown:
            #Older versions of interp1d can't work with reverse-ordered data, so let's flip everything upside down
            data = np.flipud(data)
            levels = levels[::-1]
        
        if vertical_scale == 'log':
            levels_new = np.logspace(start = rescale_data(levels[0], vertical_scale), stop = rescale_data(levels[-1], vertical_scale), num = levels.shape[0]*4,base = Y_AXIS_LOG_BASE)
            res = interpolate.interp1d(levels, data,axis = 0,bounds_error = False)(levels_new)
            res[0,:]=data[0,:]
            res[-1,:]=data[-1,:]
            data = res
        #    if 1==2:
        #        y, x = np.meshgrid(dimX[:],levels)
        #        ynew, xnew = np.meshgrid(dimX[:],levels_new)
        #        GD = interpolate.griddata((x.ravel(),y.ravel()), data.ravel(),(xnew.ravel(),ynew.ravel()), method='linear',fill_value = 0)
        #        data = GD.reshape(levels_new.shape[0], x_var.shape[0])
        #    else:
        
        if upsidedown:
            #Flip the data back to it's original state
            data = np.flipud(data)
            levels = levels[::-1]
            #data = res   
        mask = np.isnan(data)
        if upsidedown:
            mask = np.flipud(mask)
        # Flip data vertically if the 'down' attribute is set on the vertical dimension variable
        if hasattr(dimY, 'positive') and dimY.positive.lower() == 'down' and not upsidedown:
            mask = np.flipud(mask)
            data = np.flipud(data)
            levels = levels[::-1]    
        fig = plt.figure( dpi = RENDER_DPI,figsize = RENDER_SIZE)
    
        interp = 'bilinear'
        if dimX_name.lower() == 'time':
            plot_extent=[time_bands[0][0],time_bands[-1][-1], levels[0], levels[-1]]
        else:
            plot_extent=[x_var[0],x_var[-1], levels[0], levels[-1]]
    
        im = plt.imshow(data,
                        cmap = cmap,
                        origin='lower',
                        extent=plot_extent,
                        interpolation = interp,
                        vmin = data_min if user_min_max_available else None,
                        vmax = data_max if user_min_max_available else None)    #, interpolation = interp
     
        bad_data = np.ma.masked_where(~mask, mask)
        plt.imshow(bad_data,
                   extent=plot_extent,
                   interpolation='none',
                   cmap = get_gray_colorbar()
                  )
    
        #Tune up Y-axis ticks  ------------------------------------------------------------
        ax = plt.gca()
    
        ax.set_yscale(vertical_scale, nonposy='clip',basey = Y_AXIS_LOG_BASE)
        def nfmt(x, pos):
            if x>=1: return '%d' % (x)
            return '%.2f' % (x)
        
        fmt = plticker.FuncFormatter(nfmt) 
        
        spacing_max = Y_AXIS_TICK_SCALE
        spacing = math.fabs(rescale_data(levels[0], vertical_scale)-rescale_data(levels[-1], vertical_scale))/spacing_max
        start = levels[0]
        level_ticks = [start]
        for i in range(len(levels)-1):
            if math.fabs(rescale_data(levels[i+1], vertical_scale)-rescale_data(start, vertical_scale))>spacing:
            	level_ticks.append(levels[i+1])
            	start = levels[i+1]
            	
        yloc = plt.FixedLocator(level_ticks)
        ax.yaxis.set_major_locator(yloc)
        ax.yaxis.set_major_formatter(fmt)
        plt.minorticks_off()
    
        # Font -------------------------------------------------------------
        font = pylab.matplotlib.font_manager.FontProperties()
        font.set_family(FONT)
        font.set_size(FONT_SIZE)
        
        if (cli_opts.t): 
             # Title ------------------------------------------------------------
             suptitle = getattr(dataset, 'plot_hint_title', ':plot_hint_title missing')
             subtitle = getattr(dataset, 'plot_hint_subtitle', ':plot_hint_subtitle missing')
    
             title = '\n'.join(textwrap.wrap(suptitle + ' ' + subtitle))
    
             # can't use suptitle since it is buggy https://github.com/matplotlib/matplotlib/issues/6996
             plt.title(title, fontproperties = font,horizontalalignment='center')
        # Legend --------
        square = mpl.lines.Line2D([0], [0],color=[0.75,0.75,0.75],marker='s' ,ms = 6,markeredgecolor ='black')
        slabel='Missing Data'
        lgnd = plt.legend([square], [slabel],bbox_to_anchor=(1.,0),frameon = False,handleheight = 0.2,handlelength = 0.6,borderaxespad = 1.5, prop = font)#
        
        # XAxis ------------------------------------------------------------
        
        if dimX_name.lower() == 'time':
            band_half_resolution=(time_bands[0][1]-time_bands[0][0])/2
            xticks_values=[int(v) for v in getattr(dataset, 'plot_hint_time_axis_values', ':plot_hint_time_axis_values missing').split(',') if (int(v)<=np.nanmax(x_var) and int(v)>=np.nanmin(x_var))]
            xticks_labels = getattr(dataset, 'plot_hint_time_axis_labels', ':plot_hint_time_axis_labels missing').replace('~C~','\n').split(',')
            ax.set_xticks(xticks_values)
            ax.set_xticklabels(xticks_labels)
    
        for xticklabel in ax.get_xticklabels():
            xticklabel.set_fontproperties(font)
        
        xlabel = dimX_name # Start with basic name and build up to long_name if available
        if 'standard_name' in dimX: xlabel = dimX.standard_name 
        if 'long_name' in dimX: xlabel = dimX.long_name
        xlabel = '%s' % (string.capwords(xlabel))
    
        xlabel = '\n'.join(textwrap.wrap(xlabel, 60))
        
        plt.xlabel(xlabel, fontproperties = font)
        
        # YAxis ------------------------------------------------------------
    
        for yticklabel in ax.get_yticklabels():
            yticklabel.set_fontproperties(font)
        
        cur_x, _ = ax.yaxis.get_offset_text().get_position()
        ax.yaxis.get_offset_text().set_x(cur_x + SCI_NOT_OFFSET)
    
        ylabel = '%s' % (string.capwords(dimY_name)) # Start with basic name and build up to standard_name if available
        if 'standard_name' in dimY:
            ylabel = '%s' % (string.capwords(dimY.standard_name))
        elif 'positive' in dimY or ('long_name' in dimY and 'pressure' in dimY.long_name.lower()):
            ylabel = 'Pressure'
        if 'temp' in ylabel.lower() and ('prs' in ylabel.lower() or 'lvls' in ylabel.lower()):
            ylabel = 'Pressure'
    
        if dimY.units not in ('', '1'):    
            ylabel += ' (%s)' % dimY.units
        ylabel = '\n'.join(textwrap.wrap(ylabel, 25))
        plt.ylabel(ylabel, fontproperties = font)
    
        # Generate a colorbar and label it  ------------------------------------------------------------
        # Use thresholds from SLD colormap if available so that ticks align with color intervals nicely
        # Do not use thresholds if there are too many of them
        cb = plt.colorbar(im, extend = cmap_extend, ticks = None if thresholds == None or len(thresholds) > 20 else thresholds)
        if variable.units not in ('', '1'):
            cb.ax.text(0.5,1.05+(0.1 if user_min_max_available else 0),'(%s)'%variable.units,horizontalalignment='center',verticalalignment ='bottom', fontproperties = font)
        
        for t in cb.ax.get_yticklabels():
            t.set_fontproperties(font)
       
        cb.ax.yaxis.get_offset_text().set_size(FONT_SIZE)
        forceAspect(ax,aspect = 2)
        
    # Save file --------------------------------------------------------
    out_file_name = cli_opts.o + '.png'
    plt.savefig(out_file_name,bbox_inches='tight', pad_inches = 0.1)
    
    options = {'Data': {'Range': {}}, 'Y Axis': {'Range':{}}}
    if data_min_o != None:
        options['Data']['Range']['Min'] = data_options['Min']
    else:
        options['Data']['Range']['Min'] = float('%g' % data_min_complete)
    if data_max_o != None:
        options['Data']['Range']['Max'] = data_options['Max']
    else:
        options['Data']['Range']['Max'] = float('%g' % data_max_complete)
    if 'Palette' in plot_opts:
        options['Palette'] = plot_opts['Palette']
    options['Data']['Label'] = "%s%s" % (cli_opts.v,' ('+variable.units+')' if variable.units not in ('', '1') else '')
    options['Y Axis']['Range']['Min'] = float(LEVEL_BEGIN) if dimY_options == None or 'Min' not in dimY_options else dimY_options['Min']
    options['Y Axis']['Range']['Max'] = float(LEVEL_END) if dimY_options == None or 'Max' not in dimY_options else dimY_options['Max']
    options['Y Axis']['Label'] = ylabel.replace('\n',' ').replace('  ',' ')
    options['Y Axis']['Display at log10 scale'] = vertical_scale == 'log'
    output = {'images': [out_file_name], 'options': options}
    output_stream.write(json.dumps(output))
    output_stream.flush()
    dataset.close()

def main(argv, output_stream = sys.stdout):
    cli_opts = parse_cli_args(argv[1:])
    plot_opts = parse_plot_options(cli_opts)
    write_curtain_plot(cli_opts, plot_opts, output_stream)

if __name__ == '__main__':
    main(sys.argv)

