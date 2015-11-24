#!/usr/bin/env python
"""custom_mock_chroot.py - Manage mock(1) chroots with custom configuration
"""
import os
from tempfile import mkstemp
from pprint import pformat

from mock_chroot import MockChroot
from deep_update import deep_update

__all__ = ['CustomMockChroot']


class CustomMockChroot(MockChroot):
    """Thin Python wrapper around mock(1) with custom configuraion
    """
    def __init__(
        self,
        config='',
        config_opts=None,
        extend=None
    ):
        """Create a custom mock(1) chroot

        :param str config: The configuration for the chroot as a string
        :param dict config_opts: The Mock configuration as a python structure
        :param CustomMockChroot extend: An object with existing configuration to
                                        extend, this option is mutually
                                        exclusive with 'config'

        At least one way to specify configuration must be used, if more then one
        is used, they will be merged together
        """
        if extend:
            if config:
                raise RuntimeError(
                    "'config' and 'extend' options are mutually exclusive"
                )
            self._config = extend._config
            self._config_opts = extend._config_opts or {}
            if config_opts:
                deep_update(self._config_opts, config_opts)
        else:
            self._config = config
            self._config_opts = config_opts or {}
        (fd, self._cfg_name) = mkstemp(suffix='.cfg')
        try:
            final_config = self._build_mock_config(
                config=self._config,
                config_opts=self._config_opts
            )
            os.write(fd, final_config)
        finally:
            os.close(fd)
        super(CustomMockChroot, self).__init__(self._cfg_name)

    def __del__(self):
        try:
            os.remove(self._cfg_name)
        except AttributeError:
            pass

    @staticmethod
    def _build_mock_config(config='', config_opts=None):
        """Build the contents of a Mock configuration file

        :param str config: The configuration for the chroot as a string
        :param dict config_opts: The Mock configuration as a python structure

        At least one way to specify configuration must be used, if more then one
        is used, they will be merged together

        :returns: The Mock configuration string
        :rvalue: str
        """
        if not (config or config_opts):
            raise RuntimeError('No useful mock configuration specified')
        if config:
            final_config = [config]
        else:
            final_config = []
        if config_opts:
            final_config.append('extra_config = ' + pformat(config_opts))
            with open(
                os.path.join(os.path.dirname(__file__), 'deep_update.py')
            ) as dufile:
                # Need to wrap the deep_update module code with a function to
                # have a scope to define its global symbols in
                final_config.append(
                    'def _deep_update(config_opts, extra_config):'
                )
                final_config.extend((
                    ' ' * 4 + line.rstrip()
                    for line in dufile
                    if line and not line.startswith('#')
                ))
            final_config.append('\n    deep_update(config_opts, extra_config)')
            final_config.append('\n_deep_update(config_opts, extra_config)')
        return '\n'.join(final_config)
