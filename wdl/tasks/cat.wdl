version 1.0


import "../structs/resources.wdl"
import "../structs/runtime.wdl"


task cat {
    input {
        Array[File] files
        Resources resources
        String out = "concatenated"
        RuntimeEnvironment runtime_environment
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
        docker: runtime_environment.docker
        singularity: runtime_environment.singularity
    }
}
