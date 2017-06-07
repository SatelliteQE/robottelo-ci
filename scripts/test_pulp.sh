#! /bin/bash -xe

# Required 2.7 to align with what we currently are using.
REPO_URL='https://repos.fedorapeople.org/repos/pulp/pulp/testing/automation/2.8/testing/7/x86_64/'

cat > pulp-deps.repo<< EndOfMessage
[pulp-deps]
name=pulp-deps
baseurl=$REPO_URL
enabled=1
gpgcheck=0
EndOfMessage

sudo mv pulp-deps.rep /etc/yum.repos.d/

sudo yum -y install python-mongoengine qpid-tools  python-rhsm --nogpgcheck
export WORKON_HOME=$HOME/.virtualenvs
export PIP_VIRTUALENV_BASE=$WORKON_HOME
export VIRTUALENV_USE_DISTRIBUTE=true
export PIP_RESPECT_VIRTUALENV=true
source /usr/bin/virtualenvwrapper.sh
pip install -r $WORKSPACE/pulp/test_requirements.txt

mkvirtualenv --system-site-packages test
pip install --upgrade six
sudo yum -y install python-django  --nogpgcheck

rpmspec -q --queryformat '[%{REQUIRENEVRS}\n]' *.spec | grep -v "/.*" | grep -v "python-pulp.* " | grep -v "pulp.*" | uniq | xargs -d "\n" sudo dnf -y install --nogpgcheck python-pulp-devel

for setup in `find . -name setup.py`; do
		pushd `dirname $setup`;
		sudo python setup.py develop;
		popd;
done;

sudo python ./pulp-dev.py -I
cd $WORKSPACE/pulp
export PYTHGONUNBUFFERED=1
python ./run-tests.py
