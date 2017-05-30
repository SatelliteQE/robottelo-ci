# Install the latest version of betelgeuse.
pip install betelgeuse

betelgeuse test-case \
    --path "${BETELGEUSE_TC_PATH}" \
    --automation-script-format "https://github.com/SatelliteQE/${BETELGEUSE_AUTOMATION_PROJECT}/blob/master/{path}#L{line_number}" \
    "${POLARION_PROJECT}"

