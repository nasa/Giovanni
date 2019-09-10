#! /bin/env python
"""
####################################################################
NAME
histogramPlot.py - Histogram Plot using Matplotlib

DESCRIPTION
Generates a histogram plot from the output of g4_histogram.py

SYNOPSIS
Usage: histogramPlot.py [options]

OPTIONS
  -h, --help       show this help message and exit
  -i INPUT_FILE    Input NetCDF file
  -o OUTPUT_FILE   Output file 
  -f OPTIONS_FILE  Plot options in a text file
  -v VARIABLE      Variable name in input dataset
  -t TITLE         Use this option to draw title and subtitle
DEPENDENCY
netCDF4, matplotlib

AUTHORS
Daniel da Silva, 07/09/2014, Initial version

VERSION
$Revision: 1.33 $
####################################################################
"""

__author__ = 'Daniel da Silva <daniel.dasilva@nasa.gov>'

import decimal
import math
import optparse
import os
import sys
import textwrap
import operator

import matplotlib as mpl
mpl.use('Agg')           # Force matplotlib to not use any Xwindows backend.
                         # Must be called before pyplot.
mpl.rcParams['mathtext.fontset'] = "stix"

import matplotlib.pyplot as plt
from matplotlib.ticker import FormatStrFormatter
import netCDF4 as nc
import numpy as np
import pylab
import simplejson as json

BAR_COLOR = '#37a3ef'   # Color of Bars
BOX_ALPHA = 0.8         # Transparency of Top-Right Info Box
BOX_COLOR = '#e8e8e8'   # Color of Top-Right Info Box
BOX_PADDING = 10        # Passing of the Top-Right Info Box
BOX_POS = (0.745, .95)  # Position of the Top-Right Info Box (highly accurate empirical value)
FONT = 'sans-serif'     # Font Family
FONT_SIZE = 8           # Font size
POWER_LIMITS = (-3, 4)  # Limits for showing ticks in scientific notation
RENDER_SIZE = (6, 4.8)  # Inches
RENDER_DPI  = 100       # Dots per Inch
SCI_NOT_OFFSET = -.15   # Offset for scientific notation legend on Y axis

# Credit: https://stackoverflow.com/questions/27050108/convert-numpy-type-to-python/27050186
class NumpyToJsonEncoder(json.JSONEncoder):
    def default(self, obj):
        if isinstance(obj, np.integer):
            return int(obj)
        elif isinstance(obj, np.floating):
            return float(obj)
        elif isinstance(obj, np.ndarray):
            return obj.tolist()
        else:
            return super(MyEncoder, self).default(obj)

class PlotOptions(object):
    """User-defined settings at the visualization-level.
    
    All settings are attributes. If the -f option was specified, settings
    defined in that file override the defaults.

    Attributes:
    - xScale: (str) 'Log' or 'Linear'
    - yScale: (str) 'Log' or 'Linear'
    """    
    def __init__(self, cli_opts):
        self._set_defaults()
        if cli_opts.f:
            try:
                with open(cli_opts.f, 'rU') as f:
                    content = '\n'.join(f.readlines())
                    options = json.loads(content)
                    self._set_options(options)
            except Exception:
                sys.stderr.write("Error: could not load plot options file")
    
    def _set_defaults(self):
        self.yScale = 'Linear'
        self.xScale = 'Linear'

    def _set_options(self, options):
        try:
            self.xScale = 'Log' if options['Data']['Display at log10 scale'] else 'Linear'
        except:
            self.xScale = 'Linear'
        try:
            self.yScale = 'Log' if options['Y Axis']['Display at log10 scale'] else 'Linear'
        except:
            self.yScale = 'Linear'

    def get_output_options_dict(self, labels):
        options = {
            'Data': {
                'Label': labels['xLabel'],
                'Display at log10 scale': self.xScale == 'Log'
            },
            'Y Axis': {
                'Label': labels['yLabel'],
                'Display at log10 scale': self.yScale == 'Log'
            }
        }
        return options
   
