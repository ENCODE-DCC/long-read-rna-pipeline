version 1.0


import "wdl/subworkflows/concatenate_files.wdl"
import "wdl/subworkflows/crop_reference_fasta_headers.wdl"
import "wdl/subworkflows/make_gtf_from_spikein_fasta.wdl"
import "wdl/tasks/gzip.wdl"
import "wdl/tasks/talon.wdl"
import "wdl/tasks/transcriptclean.wdl"


workflow long_read_rna_pipeline {
    meta {
        author: "Otto Jolanki"
        version: "v2.0.0"
        caper_docker: "encodedcc/long-read-rna-pipeline:v2.0.0"
        caper_singularity: "docker://encodedcc/long-read-rna-pipeline:v2.0.0"
        croo_out_def: "https://storage.googleapis.com/encode-pipeline-output-definition/longreadrna.output_definition.json"
    }

    input {
        # Input fastqs, gzipped.
        Array[File] fastqs
        # Reference genome. Fasta format, gzipped.
        File reference_genome
        # Annotation file, gtf format, gzipped.
        File annotation
        # Spikein files, fasta format, gzipped.
        Array[File] spikeins = []
        # Variants file, vcf format, gzipped.
        File? variants
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
        Resources small_task_resources = {
           "cpu": 2,
           "memory_gb": 7,
           "disks": "local-disk 50 SSD",
        }
        Resources medium_task_resources = {
           "cpu": 6,
           "memory_gb": 32,
           "disks": "local-disk 100 SSD",
        }
        Resources large_task_resources = {
           "cpu": 16,
           "memory_gb": 60,
           "disks": "local-disk 150 SSD",
        }
        Resources xlarge_task_resources = {
           "cpu": 20,
           "memory_gb": 120,
           "disks": "local-disk 150 SSD",
        }
    }

    if (length(spikeins) > 1) {
        call concatenate_files.concatenate_files as combined_spikeins {
            input:
                files=spikeins,
                resources=small_task_resources,
        }
    }

    if (length(spikeins) > 0) {
        File spikes = select_first([combined_spikeins.concatenated_file,spikeins[0]])
        call make_gtf_from_spikein_fasta.make_gtf_from_spikein_fasta {
            input:
                spikein_fasta=spikes,
                resources=small_task_resources,
        }

        call concatenate_files.concatenate_files as combined_annotation {
            input:
               files=[annotation,make_gtf_from_spikein_fasta.spikein_gtf],
               resources=small_task_resources,
               output_filename="combined_annotation.gtf.gz",
        }

        call concatenate_files.concatenate_files as combined_reference {
            input:
               files=[reference_genome,spikes],
               resources=small_task_resources,
               output_filename="combined_reference.fasta.gz",
        }
    }

    File combined_fasta = select_first([combined_reference.concatenated_file,reference_genome])
    File combined_gtf = select_first([combined_annotation.concatenated_file,annotation])

    call crop_reference_fasta_headers.crop_reference_fasta_headers as clean_reference {
        input:
            reference_fasta=combined_fasta,
            resources=small_task_resources,
    }

    call gzip.gzip as decompressed_gtf {
        input:
            input_file=combined_gtf,
            output_filename="combined_annotation.gtf",
            params={
                "decompress": true,
                "noname": false,
            },
            resources=small_task_resources,
    }

    call transcriptclean.get_SJs_from_gtf as get_splice_junctions {
        input:
            annotation_gtf=decompressed_gtf.out,
            reference_fasta=clean_reference.decompressed,
            resources=medium_task_resources,
            output_filename="SJs.txt",
    }

    scatter (i in range(length(fastqs))) {

        String talon_prefix = if length(talon_prefixes) > 0 then talon_prefixes[i] else "TALON"

        call init_talon_db { input:
            annotation_gtf=decompressed_gtf.out,
            annotation_name=annotation_name,
            ref_genome_name=genome_build,
            idprefix=talon_prefix,
            output_prefix="rep"+(i+1)+experiment_prefix,
            resources=medium_task_resources,
        }

        call minimap2 { input:
            fastq=fastqs[i],
            reference_genome=clean_reference.compressed,
            output_prefix="rep"+(i+1)+experiment_prefix,
            input_type=input_type,
            resources=large_task_resources,
        }

        call transcriptclean { input:
            sam=minimap2.sam,
            reference_genome=clean_reference.decompressed,
            splice_junctions=get_splice_junctions.splice_junctions,
            variants=variants,
            output_prefix="rep"+(i+1)+experiment_prefix,
            canonical_only=canonical_only,
            resources=xlarge_task_resources,
        }

        call talon.talon_label_reads {
            input:
                input_sam=transcriptclean.corrected_sam,
                output_bam_filename="rep"+(i+1)+experiment_prefix+"_labeled.bam",
                output_sam_filename="rep"+(i+1)+experiment_prefix+"_labeled.sam",
                output_tsv_filename="rep"+(i+1)+experiment_prefix+"_labeled.tsv",
                reference_genome=clean_reference.decompressed,
                resources=small_task_resources,
        }

        call talon { input:
            talon_db=init_talon_db.database,
            sam=talon_label_reads.labeled_sam,
            genome_build=genome_build,
            output_prefix="rep"+(i+1)+experiment_prefix,
            platform=input_type,
            resources=medium_task_resources,
        }

        call create_abundance_from_talon_db { input:
            talon_db=talon.talon_db_out,
            annotation_name=annotation_name,
            genome_build=genome_build,
            output_prefix="rep"+(i+1)+experiment_prefix,
            idprefix=talon_prefix,
            resources=medium_task_resources,
        }

        call create_gtf_from_talon_db { input:
            talon_db=talon.talon_db_out,
            annotation_name=annotation_name,
            genome_build=genome_build,
            output_prefix="rep"+(i+1)+experiment_prefix,
            resources=medium_task_resources,
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
            resources=small_task_resources,
            output_prefix=experiment_prefix,
        }
    }
}

