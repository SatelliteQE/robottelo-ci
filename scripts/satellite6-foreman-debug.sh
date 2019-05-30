ssh_opts='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null'

# Grab log files
rm -rf foreman-debug.tar.xz
if [ ! "${SERVER_HOSTNAME}" ]; then
    SERVER_HOSTNAME="$(grep SERVER_HOSTNAME build_env.properties | cut -d= -f2-)"
fi
# Disable error checking, for more information check the related issue
# http://projects.theforeman.org/issues/13442
set +e
# option have changed from -m to -s in sat6.3
ssh $ssh_opts "root@${SERVER_HOSTNAME}" foreman-debug -s 0 -q -d "~/foreman-debug"
set -e
scp $ssh_opts -r "root@${SERVER_HOSTNAME}:~/foreman-debug.tar.xz" .
