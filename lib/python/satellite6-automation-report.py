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
import re

from xml.etree import ElementTree


BUG_REGEX = re.compile(r'(\w+) bug #(\d+)')
BUGZILLA_BUG_URL = 'https://bugzilla.redhat.com/show_bug.cgi?id={}'
REDMINE_BUG_URL = 'http://projects.theforeman.org/issues/{}'


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
        match = BUG_REGEX.search(testcase['message'])
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
    """Print information about the skips ordering the results by the highest
    count of tests skipped and then by bug highest bug id.
    """
    title = 'Tests skipped due to bugs'
    click.echo('{0}\n{1}\n'.format(title, '=' * len(title)))
    redmine_bugs = sorted(
        skip_bugs['redmine'].items(),
        key=lambda info: (info[1], info[0]),
        reverse=True
    )
    bugzilla_bugs = sorted(
        skip_bugs['bugzilla'].items(),
        key=lambda info: (info[1], info[0]),
        reverse=True
    )
    for bug_id, count in bugzilla_bugs:
        click.echo(' {:2} due to BZ #{} - {}'.format(
            count, bug_id, BUGZILLA_BUG_URL.format(bug_id)))
    for bug_id, count in redmine_bugs:
        click.echo(' {:2} due to Redmine issue #{} - {}'.format(
            count, bug_id, REDMINE_BUG_URL.format(bug_id)))


def print_summary(results):
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


@click.command()
@click.argument('junit_result', nargs=-1, type=click.Path(exists=True))
def cli(junit_result):
    results = list(itertools.chain(
        *[parse_junit(result) for result in junit_result]))
    print_summary(results)
    click.echo()
    print_skip_info(get_skip_bugs(get_skips([
        testcase for testcase in results
        if testcase['status'] == 'skipped'
    ])))


if __name__ == "__main__":
    cli()
