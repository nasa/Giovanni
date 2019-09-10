'''
Created on Oct 16, 2015

This class provides normalize and normalize_if_needed to "normalize" the
longitude by placing it and data on a grid from [-180,180). Areas without data
are given fill values.

@author: csmit
'''

import numpy as np
import numpy.ma as ma


class LonError(Exception):
    pass


def normalize_if_needed(lons, data, fill_value):
    '''
    This function places the data on a [-180,180) longitude grid if there are
    longitudes outside this range. See normalize for details of requirements
    on the data inputs.
    '''
    if len(lons) == 0:
        # why are you calling this function?
        return(lons, data)
    elif len(lons) == 1:
        # if there is only one value, just make sure the longitude is
        # [-180,180)
        new_lons = get_canonical_longitude(lons)
        return (new_lons, data)
    else:
        # see if there is a discontinuity in the longitudes
        over_180 = goes_over_180(lons)
        if(len(over_180) == 0):
            # didn't go over the 180 meridian
            return (get_canonical_longitude(lons), data)
        else:
            # did go over the 180 meridian, so needs to be normalized
            return normalize(lons, data, fill_value)


def goes_over_180(lons):
    '''
    Determines whether or not the data goes over the 180 meridian. If the data
    goes over the 180 meridian, it returns the indexes of the longitudes that
    cross. E.g. - [170,-170,-150] will return 1. If the longitudes do not go
    over the 180 meridian, it will return an empty array.
    '''
    new_lons = get_canonical_longitude(lons)
    diffs = new_lons[1:] - new_lons[0:-1]
    over_180 = [i + 1 for i in range(len(diffs)) if diffs[i] < 0]
    return over_180


def get_resolution(lons):
    '''
    Calculates the data resolution from the longitudes. Needs at least 2
    longitudes.
    '''
    lons = get_canonical_longitude(lons)
    if len(lons) == 2:
        # check for the case where we are going over the 180 meridian
        if(lons[0] > 0 and lons[1] < 0):
            resolution = float(lons[1] + 360 - lons[0])
        else:
            resolution = float(lons[1] - lons[0])
    else:
        lons = np.array(lons)
        diffs = sorted(np.abs(lons[1:] - lons[0:-1]))
        # sort and remove the last entry as this may go over the 180
        # meridian
        diffs = diffs[0:-1]
        resolution = np.average(diffs)

    return resolution


def extend_for_map_server(lons, data, fill_value):
    '''
    (out_lons, out_data_ = extend_for_map_server(lons,data,fill_value)

    This function checks for data grid cells that go over the 180 meridian. For
    example, suppose the first longitude is -180 and the longitude resolution is
    1 degree. This means the data for the first longitude extends from
    -180.5 -- -179.5. This code will take that data and put it in the result
    array at +180 degrees as well.
    '''

    # figure out if we actually need to do anything.
    resolution = get_resolution(lons)

    west_edge = get_canonical_longitude(lons - resolution / 2)
    east_edge = get_canonical_longitude(lons + resolution / 2)

    # see which longitude grid cells cross the 180 meridian
    inds = [
        i for i in range(
            len(lons)) if west_edge[i] > 0 and east_edge[i] < 0]

    # See if this is just a rounding error by calculating what fraction
    # of the grid cell is on either side of the 180 meridian. For example,
    # suppose the grid cell extends from 179.999 to -179.001. This would mean
    # that the cell is 0.001 of the cell is west of the 180 meridian and
    # 0.999 of the cell is east of the 180 meridian. This is clearly a
    # rounding error.
    smallest_fraction = []
    for ind in inds:
        fraction_west = (180.0 - west_edge[ind]) / resolution
        fraction_east = (east_edge[ind] + 180.0) / resolution
        smallest_fraction.append(
            fraction_west if fraction_west < fraction_east else fraction_east)
    
    # Only keep indexes where at least 10% of the cell goes over the 180
    # meridian. Why 10%? Well, we currently only have cells that should align
    # perfectly with the 180 meridian (0% overlap) and cells for MERRA that
    # are exactly 50% on either side of the 180 meridian. So 10% seems like a 
    # reasonable threshold.
    inds = [inds[i] for i in range(len(inds)) if smallest_fraction[i] > 0.1]    

    if len(inds) == 0:
        # Yay! Nothing to do
        return (get_canonical_longitude(lons), data)
    elif len(inds) != 1:
        # This does not make sense...
        raise LonError(
            "Found more than one longitude grid cell extending over the 180 meridian.")

    # put the data center points on a [-180,180) grid.
    (new_lons, new_data) = normalize(lons, data, fill_value)

    # now the data spanning the 180 meridian should be the first or the last
    # longitude.
    num_lat = new_data.shape[0]
    if new_lons[0] - resolution / 2 <= -180:
        # It's the first longitude. So copy the data over to the end.

        # Create a column matrix of the first column of data
        column = ma.reshape(new_data[:, 0], (num_lat, 1))
        # concatenate them together
        new_data = ma.concatenate([new_data, column], 1)

        # Update the longitudes
        new_lons = np.append(new_lons, new_lons[0] + 360)

    else:
        # It's the last longitude. So copy the data from the end over to the
        # beginning.

        # Create a column matrix of the last column of data
        column = ma.reshape(new_data[:, -1], (num_lat, 1))
        # concatenate them together
        new_data = ma.concatenate([column, new_data], 1)

        # Update the longitudes
        new_lons = np.append(new_lons[-1] - 360, new_lons)

    return (new_lons, new_data)


