# ENCODE long read rna pipeline
# Maintainer: Otto Jolanki

workflow long_read_rna_pipeline {
    # Inputs

    # File inputs

    # Input fastqs. Can be gzipped.
    Array[File] fastqs 

    # Reference genome. Fasta format, gzipped.

    File reference_genome

    # Annotation file, gtf format, gzipped.

    File annotation

    # Prefix that gets added into output filenames. Default empty.

    String experiment_prefix=""

    # Is the data from "pacbio" or "nanopore"

    String input_type="pacbio"
    # Resouces

    # Task minimap2

    Int minimap2_ncpus
    Int minimap2_ramGB
    String minimap2_disks

    # Task get_splice_junctions

    Int get_splice_junctions_ncpus
    Int get_splice_junctions_ramGB
    String get_splice_junctions_disks

    # Pipeline starts here

    scatter (i in range(length(fastqs))) {
        call minimap2 { input:
            fastq = fastqs[i],
            reference_genome = reference_genome,
            output_prefix = "rep"+(i+1)+experiment_prefix,
            input_type = input_type,
            ncpus = minimap2_ncpus,
            ramGB = minimap2_ramGB,
            disks = minimap2_disks,
        }
    }

    call get_splice_junctions { input:
        annotation = annotation,
        reference_genome = reference_genome,
        output_prefix = experiment_prefix,
        ncpus = get_splice_junctions_ncpus,
        ramGB = get_splice_junctions_ramGB,
        disks = get_splice_junctions_disks,
    }
}

task minimap2 {
    File fastq
    File reference_genome
    String output_prefix
    String input_type
    Int ncpus
    Int ramGB
    String disks

    command {
        if [ "${input_type}" == "pacbio" ]; then
            minimap2 -t ${ncpus} -ax splice -uf --secondary=no -C5 \
                ${reference_genome} \
                ${fastq} \
                > ${output_prefix}.sam \
                2> ${output_prefix}_minimap2.log
        fi
        if [ "${input_type}" == "nanopore" ]; then
            minimap2 -t ${ncpus} -ax splice -uf -k14 \
                ${reference_genome} \
                ${fastq} \
                > ${output_prefix}.sam \
                2> ${output_prefix}_minimap2.log
        fi
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

task get_splice_junctions {
    File annotation
    File reference_genome
    String output_prefix
    Int ncpus
    Int ramGB
    String disks

    command <<<
        gzip -cd ${reference_genome} > ref.fasta
        if [ $(head -n 1 ref.fasta | grep -oE "[[:space:]]" | wc -l) -gt 1 ]; then
            cat ref.fasta | awk '{print $1}' > reference.fasta
        else
            gzip -cd ${reference_genome} > reference.fasta
        fi

        gzip -cd ${annotation} > anno.gtf
        python TranscriptClean/accessory_scripts/get_SJs_from_gtf.py --f anno.gtf --g refefence.fasta --o ${output_prefix}_SJs.txt
    >>>

    output {
        File splice_junctions = glob("*_SJs.txt")[0]
    }

    runtime {
        cpu: ncpus
        memory: "${ramGB} GB"
        disks: disks
    }
}
