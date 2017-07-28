#!/bin/bash

jenkins-jobs --flush-cache --conf jenkins_jobs.ini update -r jobs:foreman-infra $1