def normalize(lons, data, fill_value):
    '''
    (out_lons,out_data) = normalize(lons,data,fill_value)

    This function places the data on a [-180,180) longitude grid. It fills in
    masked data where there is currently no data. It returns the new data and
    new longitudes. NOTE: The longitudes need to be contiguous even if they
    go over the 180 meridian.

    INPUTS:

    lons - the longitudes. Longitudes should be contiguous and evenly spaced.
    They can go over the 180 meridian, but they can't have jumps. So,
    [178.5,179.8,-179.5,-178.5] is fine. [1,2,10,11] will not work. Furthermore,
    longitudes must not wrap around the globe more than once. So,
    [177, 179, -179,-177,...,175,177] will not work.

    data - the data. It should be a 2-dimensional array with the longitude as
    the second dimension.

    fill_value - the fill value for the output masked array.

    OUTPUTS:
    out_lons - longitudes from [-180,180)
    out_data - data matching the new longitudes
    '''

    if len(lons) < 2:
        raise LonError("Unable to do anything with fewer than than 2 points")

    # make sure this is a numpy array
    data = ma.masked_array(data)

    # make sure these are all between [-180,180)
    lons = get_canonical_longitude(lons)

    # calculate the longitude resolution
    resolution = get_resolution(lons)

    # Figure out what the first longitude should be. We want the largest
    # n such that self.lons[0] - n*resolution >= -180.
    n = np.floor((180.0 + lons[0]) / resolution)
    min_lon = lons[0] - n * resolution

    # Create our new longitudes
    new_lons = np.arange(
        start=min_lon,
        stop=180.0,
        step=resolution,
        dtype=float)

    # Make sure we didn't get an extra longitude due to rounding errors
    num_lon = int(round(360.0 / float(resolution)))
    if len(new_lons) > num_lon:
        new_lons = new_lons[0:-1]

    # create an empty masked array with the correct new shape
    num_lat = data.shape[0]
    empty_data = np.ones(
        shape=(num_lat, num_lon), dtype=float) * fill_value
    new_data = ma.masked_array(
        data=empty_data,
        mask=True,
        fill_value=fill_value)

    # figure out the correct indexes to move the data from the old array
    # in the new array
    new_indexes = n + np.arange(0, len(lons))
    # these indexes may go out of bounds, in which case we want to wrap
    # around
    new_indexes = np.mod(new_indexes, num_lon).astype(int)

    # copy the data into the correct location
    new_data[:, new_indexes] = data

    return(new_lons, new_data)


def get_canonical_longitude(lons):
    '''
    Returns longitudes between [-180,180).
    '''
    # Get all the longitudes to [-180,180). Satisfy:
    # lon + n*360 >= -180
    lons = np.array(lons)
    return lons + 360 * np.ceil(-0.5 - lons / 360.0)
