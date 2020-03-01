from pathlib import Path
import pandas as pd

configfile: 'config.yaml'
manifest = pd.read_csv(config['manifest'])

onsuccess: shell('')
onerror: shell('')

DATA_DIR = Path(config['data_dir'])
RESULT_DIR = Path(config['result_dir'])

ALL = []
SE_SAMPLES = manifest[manifest.library_layout == 'single'].name.values
PE_SAMPLES = manifest[manifest.library_layout == 'paired'].name.values
SE_QUANT = expand(str(RESULT_DIR / '01_salmon' / 'se' / '{sample}' / 'quant.sf'), sample=SE_SAMPLES)
PE_QUANT = expand(str(RESULT_DIR / '01_salmon' / 'pe' / '{sample}' / 'quant.sf'), sample=PE_SAMPLES)
SE_ABUNDANCE = expand(str(RESULT_DIR / '01_salmon' / 'se' / '{sample}' / 'abundance.h5'), sample=SE_SAMPLES)
PE_ABUNDANCE = expand(str(RESULT_DIR / '01_salmon' / 'pe' / '{sample}' / 'abundance.h5'), sample=PE_SAMPLES)
DEG = RESULT_DIR / '02_sleuth' / 'sleuth_deg.tsv'

ALL.append(SE_QUANT)
ALL.append(PE_QUANT)
ALL.append(SE_ABUNDANCE)
ALL.append(PE_ABUNDANCE)
ALL.append(DEG)

include: 'rules/salmon.smk'
include: 'rules/wasabi.smk'
include: 'rules/sleuth.smk'

rule all:
    input: ALL

rule clean:
    shell:
        'if [ -e {RESULT_DIR}/01_salmon ]; then rm -r {RESULT_DIR}/01_salmon; fi && '
        'if [ -e {RESULT_DIR}/02_sleuth ]; then rm -r {RESULT_DIR}/02_sleuth; fi'
