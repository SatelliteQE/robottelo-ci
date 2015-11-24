#!/usr/bin/env python
# mock_brew.py - Emulate brew using mock
#
import sys
from koji_mock import KojiMock


def main():
    brew_tag = 'ruby193-satellite-6.1.0-rhel-7-build'

    mock = KojiMock(tag=brew_tag)
    out = mock.rebuild(src_rpm=sys.argv[1], define="scl ruby193")
    print out

if __name__ == '__main__':
    main()
