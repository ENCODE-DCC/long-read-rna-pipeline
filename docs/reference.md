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

### Transcriptclean v1.0.7

[Transcriptclean](https://github.com/dewyman/TranscriptClean) is a program that corrects for mismatches, microindels and non-canonical splice junctions. For publication describing the software in detail, see [Paper by Dana Wyman, Ali Mortazavi](https://doi.org/10.1093/bioinformatics/bty483).

### TALON v4.1

[TALON](https://github.com/dewyman/TALON) is a Python program for identifying known and novel genes/isoforms in long read transcriptome data sets. TALON is technology-agnostic in that it works from mapped SAM files, allowing data from different sequencing platforms (i.e. PacBio and Oxford Nanopore) to be analyzed side by side.

## Inputs

A typical `input.json` is structured in the following way:

```
{
    "long_read_rna_pipeline.fastqs" : ["test_data/chr19_test_10000_reads.fastq.gz", "test_data/chr19_test_10000_reads_rep2.fastq.gz"],
    "long_read_rna_pipeline.reference_genome" : "test_data/GRCh38_no_alt_analysis_set_GCA_000001405.15_chr19_only.fasta.gz",
    "long_read_rna_pipeline.annotation" : "test_data/gencode.v24.annotation_chr19.gtf.gz",
    "long_read_rna_pipeline.variants" : "test_data/00-common_chr19_only.vcf.gz",
    "long_read_rna_pipeline.splice_junctions" : "test_data/splice_junctions.txt",
    "long_read_rna_pipeline.experiment_prefix" : "TEST_WORKFLOW",
    "long_read_rna_pipeline.input_type" : "pacbio",
    "long_read_rna_pipeline.initial_talon_db" : "test_data/test_init_talon_db.db",
    "long_read_rna_pipeline.genome_build" : "GRCh38_chr19",
    "long_read_rna_pipeline.annotation_name" : "gencode_V24_chr19",
    "long_read_rna_pipeline.minimap2_ncpus" : 1,
    "long_read_rna_pipeline.minimap2_ramGB" : 4,
    "long_read_rna_pipeline.minimap2_disks" : "local-disk 20 HDD",
    "long_read_rna_pipeline.transcriptclean_ncpus" : 1,
    "long_read_rna_pipeline.transcriptclean_ramGB" : 4,
    "long_read_rna_pipeline.transcriptclean_disks": "local-disk 20 HDD",
    "long_read_rna_pipeline.filter_transcriptclean_ncpus" : 1,
    "long_read_rna_pipeline.filter_transcriptclean_ramGB" : 4,
    "long_read_rna_pipeline.filter_transcriptclean_disks" : "local-disk 20 HDD",
    "long_read_rna_pipeline.talon_ncpus" : 1,
    "long_read_rna_pipeline.talon_ramGB" : 4,
    "long_read_rna_pipeline.talon_disks" : "local-disk 20 HDD",
    "long_read_rna_pipeline.create_abundance_from_talon_db_ncpus" : 1,
    "long_read_rna_pipeline.create_abundance_from_talon_db_ramGB" : 4,
    "long_read_rna_pipeline.create_abundance_from_talon_db_disks" : "local-disk 20 HDD",
    "long_read_rna_pipeline.calculate_spearman_ncpus" : 2,
    "long_read_rna_pipeline.calculate_spearman_ramGB" : 4,
    "long_read_rna_pipeline.calculate_spearman_disks" : "local-disk 20 HDD"
}
```

The following elaborates on the meaning of each line in the input file.

* `long_read_rna_pipeline.fastqs` Is a list of gzipped input fastqs, one file per replicate.
* `long_read_rna_pipeline.reference_genome` Is the gzipped fasta file containing the reference genome used in mapping.
* `long_read_rna_pipeline.annotation` Is the gzipped gtf file containing the annotations.
* `long_read_rna_pipeline.variants` Is the gzipped vcf file containing variants.
* `long_read_rna_pipeline.splice_junctions` Is the splice junctions file, generated with `get-splice-junctions.wdl` workflow based on the annotation and reference genome. This will be made available for download from The ENCODE Portal.
* `long_read_rna_pipeline.experiment_prefix` This will be a prefix for the output files.
* `long_read_rna_pipeline.input_type` Platform that was used for generating the data. Options are `pacbio` and `nanopore`.
* `long_read_rna_pipeline.initial_talon_db` Initial TALON database, generated with `init_talon_db.wdl` workflow based on the annotation. This will be made available for download from The ENCODE Portal.
* `long_read_rna_pipeline.genome_build` Genome build name in the initial TALON database. This is internal metadata variable you typically do not need to touch.
* `long_read_rna_pipeline.annotation_name` Annotation name in the initial TALON database. This is internal metadata variable you typically do not need to touch.

Rest of the variables are for adjusting the computational resources of the pipeline tasks.

### Note about resources

The resources required by mapping task are quite typical for the mapping and we find that 16 cores with 60GB of memory get the job done quite fast. The resources required by TALON related tasks and filter transcriptclean are roughly 2cpus with 12GB memory. Right now we Transcriptclean is very memory intensive, using up to over 100GB of memory on full sized data, and we are working on making the task more memory efficient.

## Outputs

#### Task Minimap2

* `sam` Alignments in .sam format.
* `bam` Alignments in .bam format.
* `log` Log file from minimap2.
* `mapping_qc` .json file containing information on number of mapped reads, mapping rate and number of full length non-chimeric reads.

#### Task Transcriptclean

* `corrected_sam` SAM file of corrected transcripts. Unmapped/non-primary transcript alignments from the input file are included in their original form.
* `corrected_fasta` Fasta file of corrected transcript sequences. Unmapped transcripts from the input file are included in their original form.
* `transcript_log ` Each row represents a transcript. The columns track the mapping status of the transcript, as well as how many errors of each type were found and corrected/not corrected in the transcript.
* `transcript_error_log` Each row represents a potential error in a given transcript. The column values track whether the error was corrected or not and why.
* `report` Report of the cleaning process in .pdf format.

#### Task Filter_transcriptclean

* `filtered_sam` sam with noncanonical reads filtered, duplicates are removed and sorting is performed. Input to the TALON step.
* `filtered_bam` bam with noncanonical reads filtered, duplicates are removed and sorting is performed.

#### Task TALON

* `talon_log` talon log file.
* `talon_db_out` TALON database with information from the pipeline run added on top of the initial database.

#### Task Create_abundance_from_talon_db

* `talon_abundance` Transcript and Gene quantitation .tsv from TALON database.
* `number_of_genes_detected` .json file containing the information on the number of genes detected in the pipeline run.

#### Task Calculate_spearman (run when there are exactly 2 replicates)

* `spearman` .json file with spearman correlation metric between the replicates.

#### Crowell output directory structure

Cromwell: Cromwell will store outputs for each task under directory cromwell-executions/[WORKFLOW_ID]/call-[TASK_NAME]/shard-[IDX]. For all tasks [IDX] means a zero-based index for each replicate.