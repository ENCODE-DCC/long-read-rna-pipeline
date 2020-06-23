version 1.0


import "../structs/resources.wdl"


task cat {
    input {
        Array[File] files
        Resources resources
        String out = "concatenated"
    }

    command {
        cat \
            ~{sep=" " files} \
            > ~{out}
    }

    output {
        File concatenated = out
    }

    runtime {
        cpu: resources.cpu
        memory: "~{resources.memory_gb} GB"
        disks: resources.disks
    }
}
