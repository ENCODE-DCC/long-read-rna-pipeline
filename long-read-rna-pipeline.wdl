# ENCODE long read rna pipeline
# Maintainer: Otto Jolanki

#CAPER docker quay.io/encode-dcc/long-read-rna-pipeline:v1.1
#CAPER singularity docker://quay.io/encode-dcc/long-read-rna-pipeline:v1.1

workflow long_read_rna_pipeline {
    # Inputs

    # File inputs

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
    String experiment_prefix="my_experiment"

    # Is the data from "pacbio" or "nanopore"
    String input_type="pacbio"

    # Array[String] of prefixes for naming novel discoveries in eventual TALON runs (default = "TALON").
    # If defined, length of this array needs to be equal to number of replicates.
    Array[String] talon_prefixes=[]

    # Genome build name, for TALON. This must be in the initial_talon_db

    String genome_build

    # Annotation name, for creating abundance from talon db. This must be in the initial_talon_db

    String annotation_name

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

    # Task filter_transcriptclean

    Int filter_transcriptclean_ncpus
    Int filter_transcriptclean_ramGB
    String filter_transcriptclean_disks

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

    Int calculate_spearman_ncpus=1
    Int calculate_spearman_ramGB=2
    String calculate_spearman_disks="local-disk 20 HDD"

    # Pipeline starts here

    scatter (i in range(length(fastqs))) {
        String talon_prefix = if length(talon_prefixes) > 0 then talon_prefixes[i] else "TALON"
        call init_talon_db { input:
            annotation_gtf = annotation,
            annotation_name = annotation_name,
            ref_genome_name = genome_build,
            idprefix = talon_prefix,
            output_prefix = "rep"+(i+1)+experiment_prefix,
            ncpus = init_talon_db_ncpus,
            ramGB = init_talon_db_ramGB,
            disks = init_talon_db_disks
        }
        call minimap2 { input:
            fastq = fastqs[i],
            reference_genome = reference_genome,
            output_prefix = "rep"+(i+1)+experiment_prefix,
            input_type = input_type,
            ncpus = minimap2_ncpus,
            ramGB = minimap2_ramGB,
            disks = minimap2_disks,
        }

        call transcriptclean { input:
            sam = minimap2.sam,
            reference_genome = reference_genome,
            splice_junctions = splice_junctions,
            variants = variants,
            output_prefix = "rep"+(i+1)+experiment_prefix,
            ncpus = transcriptclean_ncpus,
            ramGB = transcriptclean_ramGB,
            disks = transcriptclean_disks,
        }

        call filter_transcriptclean { input:
            sam = transcriptclean.corrected_sam,
            output_prefix = "rep"+(i+1)+experiment_prefix,
            ncpus = filter_transcriptclean_ncpus,
            ramGB = filter_transcriptclean_ramGB,
            disks = filter_transcriptclean_disks,
        }

        call talon { input:
            talon_db = init_talon_db.database,
            sam = filter_transcriptclean.filtered_sam,
            genome_build = genome_build,
            output_prefix = "rep"+(i+1)+experiment_prefix,
            platform = input_type,
            ncpus = talon_ncpus,
            ramGB = talon_ramGB,
            disks = talon_disks,
        }

        call create_abundance_from_talon_db { input:
            talon_db = talon.talon_db_out,
            annotation_name = annotation_name,
            genome_build = genome_build,
            output_prefix = "rep"+(i+1)+experiment_prefix,
            ncpus = create_abundance_from_talon_db_ncpus,
            ramGB = create_abundance_from_talon_db_ramGB,
            disks = create_abundance_from_talon_db_disks,
        }

        call create_gtf_from_talon_db { input:
            talon_db = talon.talon_db_out,
            annotation_name = annotation_name,
            genome_build = genome_build,
            output_prefix = "rep"+(i+1)+experiment_prefix,
            ncpus = create_abundance_from_talon_db_ncpus,
            ramGB = create_abundance_from_talon_db_ramGB,
            disks = create_abundance_from_talon_db_disks,
        }
    }

    if (length(fastqs) == 2) {
        call calculate_spearman { input:
            rep1_abundance = create_abundance_from_talon_db.talon_abundance[0],
            rep2_abundance = create_abundance_from_talon_db.talon_abundance[1],
            output_prefix = experiment_prefix,
            ncpus = calculate_spearman_ncpus,
            ramGB = calculate_spearman_ramGB, 
            disks = calculate_spearman_disks,
        }
    }
}

