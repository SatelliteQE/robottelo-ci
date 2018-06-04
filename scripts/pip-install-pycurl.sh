pip install -U pip
pip install six

if [ "$(curl --version | grep NSS 2>/dev/null)" ]; then
    export PYCURL_SSL_LIBRARY=nss
    pip install --compile --install-option="--with-nss" pycurl
else
    export PYCURL_SSL_LIBRARY=openssl
    pip install --compile --install-option="--with-openssl" pycurl
fi
