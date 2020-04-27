#!/usr/bin/env groovy

/* Usage:
    branch_selection(satellite_version)
    ex : branch_selection("6.6")
*/
def call(String satellite_version='6.8') {
    branch_map=[
        "6.3": "6.3.z",
        "6.4": "6.4.z",
        "6.5": "6.5.z",
        "6.6": "6.6.z",
        "6.7": "6.7.z",
    ]
    def branch = satellite_version in branch_map ? branch_map[satellite_version] : "master"
    return branch
}
