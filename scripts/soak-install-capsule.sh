ansible-playbook --private-key conf/id_rsa_soak -i conf/hosts.ini playbooks/satellite/capsules.yaml --skip-tags "async"
