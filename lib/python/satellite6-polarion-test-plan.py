#!/usr/bin/python
"""This wrapper around pylarion that creates test plan in Polarion.

Re-implementation of `betelgeuse test-plan` subcommand. betelgeuse >1.0
deprecated `test-plan` without providing alternative, and we require
it in our process.

Usage::

    $ python satellite6-polarion-test-case-inject.py
"""
import argparse
import json
import logging
import re
import time

from pylarion.plan import Plan

INVALID_CHARS_REGEX = re.compile(r'[\\/.:"<>|~!@#$?%^&\'*()+`,=]')


def load_custom_fields(custom_fields_opt):
    """Load the custom fields from the --custom-fields option.

    The --custom-fields option can receive either a string on the format
    ``key=value`` or a JSON string ``{"key":"value"}``, which will be loaded
    into a dictionary.

    If the value passed is not in JSON or key=value format it will be ignored.

    :param custom_fields_opt: A tuple of --custom-fields option.
    """
    custom_fields = {}
    if not custom_fields_opt:
        return custom_fields
    for item in custom_fields_opt:
        if item.startswith('{'):
            custom_fields.update(json.loads(item))
        elif '=' in item:
            key, value = item.split('=', 1)
            custom_fields[key.strip()] = value.strip()
    return custom_fields


def create_test_plan(name, plan_type, parent_name, custom_fields, project):
    """Create a new test plan in Polarion."""
    # Sanitize names to valid values for IDs...
    custom_fields = load_custom_fields(custom_fields)
    plan_id = re.sub(INVALID_CHARS_REGEX, '_', name).replace(' ', '_')
    parent_plan_id = (
        re.sub(INVALID_CHARS_REGEX, '_', parent_name).replace(' ', '_')
        if parent_name else parent_name
    )

    # Check if the test plan already exists
    result = Plan.search(f'id:{plan_id}')
    if len(result) == 1:
        logging.info(f'Found Test Plan {name}.')
        test_plan = result[0]
    else:
        # Unlike Testrun, Pylarion currently does not accept **kwargs in
        # Plan.create() so the custom fields need to be updated after the
        # creation
        test_plan = Plan.create(
            parent_id=parent_plan_id,
            plan_id=plan_id,
            plan_name=name,
            project_id=project,
            template_id=plan_type
        )
        logging.info(f'Created new Test Plan {name} with ID {plan_id}.')

    update = False
    for field, value in custom_fields.items():
        if getattr(test_plan, field) != value:
            setattr(test_plan, field, value)
            logging.info(
                f'Test Plan {test_plan.name} updated with {field}={value}.'
            )
            update = True
    if update:
        test_plan.update()


def parse_args():
    parser = argparse.ArgumentParser(description='Re-implementation of "betelgeuse test-plan".')
    parser.add_argument('--name', default=f'test-plan-{time.time()}',
                        help='Name for new Test Plan.')
    parser.add_argument('--plan-type', default='release',
                        help='Test Plan type; one of "release" or "iteration"')
    parser.add_argument('--parent-name',
                        help='Name of parent Test Plan to link to.')
    parser.add_argument('--custom-fields', action='append',
                        help='Custom fields for the test plan.')
    parser.add_argument('project', nargs='+',
                        help='Name of Polarion project to use.')

    return parser.parse_args()


if __name__ == '__main__':
    args = parse_args()

    logging.basicConfig(level=logging.INFO)

    if args.plan_type not in ('release', 'iteration'):
        raise SystemExit('--plan-type must be one of "release", "iteration"')

    create_test_plan(args.name, args.plan_type, args.parent_name,
                     args.custom_fields, args.project)
