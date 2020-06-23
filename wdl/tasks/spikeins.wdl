version 1.0


import "../structs/resources.wdl"


task merge_encode_annotations {
    input {
        File spikein_fasta
        Resources resources
        String output_filename="spikeins.gtf"
    }

    String prefix = basename(spikein_fasta)

    command {
        ln ~{spikein_fasta} .
        python3.7 $(which merge_encode_annotations.py) \
            --o ~{output_filename} \
            ~{prefix}
    }

    output {
        File spikein_gtf = output_filename
    }

    runtime {
        cpu: resources.cpu
        memory: "~{resources.memory_gb} GB"
        disks: resources.disks
    }
}


task separate_multistrand_genes {
    input {
        File input_gtf
        Resources resources
        String output_filename="separated.gtf"
    }

    String prefix = basename(input_gtf)

    command {
        ln ~{input_gtf} .
        python3.7 $(which separate_multistrand_genes.py) \
            --f ~{prefix} \
            --o ~{output_filename}
    }

    output {
        File separated_gtf = output_filename
    }

    runtime {
        cpu: resources.cpu
        memory: "~{resources.memory_gb} GB"
        disks: resources.disks
    }
}
