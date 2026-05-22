import csv
from pathlib import Path
import numpy as np
import os

def read_SCM_metrics(filename: str) -> dict:
    result = {}

    with open(filename, newline="") as f:
        reader = csv.reader(f)
        
        header = next(reader)  # First row
        metric_names = header[1:]  # Skip "SIM"

        for row in reader:
            if not row or len(row) < 2:
                continue  # skip empty or incomplete lines

            run_id = row[0]
            values = row[1:]

            # Build inner dictionary, skipping missing values
            metrics_dict = {}
            for name, val in zip(metric_names, values):
                if val != "":  # skip empty entries
                    metrics_dict[name] = float(val)

            result[run_id] = metrics_dict

    return result


def read_REF_metrics(filename: str) -> dict:
    result = {}

    with open(filename, newline="") as f:
        reader = csv.reader(f)
        
        # First row
        header = next(reader)  
        metric_names = header[1:]  # Skip "TYPE"

        # 2nd row
        header = next(reader)
        means = header[1:] #Skip "MEAN"

        # 3rd row
        header = next(reader)
        variances = header[1:] #Skip "VAR"

    for name,mean,variance in zip(metric_names,means,variances):
            result[name] = {'MEAN':mean,'VAR':variance}
        
    return result


def average_implausibility_one_wave(wave: int) -> dict:
    """
    Average implausibilities of **model** evaluations over all cases, 
    for one wave and 

    Parameters
    ----------
    wave : int
        wave number

    Returns
    -------
    dict
        {'<run_id>': <averaged implausibility>}
    """    
    wave_dir = Path(f'WAVE{wave}')
    model_metrics = read_SCM_metrics(wave_dir/'Metrics.csv')
    ref_metrics = read_REF_metrics(wave_dir/f'metrics_REF_{wave}.csv')

    loss = {}

    for run_id in model_metrics:
        loss[run_id] = 0
        for case_id in ref_metrics: 
            variance = float(ref_metrics[case_id]['VAR'])
            ref = float(ref_metrics[case_id]['MEAN'])
            model = float(model_metrics[run_id][case_id])
            implausibility = np.abs(model - ref)/np.sqrt(variance)
            loss[run_id] += implausibility
        loss[run_id] = loss[run_id]/len(ref_metrics) #normalize by the number of metrics
    return loss

def MAP() -> dict:
    wave_minimums = {}
    wave=1
    while Path(f'WAVE{wave}').is_dir():
        avgs = average_implausibility_one_wave(wave)
        wave_minimums.update({run_id: loss for run_id,loss in avgs.items() if loss == min(avgs.values()) })
        wave+=1
    MAP = {run_id: loss for run_id,loss in wave_minimums.items() if loss == min(wave_minimums.values()) }
    return MAP 