task init_talon_db {
    File annotation_gtf
    String annotation_name
    String ref_genome_name
    String output_prefix
    String? idprefix 
    Int ncpus
    Int ramGB
    String disks

    command {
        gzip -cd ${annotation_gtf} > anno.gtf
        rm ${annotation_gtf}
        python3.7 $(which initialize_talon_database.py) \
            --f anno.gtf \
            --a ${annotation_name} \
            --g ${ref_genome_name} \
            ${"--idprefix " + idprefix} \
            --o ${output_prefix}

        python3.7 $(which record_init_db_inputs.py) \
            --annotation_name ${annotation_name} \
            --genome ${ref_genome_name} \
            --outfile ${output_prefix}_talon_inputs.json
        }

    output {
        File database = glob("*.db")[0]
        File talon_inputs = glob("*_talon_inputs.json")[0]
           }

    runtime {
        cpu: ncpus
        memory: "${ramGB} GB"
        disks: disks
        }
}

task minimap2 {
    File fastq
    File reference_genome
    String output_prefix
    String input_type
    Int ncpus
    Int ramGB
    String disks

    command <<<
        if [ "${input_type}" == "pacbio" ]; then
            minimap2 -t ${ncpus} -ax splice -uf --secondary=no -C5 \
                ${reference_genome} \
                ${fastq} \
                > ${output_prefix}.sam \
                2> ${output_prefix}_minimap2.log
        fi
        
        if [ "${input_type}" == "nanopore" ]; then
            minimap2 -t ${ncpus} -ax splice -uf -k14 \
                ${reference_genome} \
                ${fastq} \
                > ${output_prefix}.sam \
                2> ${output_prefix}_minimap2.log
        fi

        gzip -cd ${fastq} | grep "^@" | wc -l > FLNC.txt
        samtools view ${output_prefix}.sam | awk '{if($2 == "0" || $2 == "16") print $1}' | sort -u | wc -l > mapped.txt
        python3.7 $(which make_minimap_qc.py) --flnc FLNC.txt --mapped mapped.txt --outfile ${output_prefix}_mapping_qc.json
        samtools view -S -b ${output_prefix}.sam > ${output_prefix}.bam
    >>>

    output {
        File sam = glob("*.sam")[0]
        File bam = glob("*.bam")[0]
        File log = glob("*_minimap2.log")[0]
        File mapping_qc = glob("*_mapping_qc.json")[0] 
    }

    runtime {
        cpu: ncpus
        memory: "${ramGB} GB"
        disks: disks
    }
}

task transcriptclean {
    File sam
    File reference_genome
    File splice_junctions
    File? variants
    String output_prefix
    Int ncpus
    Int ramGB
    String disks

    command <<<
        gzip -cd ${reference_genome} > ref.fasta

        if [ $(head -n 1 ref.fasta | awk '{print NF}') -gt 1 ]; then
            cat ref.fasta | awk '{print $1}' > reference.fasta
        else
            mv ref.fasta reference.fasta
        fi

        python $(which TranscriptClean.py) --sam ${sam} \
            --genome reference.fasta \
            --spliceJns ${splice_junctions} \
            ${if defined(variants) then "--variants <(gzip -cd ${variants})" else ""} \
            --maxLenIndel 5 \
            --maxSJOffset 5 \
            -m true \
            -i true \
            --correctSJs true \
            --primaryOnly \
            --outprefix ${output_prefix}

        Rscript $(which generate_report.R) ${output_prefix}
    >>>

    output {
        File corrected_sam = glob("*_clean.sam")[0]
        File corrected_fasta = glob("*_clean.fa")[0]
        File transcript_log = glob("*_clean.log")[0]
        File transcript_error_log = glob("*_clean.TE.log")[0]
        File report = glob("*_report.pdf")[0]
    }

    runtime {
        cpu: ncpus
        memory: "${ramGB} GB"
        disks: disks
    }
}

