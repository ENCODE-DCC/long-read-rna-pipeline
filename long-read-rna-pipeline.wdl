version 1.0

# ENCODE long read rna pipeline
# Maintainer: Otto Jolanki

#CAPER docker quay.io/encode-dcc/long-read-rna-pipeline:v1.3
#CAPER singularity docker://quay.io/encode-dcc/long-read-rna-pipeline:v1.3
#CROO out_def https://storage.googleapis.com/encode-pipeline-output-definition/longreadrna.output_definition.json
workflow long_read_rna_pipeline {
    input {
        # Input fastqs, gzipped.
        Array[File] fastqs
        # Reference genome. Fasta format, gzipped.
        File reference_genome
        # Annotation file, gtf format, gzipped.
        File annotation
        # Variants file, vcf format, gzipped.
        File? variants
        # Splice junctions file, produced by get-splice-juctions.wdl
        File splice_junctions
        # Prefix that gets added into output filenames. Default "my_experiment", can not be empty.
        String experiment_prefix = "my_experiment"
        # Is the data from "pacbio" or "nanopore"
        String input_type = "pacbio"
        # Array[String] of prefixes for naming novel discoveries in eventual TALON runs (default = "TALON").
        # If defined, length of this array needs to be equal to number of replicates.
        Array[String] talon_prefixes = []
        # Genome build name, for TALON. This must be in the initial_talon_db
        String genome_build
        # Annotation name, for creating abundance from talon db. This must be in the initial_talon_db
        String annotation_name
        # If this option is set, TranscriptClean will only output transcripts that are either canonical
        # or that contain annotated noncanonical junctions to the clean SAM and Fasta files at the end
        # of the run.
        Boolean canonical_only = true
        # Resouces
        # Task init_talon_db
        Int init_talon_db_ncpus
        Int init_talon_db_ramGB
        String init_talon_db_disks
        # Task minimap2
        Int minimap2_ncpus
        Int minimap2_ramGB
        String minimap2_disks
        # Task transcriptclean
        Int transcriptclean_ncpus
        Int transcriptclean_ramGB
        String transcriptclean_disks
        # Task talon
        Int talon_ncpus
        Int talon_ramGB
        String talon_disks
        # Task create_abundance_from_talon_db
        Int create_abundance_from_talon_db_ncpus
        Int create_abundance_from_talon_db_ramGB
        String create_abundance_from_talon_db_disks
        # Task create_gtf_from_talon_db
        Int create_gtf_from_talon_db_ncpus
        Int create_gtf_from_talon_db_ramGB
        String create_gtf_from_talon_db_disks
        # Task calculate_spearman
        Int calculate_spearman_ncpus = 1
        Int calculate_spearman_ramGB = 2
        String calculate_spearman_disks = "local-disk 20 HDD"
    }

    scatter (i in range(length(fastqs))) {

        String talon_prefix = if length(talon_prefixes) > 0 then talon_prefixes[i] else "TALON"

        call init_talon_db { input:
            annotation_gtf=annotation,
            annotation_name=annotation_name,
            ref_genome_name=genome_build,
            idprefix=talon_prefix,
            output_prefix="rep"+(i+1)+experiment_prefix,
            ncpus=init_talon_db_ncpus,
            ramGB=init_talon_db_ramGB,
            disks=init_talon_db_disks
        }

        call minimap2 { input:
            fastq=fastqs[i],
            reference_genome=reference_genome,
            output_prefix="rep"+(i+1)+experiment_prefix,
            input_type=input_type,
            ncpus=minimap2_ncpus,
            ramGB=minimap2_ramGB,
            disks=minimap2_disks,
        }

        call transcriptclean { input:
            sam=minimap2.sam,
            reference_genome=reference_genome,
            splice_junctions=splice_junctions,
            variants=variants,
            output_prefix="rep"+(i+1)+experiment_prefix,
            canonical_only=canonical_only,
            ncpus=transcriptclean_ncpus,
            ramGB=transcriptclean_ramGB,
            disks=transcriptclean_disks,
        }

        call talon { input:
            talon_db=init_talon_db.database,
            sam=transcriptclean.corrected_sam,
            genome_build=genome_build,
            output_prefix="rep"+(i+1)+experiment_prefix,
            platform=input_type,
            ncpus=talon_ncpus,
            ramGB=talon_ramGB,
            disks=talon_disks,
        }

        call create_abundance_from_talon_db { input:
            talon_db=talon.talon_db_out,
            annotation_name=annotation_name,
            genome_build=genome_build,
            output_prefix="rep"+(i+1)+experiment_prefix,
            idprefix=talon_prefix,
            ncpus=create_abundance_from_talon_db_ncpus,
            ramGB=create_abundance_from_talon_db_ramGB,
            disks=create_abundance_from_talon_db_disks,
        }

        call create_gtf_from_talon_db { input:
            talon_db=talon.talon_db_out,
            annotation_name=annotation_name,
            genome_build=genome_build,
            output_prefix="rep"+(i+1)+experiment_prefix,
            ncpus=create_abundance_from_talon_db_ncpus,
            ramGB=create_abundance_from_talon_db_ramGB,
            disks=create_abundance_from_talon_db_disks,
        }
    }

    if (length(fastqs) == 2) {

        String rep1_idprefix = if length(talon_prefixes) > 0 then talon_prefixes[0] else "TALON"
        String rep2_idprefix = if length(talon_prefixes) > 0 then talon_prefixes[1] else "TALON"

        call calculate_spearman { input:
            rep1_abundance=create_abundance_from_talon_db.talon_abundance[0],
            rep2_abundance=create_abundance_from_talon_db.talon_abundance[1],
            rep1_idprefix=rep1_idprefix,
            rep2_idprefix=rep2_idprefix,
            output_prefix=experiment_prefix,
            ncpus=calculate_spearman_ncpus,
            ramGB=calculate_spearman_ramGB,
            disks=calculate_spearman_disks,
        }
    }
}

