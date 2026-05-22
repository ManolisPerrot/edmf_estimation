from pathlib import Path
import matplotlib.pyplot as plt
import pandas as pd
import omldb 
from compute_metrics_gotm import gotm_run_valid, xr_opendataset_gotm
from concurrent.futures import ProcessPoolExecutor


def open_all_simulations():
    rows = []
    
    wave = 1
    rundir = Path(f'WAVE{wave}/runs')
    
    tasks = []

    for run_id_dir in rundir.iterdir():
        if run_id_dir.is_dir():
            for case_id_dir in run_id_dir.iterdir():
                if case_id_dir.is_dir():
                    tasks.append((run_id_dir.name, case_id_dir))

    with ProcessPoolExecutor() as exe:
        rows = list(exe.map(process_case, tasks))

    df = pd.DataFrame(rows).set_index(["run_id", "case_id"])

    df = pd.DataFrame(rows,index=('case_id','run_id'))
    return df




def process_case(args):
    run_id, case_id_dir = args
    case_id = case_id_dir.name
    
    if gotm_run_valid(case_id_dir):
        ds = xr_opendataset_gotm(case_id_dir / "gotm_out.nc")
        value = extract_summary
        ds.close()
    else:
        value = np.nan
        
    return {"run_id": run_id, "case_id": case_id, "value": value}












open_all_simulations()



gotm={}
subfolder = Path('SCM-0-001')
gotm[str(subfolder)] = 1

rundir = Path(f'WAVE{1}/runs')
for run_id_dir in rundir.iterdir():
    print(str(run_id_dir))
    print(run_id_dir.name)