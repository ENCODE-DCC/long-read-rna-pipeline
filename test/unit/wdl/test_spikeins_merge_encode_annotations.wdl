version 1.0


import "../../../wdl/tasks/spikeins.wdl"


workflow test_spikeins_merge_encode_annotations {
    input {
        File spikein_fasta
        Resources resources
        String docker
        String singularity = ""
    }

    RuntimeEnvironment runtime_environment = {
      "docker": docker,
      "singularity": singularity
    }
    call spikeins.merge_encode_annotations {
        input:
            spikein_fasta=spikein_fasta,
            resources=resources,
            runtime_environment=runtime_environment,
    }
}
