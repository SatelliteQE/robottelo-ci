#!/usr/bin/env groovy

/* Usage:
    branch_selection(satellite_version)
    ex : branch_selection("6.6")
*/
def call(String satellite_version='6.9') {
    branch_map=[
        "6.6": "6.6.z",
        "6.7": "6.7.z",
        "6.8": "6.8.z",
    ]
    def branch = satellite_version in branch_map ? branch_map[satellite_version] : "6.9.freeze"
    return branch
}
