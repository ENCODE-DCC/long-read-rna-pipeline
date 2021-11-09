version 1.0


import "../../../wdl/tasks/cat.wdl"


workflow test_cat_cat {
    input {
        Array[File] files
        Resources resources
        String docker
        String singularity = ""
    }

    RuntimeEnvironment runtime_environment = {
      "docker": docker,
      "singularity": singularity
    }

    call cat.cat {
        input:
            files=files,
            resources=resources,
            runtime_environment=runtime_environment,
    }
}
