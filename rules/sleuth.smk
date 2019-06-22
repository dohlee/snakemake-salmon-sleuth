rule sleuth:
    input:
        expand(str(RESULT_DIR / '01_salmon' / 'se' / '{sample}' / 'abundance.h5'), sample=SE_SAMPLES),
        expand(str(RESULT_DIR / '01_salmon' / 'pe' / '{sample}' / 'abundance.h5'), sample=PE_SAMPLES),
    output:
        RESULT_DIR / '02_sleuth' / 'sleuth_deg.tsv'
    params:
        # Manifest file that contains sample condition information.
        manifest = config['manifest'],
        # q-value cutoff to call differentially expressed genes.
        qval = 0.05,
    log: 'logs/sleuth.log'
    benchmark: 'benchmarks/sleuth.benchmark'
    wrapper:
        'http://dohlee-bio.info:9193/sleuth/wrapper.R'
