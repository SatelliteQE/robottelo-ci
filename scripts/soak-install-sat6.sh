ansible-playbook --private-key conf/id_rsa_soak -i conf/hosts.ini playbooks/satellite/installation.yaml

ansible-playbook --private-key conf/id_rsa_soak -i conf/hosts.ini playbooks/soak-tests/sync-plan.yaml
