#!/usr/bin/env python
"""koji_mock.py - Wrapper around Koji-managed mock chroots
"""
from subprocess import check_output

from custom_mock_chroot import CustomMockChroot

__all__ = ['KojiMock']


class KojiMock(CustomMockChroot):
    """Wrapper around Koji-managed mock chroots
    """
    def __init__(
        self, tag=None, target=None, arch='x86_64', koji_profile='brew'
    ):
        """Create a koji-based mock(1) chroot

        :param str tag: The Koji tag to pull configuration from
        :param str target: The Koji build target tag to pull configuration from
        :param str arch: The Koji build architecture
        :param str koji_profile: The koji configuration profile to use

        One and only one of 'tag' or 'target' must be specified
        """
        config = self.koji_mock_config(
            tag=tag,
            target=target,
            arch=arch,
            koji_profile=koji_profile
        )
        super(KojiMock, self).__init__(config=config)

    @classmethod
    def koji_mock_config(
        cls, tag=None, target=None, arch='x86_64', koji_profile='brew'
    ):
        """Get the Mock configuration for the given koji tag/target and arch

        :param str tag: The Koji tag to pull configuration from
        :param str target: The Koji build target tag to pull configuration from
        :param str arch: The Koji build architecture
        :param str koji_profile: The koji configuration profile to use

        One and only one of 'tag' or 'target' must be specified

        :rtype: str
        :returns: The Mock configuration as string
        """
        koji_cmd = [
            cls.koji_exe(),
            '--profile', koji_profile,
            'mock_config',
            '--arch', arch,
        ]
        if tag and target:
            raise RuntimeError(
                "'tag' and 'target' arguments are mutually exclusive"
            )
        elif tag:
            koji_cmd.extend(('--tag', tag))
        elif target:
            koji_cmd.extend(('--target', target))
        else:
            raise RuntimeError(
                "one of 'tag' and 'target' arguments must be specified"
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
