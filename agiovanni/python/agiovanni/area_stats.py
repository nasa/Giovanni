'''
Calculates area statistics for time series.

@author: csmit
'''
import numpy as np
import numpy.ma as ma


class StatsError(Exception):
    """
    An exception throw by the code in this file.
    """
    pass


def compute_statistics(data, axis=None, weights=None, lat=None, lat_dim=None,
                       avg=True, min_=True, max_=True,
                       stddev=True, count=True):
    """
    Calculate the area statistics for a variable in a file. Returns a dict with
    statistics

    All statistics for each variable are calculated over indexes that:
    1. Are not a fill value in the data.
    2. Are not a fill value in the weights.
    3. Are not a zero value in the weights.



    The weighted mean is calculated

        sum(data*weights)/sum(weights)

    The standard deviation is calculated

        sqrt(sum(weights*((data-weighted_avg)**2)/sum(weights))



    Inputs:
        data - data array on which to calculate the statistics.

        axis - the axis or axes (tuple) over which to calculate the statistics.
            Defaults to averaging over all axes.

        weights - averaging weights. If this input is not specified, the lon
            input will be used to calculate longitude weights.

        lat - latitudes for latitude weights. Only used if weights is not
            specified.

        lat_dim - the data dimension/axis associated with latitudes. Only used
            if weights is not specified.

        avg - calculate the weighted average. Default is True. Key in returned
            dict is 'avg'.

        min_ - calculate the minimum data value. Default is True. Key in
            returned dict is 'min'.

        max_ - calculate the maximum data value. Default is True. Key in
            returned dict is 'max'.

        stddev - calculate the weighted standard deviation. Default is True. Key
            in returned dict is 'stddev'.

            Note:If stddev is True and avg is False, the code will calculate the
            weighted average anyway because it is part of the standard
            deviation calculation.

        count - calculate the number of data points that went into the other
            statistics. Defaults to True. Key in returned dict is 'count'.


    """

    if weights is None:
        if lat is None:
            raise StatsError("Either weights or lat must be specified")

        # use longitude-weighted weights
        weights = _create_latitude_weights(lat, data.shape, lat_dim)

    # Make sure the weights are a masked array
    weights = ma.masked_array(weights)

    # Mask out any weights that are exactly zero because they aren't going
    # to contribute to the calculation
    zero_mask = (weights.data == 0)
    new_mask = np.logical_or(zero_mask, weights.mask)
    weights = ma.masked_array(data=weights.data, mask=new_mask)

    if axis is None:
        axis = tuple(range(len(data.shape)))

    return _compute_variable_stats(
        data, axis, weights, avg, min_, max_, stddev, count)


def _create_latitude_weights(lat, weights_shape, lat_dim):
    '''
    Calculate a latitude weight for every element of the data.
    '''
    # weights are a function of latitude
    lat_in_radians = lat * np.pi / 180.0
    raw_weights = np.cos(lat_in_radians)

    # reshape so weights are in the right dimension
    new_shape = np.ones(len(weights_shape),dtype=int)
    new_shape[lat_dim] = len(raw_weights)
    weights = np.reshape(raw_weights, new_shape)

    return weights


def _compute_variable_stats(variable, axis, weights, calc_avg,
                            calc_min, calc_max,
                            calc_stddev, calc_count):
    '''
    Calculate statistics for a single variable.
    '''

    # Get the data out. Note: scale_factor and add_offset are automatically
    # applied.
    data = variable[:]
    # Make sure data is a masked array
    data = ma.masked_array(data)

    # Broadcast the weights before we try to combine the masks for data and
    # weights
    weights = ma.masked_array(data=np.broadcast_to(weights.data, data.shape),
                              mask=np.broadcast_to(ma.getmaskarray(weights), data.shape))

    # We want all our calculations to happen over areas that are unmasked in
    # both the weights and data
    combined_mask = np.logical_or(
        ma.getmaskarray(data),
        ma.getmaskarray(weights))
    data = ma.masked_array(data.data, mask=combined_mask)
    weights = ma.masked_array(weights.data, mask=combined_mask)

    out = {}
    if calc_count:
        # Irritatingly, the ma.count function can only take one value at a time
        # for the axis. So, instead, construct an array of ones
        ones = np.ones(data.shape)
        # Set the masked areas to 0
        ones[combined_mask] = 0
        out["count"] = ma.sum(ones,axis=axis)
    if calc_min:
        out["min"] = ma.min(data, axis=axis)
    if calc_max:
        out["max"] = ma.max(data, axis=axis)

    # Note: standard deviation needs the weighted average and the weights sum
    if calc_avg or calc_stddev:
        sum_weights = _add_axes_back(ma.sum(weights, axis=axis),axis)
        
        weighted_avg_numerator = _add_axes_back(ma.sum(
            weights *
            data,
            axis=axis),axis)
        weighted_avg = weighted_avg_numerator / sum_weights

        if calc_avg:
            out["avg"] = ma.squeeze(weighted_avg,axis=axis)

    if calc_stddev:
        # calculate the anomaly
        anomaly = data - weighted_avg

        # calculate the standard deviation
        variance = ma.sum(weights *
                          (anomaly ** 2) /
                          sum_weights, axis=axis)
        out["stddev"] = np.sqrt(variance)

    return out

def _add_axes_back(arr,axis):
    '''
    Add axes back in again after they've been processed out.
    
    This is not a great implementation. I'm sure it can be improved upon. The
    only reason this function exists at all is because the numpy.ma math
    functions don't consistently take the keepdims option.
    '''
    # Here is the scenario. We have some array whose shape was originally
    # something like (a,b,c,d). We processed out the second and fourth axes
    # by summing over them (axis=(1,3)). At this point, we have an array whose
    # shape is now (a,c). Unfortunately, this array shape does not work well
    # for broadcasting against our original data. What we need is an array
    # with shape (a,1,c,1).
    #
    # So, this function needs to call ma.expand_dims once for each axis that
    # was removed.   
    
    # make sure axis is iterable
    try:
        iter(axis)
    except TypeError:
        # singleton. Make iterable.
        axis = (axis,)
    
    
    if arr is ma.masked:
        # For reasons unknown, ma.expand_dims does nothing for the ma.masked. 
        # Other singletons work fine. No idea why. I've submitted a bug report:
        # https://github.com/numpy/numpy/issues/7424
        new_shape = np.ones(len(axis),dtype=int)
        new_arr = np.zeros(new_shape)
        new_arr = ma.masked_array(data=new_arr,mask=True)
    else:
        # Otherwise, systematically add back the dimensions removed.
        new_arr = ma.copy(arr)
        for i in np.sort(axis):
            new_arr = ma.expand_dims(new_arr,i)
        
    return new_arr
        
    

    
    