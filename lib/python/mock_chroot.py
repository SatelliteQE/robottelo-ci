#!/usr/bin/env python
"""mock_chroot.py - Thin Python wrapper around mock(1)
"""
from subprocess import check_output

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

    def _mock_cmd(self, *more_args):
        cmd = [self.mock_exe(), '--root={}'.format(self._root)]
        cmd.extend(more_args)
        return tuple(cmd)

    @classmethod
    def mock_exe(cls):
        return '/usr/bin/mock'
