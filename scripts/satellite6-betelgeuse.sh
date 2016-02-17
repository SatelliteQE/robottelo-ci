rm -rf pylarion
git clone --depth 1 ${PYLARION_REPO_URL}

# Make pylarion ready to be installed on a virtual environment
cd pylarion
cp setup.py setup.py.old
head -n -3 setup.py.old > setup.py
sed -i "s|'/etc', ||" setup.py
sed -i "s/cachingpolicy=1/cachingpolicy=0/" src/pylarion/session.py

# Install pylarion and its dependencies
pip install -r requirements.txt
pip install .
cd ..

# Install testimony from master
rm -rf testimony
git clone --depth 1 https://github.com/SatelliteQE/testimony.git
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
svn_repo=${POLARION_SVN_REPO}
EOF
