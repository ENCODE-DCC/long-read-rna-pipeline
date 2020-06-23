version 1.0


import "../tasks/cat.wdl"


workflow concatenate_files {
    input {
        Array[File] files
        Resources resources
        String output_filename = "concatenated"
    }

    call cat.cat {
        input:
            files=files,
            resources=resources,
            out=output_filename,
    }

    output {
        File concatenated_file = cat.concatenated
    }
}
