# Setting Prerequisites
pip install -r requirements.txt


# Sets up the satellite, capsule and clients on rhevm or personal boxes before upgrading
fab -u root setup_products_for_upgrade:'longrun',"{os}"

# Longrun to run upgrade on Satellite, capsule and clients
fab -u root product_upgrade:'longrun'
