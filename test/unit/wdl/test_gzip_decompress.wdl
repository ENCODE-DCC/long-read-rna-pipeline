version 1.0


import "../../../wdl/tasks/gzip.wdl"


workflow test_decompress {
    input {
        File input_file
        GzipParams params
        Resources resources
        String output_filename
    }

    call gzip.gzip {
        input:
            input_file=input_file,
            output_filename=output_filename,
            params=params,
            resources=resources,
    }
}
