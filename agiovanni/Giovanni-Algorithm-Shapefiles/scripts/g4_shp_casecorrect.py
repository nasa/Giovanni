#!/bin/env python
"""Corrects the capitalization of a field in a preprocessed shapefile.
Requires a preprocessed file, does not modify shapefile.

The US State Department shapefiles contains capitalized names for the
countries, e.g. "UNITED STATES". This script formats them, e.g. it
would make the former example "United States".
"""

__author__ = 'Daniel da Silva <Daniel.e.daSilva@nasa.gov>'

import os
import sys

import simplejson as json

# Words in all-capitals that should not be modified
ACCEPTABLE_CAPITALIZATIONS = set(['UK', 'US'])


def correct_case(text):
    """Fixes all-capitalization of all words, inclusing those in parens.

    'UNITED STATES' => 'United States'
    'Norfolk Island (AUSTRALIA)' => 'Norfolk Island (Australia)'
    
    Params
      text: text string to format
    Returns
      formatting string per rules above    
    """
    words = text.split(' ')
    words_formatted = []

    for word in words:
        left_paren = False
        right_paren = False

        if word.startswith('('):
            left_paren = True
            word = word[1:]

        if word.endswith(')'):
            right_paren = True
            word = word[:-1]

        if (word == word.upper() and
            word not in ACCEPTABLE_CAPITALIZATIONS):
            word = word.capitalize()

        if left_paren:
            word = '(' + word
        if right_paren:
            word = word + ')'
            
        words_formatted.append(word)

    return ' '.join(words_formatted)


def main(argv):
    # Parse command-line arguments
    # ------------------------------------------------------------------
    if len(argv) != 3:
        print 'Usage: %s FIELD_NAME PREFIX' % os.path.basename(argv[0])
        print
        print sys.modules[__name__].__doc__
        sys.exit(1)
    else:
        field_name, prefix = sys.argv[1:]
    
    # Read file
    # ------------------------------------------------------------------
    file_name = prefix + '.json'
    
    try:
        json_file = open(file_name)
    except IOError:
        print >>sys.stderr, 'Error opening', file_name
        sys.exit(1)
        
    try:
        json_content = json.load(json_file)
    except ValueError:
        print >>sys.stderr, 'Error parsing json in', file_name
        sys.exit(1)
        
    json_file.close()

    # Edit json contents
    # ------------------------------------------------------------------
    field_idx = None
    for i, field in enumerate(json_content['fields']):
        if field[0].lower() == field_name.lower():
            field_idx = i
            break

    if field_idx is None:
        print >>sys.stderr, 'Could not find field', field_name
        sys.exit(1)

    count = 0
    for shape in json_content['shapes'].values():
        existing_text = shape['values'][field_idx]
        formatted_text = correct_case(shape['values'][field_idx])

        if existing_text != formatted_text:
            shape['values'][field_idx] = formatted_text
            count += 1

    # Write file
    # ------------------------------------------------------------------
    json_file = open(file_name, 'w')
    json.dump(json_content, json_file)
    json_file.close()

    print 'Rewrote', count, 'records'


if __name__ == '__main__':
    main(sys.argv)
    
    
    
