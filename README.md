robottelo-ci
============

Jenkins jobs configuration files to be used to run Robottelo against Satellite
6 or SAM.

Installing
----------

In order to create the jobs using the YAML descriptions from this repository,
first you have to install the requirements:

```sh
pip install -r requirements.txt
```

It will install all required packages. Make sure to have pip installed.

Sample jenkins_jobs.ini configuration
-------------------------------------

After installing the required packages, you have to create a `jenkins_jobs.ini`
config file:

```ini
[job_builder]
keep_descriptions=False
include_path=.:scripts
recursive=True
allow_duplicates=False

[jenkins]
user=<jenkin-user>
password=<jenkins-api-key>
url=<jenkins-url>
```

Or you can just run `cp jenkins_jobs.ini.sample jenkins_jobs.ini` and change
the jenkins credentials section.

Creating the jobs
-----------------

When all above steps are completed, you can create the jobs by running the
following command:

```sh
jenkins-jobs --conf jenkins_jobs.ini update jobs
```

The above command considers that you are running on this repo root directory
and have placed the config file there.
