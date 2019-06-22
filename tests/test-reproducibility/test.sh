#!/bin/bash
set -e

snakemake -s startup.smk -p -j 2
snakemake -s ../../Snakefile --configfile config.yaml --config result_dir=result0 -p -j 2
snakemake -s ../../Snakefile --configfile config.yaml --config result_dir=result1 -p -j 2

pe_a=$(tail -n+2 result0/02_sleuth/sleuth_deg.tsv | md5sum | cut -d' ' -f1)
pe_b=$(tail -n+2 result1/02_sleuth/sleuth_deg.tsv | md5sum | cut -d' ' -f1)

if [ "$pe_a" == "$pe_b" ]; then
    curl https://gist.githubusercontent.com/dohlee/3ea154d52932b27d042566605a2cb9e2/raw/update_reproducibility.sh -H 'Cache-control: no-cache' | bash /dev/stdin -y
else
    curl https://gist.githubusercontent.com/dohlee/3ea154d52932b27d042566605a2cb9e2/raw/update_reproducibility.sh -H 'Cache-control: no-cache' | bash /dev/stdin -n
fi

echo "Test exited with $?."
