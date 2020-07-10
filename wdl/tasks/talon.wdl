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
            -gtf ~{prefix_gtf}
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

task talon_label_reads {
    input {
        File input_sam
        File reference_genome
        Int fraca_range_size=20
        Resources resources
        String output_bam_filename = "labeled.bam"
        String output_sam_filename = "labeled.sam"
        String output_tsv_filename = "labeled.tsv"
    }

    String sam_prefix = basename(input_sam)
    String reference_prefix = basename(reference_genome)

    command {
        ln ~{input_sam} .
        ln ~{reference_genome} .
        talon_label_reads \
            --f ~{sam_prefix} \
            --g ~{reference_prefix} \
            --t 1 \
            --ar ~{fraca_range_size}
        mv talon_prelabels_labeled.sam ~{output_sam_filename}
        mv talon_prelabels_read_labels.tsv ~{output_tsv_filename}
        samtools view -S -b ~{output_sam_filename} > ~{output_bam_filename}
    }

    output {
        File labeled_bam = output_bam_filename
        File labeled_sam = output_sam_filename
        File read_labels_tsv = output_tsv_filename
    }

    runtime {
        cpu: resources.cpu
        memory: "~{resources.memory_gb} GB"
        disks: resources.disks
    }
}