task filter_transcriptclean {
    File sam
    String output_prefix
    Int ncpus
    Int ramGB
    String disks

    command {
        python $(which filter_transcriptclean_result.py) --f ${sam} --o ${output_prefix + "_filtered.sam"}
        samtools view -S -b ${output_prefix}_filtered.sam > ${output_prefix}_filtered.bam
    }

    output {
        File filtered_sam = glob("*_filtered.sam")[0]
        File filtered_bam = glob("*_filtered.bam")[0]
    }

    runtime {
        cpu: ncpus
        memory: "${ramGB} GB"
        disks: disks
    }

}

task talon {
    File talon_db
    File sam
    String genome_build
    String output_prefix
    String platform
    Int ncpus
    Int ramGB
    String disks

    command {
        echo ${output_prefix},${output_prefix},${platform},${sam} > ${output_prefix}_talon_config.csv
        cp ${talon_db} ./${output_prefix}_talon.db
        python3.7 $(which talon.py) --f ${output_prefix}_talon_config.csv \
                                    --db ${output_prefix}_talon.db \
                                    --build ${genome_build} \
                                    --o ${output_prefix}
    }

    output {
        File talon_config = glob("*_talon_config.csv")[0]
        File talon_log = glob("*_talon_QC.log")[0]
        File talon_db_out = glob("*_talon.db")[0]
    }

    runtime {
        cpu: ncpus
        memory: "${ramGB} GB"
        disks: disks
    }

}

task create_abundance_from_talon_db {
    File talon_db
    String annotation_name
    String genome_build
    String output_prefix
    Int ncpus
    Int ramGB
    String disks

    command {
        python3.7 $(which create_abundance_file_from_database.py) --db=${talon_db} \
                                                                  -a ${annotation_name} \
                                                                  --build ${genome_build} \
                                                                  --o=${output_prefix}
        python3.7 $(which calculate_number_of_genes_detected.py) --abundance ${output_prefix}_talon_abundance.tsv \
                                                                 --counts_colname ${output_prefix} \
                                                                 --outfile ${output_prefix}_number_of_genes_detected.json
    }

    output {
        File talon_abundance = glob("*_talon_abundance.tsv")[0]
        File number_of_genes_detected = glob("*_number_of_genes_detected.json")[0]
    }

    runtime {
        cpu: ncpus
        memory: "${ramGB} GB"
        disks: disks
    }

}

task create_gtf_from_talon_db {
    File talon_db
    String annotation_name
    String genome_build
    String output_prefix
    Int ncpus
    Int ramGB
    String disks

    command {
        python3.7 $(which create_GTF_from_database.py) --db ${talon_db} \
                                                        -a ${annotation_name} \
                                                        --build ${genome_build} \
                                                        --o ${output_prefix}
    }

    output {
        File gtf = glob("*.gtf")[0]
    }

    runtime {
        cpu: ncpus
        memory: "${ramGB} GB"
        disks: disks
    }

}

task calculate_spearman {
    File rep1_abundance
    File rep2_abundance
    String output_prefix
    Int ncpus
    Int ramGB
    String disks

    command {
        python3.7 $(which calculate_correlation.py) --rep1_abundance ${rep1_abundance} \
                                                    --rep2_abundance ${rep2_abundance} \
                                                    --outfile ${output_prefix}_spearman.json
    }

    output {
        File spearman = glob("*_spearman.json")[0]
    }

    runtime {
        cpu: ncpus
        memory: "${ramGB} GB"
        disks: disks
    }

}
task skipNfirstlines {
    File input_file
    String output_fn
    Int lines_to_skip
    Int ncpus
    Int ramGB
    String disks

    command {
        sed 1,${lines_to_skip}d ${input_file} > ${output_fn}
    }

    output {
        File output_file = glob("${output_fn}")[0]
    }

    runtime {
        cpu: ncpus
        memory: "${ramGB} GB"
        disks: disks
    }
}