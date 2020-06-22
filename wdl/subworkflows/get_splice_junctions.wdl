version 1.0


import "../tasks/awk.wdl"
import "../tasks/gzip.wdl"
import "../tasks/transcriptclean.wdl"


workflow get_splice_junctions {
    input {
        File annotation_gtf
        File reference_fasta
        Resources resources
        String splice_junctions_output_filename
    }

    call gzip.gzip as reference {
        input:
            input_file=reference_fasta,
            output_filename="ref.fasta",
            params= {
                "decompress": true,
                "noname": false,
            },
            resources=resources,
    }

    call gzip.gzip as annotation {
        input:
            input_file=annotation_gtf,
            output_filename="anno.gtf",
            params= {
                "decompress": true,
                "noname": false,
            },
            resources=resources,
    }

    call awk.clean_reference_fasta {
        input:
            fasta=reference.out,
            resources=resources,
    }

    call transcriptclean.get_SJs_from_gtf {
        input:
            annotation_gtf=annotation.out,
            reference_fasta=clean_reference_fasta.cleaned_fasta,
            output_filename=splice_junctions_output_filename,
            resources=resources,
    }

    output {
        File splice_junctions = get_SJs_from_gtf.splice_junctions
    }
}