task init_talon_db {
    input {
        File annotation_gtf
        String annotation_name
        String ref_genome_name
        String output_prefix
        String? idprefix
        Int ncpus
        Int ramGB
        String disks
    }

    command {
        gzip -cd ~{annotation_gtf} > anno.gtf
        rm ~{annotation_gtf}
        python3.7 $(which initialize_talon_database.py) \
            --f anno.gtf \
            --a ~{annotation_name} \
            --g ~{ref_genome_name} \
            ~{"--idprefix " + idprefix} \
            --o ~{output_prefix}

        python3.7 $(which record_init_db_inputs.py) \
            --annotation_name ~{annotation_name} \
            --genome ~{ref_genome_name} \
            --outfile ~{output_prefix}_talon_inputs.json
        }

    output {
        File database = "~{output_prefix}.db"
        File talon_inputs = "~{output_prefix}_talon_inputs.json"
    }

    runtime {
        cpu: ncpus
        memory: "~{ramGB} GB"
        disks: disks
    }
}

task minimap2 {
    input {
       File fastq
       File reference_genome
       String output_prefix
       String input_type
       Int ncpus
       Int ramGB
       String disks
    }

    command <<<
        if [ "~{input_type}" == "pacbio" ]; then
            minimap2 -t ~{ncpus} -ax splice -uf --secondary=no -C5 \
                ~{reference_genome} \
                ~{fastq} \
                > ~{output_prefix}.sam \
                2> ~{output_prefix}_minimap2.log
        fi

        if [ "~{input_type}" == "nanopore" ]; then
            minimap2 -t ~{ncpus} -ax splice -uf -k14 \
                ~{reference_genome} \
                ~{fastq} \
                > ~{output_prefix}.sam \
                2> ~{output_prefix}_minimap2.log
        fi

        gzip -cd ~{fastq} | grep "^@" | wc -l > FLNC.txt
        samtools view ~{output_prefix}.sam | awk '{if($2 == "0" || $2 == "16") print $1}' | sort -u | wc -l > mapped.txt
        python3.7 $(which make_minimap_qc.py) --flnc FLNC.txt --mapped mapped.txt --outfile ~{output_prefix}_mapping_qc.json
        samtools view -S -b ~{output_prefix}.sam > ~{output_prefix}.bam
    >>>

    output {
        File sam = "~{output_prefix}.sam"
        File bam = "{output_prefix}.bam"
        File log = "~{output_prefix}_minimap2.log"
        File mapping_qc = "~{output_prefix}_mapping_qc.json"
    }

    runtime {
        cpu: ncpus
        memory: "~{ramGB} GB"
        disks: disks
    }
}

