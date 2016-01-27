git clone ${PYLARION_REPO_URL}

# Make pylarion ready to be installed on a virtual environment
cd pylarion
cp setup.py setup.py.old
head -n -3 setup.py.old > setup.py
sed -i "s|'/etc', ||" setup.py

# Install pylarion and its dependencies
pip install -r requirements.txt
pip install .
cd ..

# Install testimony from master
git clone https://github.com/SatelliteQE/testimony.git
cd testimony
pip install .
cd ..

pip install betelgeuse

cat > .pylarion <<EOF
[webservice]
url=${POLARION_URL}
user=${POLARION_USER}
password=${POLARION_PASSWORD}
default_project=${POLARION_DEFAULT_PROJECT}
svn_repo=i${POLARION_SVN_REPO}
EOF
