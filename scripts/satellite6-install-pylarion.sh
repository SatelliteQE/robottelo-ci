rm -rf pylarion
git clone ${PYLARION_REPO_URL}

# Install pylarion and its dependencies
cd pylarion
git checkout origin/satelliteqe-pylarion
pip install -r requirements.txt
pip install .
cd ..

cat > .pylarion << "EOF"
[webservice]
EOF
