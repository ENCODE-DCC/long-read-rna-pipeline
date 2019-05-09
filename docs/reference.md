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

### TALON

[TALON](https://github.com/dewyman/TALON) is a Python program for identifying known and novel genes/isoforms in long read transcriptome data sets. TALON is technology-agnostic in that it works from mapped SAM files, allowing data from different sequencing platforms (i.e. PacBio and Oxford Nanopore) to be analyzed side by side.

## Inputs



### Note about resources

## Outputs