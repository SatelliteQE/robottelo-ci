robottelo-ci
============

Jenkins jobs configuration files to be used to run Robottelo against
Satellite6, SAM and unit-testing of various foreman projects.

Installing
----------

In order to create the jobs using the YAML descriptions from this repository,
first you have to install the requirements:

```sh
pip install -r requirements.txt
```

It will install all required packages. Make sure to have pip installed.

Setup Jenkins Job Builder
-------------------------

After installing the required packages, to setup run `./setup_jjb.sh`.
This script will setup a local copy of foreman-infra from which
macros are used for unit-testing of various projects.

```ini
[job_builder]
keep_descriptions=False
include_path=.:scripts:foreman-infra
recursive=True
allow_duplicates=False
exclude=foreman-infra/yaml/jobs

[jenkins]
user=<jenkin-user>
password=<jenkins-api-key>
url=<jenkins-url>
```

Now update the jenkins credentials section in the `jenkins_jobs.ini` file,
created by the above script.

Generating the jobs
-------------------

It is better to run `./generate_jobs.sh` to test the jobs, before proceeding
ahead.

Creating the jobs
-----------------

When all above steps are completed, you can update the jobs by running the
following command:

```sh
./update-job.sh job-name
```

The above command considers that you are running on this repo root directory
and have placed the config file there.
