version 1.0


import "../../../wdl/tasks/spikeins.wdl"


workflow test_spikeins_separate_multistrand_genes {
    input {
        File input_gtf
        Resources resources
        String docker
        String singularity = ""
    }

    RuntimeEnvironment runtime_environment = {
      "docker": docker,
      "singularity": singularity
    }
    call spikeins.separate_multistrand_genes {
        input:
            input_gtf=input_gtf,
            resources=resources,
            runtime_environment=runtime_environment,
    }
}

