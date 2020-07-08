version 1.0


import "../../../wdl/subworkflows/crop_reference_fasta_headers.wdl"


workflow test_crop_reference_fasta_headers {
    call crop_reference_fasta_headers.crop_reference_fasta_headers
}
