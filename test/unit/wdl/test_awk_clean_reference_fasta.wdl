version 1.0


import "../../../wdl/tasks/awk.wdl"


workflow test_awk_clean_reference_fasta {
    input {
        File fasta
        Resources resources
        String output_filename
    }

    call awk.clean_reference_fasta {
        input:
            fasta=fasta,
            output_filename=output_filename,
            resources=resources,
    }
}
