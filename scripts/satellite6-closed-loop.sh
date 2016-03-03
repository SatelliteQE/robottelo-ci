# Install python dependencies
echo "Installing python dependencies.."
pip install -r requirements.txt

echo "Creating user config.."
cp user.ini.sample ~/.config/user.ini
sed -i "s/^username.*/username=$BUGZILLA_USER/" ~/.config/user.ini
sed -i "s/^password.*/password=$BUGZILLA_PASSWORD/" ~/.config/user.ini

echo "Creating bz config.."
cp bz.ini.sample bz.ini

echo "Setting changed date to yesterday and setting YY/MM/DD format.."
sed -i "s/^v3.*/v3=$(date -d "-1 days" +%Y-%m-%d)/" bz.ini

echo "Running closed loop script.."
python run.py --run=update
