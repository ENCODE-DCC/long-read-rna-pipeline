version 1.0


import "../../../wdl/tasks/transcriptclean.wdl"


workflow test_transcriptclean_get_SJs_from_gtf {
    input {
        File annotation_gtf
        File reference_fasta
        Resources resources
        String output_filename
        String docker
        String singularity = ""
    }

    RuntimeEnvironment runtime_environment = {
      "docker": docker,
      "singularity": singularity
    }
    call transcriptclean.get_SJs_from_gtf {
        input:
            annotation_gtf=annotation_gtf,
            reference_fasta=reference_fasta,
            resources=resources,
            output_filename=output_filename,
            runtime_environment=runtime_environment,
    }
}
