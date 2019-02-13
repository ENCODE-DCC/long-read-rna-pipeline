# Test workflow for transcriptclean task in ENCODE long read rna pipeline

import "../../long-read-rna-pipeline.wdl" as longrna

workflow test_filter_transcriptclean {
    File sam
    String output_prefix
    Int lines_to_skip 
    String output_fn
    Int ncpus
    Int ramGB
    String disks

    call longrna.filter_transcriptclean { input:
        sam = sam,
        output_prefix = output_prefix,
        ncpus = ncpus,
        ramGB = ramGB,
        disks = disks
    }

    call longrna.skipNfirstlines { input:
        input_file = filter_transcriptclean.filtered_sam,
        output_fn = output_fn,
        lines_to_skip = lines_to_skip,
        ncpus = ncpus,
        ramGB = ramGB,
        disks = disks,
    }

}