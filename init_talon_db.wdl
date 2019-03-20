workflow init_talon_db {
    File annotation_gtf
    String annotation_name
    String ref_genome_name
    String output_prefix
    Int ncpu
    Int ramGB
    String disk

    call init_db { input:
        annotation_gtf = annotation_gtf,
        annotation_name = annotation_name,
        ref_genome_name = ref_genome_name,
        output_prefix = output_prefix,
        ncpu = ncpu,
        ramGB = ramGB,
        disk = disk,
    }
}

task init_db {
    File annotation_gtf
    String annotation_name
    String ref_genome_name
    String output_prefix
    Int ncpu
    Int ramGB
    String disk

    command {
        python $(which initialize_talon_database.py) \
            --f ${annotation_gtf} \
            --a ${annotation_name} \
            --g ${ref_genome_name} \
            --o ${output_prefix}
        }
    
    output {
        File database = glob("*.db")[0]
           }

    runtime {
        cpu: ncpu
        memory: "${ramGB} GB"
        disks: select_first(["local-disk 100 SSD", disk])
        }
}