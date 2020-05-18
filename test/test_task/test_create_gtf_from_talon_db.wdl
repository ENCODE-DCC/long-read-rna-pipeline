version 1.0

# Test workflow for create_gtf_from_talon_db task in ENCODE long read rna pipeline

import "../../long-read-rna-pipeline.wdl" as longrna

workflow test_create_gtf_from_talon_db {
    input {
        File talon_db
        String annotation_name
        String genome_build
        String output_prefix
        Int ncpus
        Int ramGB
        String disks
    }

    call longrna.create_gtf_from_talon_db { input:
        talon_db=talon_db,
        annotation_name=annotation_name,
        genome_build=genome_build,
        output_prefix=output_prefix,
        ncpus=ncpus,
        ramGB=ramGB,
        disks=disks,
    }
}
