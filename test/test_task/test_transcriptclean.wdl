version 1.0

# Test workflow for transcriptclean task in ENCODE long read rna pipeline

import "../../long-read-rna-pipeline.wdl" as longrna

workflow test_transcriptclean {
    input {
        File sam
        File reference_genome
        File splice_junctions
        Boolean canonical_only
        File? variants
        String output_prefix
        Int lines_to_skip
        String output_fn
        Resources resources = {
           "cpu": 1,
           "memory_gb": 2,
           "disks": "local-disk 50",
        }
    }

    call longrna.transcriptclean { input:
        sam=sam,
        reference_genome=reference_genome,
        splice_junctions=splice_junctions,
        variants=variants,
        output_prefix=output_prefix,
        canonical_only=canonical_only,
        resources=resources,
    }

    call longrna.skipNfirstlines { input:
        input_file=transcriptclean.corrected_sam,
        output_fn=output_fn,
        lines_to_skip=lines_to_skip,
        resources=resources,
    }
}