task init_talon_db {
    input {
        File annotation_gtf
        Resources resources
        String annotation_name
        String ref_genome_name
        String output_prefix
        String? idprefix
    }

    command {
        talon_initialize_database \
            --f ~{annotation_gtf} \
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
        cpu: resources.cpu
        memory: "~{resources.memory_gb} GB"
        disks: resources.disks
    }
}

task minimap2 {
    input {
       File fastq
       File reference_genome
       Resources resources
       String output_prefix
       String input_type
    }

    command <<<
        if [ "~{input_type}" == "pacbio" ]; then
            minimap2 -t ~{resources.cpu} -ax splice -uf --secondary=no -C5 \
                ~{reference_genome} \
                ~{fastq} \
                > ~{output_prefix}.sam \
                2> ~{output_prefix}_minimap2.log
        fi

        if [ "~{input_type}" == "nanopore" ]; then
            minimap2 -t ~{resources.cpu} -ax splice -uf -k14 \
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
        File bam = "~{output_prefix}.bam"
        File log = "~{output_prefix}_minimap2.log"
        File mapping_qc = "~{output_prefix}_mapping_qc.json"
    }

    runtime {
        cpu: resources.cpu
        memory: "~{resources.memory_gb} GB"
        disks: resources.disks
    }
}

task transcriptclean {
    input {
        File sam
        File reference_genome
        File splice_junctions
        File? variants
        Resources resources
        String output_prefix
        Boolean canonical_only
    }

    command { 
        test -f ~{variants} && gzip -cd ~{variants} > variants.vcf
        python3.7 $(which TranscriptClean.py) --sam ~{sam} \
            --genome ~{reference_genome} \
            --spliceJns ~{splice_junctions} \
            ~{if defined(variants) then "--variants variants.vcf" else ""} \
            --maxLenIndel 5 \
            --maxSJOffset 5 \
            -m true \
            -i true \
            --correctSJs true \
            --primaryOnly \
            --outprefix ~{output_prefix} \
            --threads ~{resources.cpu} \
            ~{if canonical_only then "--canonOnly" else ""}

        samtools view -S -b ~{output_prefix}_clean.sam > ~{output_prefix}_clean.bam
        Rscript $(which generate_report.R) ~{output_prefix}
    }

    output {
        File corrected_bam = "~{output_prefix}_clean.bam"
        File corrected_sam = "~{output_prefix}_clean.sam"
        File corrected_fasta = "~{output_prefix}_clean.fa"
        File transcript_log = "~{output_prefix}_clean.log"
        File transcript_error_log = "~{output_prefix}_clean.TE.log"
        File report = "~{output_prefix}_report.pdf"
    }

    runtime {
        cpu: resources.cpu
        memory: "~{resources.memory_gb} GB"
        disks: resources.disks
    }
}

