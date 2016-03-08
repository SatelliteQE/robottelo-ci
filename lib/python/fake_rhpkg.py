#!/usr/bin/env python
""" fake_rhpkg.py - Wrap rhpkg to make it run 'mockbuild' when 'build' is
called and never push
"""
import argparse


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('command', help='rhpkg commad to run')
    parser.parse_args()
    pass


if __name__ == '__main__':
    main()
