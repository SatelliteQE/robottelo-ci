#!/usr/bin/env python
# -*- encoding: utf-8 -*-
"""Parses and generates reports from Robottelo test runs."""

from __future__ import print_function
from collections import Counter
from optparse import OptionParser
from xml.etree import ElementTree

import re
import sys

BUGZILLA_BUG_URL = 'https://bugzilla.redhat.com/show_bug.cgi?id={}'
REDMINE_BUG_URL = 'http://projects.theforeman.org/issues/{}'
REGEX = re.compile(
    r'Skipping test due to open (\w+) bug #(\d+)')
JUNIT_TEST_STATUS = ['error', 'failure', 'skipped']


def get_skips(results):
    """Grep the log file looking for skips entries and returns a list with
    the matched regex groups.

    """
    skips = []
    for test in results:
        if test['status'] == u'skipped':
            match = REGEX.search(test['message'])
            if match is not None:
                skips.append(match.groups())
    return skips


def get_skip_bugs(skips):
    """Parse the skips and return a dict with Bugzilla and Redmine bugs
    count.

    """
    skip_bugs = {
        'bugzilla': {},
        'redmine': {},
    }
    for skip in skips:
        bug_dict = skip_bugs[skip[0].lower()]
        bug_id = int(skip[1])
        if bug_id not in bug_dict:
            bug_dict[bug_id] = 0
        bug_dict[bug_id] += 1
    return skip_bugs


def print_skip_info(skip_bugs):
    """Prints information about the skips ordering the results by the
    highest count of tests skipped.

    """
    redmine_bugs = skip_bugs['redmine'].items()
    redmine_bugs.sort(key=lambda info: info[1], reverse=True)
    bugzilla_bugs = skip_bugs['bugzilla'].items()
    bugzilla_bugs.sort(key=lambda info: info[1], reverse=True)

    for bug_id, count in bugzilla_bugs:
        print(' {:2} due to BZ #{} - {}'.format(
            count, bug_id, BUGZILLA_BUG_URL.format(bug_id)))
    for bug_id, count in redmine_bugs:
        print(' {:2} due to Redmine issue #{} - {}'.format(
            count, bug_id, REDMINE_BUG_URL.format(bug_id)))


def parse_junit(path):
    """Parse a jUnit XML file.

    Given the following jUnit file::

        <testsuite tests="3">
            <testcase classname="foo1" name="test_passed"></testcase>
            <testcase classname="foo2" name="test_skipped">
                <skipped message="...">...</skipped>
            </testcase>
            <testcase classname="foo3" name="test_failure">
                <failure type="Type" message="...">...</failure>
            </testcase>
            <testcase classname="foo3" name="test_error">
                <error type="ExceptionName" message="...">...</error>
            </testcase>
        </testsuite>

    The return will be::

        [
            {'classname': 'foo1', 'name': 'test_passed', 'status': 'passed'},
            {'classname': 'foo2', 'message': '...', 'name': 'test_skipped',
             'status': 'skipped'},
            {'classname': 'foo3', 'name': 'test_failure', 'status': 'passed'},
            {'classname': 'foo3', 'name': 'test_error', 'status': 'passed'}
        ]

    :param str path: Path to the jUnit XML file.
    :return: A list of dicts with information about every test
        case result.
    """
    root = ElementTree.parse(path).getroot()
    result = []
    for testcase in root.iter('testcase'):
        data = testcase.attrib
        # Check if the test has passed or else...
        status = [
            element for element in list(testcase)
            if element.tag in JUNIT_TEST_STATUS
        ]
        # ... no status means the test has passed
        if status:
            data['status'] = status[0].tag
            data.update(status[0].attrib)
        else:
            data['status'] = u'passed'

        result.append(data)
    return result


def parse_test_results(test_results):
    """Returns the summary of test results by their status.

    :param test_results: A list of dicts with information about
        test results, such as those reported in a jUnit file.
    :return: A dictionary containing a summary for all test results
        provided by the ``test_results`` parameter, broken down by their
        status.
    """
    return Counter([test['status'] for test in test_results])


def report(label, path):
    """Generates a report containing information from an automated test run."""

    all_tests = parse_junit(path)
    test_stats = parse_test_results(all_tests)

    title = "Test Results for {0}".format(label)
    print(title)
    print("=" * len(title))
    print()
    print(
        "Passed: {passed}  "
        "Skipped: {skipped}  "
        "Failed: {failure} "
        " Error: {error}".format(**test_stats)
    )
    print()
    print("The following tests are currently blocked:")
    print()
    print_skip_info(get_skip_bugs(get_skips(all_tests)))


if __name__ == '__main__':

    description = "Generates automation reports from Robottelo test runs."

    usage = "Usage: %prog [options]"
    epilog = "Constructive comments and feedback can be sent to Og Maciel"
    " <omaciel at redhat dot com>."
    version = "%prog version 0.1"

    parser = OptionParser(
        usage=usage, description=description, epilog=epilog, version=version)

    parser.add_option('-l', '--label', dest='label', default=u'Report',
                      help="What label to use for your report", type=str)
    parser.add_option('--path', dest='path',
                      help="Path to a JUNIT XML file.", type=str)

    (options, args) = parser.parse_args()

    if not options.path:
        parser.print_help()
        sys.exit(-1)

    report(options.label, options.path)
