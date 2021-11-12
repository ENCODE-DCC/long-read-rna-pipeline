# REFERENCE

This document contains detailed information on the inputs, outputs and the software used in the pipeline.

# CONTENTS

[Software](reference.md#software)  
[Inputs](reference.md#inputs)  
[Resurce Considerations](reference.md#note-about-resources)  
[Outputs](reference.md#outputs)

## Software

### Ubuntu 16.04

The pipeline docker image is based on [Ubuntu base image](https://hub.docker.com/_/ubuntu/) version `16.04`.

### Python versions 2.7 and 3.7

Transcriptclean runs on python 2.7, and other parts utilize 3.7.

### Minimap2 2.15

[Minimap2](https://github.com/lh3/minimap2) is a versatile sequence alignment program that aligns DNA or mRNA sequences against a large reference database. For publication describing the software in detail, see [Paper by Li, H](https://doi.org/10.1093/bioinformatics/bty191).

### Transcriptclean v2.0.2

[Transcriptclean](https://github.com/dewyman/TranscriptClean) is a program that corrects for mismatches, microindels and non-canonical splice junctions. For publication describing the software in detail, see [Paper by Dana Wyman, Ali Mortazavi](https://doi.org/10.1093/bioinformatics/bty483). Version 2.x is an extensive rewrite of the first version, featuring parallel processing and very significant improvements in memory efficiency.

### TALON v5.0

[TALON](https://github.com/dewyman/TALON) is a Python program for identifying known and novel genes/isoforms in long read transcriptome data sets. TALON is technology-agnostic in that it works from mapped SAM files, allowing data from different sequencing platforms (i.e. PacBio and Oxford Nanopore) to be analyzed side by side.

## Inputs

A typical `input.json` is structured in the following way:

```
{
    "long_read_rna_pipeline.fastqs" : ["test_data/chr19_test_10000_reads.fastq.gz", "test_data/chr19_test_10000_reads_rep2.fastq.gz"],
    "long_read_rna_pipeline.reference_genome" : "test_data/GRCh38_no_alt_analysis_set_GCA_000001405.15_chr19_only.fasta.gz",
    "long_read_rna_pipeline.annotation" : "test_data/gencode.v24.annotation_chr19.gtf.gz",
    "long_read_rna_pipeline.variants" : "test_data/00-common_chr19_only.vcf.gz",
    "long_read_rna_pipeline.experiment_prefix" : "TEST_WORKFLOW",
    "long_read_rna_pipeline.input_type" : "pacbio",
    "long_read_rna_pipeline.genome_build" : "GRCh38_chr19",
    "long_read_rna_pipeline.annotation_name" : "gencode_V24_chr19",
    "long_read_rna_pipeline.talon_prefixes" : ["FOO", "BAR"],
    "long_read_rna_pipeline.canonical_only" : true,
    "long_read_rna_pipeline.small_task_resources" : {
        "cpu": 1,
        "memory_gb": 1,
        "disks": "local-disk 10 SSD"
    },
    "long_read_rna_pipeline.medium_task_resources" : {
        "cpu": 1,
        "memory_gb": 1,
        "disks": "local-disk 10 SSD"
    },
    "long_read_rna_pipeline.large_task_resources" : {
        "cpu": 1,
        "memory_gb": 1,
        "disks": "local-disk 10 SSD"
    },
    "long_read_rna_pipeline.xlarge_task_resources" : {
        "cpu": 1,
        "memory_gb": 1,
        "disks": "local-disk 10 SSD"
    }
}
```

Note that default resources for running with full sized data have been defined in the main pipeline wdl, and do not need to be defined in the `input.json`, if you are happy with the defaults.

The following elaborates on the meaning of each line in the input file.

* `long_read_rna_pipeline.fastqs` Is a list of gzipped input fastqs, one file per replicate.
* `long_read_rna_pipeline.reference_genome` Is the gzipped fasta file containing the reference genome used in mapping. Files for [human](https://www.encodeproject.org/files/GRCh38_no_alt_analysis_set_GCA_000001405.15/) and [mouse](https://www.encodeproject.org/files/mm10_no_alt_analysis_set_ENCODE/) are available on the [ENCODE Portal](https://https://www.encodeproject.org/).
* `long_read_rna_pipeline.annotation` Is the gzipped gtf file containing the annotations. Files for [human V29](https://www.encodeproject.org/files/gencode.v29.primary_assembly.annotation_UCSC_names/) and [mouse M21](https://www.encodeproject.org/files/gencode.vM21.primary_assembly.annotation_UCSC_names/) are available on the [ENCODE Portal](https://https://www.encodeproject.org/).
* `long_read_rna_pipeline.variants` Is the gzipped vcf file containing variants. File for [human]((https://www.encodeproject.org/files/ENCFF911UGW/) is available on the [ENCODE Portal](https://https://www.encodeproject.org/). Variants file used in the pipeline is derived from dbsnp variants [file](https://www.encodeproject.org/files/ENCFF744NWL/) by modifying the chromosome names to match the ones in the reference genome. The original file uses short chromosome names (1,2,3 etc.) and the reference uses longer names (chr1, chr2, chr3, etc.). This input is optional and can be left undefined. Defining variants input prevents TranscriptClean from correcting away known variants.
* `long_read_rna_pipeline.experiment_prefix` This will be a prefix for the output files.
* `long_read_rna_pipeline.input_type` Platform that was used for generating the data. Options are `pacbio` and `nanopore`.
* `long_read_rna_pipeline.genome_build` Genome build name in the initial TALON database. This is internal metadata variable you typically do not need to touch.
* `long_read_rna_pipeline.annotation_name` Annotation name in the initial TALON database. This is internal metadata variable you typically do not need to touch.
* `long_read_rna_pipeline.talon_prefixes` This is a list of strings that, if provided, will be prefixes to the transcript names in the gtf generated by `create_gtf_from_talon_db`. If this is not defined, "TALON" will be the default prefix. Note, that if this list is defined, its length must be equal to the number of replicates.
* `long_read_rna_pipeline.canonical_only` If this option is set to true, TranscriptClean will only output transcripts that are either canonical or that contain annotated noncanonical junctions to the clean SAM and Fasta files at the end of the run. Set this parameter to false to output all transcripts.
* `long_read_rna_pipeline.docker` and `long_read_rna_pipeline.singularity` These should not need to be touched, unless you are hosting your own images, in which case you probably know what to do.
In addition, if you have used spikeins in your experiment, you can define them as an array of gzipped fasta files in workflow level variable `long_read_rna_pipeline.spikeins`.
The rest of the variables are for adjusting the computational resources of the pipeline tasks. See [notes about resources](reference.md#note-about-resources) below for more details.

## Outputs

#### Task Init_talon_db

* `database` TALON database
* `talon_inputs` this file contains the annotation name and reference genome name that are stored in database and are needed in the subsequent TALON call.

#### Task Minimap2

* `sam` Alignments in .sam format.
* `bam` Alignments in .bam format.
* `log` Log file from minimap2.
* `mapping_qc` .json file containing information on number of mapped reads, mapping rate and number of full length non-chimeric reads.

#### Task Transcriptclean

* `corrected_sam` SAM file of corrected transcripts. Unmapped/non-primary transcript alignments from the input file are included in their original form.
* `corrected_bam` BAM file of corrected transcripts. Unmapped/non-primary transcript alignments from the input file are included in their original form.
* `corrected_fasta` Fasta file of corrected transcript sequences. Unmapped transcripts from the input file are included in their original form.
* `transcript_log ` Each row represents a transcript. The columns track the mapping status of the transcript, as well as how many errors of each type were found and corrected/not corrected in the transcript.
* `transcript_error_log` Each row represents a potential error in a given transcript. The column values track whether the error was corrected or not and why.
* `report` Report of the cleaning process in .pdf format.

#### Task Talon_label_reads

* `labeled_sam` SAM file with internal priming events flagged.
* `labeled_bam` BAM file with internal priming events flagged.
* `read_labels_tsv` TSV with read labels

#### Task TALON

* `talon_log` talon log file.
* `talon_db_out` TALON database with information from the pipeline run added on top of the initial database.

#### Task Create_abundance_from_talon_db

* `talon_abundance` Transcript and Gene quantitation .tsv from TALON database.
* `number_of_genes_detected` .json file containing the information on the number of genes detected in the pipeline run.

#### Task Create_gtf_from_talon_db

* `gtf` a transcriptome reference file in gzipped .gtf format containing the new transcripts found in the replicate.

#### Task Calculate_spearman (run when there are exactly 2 replicates)

* `spearman` .json file with spearman correlation metric between the replicates.

### Note about resources

The hardware resources needed to run the pipeline depend on the sequencing depth so it is hard to give definitive values that will be good for everyone. Further, some users may value time more than money, and vice versa. The defaults have been set with runtime on mind, but should also be quite cost effective.
```
