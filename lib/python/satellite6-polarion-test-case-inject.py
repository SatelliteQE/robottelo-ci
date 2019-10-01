#!/usr/bin/python

"""Script that parses robottelo ids for each test case from all branches
and inject satellite6 versions according to branches in polarion-test-case.xml

Usage::

    $ python satellite6-polarion-test-case-inject.py
"""
from pathlib import Path

import os
import subprocess
import re
import xml.etree.ElementTree as ET
import yaml


def get_repo(url, tmp_path):
    os.system("git clone {0} {1}".format(url, tmp_path))


def get_all_branches(path):
    cmd = ['git', '--git-dir', path, 'branch', '-r']
    out = subprocess.check_output(cmd, stderr=subprocess.STDOUT)
    return out


def get_product_versions(repo, test_path, tmp_path, xml_file_path):
    # Get all branches of cloned repo
    get_repo(url=repo, tmp_path=tmp_path)
    branches = get_all_branches(tmp_path + "/.git")
    satellite_stable_branches = re.findall(r"origin/6.*", branches.decode('utf-8'))

    satellite_stable_branches = [
        name.replace("origin/", " ").strip() for name in satellite_stable_branches]
    satellite_stable_branches.append('master')
    previous_directory = os.getcwd()
    os.chdir(tmp_path)

    # Fetch branches of cloned repo
    for branch_name in satellite_stable_branches:
        os.system("git fetch origin {}".format(branch_name))

    # Get all ids from all branches in dict where key is branch name and value is test case id
    dict = {}
    for branch in satellite_stable_branches:
        os.system("git checkout {}".format(branch))
        ids = []
        result = list(Path(test_path).rglob("*.[p][y]"))
        for mod in result:
            with open(str(mod), 'r') as f:
                content = f.readlines()
                for line in content:
                    if ':id:' in line.lower():
                        ids.append(line.split(': ')[1].strip())
        dict[branch] = ids

    # Get all ids in set to make them unique
    all_robottelo_ids = list(set().union(*dict.values()))

    # Create dict of test case id as key and product versions in which it is valid as value
    dict1 = {}
    for tc_id in all_robottelo_ids:
        versions = []
        for branches_name in satellite_stable_branches:
            if tc_id in dict[branches_name]:
                if branches_name == "master":
                    # Replace master with respective product version it points to
                    master_branch_sat_version = float(max([x.replace(
                        ".z", "") for x in satellite_stable_branches if x != "master"])) + 0.1
                    versions.append(branches_name.replace(
                        "master", str(master_branch_sat_version)))
                else:
                    versions.append(branches_name.replace(".z", ""))
        dict1[tc_id] = ", ".join(versions)

    os.chdir(previous_directory)

    # Insert product versions in polarion test case file
    tree = ET.parse(xml_file_path)
    root = tree.getroot()
    testcases = root.findall('testcase')
    for testcase in testcases:
        custom_fields = testcase.findall('custom-fields')
        if testcase.get('id') in dict1.keys():
            attrib = {'id': 'satelliteversions', 'content': dict1[testcase.get('id')]}
            ET.SubElement(custom_fields[0], 'custom-field', attrib)
    tree.write(xml_file_path)


def inject_component_owners(component_owners_yaml, xml_file_path):
    component_owners = yaml.load(open(component_owners_yaml), Loader=yaml.FullLoader)
    component_owners = {_['slug']: _ for _ in component_owners.values()}
    # Insert primary and secondary owners in polarion test case file
    tree = ET.parse(xml_file_path)
    root = tree.getroot()
    testcases = root.findall('testcase')
    for testcase in testcases:
        custom_fields = testcase.findall('custom-fields')
        for child in custom_fields[0].getchildren():
            if child.get('id') == 'casecomponent':
                component_name = child.get('content').lower()
                if component_name in component_owners.keys():
                    attrib1 = {
                        'id': 'primary',
                        'content': component_owners[component_name]['primary']
                    }
                    attrib2 = {
                        'id': 'secondary',
                        'content': component_owners[component_name]['secondary']
                    }
                    ET.SubElement(custom_fields[0], 'custom-field', attrib1)
                    ET.SubElement(custom_fields[0], 'custom-field', attrib2)
    tree.write(xml_file_path)


get_product_versions(
    repo="https://github.com/SatelliteQE/robottelo",
    test_path="tests/foreman/",
    tmp_path="tmp/robottelo/",
    xml_file_path="polarion-test-cases.xml"
)

get_product_versions(
    repo="https://github.com/SatelliteQE/satellite6-upgrade",
    test_path="upgrade_tests/test_existance_relations/",
    tmp_path="tmp/satellite6-upgrade/",
    xml_file_path="polarion-test-cases.xml"
)

inject_component_owners(
    component_owners_yaml="satellite6-reporting/component-owners/component-owners-map.yaml",
    xml_file_path="polarion-test-cases.xml"
)
