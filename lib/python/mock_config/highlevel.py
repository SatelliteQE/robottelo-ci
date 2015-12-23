#!/usr/bin/env python
"""mock_config.py - Library of high-level Mock configuration snippets
"""
from .builder import to
from .composition import compose, ConfigurationObject

__all__ = ['bind_mount', 'file', 'env_vars', 'use_host_resolv']


class bind_mount(ConfigurationObject):
    """Class for generating Mock bind mount configuration. This class
    implements a Mock configuration object as described in
    mock_config.Composit docstring
    """
    def __init__(self, *pairs):
        """Init the configuration

        :param list pairs: List of pairs of directories and mount points inside
                           Mock
        """
        super(bind_mount, self).__init__(
            body=to['plugin_conf']['bind_mount_opts']['dirs'].extend(pairs)
        )

    def initialization(self, composition_context):
        if composition_context.get('bind_mount_enabled', False):
            return ''
        else:
            composition_context['bind_mount_enabled'] = True
            return to['plugin_conf']['bind_mount_enable'].set(True)


def file(path, content):
    """Add a file with given content to the mock environemnt

    :param str path: The path to the file inside the Mock environment
    :param str content: The content of the file

    :returns: Mock configuration string
    :rtype: dict
    """
    return to['files'][path].set(content)


def env_vars(**vars):
    """Setup environment varaibles inside Mock

    :param dict vars: A dictionary of variables mapped to values

    :returns: Mock configuration string
    :rtype: dict
    """
    return compose(*(
        to['environment'][var].set(value) for (var, value) in vars.iteritems()
    ))


def use_host_resolv():
    """Setup Mock to use name rosolution from host

    :returns: Mock configuration string
    :rtype: dict
    :returns: Mock configuration object
    :rtype: composition.Comosit
    """
    return compose(
        to['use_host_resolv'].set(True),
        file('/etc/hosts', _read_file('/etc/hosts')),
    )


def _read_file(name):
    """A conveniance founction to open and read a file in a single command

    :param str name: The name of the fie to read

    :returns: The contents of the file
    :rtype: str
    """
    with open(name, 'r') as ofd:
        return ofd.read()
