#!/usr/bin/env python
# -*- encoding: utf-8 -*-
"""Manage Jenkins plugins.

This module functions both as a stand-alone command-line script and as an
importable Python library. It contains tools for managing the plugins on a
Jenkins server. This script makes use of the "jenkins" section of
``jenkins_jobs.ini``.

"""
from __future__ import print_function
from argparse import ArgumentParser
from xml.etree import ElementTree
import os
import requests

from sys import version_info
if version_info.major == 2:
    from ConfigParser import ConfigParser  # pylint:disable=import-error
else:
    from configparser import ConfigParser  # pylint:disable=import-error


def main():
    """Parse command-line arguments."""
    parser = ArgumentParser(description='Manage Jenkins plugins.')
    subparsers = parser.add_subparsers()

    install_parser = subparsers.add_parser(
        'install',
        help=(
            'Install the named plugin(s). A specific plugin version may be '
            'provided by appending "@version_number" to the end of a plugin '
            'name. If no plugin version is provided, "@default" is appended.'
        ),
    )
    install_parser.set_defaults(func=install)
    install_parser.add_argument('plugins', metavar='plugin', nargs='+')

    uninstall_parser = subparsers.add_parser(
        'uninstall',
        help='Uninstall the named plugin(s).',
    )
    uninstall_parser.set_defaults(func=uninstall)
    uninstall_parser.add_argument('plugins', metavar='plugin', nargs='+')

    query_parser = subparsers.add_parser(
        'query',
        help='List installed plugins.',
    )
    query_parser.set_defaults(func=query)
    query_parser_group = query_parser.add_mutually_exclusive_group()
    query_parser_group.add_argument(
        '--implicit',
        action='count',
        help='Only show plugins installed implicitly (as dependencies).',
    )
    query_parser_group.add_argument(
        '--explicit',
        action='count',
        help='Only show plugins installed explicitly (not as dependencies).',
    )

    args = parser.parse_args()
    result = args.func(args)
    if args.func == query:
        for plugin in result:
            print(plugin)
    elif args.func == install:
        print(
            'Plugins are being installed. You may need to restart Jenkins '
            'when all plugins are done installing.'
        )
    elif args.func == uninstall:
        print(
            'Plugins are being uninstalled. You may need to restart Jenkins '
            'when all plugins are done uninstalling.'
        )


def install(args):
    """Install one or more plugins."""
    config = _get_config()
    xml_root = ElementTree.Element('jenkins')
    for plugin in args.plugins:
        if '@' not in plugin:
            plugin = plugin + '@default'
        ElementTree.SubElement(xml_root, 'install', {'plugin': plugin})
    response = requests.post(
        '{0}/pluginManager/installNecessaryPlugins'.format(config['url']),
        ElementTree.tostring(xml_root),
        auth=config['auth'],
        headers={'content-type': 'text/xml'},
        verify=False,
    )
    response.raise_for_status()


def uninstall(args):
    """Uninstall one or more plugins."""
    config = _get_config()
    for plugin in args.plugins:
        requests.post(
            '{0}/pluginManager/plugin/{1}/doUninstall'.format(
                config['url'],
                plugin,
            ),
            auth=config['auth'],
            verify=False,
        ).raise_for_status()


def query(args):
    """Get information about plugins.

    :returns: An iterable of strings in the form
        ``'plugin-name@plugin-version'``.

    """
    config = _get_config()
    response = requests.get(
        '{0}/pluginManager/api/json?depth=2'.format(config['url']),
        auth=config['auth'],
        verify=False,
    )
    response.raise_for_status()
    plugins = response.json()['plugins']

    # If the user just wants a list of all plugins, our job is easy.
    if args.explicit is None and args.implicit is None:
        return set((
            '{}@{}'.format(plugin['shortName'], plugin['version'])
            for plugin in plugins
        ))

    # Here, we enumerate explicitly- and implicitly-installed plugins. Our
    # strategy is to gather all plugins into the "explicit" set, then move them
    # to the "implicit" set as needed. We do this because not-installed plugins
    # may be listed as dependencies. Here's an example of a dependency:
    #
    #   {"optional" : false, "shortName" : "matrix-auth", "version" : "1.0.2"}
    #
    exp_names = set((plugin['shortName'] for plugin in plugins))
    imp_names = set()
    for plugin in plugins:
        for dependency in plugin['dependencies']:
            if (dependency['optional'] is False and
                    dependency['shortName'] in exp_names):
                exp_names.remove(dependency['shortName'])
                imp_names.add(dependency['shortName'])

    # Finally — compile a set of 'plugin-name@plugin-version' strings!
    target = exp_names if args.explicit is not None else imp_names
    return set((
        '{}@{}'.format(plugin['shortName'], plugin['version'])
        for plugin in plugins
        if plugin['shortName'] in target
    ))


def _get_config():
    """Read configuration options from the ``jenkins_jobs.ini`` config file.

    Parse the ``jenkins_jobs.ini`` configuration file and return a dict in the
    following form::

        {
            'auth': ('username', 'password'),
            'url': …,
        }

    """
    config = ConfigParser()
    reader = config.readfp if version_info.major == 2 else config.read_file  # noqa pylint:disable=no-member
    with open(
        os.path.join(os.path.dirname(__file__), os.pardir, 'jenkins_jobs.ini')
    ) as handle:
        reader(handle)
    if version_info.major == 2:
        return {
            'auth': (
                config.get('jenkins', 'user'),
                config.get('jenkins', 'password')
            ),
            'url': config.get('jenkins', 'url'),
        }
    else:
        return {
            'auth': (config['jenkins']['user'], config['jenkins']['password']),
            'url': config['jenkins']['url'],
        }


if __name__ == '__main__':
    main()
