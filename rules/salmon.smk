from pathlib import Path
DATA_DIR = Path(config['data_dir'])
RESULT_DIR = Path(config['result_dir'])

SI = config['salmon_index']
rule salmon_index:
    input:
        config['reference']['fasta'],
    output:
        directory(config['reference']['salmon_index'])
    params:
        extra = SI['extra'],
        # The size of k-mers that should be used for the quasi index.
        # Default: 31
        kmerLen = SI['kmerLen'],
        # This flag will expect the input transcript fasta to be in 
        # GENCODE format, and will split the transcript name at the first '|' character.
        # These reduced names will be used in the output and when looking for these transcripts
        # in a gene to transcript GTF.
        # Default: False
        gencode = SI['gencode'],
        # This flag will disable the dfeault indexing behavior of discarding sequence-identical
        # duplicate transcripts. If this flag is passed, then duplicate transcripts that
        # appear in the input will be retained and quantified separately.
        # Default: False
        keepDuplicates = SI['keepDuplicates'],
        # [quasi index only] Build the index using a perfect hash rather than a dense hash.
        # This will require less memory (especially during quantification),
        # but will take longer to construct.
        # Default: False
        perfectHash = SI['perfectHash'],
        # Treat these sequences are decoys that may have sequence homologous to some known
        # transcript.
        # Default: False
        decoys = SI['decoys'],
        # The type of index to build; the only option is "quasi" in this version of salmon.
        # Default: quasi
        type_ = SI['type_'],
    threads: config['threads']['salmon_index']
    log: 'logs/salmon/index/%s.log' % config['reference']['name']
    benchmark: 'benchmarks/salmon/index/%s.log' % config['reference']['name']
    wrapper:
        'http://dohlee-bio.info:9193/salmon/index'