def parse_cli_args(args):
    """Parses command line arguments.
    
    Returns
      options, an object whose attributes match the values of the
      specified in the command line. e.g. '-e xyz' <=> cli_opts.e
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
    parser.add_option("-t", metavar="TITLE", dest="t", action="store_true",
                      help="Use this option to draw title and subtitle")   
 
    cli_opts, _ = parser.parse_args(args)
    
    # Verify required are present and not empty
    for required_opt in "iov":
        if not getattr(cli_opts, required_opt, None):
            raise ValueError("-%s missing" % required_opt)
        
    return cli_opts
    

def format_number(number, sci_bounds=(-3, 4)):
    """Formats a number using special rules.

    Args
      number, the number to format. float, int, or long only.
      sci_bounds, bounds of log10(|number|) to not use scientific
        notation for.
    Returns
      ret, number formatted as a string.
    """
    ret = None

    if np.isnan(number) or np.isinf(number):
        ret = str(number)
    elif abs(number) >= 1e-6 and not(
        sci_bounds[0] < math.log10(abs(number)) < sci_bounds[1]
        ):
        ret = '%.2e' % number
    elif isinstance(number, (int, long, np.integer)):
        ret = str(number)
    else:
        ret = '%.2f' % number

    return ret


def write_histogram_plot(cli_opts, plot_opts, output_stream):
    """Writes a histogram plot from a histogram dataset."""

    y_log_scale = (plot_opts.yScale == 'Log')
    x_log_scale = (plot_opts.xScale == 'Log')
    
    fig = plt.figure(figsize=RENDER_SIZE, dpi=RENDER_DPI)
    ax = plt.gca()
   
    dataset = nc.Dataset(cli_opts.i)

    bin_left = None
    bin_left_var_name = 'bin_left'+('' if not x_log_scale else '_log')
    if bin_left_var_name in dataset.variables:
        bin_left = dataset.variables[bin_left_var_name]
    if bin_left != None and bin_left[:]!= []:
        bin_width = [bin_left[1] - bin_left[0]] * bin_left.shape[0] 
    if bin_left != None and bin_left[:] != []:
        #ax.set_xticks(bin_left)#can be used to set ticks to bin edges
        pass
    
    variable = None
    var_name = cli_opts.v+('' if not x_log_scale else '_log')
    if var_name in dataset.variables:
        variable = dataset.variables[var_name]
    if variable != None and variable[:] != []:
        ax.bar(bin_left[:], variable[:], bin_width, color=BAR_COLOR, log=y_log_scale)
    
    # Font -------------------------------------------------------------
    font = pylab.matplotlib.font_manager.FontProperties()
    font.set_family(FONT)
    font.set_size(FONT_SIZE)
   
     
    # Title ------------------------------------------------------------     
    if (cli_opts.t):
        suptitle = getattr(dataset, 'plot_hint_title', ':plot_hint_title missing')
        subtitle = getattr(dataset, 'plot_hint_subtitle', ':plot_hint_subtitle missing')
        title = '\n'.join(textwrap.wrap(suptitle + ' ' + subtitle))
        plt.title(title, fontproperties=font) # can't use suptitle https://github.com/matplotlib/matplotlib/issues/6996
    
    # XAxis ------------------------------------------------------------
    if not x_log_scale:
        ax.xaxis.get_major_formatter().set_powerlimits(POWER_LIMITS)
    else:
        ax.xaxis.set_major_formatter(FormatStrFormatter(r'$10^{%s}$'))

    for xticklabel in ax.get_xticklabels():
        xticklabel.set_fontproperties(font)
   
    xlabel_short = '%s.%s: %s' % (dataset.variables[cli_opts.v].product_short_name,
                        dataset.variables[cli_opts.v].product_version,
                        dataset.variables[cli_opts.v].long_name)
    xlabel = xlabel_short + ('' if not x_log_scale else '')#' (log(x))'

    if dataset.variables[cli_opts.v].units not in ('', '1'):    
        xlabel += ' (%s)' % dataset.variables[cli_opts.v].units

    xlabel = '\n'.join(textwrap.wrap(xlabel, 60))
    
    plt.xlabel(xlabel, fontproperties=font)
    
    # YAxis ------------------------------------------------------------
    if not y_log_scale:
        ax.yaxis.get_major_formatter().set_powerlimits(POWER_LIMITS)

    for yticklabel in ax.get_yticklabels():
        yticklabel.set_fontproperties(font)
    
    cur_x, _ = ax.yaxis.get_offset_text().get_position()
    ax.yaxis.get_offset_text().set_x(cur_x + SCI_NOT_OFFSET)

    plt.ylabel('Frequency', fontproperties=font)

    # Text Box ---------------------------------------------------------
    # The box is placed in the top right corner. The statistical values
    # were computed and stored by g4_histogram.py in attributes of the
    # variable.
    total = str(dataset.variables[cli_opts.v].total)
    excluded = 0
    if x_log_scale:
        excluded = total
        if variable != None:
            excluded = dataset.variables[cli_opts.v].total - dataset.variables[cli_opts.v+'_log'].total
    
    lines = [
        'Total:          ' + total,
    ]
    if excluded > 0: lines.append(
        'Excluded:   ' +str(excluded)
    )
    if bin_left != None and bin_left[:] != []:
        lines.append('Bins:           ' + str(bin_left[:].shape[0]))
    if variable != None:
        if hasattr(variable, 'mean') and variable.mean != None:
            lines.append('Mean:         ' + format_number(variable.mean))
        if hasattr(variable, 'med') and variable.med != None:
            lines.append('Med:           ' + format_number(variable.med))
        if hasattr(variable, 'std') and variable.std != None:
            lines.append('Std:            ' + format_number(variable.std))
        if hasattr(variable, 'max') and variable.max != None:
            lines.append('Max:           ' + format_number(variable.max))
        if hasattr(variable, 'min') and variable.min != None:
            lines.append('Min:            ' + format_number(variable.min))
    
    box_left = BOX_POS[0] - max([len(line[line.rfind(' ') + 1:]) for line in lines]) * 0.008 # Highly accurate empirical constant, adjusts position of textbox depending on the length of total 
    plt.text(
        box_left,
        BOX_POS[1],
        '\n'.join(lines),
        transform=ax.transAxes,
        bbox={'facecolor': BOX_COLOR,
              'pad': BOX_PADDING,
              'alpha': BOX_ALPHA},
        verticalalignment='top',
        horizontalalignment='left',
        fontproperties=font)

    # Save file --------------------------------------------------------
    out_file_name = cli_opts.o + '.png'
    plt.savefig(out_file_name, bbox_inches='tight')
    
    options = plot_opts.get_output_options_dict({'xLabel': xlabel_short.replace('\n',' ').replace('  ',' '), 'yLabel': 'Scale'})
    output = {'images': [out_file_name], 'options': options}
    output_stream.write(json.dumps(output, cls=NumpyToJsonEncoder))
    output_stream.flush()
    dataset.close()

def main(argv, output_stream=sys.stdout):
    cli_opts = parse_cli_args(argv[1:])
    plot_opts = PlotOptions(cli_opts)
    write_histogram_plot(cli_opts, plot_opts, output_stream)


if __name__ == '__main__':
    main(sys.argv)


