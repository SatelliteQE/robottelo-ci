#!/usr/bin/env python
"""mock_config/koji.py - Pull Mock configuration from Koji
"""
from subprocess import check_output

from .composition import ConfigurationObject

__all__ = ['from_koji']


class from_koji(ConfigurationObject):
    """Mock configration object to pull configuration from Koji
    """
    def __init__(
        self,
        tag=None, target=None, arch='x86_64',
        topurl=None, koji_profile='brew',
    ):
        """Create a koji-based mock(1) configuration object

        :param str tag: The Koji tag to pull configuration from
        :param str target: The Koji build target tag to pull configuration from
        :param str arch: The Koji build architecture
        :param str topurl: An optional Koji packgae mirror URL
        :param str koji_profile: The koji configuration profile to use

        One and only one of 'tag' or 'target' must be specified
        """
        config = self.koji_mock_config(
            tag=tag,
            target=target,
            arch=arch,
            topurl=topurl,
            koji_profile=koji_profile
        )
        super(from_koji, self).__init__(body=config)

    @classmethod
    def koji_mock_config(
        cls,
        tag=None, target=None, arch='x86_64',
        topurl=None, koji_profile='brew',
    ):
        """Get the Mock configuration for the given koji tag/target and arch

        :param str tag: The Koji tag to pull configuration from
        :param str target: The Koji build target to pull configuration from
        :param str arch: The Koji build architecture
        :param str topurl: An optional Koji packgae mirror URL
        :param str koji_profile: The koji configuration profile to use

        One and only one of 'tag' or 'target' must be specified

        :rtype: str
        :returns: The Mock configuration as string
        """
        koji_cmd = [cls.koji_exe(), '--profile', koji_profile]
        if topurl is not None:
            koji_cmd.extend(('--topurl', topurl))
        koji_cmd.extend(('mock_config', '--arch', arch))
        if tag and target:
            raise RuntimeError(
                "'tag' and 'target' arguments are mutually exclusive"
            )
        elif tag:
            koji_cmd.extend(('--tag', tag))
        elif target:
            # Work-around for a BZ#1287185 in koji cli
            tag = cls.koji_tag_for_target(
                target=target,
                koji_profile=koji_profile
            )
            koji_cmd.extend(('--tag', tag))
        else:
            raise RuntimeError(
                "one of 'tag' and 'target' arguments must be specified"
            )
        output = check_output(koji_cmd)
        return output

    @classmethod
    def koji_tag_for_target(cls, target, koji_profile='brew'):
        """Get the build tag for the given Koji target

        :param str target: The Koji build target to get tag for

        :rtype: str
        :returns: The Koji tag as string
        """
        koji_cmd = [
            cls.koji_exe(),
            '--profile', koji_profile,
            'list-targets',
            '--quiet',
            '--name', target,
        ]
        output = check_output(koji_cmd)
        # If the terget is found the output is a single line with 3 whitespace
        # delimited strings in it. The 2nd of which is the build tag name.
        output = output.split()
        if len(output) < 3:
            # Of the output conatins less then 3 strings, we assume the taget
            # was not found
            raise RuntimeError(
                "Could not find target '{}'".format(target)
            )
        # We do leave the possiblity we got more then 3 words in the output
        # unhandled, we just assume the 2nd word is the build tag we need
        return output[1]

    @staticmethod
    def koji_exe():
        # We use the koji executable rather then the koji Python library because
        # the library doesn't contain the configuration file parsing
        # functionality
        return '/usr/bin/koji'
