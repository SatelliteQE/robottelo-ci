#!/bin/bash

jenkins-jobs --conf jenkins_jobs.ini update -r jobs:foreman-infra $1
