version 1.0


import "../structs/resources.wdl"
import "../tasks/awk.wdl"
import "../tasks/gzip.wdl"


workflow crop_reference_fasta_headers {
    input {
        File reference_fasta
        Resources resources
        RuntimeEnvironment runtime_environment
    }

    call gzip.gzip as decompressed_reference {
        input:
            input_file=reference_fasta,
            params= {
                "decompress": true,
                "noname": false,
            },
            resources=resources,
            runtime_environment=runtime_environment,
    }

    call awk.clean_reference_fasta as clean_decompressed {
        input:
            fasta=decompressed_reference.out,
            output_filename="clean_ref.fasta",
            resources=resources,
            runtime_environment=runtime_environment,
    }

    call gzip.gzip as clean_compressed {
        input:
            input_file=clean_decompressed.cleaned_fasta,
            output_filename="clean_ref.fasta.gz",
            params= {
                "decompress": false,
                "noname": true,
            },
            resources=resources,
            runtime_environment=runtime_environment,
    }

    output {
        File compressed = clean_compressed.out
        File decompressed = clean_decompressed.cleaned_fasta
    }
}
