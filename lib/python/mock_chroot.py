#!/usr/bin/env python
"""mock_chroot.py - Thin Python wrapper around mock(1)
"""
import os
from subprocess import check_output
from collections import Iterable
from tempfile import mkstemp

__all__ = ['MockChroot']


class MockChroot(object):
    """Thin Python wrapper around mock(1)
    """
    # Star arguments are used in this class
    # pylint: disable=star-args
    def __init__(self, root=None, config=None):
        """Create a mock(1) chroot
        :param str root: The name or path for the mock configuration file to
                         use
        :param str config: The Mock configuration for the chroot as string or
                           some other object that will yield a configuration
                           string when passed to 'str()'

        'root' and 'config' are mutually exclusive
        """
        if root and config:
            raise RuntimeError(
                "'root' and 'config' arguments are mutually exclusive"
            )
        elif root:
            self._root = root
        elif config:
            (fd, self._cfg_name) = mkstemp(suffix='.cfg')
            try:
                os.write(fd, str(config))
            finally:
                os.close(fd)
            self._root = self._cfg_name
        else:
            # If no configuration specified, use the default file Mock would
            self._root = '/etc/mock/default.cfg'

    def __del__(self):
        try:
            os.remove(self._cfg_name)
        except AttributeError:
            pass

    def get_root_path(self):
        """Get the bash path of the chroot

        :returns: the bash path
        :rtype: str
        """
        mock_cmd = self._mock_cmd('--print-root-path')
        output = check_output(mock_cmd)
        return output.rstrip()

    def chroot(self, *cmd, **more_options):
        """Run a non-interactive command in mock

        All positional arguments are passes as the command to run and its
        argumens
        This method will behave in a similliar manner to
        subprocess.check_output yeilding CalledProcessError on command failure

        Optional named agruments passed via 'more_options' can be as follows:
        :param str cwd: Wrking directory inside the chroot to run in

        :returns: the command output as string
        :rtype: str
        """
        mock_args = ['--chroot']
        if 'cwd' in more_options:
            mock_args.extend(('--cwd', more_options['cwd']))
        if 'resultdir' in more_options:
            mock_args.extend(('--resultdir', more_options['resultdir']))
        mock_args.append('--')
        mock_args.extend(cmd)
        mock_cmd = self._mock_cmd(*mock_args)
        output = check_output(mock_cmd)
        return output

    def clean(self):
        """Clean the mock chroot
        """
        mock_cmd = self._mock_cmd('--clean')
        check_output(mock_cmd)

    def rebuild(self, src_rpm, no_clean=False, define=None, resultdir=None):
        """Build a package from .src.rpm in Mock

        :param str src_rpm: The path to the .src.rpm file to build
        :param bool no_clean: Avoid cleaning the chroot before building
        :param object define: An optional define string for the build process
                              or an Iterable of multiple such define strings.
        :param str resultdir: Override where the build results get placed

        :returns: the command output as string
        :rtype: str
        """
        options = self._setup_mock_build_options(
            no_clean=no_clean, define=define, resultdir=resultdir
        )
        mock_cmd = self._mock_cmd('--rebuild', src_rpm, *options)
        output = check_output(mock_cmd)
        return output

    def buildsrpm(  # pylint: disable=too-many-arguments,bad-continuation
        self, spec, sources, no_clean=False, define=None, resultdir=None
    ):
        """Build a .src.rpm package from sources and spcefile in Mock

        :param str spec: The path to the specfile to build
        :param str sources: The path to the sources directory
        :param bool no_clean: Avoid cleaning the chroot before building
        :param object define: An optional define string for the build process
                              or an Iterable of multiple such define strings.
        :param str resultdir: Override where the build results get placed

        :returns: the command output as string
        :rtype: str
        """
        options = self._setup_mock_build_options(
            no_clean=no_clean, define=define, resultdir=resultdir
        )
        mock_cmd = self._mock_cmd(
            '--buildsrpm',
            '--spec', spec,
            '--sources', sources,
            *options
        )
        output = check_output(mock_cmd)
        return output

    def _mock_cmd(self, *more_args):
        """Create the Mock command line
        """
        cmd = [self.mock_exe(), '--root={}'.format(self._root)]
        cmd.extend(more_args)
        return tuple(cmd)

    @staticmethod
    def _setup_mock_build_options(no_clean=False, define=None, resultdir=None):
        """Setup common options for the various RPM building commands

        :param bool no_clean: Avoid cleaning the chroot before building
        :param object define: An optional define string for the build process
                              or an Iterable of multiple such define strings.
        :param str resultdir: Override where the build results get placed

        :returns: A tuple of Mock command line arguments for the given options
        :rtype: tuple
        """
        options = ()
        if no_clean:
            options += ('--no-clean',)
        if define:
            if isinstance(define, basestring):
                options += ('--define', define)
            elif isinstance(define, Iterable):
                options += reduce(lambda l, x: l + ('--define', x), define, ())
            else:
                raise TypeError(
                    "given 'define' is not an Iterable or a string"
                )
        if resultdir:
            options += ('--resultdir', resultdir)
        return options

    @staticmethod
    def mock_exe():
        """Returns the full path to the Mock executable
        """
        return '/usr/bin/mock'
