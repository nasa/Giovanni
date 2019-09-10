#! /bin/env python
'''
Format a region for makefile back-chaining. Note: be sure to use the '--' or
the bounding box will not be parsed correctly!

format_region -S 'shape' -C 3 -N 4 -- '-180,-90,180,90'

Mandatory arguments:
  bbox - the bounding box in W,S,E,N format

Optional arguments:
  -S - the user selected shape. Optional
  -C - number of characters used to encode the shape. Ignored unless -S is
       specified. Defaults to 3.
  -N - number of places after the decimal point to use in the bounding box
       representation. Defaults to 4.
'''


import argparse
import sys
import re


def main(argv, output_stream=sys.stdout):

    # parse input arguments
    description = """
    Creates the string used in manifest files to represent the region selection.
    Be sure to use "-b=-180,-90,180,90"-style notation for the bounding box or
    the negative sign in front of the west edge will be interpreted as a
    command line option.
    """
    parser = argparse.ArgumentParser(description=description)
    parser.add_argument(
        "-b",
        dest="bbox",
        type=str,
        default=None,
        help="bounding box")
    parser.add_argument(
        "-N",
        dest="num_bbox_digits",
        type=int,
        default=4,
        help="number of digits after the decimal point for the bounding box. Defaults to 4.")
    parser.add_argument(
        "-S",
        dest="shape",
        type=str,
        default=None,
        help="selected shape")
    parser.add_argument(
        "-C",
        dest='num_checksum_characters',
        type=int,
        default=3,
        help='number of characters for the shape checksum. Defaults to 3.')

    args = parser.parse_args(argv)

    bbox_str = format_bbox(args.bbox,
                           args.num_bbox_digits)
    output_stream.write(bbox_str)

    if args.shape:
        shape_str = format_shape(args.shape, args.num_checksum_characters)
        output_stream.write(shape_str)

    output_stream.flush()


def format_shape(shape, num_characters=3):
    '''
    Take the shape and get its equivalent 2-letter checksum code
    '''

    # remove anything that isn't a-zA-Z0-9_
    shape = re.sub(r'\W', r'', shape)

    # define the alphabet for shapes
    alphabet = list(
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_')

    return _calc_checksum(shape, alphabet, num_characters)


def _calc_checksum(str_, alphabet, num_characters=3):
    '''
    Calculate an num_characters checksum for str_ using the given alphabet of
    digit characters. Note: the alphabet should be specified in increasing values.


    Example 1:
    Your string is constructed from the alphabet ['0','1','2','3','4','5','6',
    '7','8','9']. You want to calculate a 3-digit checksum for the string
    '523452447'.

      Step 1: Break the string into 3-digit sub-strings: ['523,'452','447'].
      Step 2: Sum the strings together and ignore carries:
        We are, conveniently enough, in base 10. So this is easy!
        523 + 452 + 447 = 1422. We are ignoring the carried '1', so we end up
        with checksum 422.

    Example 2:
    Your string is constructed from the alphabet ['A','B','C']. You
    want to calculate a 2-digit checksum for the string 'CBBC'.

      Step 1: Break the string into 2-digit sub-strings: ['CB','BC']
      Step 2: Sum the strings together and ignore carries:
        We are effectively in base 3 here because we have 3 characters in our
        alphabet. So, if we assign 'A'->0, 'B'->1, 'C'->2, our sum is:
        21 + 12 = 110 in base 3. We want to ignore the carried '1', so we end
        up with 10, which translates to 'BA', our final checksum.
    '''

    # Reverse the string so the least significant figure is on the left rather
    # than the right to make indexing easier.
    str_ = str_[::-1]

    # Break up our input string into ndigit strings.
    sub_strings = [str_[i:i + num_characters]
                   for i in range(0, len(str_), num_characters)]

    # Associate a base-10 value with each character in the alphabet. Use the
    # index.
    letter_dict = {}
    for i in range(len(alphabet)):
        letter_dict[alphabet[i]] = i

    # sum the strings
    checksum = 0
    base = len(alphabet)
    for sub_string in sub_strings:
        # loop over each character in the substring and add it to our sum
        for i in range(len(sub_string)):
            # the value associated with this string element needs to be
            # put in the right place for this base math.
            num = letter_dict[sub_string[i]] * (base ** i)
            # add the value. We don't want the carry to the num_characters+1 place,
            # which is the same thing as calculating the modulus.
            checksum = (checksum + num) % (base ** num_characters)

    # convert the sum into an n-digit string checksum in the proper alphabet
    str_checksum = ''
    for i in range(num_characters):
        # get the least significant figure remaining in the original base
        digit_index = checksum % base
        # shift the checksum over one digit in the original base
        checksum = int(checksum / base)
        str_checksum = alphabet[digit_index] + str_checksum

    return str_checksum


def format_bbox(bbox, num_digits=4):
    '''
    Reformat a bounding box in W,S,E,N format to have a fixed number of decimal
    points after the decimal point and use N/S, E/W notation instead of +/-.
    Returns an empty string if bbox is None or the empty string.

    INPUT:
       bbox - the bounding box in W,S,E,N format. E.g. - '-180,-90,180,90'
       num_digits - number of digits after the decimal point

    OUTPUT:
       the reformatted bounding box string
    '''
    if not bbox:
        return ''

    bbox = bbox.split(',')
    formatted = ''
    format_str = "%%.%df" % num_digits
    for i in range(len(bbox)):
        num = float(bbox[i])
        formatted += (format_str % abs(num))

        if i == 0 or i == 2:
            formatted += 'W' if num < 0 else 'E'

        else:
            formatted += 'S' if num < 0 else 'N'

    return formatted

if __name__ == "__main__":
    main(sys.argv[1:])
