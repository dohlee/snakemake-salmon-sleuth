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
    threads: 1
    log: 'logs/salmon/index/Homo_sapiens.GRCh38.transcriptome.log'
    benchmark: 'benchmarks/salmon/index/Homo_sapiens.GRCh38.transcriptome.log'
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
        # Number of bootstrap samples to generate.
        # Note: This is mutually exclusive with Gibbs sampling.
        # Default: False
        numBootstraps = SQS['numBootstraps'],
        # NOTE: The rest of advanced options are omitted here.
        # so please refer to the documentation for whole options.x
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
        # Number of bootstrap samples to generate.
        # Note: This is mutually exclusive with Gibbs sampling.
        # Default: False
        numBootstraps = SQP['numBootstraps'],
        # NOTE: The rest of advanced options are omitted here.
        # so please refer to the documentation for whole options.x
    threads: config['threads']['salmon_quant_pe']
    log: 'logs/salmon/quant/{sample}.log'
    benchmark: 'benchmarks/salmon/quant/{sample}.log'
    wrapper:
        'http://dohlee-bio.info:9193/salmon/quant'
