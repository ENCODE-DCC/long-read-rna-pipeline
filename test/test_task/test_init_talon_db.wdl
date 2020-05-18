version 1.0

# Test workflow for init_talon_db task in ENCODE long read rna pipeline

import "../../long-read-rna-pipeline.wdl" as longrna

workflow test_init_talon_db {
    input {
        File annotation_gtf
        String annotation_name
        String ref_genome_name
        String output_prefix
        String? idprefix
        Int ncpus
        Int ramGB
        String disks
    }

    call longrna.init_talon_db { input:
        annotation_gtf=annotation_gtf,
        annotation_name=annotation_name,
        ref_genome_name=ref_genome_name,
        output_prefix=output_prefix,
        idprefix=idprefix,
        ncpus=ncpus,
        ramGB=ramGB,
        disks=disks,
    }
}
