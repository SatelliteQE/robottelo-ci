# Grab log files
rm -rf foreman-debug.tar.xz
if [ ! "${SERVER_HOSTNAME}" ]; then
    SERVER_HOSTNAME="$(grep SERVER_HOSTNAME build_env.properties | cut -d= -f2-)"
fi
if [ ! "${SATELLITE_VERSION}" ]; then
    SATELLITE_VERSION="$(grep SATELLITE_VERSION build_env.properties | cut -d= -f2-)"
fi
# Disable error checking, for more information check the related issue
# http://projects.theforeman.org/issues/13442
set +e
# option have changed from m to s  in sat6.3
if [[ ${SATELLITE_VERSION} =~ 6\.[0-2]$ ]]; then
    ssh -o StrictHostKeyChecking=no "root@${SERVER_HOSTNAME}" foreman-debug -m 0 -q -d "~/foreman-debug"
else
    ssh -o StrictHostKeyChecking=no "root@${SERVER_HOSTNAME}" foreman-debug -s 0 -q -d "~/foreman-debug"
fi
set -e
scp -o StrictHostKeyChecking=no -r "root@${SERVER_HOSTNAME}:~/foreman-debug.tar.xz" .