task transcriptclean {
    input {
        File sam
        File reference_genome
        File splice_junctions
        File? variants
        String output_prefix
        Boolean canonical_only
        Int ncpus
        Int ramGB
        String disks
    }

    command <<<
        gzip -cd ~{reference_genome} > ref.fasta

        if [ $(head -n 1 ref.fasta | awk '{print NF}') -gt 1 ]; then
            cat ref.fasta | awk '{print $1}' > reference.fasta
        else
            mv ref.fasta reference.fasta
        fi

        test -f ~{variants} && gzip -cd ~{variants} > variants.vcf


        python3.7 $(which TranscriptClean.py) --sam ~{sam} \
            --genome reference.fasta \
            --spliceJns ~{splice_junctions} \
            ~{if defined(variants) then "--variants variants.vcf" else ""} \
            --maxLenIndel 5 \
            --maxSJOffset 5 \
            -m true \
            -i true \
            --correctSJs true \
            --primaryOnly \
            --outprefix ~{output_prefix} \
            --threads ~{ncpus} \
            ~{if canonical_only then "--canonOnly" else ""}

        samtools view -S -b ~{output_prefix}_clean.sam > ~{output_prefix}_clean.bam
        Rscript $(which generate_report.R) ~{output_prefix}
    >>>

    output {
        File corrected_bam = "~{output_prefix}_clean.bam"
        File corrected_sam = "~{output_prefix}_clean.sam"
        File corrected_fasta = "{output_prefix}_clean.fa"
        File transcript_log = "~{output_prefix}_clean.log"
        File transcript_error_log = "~{output_prefix}_clean.TE.log"
        File report = "~{output_prefix}_report.pdf"
    }

    runtime {
        cpu: ncpus
        memory: "~{ramGB} GB"
        disks: disks
    }
}

task talon {
    input {
        File talon_db
        File sam
        String genome_build
        String output_prefix
        String platform
        Int ncpus
        Int ramGB
        String disks
    }

    command {
        echo ~{output_prefix},~{output_prefix},~{platform},~{sam} > ~{output_prefix}_talon_config.csv
        cp ~{talon_db} ./~{output_prefix}_talon.db
        python3.7 $(which talon.py) --f ~{output_prefix}_talon_config.csv \
                                    --db ~{output_prefix}_talon.db \
                                    --build ~{genome_build} \
                                    --o ~{output_prefix}
    }

    output {
        File talon_config = glob("*_talon_config.csv")[0]
        File talon_log = glob("*_talon_QC.log")[0]
        File talon_db_out = glob("*_talon.db")[0]
    }

    runtime {
        cpu: ncpus
        memory: "~{ramGB} GB"
        disks: disks
    }

}

task create_abundance_from_talon_db {
    input {
        File talon_db
        String annotation_name
        String genome_build
        String output_prefix
        String idprefix
        Int ncpus
        Int ramGB
        String disks
    }

    command {
        python3.7 $(which create_abundance_file_from_database.py) --db=~{talon_db} \
                                                                  -a ~{annotation_name} \
                                                                  --build ~{genome_build} \
                                                                  --o=~{output_prefix}
        python3.7 $(which calculate_number_of_genes_detected.py) --abundance ~{output_prefix}_talon_abundance.tsv \
                                                                 --counts_colname ~{output_prefix} \
                                                                 --idprefix ~{idprefix} \
                                                                 --outfile ~{output_prefix}_number_of_genes_detected.json
    }

    output {
        File talon_abundance = glob("*_talon_abundance.tsv")[0]
        File number_of_genes_detected = glob("*_number_of_genes_detected.json")[0]
    }

    runtime {
        cpu: ncpus
        memory: "~{ramGB} GB"
        disks: disks
    }

}

task create_gtf_from_talon_db {
    input {
        File talon_db
        String annotation_name
        String genome_build
        String output_prefix
        Int ncpus
        Int ramGB
        String disks
    }

    command {
        python3.7 $(which create_GTF_from_database.py) --db ~{talon_db} \
                                                        -a ~{annotation_name} \
                                                        --build ~{genome_build} \
                                                        --o ~{output_prefix}
        gzip -n ~{output_prefix}_talon.gtf
    }

    output {
        File gtf = glob("*.gtf.gz")[0]
    }

    runtime {
        cpu: ncpus
        memory: "~{ramGB} GB"
        disks: disks
    }

}

task calculate_spearman {
    input {
        File rep1_abundance
        File rep2_abundance
        String rep1_idprefix
        String rep2_idprefix
        String output_prefix
        Int ncpus
        Int ramGB
        String disks
    }

    command {
        python3.7 $(which calculate_correlation.py) --rep1_abundance ~{rep1_abundance} \
                                                    --rep2_abundance ~{rep2_abundance} \
                                                    --rep1_idprefix ~{rep1_idprefix} \
                                                    --rep2_idprefix ~{rep2_idprefix} \
                                                    --outfile ~{output_prefix}_spearman.json
    }

    output {
        File spearman = glob("*_spearman.json")[0]
    }

    runtime {
        cpu: ncpus
        memory: "~{ramGB} GB"
        disks: disks
    }

}
task skipNfirstlines {
    input {
        File input_file
        String output_fn
        Int lines_to_skip
        Int ncpus
        Int ramGB
        String disks
    }

    command {
        sed 1,~{lines_to_skip}d ~{input_file} > ~{output_fn}
    }

    output {
        File output_file = glob("~{output_fn}")[0]
    }

    runtime {
        cpu: ncpus
        memory: "~{ramGB} GB"
        disks: disks
    }
}
