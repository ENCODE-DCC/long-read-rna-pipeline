# HOWTO

Here are concrete instructions for running analyses on different platforms.
Before following these instructions, make sure you have completed installation and possible account setup detailed in [installation instructions](installation.md). These instructions show how to use Cromwell directly. Consider running the pipeline using [Caper](https://github.com/ENCODE-DCC/caper) which is more user friendly way.

# CONTENTS

## Running Workflows

[Google Cloud](howto.md#google-cloud)  
[SLURM](howto.md#slurm-singularity)  
[Splice Junctions](howto.md#splice-junctions)  


# RUNNING WORKFLOWS

## Google Cloud

Make sure you have completed the steps for installation and Google Cloud setup described in the [installation instructions](installation.md#google-cloud). The following assumes your Google Cloud project is `YOUR_PROJECT`, you have created a bucket `gs://YOUR_BUCKET_NAME`, and also directories `input`, `output` and `reference` in the bucket.
The goal is to run the pipeline with test data using Google Cloud Platform.

1. Launch a VM into your Google Cloud project, and connect to the instance.

2. Get the code and move into the code directory:

```bash
  git clone https://github.com/ENCODE-DCC/long-read-rna-seq-pipeline.git
  cd long-read-rna-seq-pipeline
```

3. Copy input and reference files into your bucket:

```bash
  gsutil cp gsutil cp test_data/chr19_test_10000_reads.fastq.gz gs://YOUR_BUCKET_NAME/input/
  gsutil cp test_data/GRCh38_no_alt_analysis_set_GCA_000001405.15_chr19_only.fasta.gz test_data/splice_junctions.txt test_data/00-common_chr19_only.vcf.gz test_data/gencode.v24.annotation_chr19.gtf.gz gs://YOUR_BUCKET_NAME/reference/
```

4. Prepare the `input.json`. In the following template fill in the actual URI of your Google Cloud Bucket and save the file as `input.json` in the `long-read-rna-pipeline` directory.

```
{
    "long_read_rna_pipeline.fastqs" : ["gs://YOUR_BUCKET_NAME/input/chr19_test_10000_reads.fastq.gz"],
    "long_read_rna_pipeline.reference_genome" : "gs://YOUR_BUCKET_NAME/reference/GRCh38_no_alt_analysis_set_GCA_000001405.15_chr19_only.fasta.gz",
    "long_read_rna_pipeline.annotation" : "gs://YOUR_BUCKET_NAME/reference/gencode.v24.annotation_chr19.gtf.gz",
    "long_read_rna_pipeline.variants" : "gs://YOUR_BUCKET_NAME/reference/00-common_chr19_only.vcf.gz",
    "long_read_rna_pipeline.splice_junctions" : "gs://YOUR_BUCKET_NAME/reference/splice_junctions.txt",
    "long_read_rna_pipeline.experiment_prefix" : "TEST_WORKFLOW",
    "long_read_rna_pipeline.input_type" : "pacbio",
    "long_read_rna_pipeline.genome_build" : "GRCh38_chr19",
    "long_read_rna_pipeline.annotation_name" : "gencode_V24_chr19",
    "long_read_rna_pipeline.minimap2_ncpus" : 2,
    "long_read_rna_pipeline.minimap2_ramGB" : 4,
    "long_read_rna_pipeline.minimap2_disks" : "local-disk 20 HDD",
    "long_read_rna_pipeline.transcriptclean_ncpus" : 2,
    "long_read_rna_pipeline.transcriptclean_ramGB" : 4,
    "long_read_rna_pipeline.transcriptclean_disks": "local-disk 20 HDD",
    "long_read_rna_pipeline.filter_transcriptclean_ncpus" : 2,
    "long_read_rna_pipeline.filter_transcriptclean_ramGB" : 4,
    "long_read_rna_pipeline.filter_transcriptclean_disks" : "local-disk 20 HDD",
    "long_read_rna_pipeline.talon_ncpus" : 2,
    "long_read_rna_pipeline.talon_ramGB" : 4,
    "long_read_rna_pipeline.talon_disks" : "local-disk 20 HDD",
    "long_read_rna_pipeline.create_abundance_from_talon_db_ncpus" : 2,
    "long_read_rna_pipeline.create_abundance_from_talon_db_ramGB" : 4,
    "long_read_rna_pipeline.create_abundance_from_talon_db_disks" : "local-disk 20 HDD"
}
```

5. Get cromwell 40:

```bash
  wget -N -c https://github.com/broadinstitute/cromwell/releases/download/40/cromwell-40.jar
```

6. Run the pipeline:

```bash
  $ java -jar -Dconfig.file=backends/backend.conf -Dbackend.default=google -Dbackend.providers.google.config.project=YOUR_PROJECT -Dbackend.providers.google.config.root=gs://YOUR_BUCKET_NAME/output cromwell-40.jar run long-read-rna-pipeline.wdl -i input.json -o workflow_opts/docker.json -m metadata.json
```

7. See the outputs in `gs://YOUR_BUCKET_NAME/output`. You can also use [croo](https://github.com/ENCODE-DCC/croo) to organize the outputs before taking a look. The required configuration json file `output_definition.json` is provided with this repo.

## SLURM Singularity

For this example you need to have Singularity installed. For details see [installation instructions](installation.md). The goal is to run the pipeline with testdata using Singularity on a SLURM cluster. Login into your cluster first and then follow the instructions.
When running workflows on SLURM (or other) HPC clusters, use [Caper](https://github.com/ENCODE-DCC/caper), it takes care of backend configuration for you.

1. Get the code and move into the code directory:

```bash
  git clone https://github.com/ENCODE-DCC/long-read-rna-pipeline.git
  cd long-read-rna-pipeline
``` 

3. Build the singularity image for the pipeline. The following pulls the pipeline docker image, and uses that to construct the singularity image. The image will be stored in `~/.singularity`. It is bad practice to build images (or do any other intensive work) on login nodes. For this reason we will first invoke an interactive session on a different node by running `sdev` command, and building there (It will take few seconds to get back into the shell after running `sdev`).

```bash
  sdev
  mkdir -p ~/.singularity && cd ~/.singularity && SINGULARITY_CACHEDIR=~/.singularity SINGULARITY_PULLFOLDER=~/.singularity singularity pull --name long_read_rna_pipeline-v1.0.simg -F docker://quay.io/encode-dcc/long-read-rna-pipeline:v1.0
  exit #this takes you back to the login node
```

Note: If you want to store your inputs `/in/some/data/directory1`and `/in/some/data/directory2`you must edit `workflow_opts/singularity.json` in the following way:
```
{
    "default_runtime_attributes" : {
        "singularity_container" : "~/.singularity/long-read-rna-pipeline-v1.0.simg",
        "singularity_bindpath" : "~/, /in/some/data/directory1/, /in/some/data/directory2/"
    }
}
```

4. Install caper. Python 3.4.1 or newer is required.

```bash
  pip install caper
```

5. Follow [Caper configuration instructions](https://github.com/ENCODE-DCC/caper#configuration-file). 

Note: In Caper configuration file, you will need to give a value to `--time` parameter by editing `slurm-extra-param` line. For example:
```
  slurm-extra-param=--time=01:00:00
```
to give one hour of runtime.

6. Edit the input file `test/test_workflow/test_workflow_2reps_input.json` so that all the input file paths are absolute.
For example replace `test_data/chr19_test_10000_reads.fastq.gz` in fastq inputs with `[PATH-TO-REPO]/test_data/chr19_test_10000_reads.fastq.gz`. You can find out the `[PATH-TO-REPO]` by running `pwd` command in the `long-read-rna-pipeline` directory.

7. Run the pipeline using Caper:

```bash
  caper run -i test/test_workflow/test_workflow_2reps_input.json -o workflow_opts/singularity.json -m metadata.json
```

## Splice junctions

You may want to run the pipeline using other references than the ones used by ENCODE. In this case you must prepare your own splice junctions file. The workflows for this is in this repo and it is `get-splice-junctions.wdl`. This workflow uses the same Docker/Singularity images as the main pipeline and running this workflow is done in exactly same way as the running of the main pipeline.

`input.json` for splice junction workflow with gencode v24 annotation, and GRCh38 reference genome looks like this:

```
{
    "get_splice_junctions.annotation" : "gs://long_read_rna/splice_junctions/inputs/gencode.v24.primary_assembly.annotation.gtf.gz",
    "get_splice_junctions.reference_genome" : "gs://long_read_rna/splice_junctions/inputs/GRCh38_no_alt_analysis_set_GCA_000001405.15.fasta.gz",
    "get_splice_junctions.output_prefix" : "gencode_V24_splice_junctions",
    "get_splice_junctions.ncpus" : 2,
    "get_splice_junctions.ramGB" : 7,
    "get_splice_junctions.disks" : "local-disk 50 SSD"
}
```
