# Grab log files
rm -rf foreman-debug.tar.xz
if [ ! "${SERVER_HOSTNAME}" ]; then
    SERVER_HOSTNAME="$(grep SERVER_HOSTNAME build_env.properties | cut -d= -f2-)"
fi
# Disable error checking, for more information check the related issue
# http://projects.theforeman.org/issues/13442
set +e
ssh -o StrictHostKeyChecking=no "root@${SERVER_HOSTNAME}" foreman-debug -g -q -d "~/foreman-debug"
set -e
scp -o StrictHostKeyChecking=no -r "root@${SERVER_HOSTNAME}:~/foreman-debug.tar.xz" .
