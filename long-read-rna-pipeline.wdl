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

    # Variants file, vcf format, gzipped.
    File variants

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

    # Task transcriptclean

    Int transcriptclean_ncpus
    Int transcriptclean_ramGB
    String transcriptclean_disks

    # Task filter_transcriptclean

    Int filter_transcriptclean_ncpus
    Int filter_transcriptclean_ramGB
    String filter_transcriptclean_disks

    # Pipeline starts here
    
    call get_splice_junctions { input:
            annotation = annotation,
            reference_genome = reference_genome,
            output_prefix = experiment_prefix,
            ncpus = get_splice_junctions_ncpus,
            ramGB = get_splice_junctions_ramGB,
            disks = get_splice_junctions_disks,
        }

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

        call transcriptclean { input:
            sam = minimap2.sam,
            reference_genome = reference_genome,
            splice_junctions = get_splice_junctions.splice_junctions,
            variants = variants,
            output_prefix = "rep"+(i+1)+experiment_prefix,
            ncpus = transcriptclean_ncpus,
            ramGB = transcriptclean_ramGB,
            disks = transcriptclean_disks,
        }

        call filter_transcriptclean { input:
            sam = transcriptclean.corrected_sam,
            output_prefix = "rep"+(i+1)+experiment_prefix,
            ncpus = filter_transcriptclean_ncpus,
            ramGB = filter_transcriptclean_ramGB,
            disks = filter_transcriptclean_disks,
        }
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
        
        if [ $(head -n 1 ref.fasta | awk '{print NF}') -gt 1 ]; then
            cat ref.fasta | awk '{print $1}' > reference.fasta
        else
            mv ref.fasta reference.fasta
        fi

        gzip -cd ${annotation} > anno.gtf
        python $(which get_SJs_from_gtf.py) --f anno.gtf --g reference.fasta --o ${output_prefix}_SJs.txt
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

task transcriptclean {
    File sam
    File reference_genome
    File splice_junctions
    File variants
    String output_prefix
    Int ncpus
    Int ramGB
    String disks

    command <<<
        gzip -cd ${reference_genome} > ref.fasta
        gzip -cd ${variants} > variants.vcf

        if [ $(head -n 1 ref.fasta | awk '{print NF}') -gt 1 ]; then
            cat ref.fasta | awk '{print $1}' > reference.fasta
        else
            mv ref.fasta reference.fasta
        fi

        python $(which TranscriptClean.py) --sam ${sam} \
            --genome reference.fasta \
            --spliceJns ${splice_junctions} \
            --variants variants.vcf \
            --maxLenIndel 5 \
            --maxSJOffset 5 \
            -m true \
            -i true \
            --correctSJs true \
            --primaryOnly \
            --outprefix ${output_prefix}

        Rscript $(which generate_report.R) ${output_prefix}
    >>>

    output {
        File corrected_sam = glob("*_clean.sam")[0]
        File corrected_fasta = glob("*_clean.fa")[0]
        File transcript_log = glob("*_clean.log")[0]
        File transcript_error_log = glob("*_clean.TE.log")[0]
        File report = glob("*_report.pdf")[0]
    }

    runtime {
        cpu: ncpus
        memory: "${ramGB} GB"
        disks: disks
    }
}

task filter_transcriptclean {
    File sam
    String output_prefix
    Int ncpus
    Int ramGB
    String disks

    command {
        filter_transcriptclean_result.sh ${sam} ${output_prefix + "_filtered.sam"}
    }

    output {
        File filtered_sam = glob("*_filtered.sam")[0]
    }

    runtime {
        cpu: ncpus
        memory: "${ramGB} GB"
        disks: disks
    }

}