#!/usr/bin/env python
"""mocktito.py - Make tito do stuff with Mock
"""
from __future__ import print_function

import os
from sys import stderr, exit
from glob import glob
import argparse
import json
from glob import fnmatch

from tito.common import debug, chdir, find_git_root, tito_config_dir
from tito.compat import RawConfigParser, getoutput
from tito.release import DistGitReleaser as TitoDistGitReleaser
from tito.cli import RELEASERS_CONF_FILENAME

from mock_chroot import MockChroot
import mock_config


# Configuration option names
EXTRA_YUM_REPOS = 'extra_yum_repos'
EXTRA_YUM_REPOS_FOR = 'extra_yum_repos_for'


class DistGitReleaser(TitoDistGitReleaser):
    """A releaser class for tito to use mock when tito would otherwise use
    rhpkg
    """
    def _git_release(self):
        getoutput("mkdir -p %s" % self.package_workdir)

        # Mead builds need to be in the git_root.  Other builders are agnostic.
        with chdir(self.git_root):
            self.builder.tgz()

        if self.test:
            self.builder._setup_test_specfile()

        debug("Searching for source files to build")
        files_to_copy = self._list_files_to_copy()
        self._sync_files(files_to_copy, self.package_workdir)

        debug("would build with specfile: {0} and sources at: {1}".format(
            self.builder.spec_file, self.package_workdir
        ))
        debug("build branches: {0}".format(self.git_branches))
        for branch in self.git_branches:
            self.build_in_mock(branch)

    def _list_files_to_copy(self):
        """Returns a list of files to copy to the directory in which rpmbuild
        will look for its sources
        """
        return super(DistGitReleaser, self)._list_files_to_copy() + \
            self.builder.sources

    def build_in_mock(self, branch):
        """Build the sources in self.package_workdir as rhpkg woulb build them
        if they were pushed to the specified distgit branch

        The following environment variables can affect how this method works:
        - KOJI_TOPURL: Specifies a Koji package mirror to use
        - KOJI_PROFILE: Specifies which Koji configuration profile to use
                        (defaults to 'brew')
        """
        print("Building branch '{0}' in Mock".format(branch))
        out_dir = os.path.join(
            self.builder.rpmbuild_basedir,
            '{0}-{1}'.format(self.project_name, self.builder.build_version),
            branch
        )
        getoutput("mkdir -p %s" % out_dir)
        print('build output will be written to {0}'.format(out_dir))
        # Logic taken from pyrpkg sources:
        target = '%s-candidate' % branch
        mock_conf = mock_config.compose(
            mock_config.from_koji(
                target=target,
                topurl=os.environ.get('KOJI_TOPURL', None),
                koji_profile=os.environ.get('KOJI_PROFILE', 'brew'),
            ),
            mock_config.to['resultdir'].set(out_dir),
            mock_config.to['root_cache_enable'].set(True),
            mock_config.to['yum_cache_enable'].set(True)
        )
        extra_yum_config = self._build_extra_yum_config(branch)
        if extra_yum_config:
            print('Injecting extra yum configuration to Mock')
            mock_conf.append(mock_config.to['yum.conf'].add(extra_yum_config))
        debug('Dumping mock configuration')
        debug(str(mock_conf))
        mock = MockChroot(config=mock_conf)
        print('Building SRPM in Mock')
        mock.buildsrpm(
            spec=self.builder.spec_file,
            sources=self.package_workdir,
        )
        srpms = glob('{0}/*.src.rpm'.format(out_dir))
        if len(srpms) == 0:
            raise RuntimeError('no srpms found in {0}'.format(out_dir))
        elif len(srpms) > 1:
            raise RuntimeError('multiple srpms found in {0}'.format(out_dir))
        else:
            srpm = srpms[0]
        print('Building RPM in Mock')
        mock.rebuild(src_rpm=srpm, no_clean=True)

    def _build_extra_yum_config(self, branch):
        """Build extra yum configuration for a branch's mock environment
        according to values in the releasers configuration file
        """
        debug('looking for extra yum configuration')
        yum_config = []
        if self.releaser_config.has_option(self.target, EXTRA_YUM_REPOS):
            debug('Appending extra yum configuration')
            yum_config.append(
                self.releaser_config.get(self.target, EXTRA_YUM_REPOS)
            )
        if self.releaser_config.has_option(self.target, EXTRA_YUM_REPOS_FOR):
            debug('Adding branch-specific extra yum configuraition')
            for pattern, yum_conf in json.loads(
                self.releaser_config.get(self.target, EXTRA_YUM_REPOS_FOR)
            ):
                debug(
                    "  matching extra repos pattern '{0}' against '{1}'"
                    .format(pattern, branch)
                )
                if fnmatch.fnmatch(branch, pattern):
                    debug(
                        "  found extra yum configuration for '{0}'"
                        .format(branch)
                    )
                    yum_config.append(yum_conf)
        return '\n'.join(yum_config)


def main():
    """The main function allows converting a git repo the is stup for "normal"
    tito to use classed defined here instead
    """
    options = parse_args()
    rel_eng_dir = os.path.join(find_git_root(), tito_config_dir())
    releasers_filename = os.path.join(rel_eng_dir, RELEASERS_CONF_FILENAME)
    releasers_config = RawConfigParser()
    releasers_config.read(releasers_filename)
    print("Read configuration file: {0}".format(releasers_filename))
    for section in releasers_config.sections():
        print("  found section: {0}".format(section))
        if releasers_config.has_option(section, 'releaser'):
            old_releaser = releasers_config.get(section, 'releaser')
            print("  releaser is set to: {0}".format(old_releaser))
            if old_releaser.startswith('tito.release.'):
                new_releaser = old_releaser.replace(
                    'tito.release.', 'mocktito.', 1
                )
                print("  replaced with: {0}".format(new_releaser))
                releasers_config.set(section, 'releaser', new_releaser)
            elif old_releaser.startswith('mocktito.'):
                pass
            else:
                stderr.write("Found a releaser type I don't know, aborting\n")
                exit(1)
            if options.extra_yum_repos:
                print("  adding extra yum repos")
                releasers_config.set(
                    section,
                    EXTRA_YUM_REPOS,
                    "\n".join(options.extra_yum_repos)
                )
            if options.extra_yum_repos_for:
                print("  adding extra yum repos for branches")
                releasers_config.set(
                    section,
                    EXTRA_YUM_REPOS_FOR,
                    json.dumps(options.extra_yum_repos_for)
                )
    with open(releasers_filename, 'w') as rfp:
        releasers_config.write(rfp)


def parse_args():
    parser = argparse.ArgumentParser(
        description="Convert a tito using repo to a mocktito using one"
    )
    parser.add_argument(
        '--extra-yum-repos',
        metavar='YUM_CONF',
        help='Inject extra yum repo configuration into the mock environment.'
        + ' This argument can be repeated to add multipile configuration'
        + ' strings.',
        action='append'
    )
    parser.add_argument(
        '--extra-yum-repos-for',
        nargs=2,
        metavar=('TARGET_PATTERN', 'YUM_CONF'),
        help='Inject extra yum repo configuration into the mock environment'
        + ' that builds the distgit branch that matches the Glob patterns given'
        + ' in TARGET_PATTERN. This argument can be repeated to configure'
        + ' environments for different branches.',
        action='append'
    )
    return parser.parse_args()

if __name__ == '__main__':
    main()
