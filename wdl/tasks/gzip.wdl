version 1.0


import "../structs/gzip.wdl"
import "../structs/resources.wdl"


task gzip {
    input {
        File input_file 
        String output_filename = "out"
        GzipParams params
        Resources resources
    }

    String prefix = basename(input_file)

    command {
        ln ~{input_file} .
        gzip \
            -c \
            ~{true="-n" false="" params.noname} \
            ~{true="-d" false="" params.decompress} \
            ~{prefix} \
            > ~{output_filename}
    }

    output {
        File out = output_filename
    }

    runtime {
        cpu: resources.cpu
        memory: "~{resources.memory_gb} GB"
        disks: resources.disks
    }
}
