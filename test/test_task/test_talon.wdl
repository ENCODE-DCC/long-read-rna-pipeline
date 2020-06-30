version 1.0

# Test workflow for talon task in ENCODE long read rna pipeline

import "../../long-read-rna-pipeline.wdl" as longrna

workflow test_talon {
    input {
        File talon_db
        File sam
        String genome_build
        String output_prefix
        String platform
        Resources resources = {
           "cpu": 1,
           "memory_gb": 2,
           "disks": "local-disk 50",
        }
    }

    call longrna.talon { input:
        talon_db=talon_db,
        sam=sam,
        genome_build=genome_build,
        output_prefix=output_prefix,
        platform=platform,
        resources=resources,
    }
}