task talon {
    input {
        File talon_db
        File sam
        Resources resources
        String genome_build
        String output_prefix
        String platform
    }

    command {
        export TMPDIR=/tmp
        echo ~{output_prefix},~{output_prefix},~{platform},~{sam} > ~{output_prefix}_talon_config.csv
        cp ~{talon_db} ./~{output_prefix}_talon.db
        talon --f ~{output_prefix}_talon_config.csv \
                                    --db ~{output_prefix}_talon.db \
                                    --build ~{genome_build} \
                                    --o ~{output_prefix}
    }

    output {
        File talon_config = "~{output_prefix}_talon_config.csv"
        File talon_log = "~{output_prefix}_QC.log"
        File talon_db_out = "~{output_prefix}_talon.db"
    }

    runtime {
        cpu: resources.cpu
        memory: "~{resources.memory_gb} GB"
        disks: resources.disks
    }
}

task create_abundance_from_talon_db {
    input {
        File talon_db
        Resources resources
        String annotation_name
        String genome_build
        String output_prefix
        String idprefix
    }

    command {
        talon_abundance --db=~{talon_db} \
                        -a ~{annotation_name} \
                        --build ~{genome_build} \
                        --o=~{output_prefix}
        python3.7 $(which calculate_number_of_genes_detected.py) --abundance ~{output_prefix}_talon_abundance.tsv \
                                                                 --counts_colname ~{output_prefix} \
                                                                 --idprefix ~{idprefix} \
                                                                 --outfile ~{output_prefix}_number_of_genes_detected.json
    }

    output {
        File talon_abundance = "~{output_prefix}_talon_abundance.tsv"
        File number_of_genes_detected = "~{output_prefix}_number_of_genes_detected.json"
    }

    runtime {
        cpu: resources.cpu
        memory: "~{resources.memory_gb} GB"
        disks: resources.disks
    }
}

task create_gtf_from_talon_db {
    input {
        File talon_db
        Resources resources
        String annotation_name
        String genome_build
        String output_prefix
    }

    command {
        talon_create_GTF --db ~{talon_db} \
                         -a ~{annotation_name} \
                         --build ~{genome_build} \
                         --o ~{output_prefix}
        gzip -n ~{output_prefix}_talon.gtf
    }

    output {
        File gtf = "~{output_prefix}_talon.gtf.gz"
    }

    runtime {
        cpu: resources.cpu
        memory: "~{resources.memory_gb} GB"
        disks: resources.disks
    }
}

task calculate_spearman {
    input {
        File rep1_abundance
        File rep2_abundance
        Resources resources
        String rep1_idprefix
        String rep2_idprefix
        String output_prefix
    }

    command {
        python3.7 $(which calculate_correlation.py) --rep1_abundance ~{rep1_abundance} \
                                                    --rep2_abundance ~{rep2_abundance} \
                                                    --rep1_idprefix ~{rep1_idprefix} \
                                                    --rep2_idprefix ~{rep2_idprefix} \
                                                    --outfile ~{output_prefix}_spearman.json
    }

    output {
        File spearman = "~{output_prefix}_spearman.json"
    }

    runtime {
        cpu: resources.cpu
        memory: "~{resources.memory_gb} GB"
        disks: resources.disks
    }
}

task skipNfirstlines {
    input {
        File input_file
        Resources resources
        String output_fn
        Int lines_to_skip
    }

    command {
        sed 1,~{lines_to_skip}d ~{input_file} > ~{output_fn}
    }

    output {
        File output_file = output_fn
    }

    runtime {
        cpu: resources.cpu
        memory: "~{resources.memory_gb} GB"
        disks: resources.disks
    }
}
