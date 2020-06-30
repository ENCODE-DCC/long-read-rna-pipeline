version 1.0

# Test workflow for calculate_spearman task in ENCODE long read rna pipeline

import "../../long-read-rna-pipeline.wdl" as longrna

workflow test_calculate_spearman {
    input {
        File rep1_abundance
        File rep2_abundance
        String rep1_idprefix
        String rep2_idprefix
        String output_prefix
        Resources resources = {
           "cpu": 1,
           "memory_gb": 2,
           "disks": "local-disk 50",
        }
    }

    call longrna.calculate_spearman { input:
        rep1_abundance=rep1_abundance,
        rep2_abundance=rep2_abundance,
        rep1_idprefix=rep1_idprefix,
        rep2_idprefix=rep2_idprefix,
        output_prefix=output_prefix,
        resources=resources,
    }
}
