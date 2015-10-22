#!/bin/bash

jenkins-jobs --conf jenkins_jobs.ini  -l debug test -r -o /tmp/jobs .:foreman-infra
