import pytest
import omldb 
import sys
from pathlib import Path
sys.path.append('../')
from compute_metrics_gotm import get_gotm_config_for_case
import yaml

def test_temperature_method():
    """Check that initial temperature method is well specified"""
    catalog = omldb.load_catalog()

    for case_id in catalog['case_id']:
        # case_id = catalog['case_id'][i]
        config_path = get_gotm_config_for_case(case_id=case_id)
        config = yaml.safe_load(Path(config_path).read_text())

        metadata = omldb.load_case_metadata(case_id)
        print(case_id)
        print(config['temperature']['method'] == metadata['case']['temperature/method'])






case_id = 'LES_IDEAL_GARANAIK2023_E01'

config_path = get_gotm_config_for_case(case_id=case_id)
config = yaml.safe_load(Path(config_path).read_text())

metadata = omldb.load_case_metadata(case_id)
print(case_id)

metadata['case']
print(config['temperature']['method'] == metadata['case']['temperature/method'])

# catalog = omldb.load_catalog()
# for i in catalog['case_id']:
#     print(str(i))