version 1.0


import "../../../wdl/tasks/gzip.wdl"


workflow test_gzip_decompress {
    input {
        File input_file
        GzipParams params
        Resources resources
        String output_filename
        String docker
        String singularity = ""
    }

    RuntimeEnvironment runtime_environment = {
      "docker": docker,
      "singularity": singularity
    }
    call gzip.gzip {
        input:
            input_file=input_file,
            output_filename=output_filename,
            params=params,
            resources=resources,
            runtime_environment=runtime_environment,
    }
}
