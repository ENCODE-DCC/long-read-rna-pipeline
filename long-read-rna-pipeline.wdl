# ENCODE long read rna pipeline
# Maintainer: Otto Jolanki

workflow long_read_rna_pipeline {
    # Inputs

    # File inputs

    # Input fastqs. Can be gzipped.
    Array[File] fastqs 

    # Reference genome. Fasta format, can be gzipped.

    File reference_genome

    # Prefix that gets added into output filenames. Default empty.

    String experiment_prefix=""

    # Is the data from oxford nanopore?

    Boolean oxford_nanopore=false
    # Resouces

    # Task minimap2

    Int minimap2_ncpus
    Int minimap2_ramGB
    String minimap2_disks


    # Pipeline starts here

    scatter (i in range(length(fastqs))) {
        if (oxford_nanopore == false) {
            call minimap2_pacbio as minimap2 { input:
                fastq = fastqs[i],
                reference_genome = reference_genome,
                output_prefix = "rep"+(i+1)+experiment_prefix,
                ncpus = minimap2_ncpus,
                ramGB = minimap2_ramGB,
                disks = minimap2_disks,
            }
        }
        if (oxford_nanopore == true) {
            call minimap2_oxford_nanopore as minimap2 { input:
                fastq = fastqs[i],
                reference_genome = reference_genome,
                output_prefix = "rep"+(i+1)+experiment_prefix,
                ncpus = minimap2_ncpus,
                ramGB = minimap2_ramGB,
                disks = minimap2_disks,
            }
        }
    }
}

task minimap2_pacbio {
    File fastq
    File reference_genome
    String output_prefix
    Int ncpus
    Int ramGB
    String disks

    command {
        minimap2 -t ${ncpus} -ax splice -uf --secondary=no -C5 \
            ${reference_genome} \
            ${fastq} \
            > ${output_prefix}.sam \
            2> ${output_prefix}_minimap2.log
    }

    output {
        File sam = glob("*.sam")[0]
        File log = glob("*_minimap2.log")[0]
    }

    runtime {
        cpu: ncpus
        memory: "${ramGB} GB"
        disks: disks
    }
}

task minimap2_oxford_nanopore {
    File fastq
    File reference_genome
    String output_prefix
    Int ncpus
    Int ramGB
    String disks

    command {
        minimap2 -t ${ncpus} -ax splice -uf -k14 \
            ${reference_genome} \
            ${fastq} \
            > ${output_prefix}.sam \
            2> ${output_prefix}_minimap2.log
    }

    output {
        File sam = glob("*.sam")[0]
        File log = glob("*_minimap2.log")[0]
    }

    runtime {
        cpu: ncpus
        memory: "${ramGB} GB"
        disks: disks
    }
}