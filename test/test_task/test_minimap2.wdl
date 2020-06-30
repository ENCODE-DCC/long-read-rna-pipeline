version 1.0

# Test workflow for minimap2 task in ENCODE long read rna pipeline

import "../../long-read-rna-pipeline.wdl" as longrna

workflow test_minimap2 {
    input {
        File fastq
        File reference_genome
        String output_prefix
        String input_type
        Int lines_to_skip
        String output_fn
        Resources resources = {
           "cpu": 1,
           "memory_gb": 2,
           "disks": "local-disk 50",
        }
    }

    call longrna.minimap2 { input:
        fastq=fastq,
        reference_genome=reference_genome,
        output_prefix=output_prefix,
        input_type=input_type,
        resources=resources,
    }

    call longrna.skipNfirstlines { input:
        input_file=minimap2.sam,
        output_fn=output_fn,
        lines_to_skip=lines_to_skip,
        resources=resources,
    }
}