SQS = config['salmon_quant_se']
rule salmon_quant_se:
    input:
        # Required input.
        index = config['reference']['salmon_index'],
        reads = [
            DATA_DIR / '{sample}.fastq.gz',
        ]
    output:
        # Required output.
        quant = RESULT_DIR / '01_salmon' / 'se' / '{sample}' / 'quant.sf',
        lib = RESULT_DIR / '01_salmon' / 'se' / '{sample}' / 'lib_format_counts.json',
    params:
        extra = SQS['extra'],
        # Format string describing the library type.
        # Please refer to: https://salmon.readthedocs.io/en/latest/library_type.html
        # Default: 'A' (Automatically detect library type.)
        libType = SQS['libType'],
        # Perform sequence-specific bias correction.
        # Default: False
        seqBias = SQS['seqBias'],
        # Perform fragment GC bias correction.
        # Default: False
        gcBias = SQS['gcBias'],
        # This option sets the prior probability that an alignment that disagrees with
        # the specified library type (--libType) results from the true fragment origin.
        # Setting this to 0 specifies that alignments that disagree with the library type
        # are no less likely than those that do.
        # Default: False
        incompatPrior = SQS['incompatPrior'],
        # File containing a mapping of transcripts to genes. If this file is provided salmon
        # will output both quant.sf and quant.genes.sf files, where the latter contains 
        # aggregated gene-level abundance estimates. The transcript to gene mapping should be
        # provided as either a GTF file, or a in a simple tab-delimited format where each line
        # contains the name of a transcript and the gene to which it belongs separated by a tab.
        # The extension of the file is used to determine how the file should be parsed.
        # Files ending in '.gtf', '.gff' or '.gff3' are assumed to be in GTF format; files with
        # any other extension are assumed to be in the simple format. In GTF / GFF format, the 
        # "transcript_id" is assumed to contain the transcript identifier and the "gene_id" is
        # assumed to contain the correspondin gene identifier.
        # Default: False
        geneMap = SQS['geneMap'],
        # If you're using Salmon on a metagenomic dataset, consider setting this flag to disable
        # parts of the abundance estimation model that make less sense for metagenomic data.
        # Default: False
        meta = SQS['meta'],
        # Discard orphan mappings in quasi-mapping mode. If this flag is passed then only paired
        # mappings will be considered toward quantification estimates. The default behavior is to
        # consider orphan mappings if no valid paired mappings exist. This flag is independent
        # of the option to write the orphaned mappings to file (--writeOrphanLinks).
        # Default: False
        discardOrphansQuasi = SQS['discardOrphansQuasi'],
        # Validate mappings using alignment-based verification. If this flag is passed, quasi-mappings
        # will be validated to ensure that they could give rise to a reasonable alignment before they are
        # further used for quantification.
        # Default: False
        validateMappings = SQS['validateMappings'],
        # The amount of slack allowed in the quasi-mapping consensus mechanism. Normally, a transcript
        # must cover all hits to be considered for mapping. If this is set to a fraction, X, greater than
        # 0 (and in [0,1)), then a transcript can fail to cover up to (100 * X)% of the hits before it is
        # discounted as a mapping candidate. The default value of this option is 0.2 if --validateMappings
        # is given and 0 otherwise.
        # Default: False
        consensusSlack = SQS['consensusSlack'],
        # The fraction of the optimal possible alignment score that a mapping must achieve in order to be
        # considered "valid" --- should be in (0, 1].
        # Salmon Default 0.65 and Alevin Default 0.87
        # Default: False
        minScoreFraction = SQS['minScoreFraction'],
        # Sets the maximum allowable MMP extension when collecting suffix array intervals to be used in
        # chaining. This prevents MMPs from becoming too long, and potentially masking intervals that would
        # uncover other goo quasi-mappings for the read. This heuristic mimics the idea of the
        # maximum mappable safe prefix (MMSP) in selective alignment. Setting a smaller value will potentially
        # allow for more sensitive, but slower, mapping.
        # Default: 7
        maxMMPExtension = SQS['maxMMPExtension'],
        # The value given to a match between read and reference nucleotides in an alignment.
        # Default: 2
        ma = SQS['ma'],
        # The value given to a mis-match between read and reference nucleotides in an alignment.
        # Default: -4
        mp = SQS['mp'],
        # The value given to a gap opening in an alignment.
        # Default: 4
        go = SQS['go'],
        # The value given to a gap extension in an alignment.
        # Default: 2
        ge = SQS['ge'],
        # The value used for the bandwidth passed to ksw2. A smaller bandwidth can make the alignment
        # verification run more quickly, but could possibly miss valid alignments.
        # Default: 15
        bandwidth = SQS['bandwidth'],
        # Allow dovetailing mappings.
        # Default: False
        allowDovetail = SQS['allowDovetail'],
        # Attempt to recover the mates of orphaned reads. This uses edlib for orphan recovery, and so
        # introduces some computational overhead, but it can improve sensitivity.
        # Default: False
        recoverOrphans = SQS['recoverOrphans'],
        # Set flags to mimic parameters similar to Bowtie2 with --no-discordant and --no-mixed flags.
        # This increases disallows dovetailing reads, and discards orphans. Note, this does not impose
        # the very strict parameters assumed by RSEM+Bowtie2, like gapless alignments. For that behavior,
        # use the --mimicStrictBT2 flag below.
        # Default: False
        mimicBT2 = SQS['mimicBT2'],
        # Set flags to mimic the very strict parameters used by RSEM+Bowtie2. This increases --minScoreFraction
        # to 0.8, disallows dovetailing reads, discards orphans, and disallows gaps in alignments.
        # Default: False
        mimicStrictBT2 = SQS['mimicStrictBT2'],
        # Instead of weighting mappings by their alignment score, this flag will discard any mappings with
        # sub-optimal alignment score. The default option of soft-filtering (i.e. weighting mappings by
        # their alignment score) usually yields slightly more accurate abundance estimates but this flag may be
        # desirable if you want more accurate 'naive' equivalence classes, rather than range factorizd equivalence
        # classes.
        hardFilter = SQS['hardFilter'],
        # If this option is provided, then the quasi-mapping results will be written out in SAM-compatible
        # format. By default, output will be directed to stdout, but an alternative file name can be provided
        # instead.
        # Default: False (when specified, '-')
        writeMappings = SQS['writeMappings'],
        # Force hits gathered during quasi-mapping to be "consistent" (i.e. co-linear and approximately the right
        # distance apart).
        # Default: False
        consistentHits = SQS['consistentHits'],
        # Number of bootstrap samples to generate. Note: This is mutually exclusive with Gibbs sampling.
        # Default: False (0)
        numBootstraps = SQS['numBootstraps'],
        # NOTE: Advanced options are omitted here, so please refer to the documentation for whole options.
    threads: config['threads']['salmon_quant_se']
    log: 'logs/salmon/quant/{sample}.log'
    benchmark: 'benchmarks/salmon/quant/{sample}.log'
    wrapper:
        'http://dohlee-bio.info:9193/salmon/quant'

