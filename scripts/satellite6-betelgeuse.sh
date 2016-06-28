rm -rf pylarion
git clone ${PYLARION_REPO_URL}

# Install pylarion and its dependencies
cd pylarion
git checkout origin/satelliteqe-pylarion
pip install -r requirements.txt
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
