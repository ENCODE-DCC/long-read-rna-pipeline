# ENCODE long read rna pipeline: get splice junctions
# Maintainer: Otto Jolanki

#CAPER docker quay.io/encode-dcc/long-read-rna-pipeline:v1.2
#CAPER singularity docker://quay.io/encode-dcc/long-read-rna-pipeline:v1.2

workflow get_splice_junctions {
    # Inputs

    # File inputs

    # Annotation file, gtf format, gzipped.
    File annotation

    # Reference genome, fasta format, gzipped.
    File reference_genome

    # Output prefix, the output filename will be output_prefix_SJs.txt
    String output_prefix

    # Resources
    Int ncpus
    Int ramGB
    String disks

    # Pipeline starts here

    call get_splice_junctions_ { input:
            annotation = annotation,
            reference_genome = reference_genome,
            output_prefix = output_prefix,
            ncpus = ncpus,
            ramGB = ramGB,
            disks = disks,
        }
}

task get_splice_junctions_ {
    File annotation
    File reference_genome
    String output_prefix
    Int ncpus
    Int ramGB
    String disks

    command <<<
        gzip -cd ${reference_genome} > ref.fasta
        rm ${reference_genome}
        
        if [ $(head -n 1 ref.fasta | awk '{print NF}') -gt 1 ]; then
            cat ref.fasta | awk '{print $1}' > reference.fasta
        else
            mv ref.fasta reference.fasta
        fi

        gzip -cd ${annotation} > anno.gtf
        rm ${annotation}
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
