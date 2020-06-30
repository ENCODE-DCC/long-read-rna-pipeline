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
        Resources resources = {
           "cpu": 1,
           "memory_gb": 2,
           "disks": "local-disk 50",
        }
    }

    call longrna.init_talon_db { input:
        annotation_gtf=annotation_gtf,
        annotation_name=annotation_name,
        ref_genome_name=ref_genome_name,
        output_prefix=output_prefix,
        idprefix=idprefix,
        resources=resources,
    }
}
