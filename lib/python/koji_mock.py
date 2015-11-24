#!/usr/bin/env python
"""koji_mock.py - Wrapper around Koji-managed mock chroots
"""
from subprocess import check_output

from custom_mock_chroot import CustomMockChroot

__all__ = ['KojiMock']


class KojiMock(CustomMockChroot):
    """Wrapper around Koji-managed mock chroots
    """
    def __init__(self, tag, arch='x86_64', koji_profile='brew'):
        config = self.koji_mock_config(
            tag=tag,
            arch=arch,
            koji_profile=koji_profile
        )
        super(KojiMock, self).__init__(config=config)

    @classmethod
    def koji_mock_config(cls, tag, arch='x86_64', koji_profile='brew'):
        """Get the Mock configuration for the given koji tag and arch
        """
        koji_cmd = (
            cls.koji_exe(),
            '--profile', koji_profile,
            'mock_config',
            '--tag', tag,
            '--arch', arch,
        )
        output = check_output(koji_cmd)
        return output

    @classmethod
    def koji_exe(cls):
        # We use the koji executable rather then the koji Python library because
        # the library doesn't contain the configuration file parsing
        # functionality
        return '/usr/bin/koji'

if __name__ == '__main__':
    print KojiMock.koji_mock_config(tag='rhevm-3.5-rhel-6-mead-build')
