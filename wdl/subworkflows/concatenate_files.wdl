version 1.0


import "../tasks/cat.wdl"


workflow concatenate_files {
    input {
        Array[File] files
        Resources resources
        String output_filename = "concatenated"
        RuntimeEnvironment runtime_environment
    }

    call cat.cat {
        input:
            files=files,
            resources=resources,
            out=output_filename,
            runtime_environment=runtime_environment,
    }

    output {
        File concatenated_file = cat.concatenated
    }
}
