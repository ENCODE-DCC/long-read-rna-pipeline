version 1.0


import "../../../wdl/tasks/transcriptclean.wdl"


workflow test_transcriptclean_get_SJs_from_gtf {
    input {
        File annotation_gtf
        File reference_fasta
        Resources resources
        String output_filename
    }

    call transcriptclean.get_SJs_from_gtf {
        input:
            annotation_gtf=annotation_gtf,
            reference_fasta=reference_fasta,
            resources=resources,
            output_filename=output_filename,
    }
}
