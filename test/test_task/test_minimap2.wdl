# Test workflow for minimap2 task in ENCODE long read rna pipeline

import "../../long-read-rna-pipeline.wdl" as longrna

workflow test_minimap2 {
    File fastq
    File reference_genome
    String output_prefix
    String input_type
    Int lines_to_skip
    String output_fn
    Int ncpus
    Int ramGB
    String disks

    call longrna.minimap2 { input:
        fastq=fastq,
        reference_genome=reference_genome,
        output_prefix=output_prefix,
        input_type=input_type,
        ncpus=ncpus,
        ramGB=ramGB,
        disks=disks,
    }

    call longrna.skipNfirstlines { input:
        input_file=minimap2.sam,
        output_fn=output_fn,
        lines_to_skip=lines_to_skip,
        ncpus=ncpus,
        ramGB=ramGB,
        disks=disks,
    }
}
