version 1.0


import "../tasks/gzip.wdl"
import "../tasks/spikeins.wdl"
import "../tasks/talon.wdl"


workflow make_gtf_from_spikein_fasta {
    input {
        File spikein_fasta
        Resources resources
        String output_filename = "from_spikein_fasta.gtf.gz"
        RuntimeEnvironment runtime_environment
    }

    call spikeins.merge_encode_annotations {
        input:
            resources=resources,
            spikein_fasta=spikein_fasta,
            runtime_environment=runtime_environment,
    }

    call spikeins.separate_multistrand_genes {
        input:
            input_gtf=merge_encode_annotations.spikein_gtf,
            resources=resources,
            runtime_environment=runtime_environment,
    }

    call talon.talon_reformat_gtf {
        input:
            input_gtf=separate_multistrand_genes.separated_gtf,
            resources=resources,
            runtime_environment=runtime_environment,
    }

    call gzip.gzip {
        input:
            input_file=talon_reformat_gtf.reformatted_gtf,
            output_filename=output_filename,
            params= {
                "decompress": false,
                "noname": true,
            },
            resources=resources,
            runtime_environment=runtime_environment,
    }

    output {
        File spikein_gtf = gzip.out
    }
}
