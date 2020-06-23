version 1.0


import "../../../wdl/tasks/spikeins.wdl"


workflow test_spikeins_separate_multistrand_genes {
    input {
        File input_gtf
        Resources resources
    }

    call spikeins.separate_multistrand_genes {
        input:
            input_gtf=input_gtf,
            resources=resources,
    }
}

