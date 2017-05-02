# Install the latest version of betelgeuse.
pip install betelgeuse

betelgeuse test-case \
    --path tests/foreman \
    --automation-script-format "https://github.com/SatelliteQE/robottelo/blob/master/{path}#L{line_number}" \
    "${POLARION_PROJECT}"
