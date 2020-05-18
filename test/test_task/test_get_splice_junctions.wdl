version 1.0

# Test workflow for get_splice_junctions task in ENCODE long read rna pipeline

import "../../long-read-rna-pipeline.wdl" as longrna

workflow test_get_splice_junctions {
    input {
        File annotation
        File reference_genome
        String output_prefix
        Int ncpus
        Int ramGB
        String disks
    }

    call longrna.get_splice_junctions { input:
        annotation=annotation,
        reference_genome=reference_genome,
        output_prefix=output_prefix,
        ncpus=ncpus,
        ramGB=ramGB,
        disks=disks,
    }
}
