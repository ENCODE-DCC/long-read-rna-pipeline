version 1.0


import "../../../wdl/subworkflows/make_gtf_from_spikein_fasta.wdl"


workflow test_make_gtf_from_spikein_fasta {
    call make_gtf_from_spikein_fasta.make_gtf_from_spikein_fasta
}
