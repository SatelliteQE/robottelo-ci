#!/bin/bash

jenkins-jobs --conf jenkins_jobs.ini update -r .:foreman-infra $1
