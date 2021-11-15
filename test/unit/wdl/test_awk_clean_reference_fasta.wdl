version 1.0


import "../../../wdl/tasks/awk.wdl"


workflow test_awk_clean_reference_fasta {
    input {
        File fasta
        Resources resources
        String output_filename
        String docker
        String singularity = ""
    }

    RuntimeEnvironment runtime_environment = {
      "docker": docker,
      "singularity": singularity
    }

    call awk.clean_reference_fasta {
        input:
            fasta=fasta,
            output_filename=output_filename,
            resources=resources,
            runtime_environment=runtime_environment,
    }
}
