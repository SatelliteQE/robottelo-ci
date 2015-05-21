help:
	@echo "Please use \`make <target>' where <target> is one of:"
	@echo "  help   to show this message"
	@echo "  setup  to update jobs and install missing plugins"

setup:
	jenkins-jobs --conf jenkins_jobs.ini update jobs
	scripts/manage_plugins.py install $$(cat plugins.txt)

.PHONY: help setup
