version 1.0


import "../structs/resources.wdl"


task clean_reference_fasta {
    input {
        File fasta
        Resources resources
        String output_filename = "clean.fasta"
    }

    String prefix = basename(fasta)

    command <<<
        ln ~{fasta} .
        if [ $(head -n 1 ~{prefix} | awk '{print NF}') -gt 1 ]; then
            awk '{print $1}' ~{prefix} > ~{output_filename}
        else
            mv ~{prefix} ~{output_filename}
        fi
    >>>

    output {
        File cleaned_fasta = output_filename
    }

    runtime {
        cpu: resources.cpu
        memory: "~{resources.memory_gb} GB"
        disks: resources.disks
    }
}
