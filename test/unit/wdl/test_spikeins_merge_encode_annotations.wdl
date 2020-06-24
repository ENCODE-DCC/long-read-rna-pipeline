version 1.0


import "../../../wdl/tasks/spikeins.wdl"


workflow test_spikeins_merge_encode_annotations {
    input {
        File spikein_fasta
        Resources resources
    }

    call spikeins.merge_encode_annotations {
        input:
            spikein_fasta=spikein_fasta,
            resources=resources,
    }
}
