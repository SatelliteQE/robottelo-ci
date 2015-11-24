#!/usr/bin/env python
# mock_brew.py - Emulate brew using mock
#
import sys
import argparse

from koji_mock import KojiMock


def main():
    brew_tag = 'ruby193-satellite-6.1.0-rhel-7-build'
    args = parse_args()

    mock = KojiMock(tag=brew_tag)
    out = mock.rebuild(
        src_rpm=args.srpm,
        define="scl ruby193",
        resultdir=args.resultdir,
    )
    print out


def parse_args():
    """Parse arguments passed to this program

    :returns: The parsed arguments
    :rtype: argparse.Namespace
    """
    parser = argparse.ArgumentParser()
    parser.add_argument('srpm', help='Path to the .src.rpm file to buid')
    parser.add_argument('--resultdir', help='Where to place build results')
    return parser.parse_args()

if __name__ == '__main__':
    main()
