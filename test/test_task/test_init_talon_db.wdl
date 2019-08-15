# Test workflow for init_talon_db task in ENCODE long read rna pipeline

import "../../long-read-rna-pipeline.wdl" as longrna

workflow test_init_talon_db {
    File annotation_gtf
    String annotation_name
    String ref_genome_name
    String output_prefix
    Int ncpus
    Int ramGB
    String disks

    call longrna.init_talon_db { input:
        talon_db = talon_db,
        annotation_name = annotation_name,
        ref_genome_name = ref_genome_name,
        output_prefix = output_prefix,
        ncpus = ncpus,
        ramGB = ramGB,
        disks = disks,
    }
}

