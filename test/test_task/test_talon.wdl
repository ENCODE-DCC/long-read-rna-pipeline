# Test workflow for talon task in ENCODE long read rna pipeline

import "../../long-read-rna-pipeline.wdl" as longrna

workflow test_talon {
    File talon_db
    File sam
    String genome_build
    String output_prefix
    String platform
    Int ncpus
    Int ramGB
    String disks

    call longrna.talon { input:
        talon_db = talon_db,
        sam = sam,
        genome_build = genome_build,
        output_prefix = output_prefix,
        platform = platform,
        ncpus = ncpus,
        ramGB = ramGB,
        disks = disks
    }
}