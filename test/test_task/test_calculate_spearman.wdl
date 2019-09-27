# Test workflow for calculate_spearman task in ENCODE long read rna pipeline

import "../../long-read-rna-pipeline.wdl" as longrna

workflow test_calculate_spearman {
    File rep1_abundance
    File rep2_abundance
    String rep1_idprefix
    String rep2_idprefix
    String output_prefix
    Int ncpus
    Int ramGB
    String disks

    call longrna.calculate_spearman { input:
        rep1_abundance = rep1_abundance,
        rep2_abundance = rep2_abundance,
        rep1_idprefix = rep1_idprefix,
        rep2_idprefix = rep2_idprefix,
        output_prefix = output_prefix,
        ncpus = ncpus,
        ramGB = ramGB,
        disks = disks
    }
}