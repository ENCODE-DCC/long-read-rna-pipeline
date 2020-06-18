version 1.0


import "../structs/resources.wdl"


task get_SJs_from_gtf {
    input {
        File annotation_gtf
        File reference_fasta
        Resources resources
        String output_filename = "SJs.txt"
    }

    String annotation_prefix = basename(annotation_gtf)
    String reference_prefix = basename(reference_fasta)

    command {
        ln ~{annotation_gtf} .
        ln ~{reference_fasta} .
        python $(which get_SJs_from_gtf.py) \
            --f ~{annotation_prefix} \
            --g ~{reference_prefix} \
            --o ~{output_filename}
    }

    output {
        File splice_junctions = output_filename
    }

    runtime {
        cpu: resources.cpu
        memory: "~{resources.memory_gb} GB"
        disks: resources.disks
    }
}
