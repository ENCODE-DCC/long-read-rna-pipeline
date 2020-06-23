version 1.0


import "../structs/resources.wdl"


task talon_reformat_gtf {
    input {
        File input_gtf
        Resources resources
        String output_filename = "reformatted.gtf"
    }

    String prefix = basename(input_gtf, ".gtf")
    String original_outfn = prefix + "_reformatted.gtf"
    String prefix_gtf = basename(input_gtf)

    command {
        ln ~{input_gtf} .
        talon_reformat_gtf \
            --gtf ~{prefix_gtf}
        mv ~{original_outfn} ~{output_filename}
    }

    output {
        File reformatted_gtf = output_filename
    }

    runtime {
        cpu: resources.cpu
        memory: "~{resources.memory_gb} GB"
        disks: resources.disks
    }
}
