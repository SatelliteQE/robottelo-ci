# Grab log files
rm -rf foreman-debug.tar.xz

# Disable error checking, for more information check the related issue
# http://projects.theforeman.org/issues/13442
set +e
ssh root@${PROVISIONING_HOST} foreman-debug -g -q -d ~/foreman-debug
set -e

scp -r root@${PROVISIONING_HOST}:~/foreman-debug/foreman-debug.tar.xz .
