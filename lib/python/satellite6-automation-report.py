"""Command line utility that parses jUnit XML files and provides a report about
skips. ``(\w+) bug #(\d+)`` regex will be used to check the skip message in
order to provide information about open Bugzilla and Redmine bugs.

Usage::

    $ python satellite6_test_skip_report.py results-tier1.xml \
    results-tier2.xml results-tiern.xml
"""
import click
import collections
import itertools
import os
import re

from jinja2 import Environment, FileSystemLoader
from xml.etree import ElementTree


BUG_REGEX = re.compile(r'(\w+) bug #(\d+)')

TRACKERS = {
    'bugzilla': 'https://bugzilla.redhat.com/show_bug.cgi?id={}',
    'redmine': 'http://projects.theforeman.org/issues/{}',
}


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
            if element.tag in ('error', 'failure', 'skipped')
        ]
        # ... no status means the test has passed
        if status:
            data['status'] = status[0].tag
            data.update(status[0].attrib)
        else:
            data['status'] = u'passed'
        result.append(data)
    return result


def get_skips(testcases):
    """Parse skipped testcases messages using the ``BUG_REGEX`` and return the
    matched groups.
    """
    skips = []
    for testcase in testcases:
        if testcase['status'] == 'skipped':
            match = BUG_REGEX.search(testcase['message'])
            if match is not None:
                skips.append(match.groups())
    return skips


def get_failed_tests(testcases):
    """Returns list of all failed test cases"""
    return [test for test in testcases if test['status'] == 'failure']


def get_issue_url(tracker, bug_id):
    """Returns the absolute URL for an issue

    """

    return TRACKERS[tracker].format(bug_id)


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


def sort_issues_by_count(bugs):
    """Sorts all test cases by the number"""

    sorted_bugs = {}

    for key, value in bugs.items():
        sorted_bugs[key] = sorted(
            value.items(),
            key=lambda info: (info[1], info[0]),
            reverse=True
        )
    return sorted_bugs


def print_skip_info(skip_bugs):
    """Print information about the skips ordering the results by the highest
    count of tests skipped and then by bug highest bug id.
    """
    title = 'Tests skipped due to bugs'
    click.echo('{0}\n{1}\n'.format(title, '=' * len(title)))
    bugs = sort_issues_by_count(skip_bugs)

    for bug_id, count in bugs['bugzilla']:
        click.echo(' {:2} due to BZ #{} - {}'.format(
            count, bug_id, get_issue_url('bugzilla', bug_id)))
    for bug_id, count in bugs['redmine']:
        click.echo(' {:2} due to Redmine issue #{} - {}'.format(
            count, bug_id, get_issue_url('redmine', bug_id)))


def print_html_summary(results):
    """Prints a summary of the results in HTML format"""

    failures = get_failed_tests(results)
    skips = sort_issues_by_count(get_skip_bugs(get_skips(results)))
    summary = collections.Counter(
        [result['status'] for result in results])

    context = {
        'passed': summary.get('passed', 0),
        'skipped': summary.get('skipped', 0),
        'failure': summary.get('failure', 0),
        'error': summary.get('error', 0),
        'total': sum(summary.values()),
        'failed_tests': failures,
        'skipped_tests': skips,
    }

    jinjaenv = Environment(loader=FileSystemLoader(
        os.path.join(os.path.dirname(__file__), 'templates')))
    template = jinjaenv.get_template('report.html')
    click.echo(template.render(context))


def print_text_summary(results):
    """Print a summary of the results, how many passes, skips, failures
    and errors."""
    title = 'Summary'
    click.echo('{0}\n{1}\n'.format(title, '=' * len(title)))
    summary = collections.Counter(
        [result['status'] for result in results])
    click.echo('\n'.join(
        ['{0}: {1}'.format(*status) for status in sorted(summary.items())]
    ).title())
    click.echo('Total: {0}'.format(sum(summary.values())))
    click.echo()
    print_skip_info(get_skip_bugs(get_skips(results)))


@click.command()
@click.option(
    '-o', '--output',
    type=click.Choice(['text', 'html']),
    default='text'
)
@click.argument('junit_result', nargs=-1, type=click.Path(exists=True))
def cli(output, junit_result):
    results = list(itertools.chain(
        *[parse_junit(result) for result in junit_result]))
    if output == 'text':
        print_text_summary(results)
    else:
        print_html_summary(results)


if __name__ == "__main__":
    cli()