SQP = config['salmon_quant_pe']
rule salmon_quant_pe:
    input:
        # Required input.
        index = config['reference']['salmon_index'],
        reads = [
            DATA_DIR / '{sample}.read1.fastq.gz',
            DATA_DIR / '{sample}.read2.fastq.gz',
        ]
    output:
        # Required output.
        quant = RESULT_DIR / '01_salmon' / 'pe' / '{sample}' / 'quant.sf',
        lib = RESULT_DIR / '01_salmon' / 'pe' / '{sample}' / 'lib_format_counts.json',
    params:
        extra = SQP['extra'],
        # Format string describing the library type.
        # Please refer to: https://salmon.readthedocs.io/en/latest/library_type.html
        # Default: 'A' (Automatically detect library type.)
        libType = SQP['libType'],
        # Perform sequence-specific bias correction.
        # Default: False
        seqBias = SQP['seqBias'],
        # Perform fragment GC bias correction.
        # Default: False
        gcBias = SQP['gcBias'],
        # This option sets the prior probability that an alignment that disagrees with
        # the specified library type (--libType) results from the true fragment origin.
        # Setting this to 0 specifies that alignments that disagree with the library type
        # are no less likely than those that do.
        # Default: False
        incompatPrior = SQP['incompatPrior'],
        # File containing a mapping of transcripts to genes. If this file is provided salmon
        # will output both quant.sf and quant.genes.sf files, where the latter contains 
        # aggregated gene-level abundance estimates. The transcript to gene mapping should be
        # provided as either a GTF file, or a in a simple tab-delimited format where each line
        # contains the name of a transcript and the gene to which it belongs separated by a tab.
        # The extension of the file is used to determine how the file should be parsed.
        # Files ending in '.gtf', '.gff' or '.gff3' are assumed to be in GTF format; files with
        # any other extension are assumed to be in the simple format. In GTF / GFF format, the 
        # "transcript_id" is assumed to contain the transcript identifier and the "gene_id" is
        # assumed to contain the correspondin gene identifier.
        # Default: False
        geneMap = SQP['geneMap'],
        # If you're using Salmon on a metagenomic dataset, consider setting this flag to disable
        # parts of the abundance estimation model that make less sense for metagenomic data.
        # Default: False
        meta = SQP['meta'],
        # Discard orphan mappings in quasi-mapping mode. If this flag is passed then only paired
        # mappings will be considered toward quantification estimates. The default behavior is to
        # consider orphan mappings if no valid paired mappings exist. This flag is independent
        # of the option to write the orphaned mappings to file (--writeOrphanLinks).
        # Default: False
        discardOrphansQuasi = SQP['discardOrphansQuasi'],
        # Validate mappings using alignment-based verification. If this flag is passed, quasi-mappings
        # will be validated to ensure that they could give rise to a reasonable alignment before they are
        # further used for quantification.
        # Default: False
        validateMappings = SQP['validateMappings'],
        # The amount of slack allowed in the quasi-mapping consensus mechanism. Normally, a transcript
        # must cover all hits to be considered for mapping. If this is set to a fraction, X, greater than
        # 0 (and in [0,1)), then a transcript can fail to cover up to (100 * X)% of the hits before it is
        # discounted as a mapping candidate. The default value of this option is 0.2 if --validateMappings
        # is given and 0 otherwise.
        # Default: False
        consensusSlack = SQP['consensusSlack'],
        # The fraction of the optimal possible alignment score that a mapping must achieve in order to be
        # considered "valid" --- should be in (0, 1].
        # Salmon Default 0.65 and Alevin Default 0.87
        # Default: False
        minScoreFraction = SQP['minScoreFraction'],
        # Sets the maximum allowable MMP extension when collecting suffix array intervals to be used in
        # chaining. This prevents MMPs from becoming too long, and potentially masking intervals that would
        # uncover other goo quasi-mappings for the read. This heuristic mimics the idea of the
        # maximum mappable safe prefix (MMSP) in selective alignment. Setting a smaller value will potentially
        # allow for more sensitive, but slower, mapping.
        # Default: 7
        maxMMPExtension = SQP['maxMMPExtension'],
        # The value given to a match between read and reference nucleotides in an alignment.
        # Default: 2
        ma = SQP['ma'],
        # The value given to a mis-match between read and reference nucleotides in an alignment.
        # Default: -4
        mp = SQP['mp'],
        # The value given to a gap opening in an alignment.
        # Default: 4
        go = SQP['go'],
        # The value given to a gap extension in an alignment.
        # Default: 2
        ge = SQP['ge'],
        # The value used for the bandwidth passed to ksw2. A smaller bandwidth can make the alignment
        # verification run more quickly, but could possibly miss valid alignments.
        # Default: 15
        bandwidth = SQP['bandwidth'],
        # Allow dovetailing mappings.
        # Default: False
        allowDovetail = SQP['allowDovetail'],
        # Attempt to recover the mates of orphaned reads. This uses edlib for orphan recovery, and so
        # introduces some computational overhead, but it can improve sensitivity.
        # Default: False
        recoverOrphans = SQP['recoverOrphans'],
        # Set flags to mimic parameters similar to Bowtie2 with --no-discordant and --no-mixed flags.
        # This increases disallows dovetailing reads, and discards orphans. Note, this does not impose
        # the very strict parameters assumed by RSEM+Bowtie2, like gapless alignments. For that behavior,
        # use the --mimicStrictBT2 flag below.
        # Default: False
        mimicBT2 = SQP['mimicBT2'],
        # Set flags to mimic the very strict parameters used by RSEM+Bowtie2. This increases --minScoreFraction
        # to 0.8, disallows dovetailing reads, discards orphans, and disallows gaps in alignments.
        # Default: False
        mimicStrictBT2 = SQP['mimicStrictBT2'],
        # Instead of weighting mappings by their alignment score, this flag will discard any mappings with
        # sub-optimal alignment score. The default option of soft-filtering (i.e. weighting mappings by
        # their alignment score) usually yields slightly more accurate abundance estimates but this flag may be
        # desirable if you want more accurate 'naive' equivalence classes, rather than range factorizd equivalence
        # classes.
        hardFilter = SQP['hardFilter'],
        # If this option is provided, then the quasi-mapping results will be written out in SAM-compatible
        # format. By default, output will be directed to stdout, but an alternative file name can be provided
        # instead.
        # Default: False (when specified, '-')
        writeMappings = SQP['writeMappings'],
        # Force hits gathered during quasi-mapping to be "consistent" (i.e. co-linear and approximately the right
        # distance apart).
        # Default: False
        consistentHits = SQP['consistentHits'],
        # Number of bootstrap samples to generate. Note: This is mutually exclusive with Gibbs sampling.
        # Default: False (0)
        numBootstraps = SQP['numBootstraps'],
        # NOTE: Advanced options are omitted here, so please refer to the documentation for whole options.
    threads: config['threads']['salmon_quant_pe']
    log: 'logs/salmon/quant/{sample}.log'
    benchmark: 'benchmarks/salmon/quant/{sample}.log'
    wrapper:
        'http://dohlee-bio.info:9193/salmon/quant'
