from pathlib import Path
RESULT_DIR = Path(config['result_dir'])

rule wasabi_se:
    input:
        # For example,
        expand(str(RESULT_DIR / '01_salmon' / 'se' / '{sample}' / 'quant.sf'), sample=SE_SAMPLES),
    output:
        expand(str(RESULT_DIR / '01_salmon' / 'se' / '{sample}' / 'abundance.h5'), sample=SE_SAMPLES),
    log: 'logs/wasabi/wasabi_se.log'
    benchmark: 'benchmarks/wasabi/wasabi_se.benchmark'
    script:
        'http://dohlee-bio.info:9193/wasabi/wrapper.R'

rule wasabi_pe:
    input:
        # For example,
        expand(str(RESULT_DIR / '01_salmon' / 'pe' / '{sample}' / 'quant.sf'), sample=PE_SAMPLES),
    output:
        expand(str(RESULT_DIR / '01_salmon' / 'pe' / '{sample}' / 'abundance.h5'), sample=PE_SAMPLES),
    log: 'logs/wasabi/wasabi_pe.log'
    benchmark: 'benchmarks/wasabi/wasabi_pe.benchmark'
    script:
        'http://dohlee-bio.info:9193/wasabi/wrapper.R'


