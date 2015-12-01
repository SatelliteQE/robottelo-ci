#!/usr/bin/env python
"""mock_chroot.py - Thin Python wrapper around mock(1)
"""
from subprocess import check_output
from collections import Iterable

__all__ = ['MockChroot']


class MockChroot(object):
    """Thin Python wrapper around mock(1)
    """
    def __init__(self, root='/etc/mock/default.cfg'):
        """Create a mock(1) chroot
        :param str root: The name or path for the mock configuration file to use
        """
        self._root = root

    def chroot(self, *cmd):
        """Run a non-interactive command in mock

        All positional arguments are passes as the command to run and its
        argumens
        This method will behave in a similliar manner to subprocess.check_output
        yeilding CalledProcessError on command failure

        :returns: the command output as string
        :rtype: str
        """
        mock_cmd = self._mock_cmd('--chroot', '--', *cmd)
        output = check_output(mock_cmd)
        return output

    def clean(self):
        """Clean the mock chroot
        """
        mock_cmd = self._mock_cmd('--clean')
        check_output(mock_cmd)

    def rebuild(self, src_rpm, define=None, resultdir=None):
        """Build a package from .src.rpm in Mock

        :param str src_rpm: The path to the .src.rpm file to build
        :param list define: An optional list of defines for the build process
        :param str resultdir: Override where the build results get placed

        :returns: the command output as string
        :rtype: str
        """
        options = ()
        if define:
            if isinstance(define, basestring):
                options += ('--define', define)
            elif isinstance(define, Iterable):
                options += reduce(lambda l, x: l + ('--define', x), define, ())
            else:
                raise TypeError("given 'define' is not a list or a string")
        if resultdir:
            options += ('--resultdir', resultdir)
        mock_cmd = self._mock_cmd('--rebuild', src_rpm, *options)
        output = check_output(mock_cmd)
        return output

    def _mock_cmd(self, *more_args):
        cmd = [self.mock_exe(), '--root={}'.format(self._root)]
        cmd.extend(more_args)
        return tuple(cmd)

    @classmethod
    def mock_exe(cls):
        return '/usr/bin/mock'
