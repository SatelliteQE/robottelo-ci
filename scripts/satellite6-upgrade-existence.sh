# Setting Prerequisites
pip install -r requirements.txt

$(which py.test) -v --continue-on-collection-errors --junit-xml=test_existance-results.xml upgrade_tests/test_existance_relations/
