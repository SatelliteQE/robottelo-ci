#!/usr/bin/env groovy

/* Usage:
    branch_selection(satellite_version)
    ex : branch_selection("6.6")
*/
def call(String satellite_version) {
    satellite_version = satellite_version ?: '6.7'
    branch_name=["6.3": "6.3.z","6.4": "6.4.z", "6.5": "6.5.z", "6.6": "6.6.z"]
    def branch = satellite_version in branch_name?branch_name[satellite_version]:"master"
    return branch
}
