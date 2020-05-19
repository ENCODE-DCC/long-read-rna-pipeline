version 1.0

# ENCODE long read rna pipeline: get splice junctions

#CAPER docker quay.io/encode-dcc/long-read-rna-pipeline:v1.3
#CAPER singularity docker://quay.io/encode-dcc/long-read-rna-pipeline:v1.3

workflow get_splice_junctions {
    meta {
        author: "Otto Jolanki"
        version: "dev_1.4"
    }

    input {
        File annotation
        File reference_genome
        String output_prefix
        Int ncpus
        Int ramGB
        String disks
    }

    call get_splice_junctions_ { input:
            annotation=annotation,
            reference_genome=reference_genome,
            output_prefix=output_prefix,
            ncpus=ncpus,
            ramGB=ramGB,
            disks=disks,
    }
}

task get_splice_junctions_ {
    input {
        File annotation
        File reference_genome
        String output_prefix
        Int ncpus
        Int ramGB
        String disks
    }

    command <<<
        gzip -cd ~{reference_genome} > ref.fasta
        rm ~{reference_genome}

        if [ $(head -n 1 ref.fasta | awk '{print NF}') -gt 1 ]; then
            cat ref.fasta | awk '{print $1}' > reference.fasta
        else
            mv ref.fasta reference.fasta
        fi

        gzip -cd ~{annotation} > anno.gtf
        rm ~{annotation}
        python $(which get_SJs_from_gtf.py) --f anno.gtf --g reference.fasta --o ~{output_prefix}_SJs.txt
    >>>

    output {
        File splice_junctions = "~{output_prefix}_SJs.txt"
    }

    runtime {
        cpu: ncpus
        memory: "~{ramGB} GB"
        disks: disks
    }
}
