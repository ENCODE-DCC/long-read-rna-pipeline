version 1.0


import "../../../wdl/tasks/talon.wdl"


workflow test_talon_talon_reformat_gtf {
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
    call talon.talon_reformat_gtf {
        input:
            input_gtf=input_gtf,
            resources=resources,
            runtime_environment=runtime_environment,
    }
}
