"""Methods for implementing algorithms in G4."""

__author__ = 'Daniel da Silva <Daniel.e.daSilva@nasa.gov>'

import optparse


def parse_cli_args(args, comparison=False):
    """Parses command line arguments.

    Returns
      options, an object whose attributes match the values of the
      specified in the command line. e.g. '-e xyz' <=> options.e
    Raises
      OptionError, error parsing options
      ValueError, invalid or missing argument      
    """
    parser = optparse.OptionParser()

    parser.add_option("-s", metavar="START_TIME", dest="s",
                      help="Start time in ISO8601 format")
    parser.add_option("-e", metavar="END_TIME", dest="e",
                      help="End time in IS08601 format")
    parser.add_option("-b", metavar="BBOX", dest="b",
                      help="Bounding box in 'W,S,E,N' format")
    parser.add_option("-f", metavar="INPUT_FILE", dest="f",
                      help="An input file with a list of input files")
    parser.add_option("-o", metavar="OUTPUT_FILE", dest="o",
                      help="The netCDF output filename")
    parser.add_option("-v", metavar="VAR_NAME", dest="v",
                      help="Variable name in netCDF file to process")
    parser.add_option("-z", metavar="Z-SLICE", dest="z",
                      help="Dimension slize for 3D variables")
    parser.add_option("-l", metavar="LINEAGE_EXTRAS", dest="l",
                      help="Lineage extras filename")
    parser.add_option("-S", metavar="SHAPEFILE", dest="S",
                      help="Shapefile, in $shapefile/$shape format")
    parser.add_option('-g', metavar='GROUP', dest='g',
                      help='Group info, in TYPE=VAL format')
    parser.add_option('-j', metavar='THREADS', dest='j',
                      help='Number of jobs to run in parallel (INT)')
    
    options, _ = parser.parse_args(args)

    # Verify required are present and not empty
    required_opts = 'sebfov'

    for required_opt in required_opts:
        if not getattr(options, required_opt, None):
            raise ValueError("-%s missing" % required_opt)
        
    # Validate bbox
    toks = options.b.split(',')

    if len(toks) != 4:
        raise ValueError("-b has invalid format")

    for tok in toks:
        try:
            float(tok)
        except ValueError:
            raise ValueError("-b has invalid format")

    # Return
    return options


def read_file_list(path, comparison=False):
    """Extract the granule paths from a file list.
    
    Args
      comparison, set to True if you expect multiple paths
        per line (separated by a space)
    Returns
      By default, returns a list of strings which are valid paths
      to granules on the filesystem. If comparison is set to True,
      returns a list of tuples of strings which are valid paths to
      granules on the filesystem.
    """
    file_list = []

    with open(path) as fh:
        for line in fh:
            if comparison:        
                elem = line[:-1].split(' ')
            else:
                elem = line[:-1]

            file_list.append(elem)

    return file_list


def write_file_list(path, file_list):
    """Writes a list of files to the file system.

    Args
      file_list, list of strings
    """
    with open(path, 'w') as fh:
        for line in file_list:
            fh.write(line)
            fh.write('\n')
