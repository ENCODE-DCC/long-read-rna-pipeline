version 1.0

# Test workflow for create_abundance_from_talon_db task in ENCODE long read rna pipeline

import "../../long-read-rna-pipeline.wdl" as longrna

workflow test_create_abundance_from_talon_db {
    input {
        File talon_db
        String annotation_name
        String genome_build
        String output_prefix
        String idprefix
        Resources resources = {
           "cpu": 1,
           "memory_gb": 2,
           "disks": "local-disk 50",
        }
        String docker
        String singularity=""
    }

    RuntimeEnvironment runtime_environment = {
      "docker": docker,
      "singularity": singularity
    }

    call longrna.create_abundance_from_talon_db { input:
        talon_db=talon_db,
        annotation_name=annotation_name,
        genome_build=genome_build,
        output_prefix=output_prefix,
        idprefix=idprefix,
        resources=resources,
        runtime_environment=runtime_environment,
    }
}
