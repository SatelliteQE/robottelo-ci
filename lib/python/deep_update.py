#!/usr/bin/env python
"""deep_update.py - Function for performing deep updates to data structures
"""
from collections import MutableMapping, MutableSequence


def deep_update(original, updates):
    """Update the original data structure with given data

    :param iterable original: The original data structure (Typially a list or a
                              dict)
    :param iterable updates: The data structure containnig updates
    :rtype: bool
    :returns: True if the original could be updated (E.g. it is a list or a
              dict)
    """
    if isinstance(original, MutableMapping):
        try:
            updates_iter = updates.iteritems()
        except AttributeError:
            updates_iter = iter(updates)
        for key, value in updates_iter:
            if key in original:
                if not deep_update(original[key], value):
                    original[key] = value
            else:
                original[key] = value
        return True
    elif isinstance(original, MutableSequence):
        original.extend(updates)
        return True
    else:
        return False
