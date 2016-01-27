#!/usr/bin/env python
"""mock_config/builder.py - Mock configuration builder
"""
from pprint import pformat

__all__ = ['to']


class _Config(object):
    """Mock configuration code generator

    This class provides a python-based DSL for genrating Mock configuration
    strings, it is not meant to be instanciated directy, instead, the singleton
    instance in the 'to' global is meant to be used. here are some examples for
    use:

    to-expression                       returned string
    to['a_key'].set('a_value')          config_opts['a_key'] = 'a_value'
    to['a_key'].append('a_value')       config_opts['a_key'].append('a_value')
    to['a_key'].extend(('a_val',))      config_opts['a_key'].extend(('a_val',))
    to['key1']['key2'].set(7)           config_opts['key1']['key2'] = 7
    """
    def __getitem__(self, key):
        """Returns a _ConfigKey object with the given key which points to this
        object as its parnet
        """
        return _ConfigKey(self, key)

    def __str__(self):
        """Returns the configration element defined by this object"""
        return 'config_opts'


class _ConfigKey(_Config):
    """_Config counterpart for implementing the Mock code generator
    """
    def __init__(self, parent, key):
        """Initialize the object"""
        self._parent = parent
        self._key = key

    def __str__(self):
        """Returns the configration element defined by this object"""
        return '{0}[{1}]'.format(self._parent, pformat(self._key))

    def set(self, value):
        """Returns a string for configuration 'set' operation"""
        return '{0} = {1}'.format(self, pformat(value))

    def append(self, value):
        """Returns a string for configuration 'append' operation"""
        return '{0}.append({1})'.format(self, pformat(value))

    def extend(self, value):
        """Returns a string for configuration 'extend' operation"""
        return '{0}.extend({1})'.format(self, pformat(value))

    def add(self, value):
        """Returns a string for configuration '+=' operation"""
        return '{0} += {1}'.format(self, pformat(value))


to = _Config()
