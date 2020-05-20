# Dockerfile for ENCODE-DCC long read rna seq pipeline
FROM ubuntu@sha256:db6697a61d5679b7ca69dbde3dad6be0d17064d5b6b0e9f7be8d456ebb337209
MAINTAINER Otto Jolanki

RUN apt-get update && apt-get install -y software-properties-common
RUN add-apt-repository -y ppa:deadsnakes/ppa
RUN apt-get update && apt-get install -y \
    python \
    cython \
    python-pip \
    python3-pip \
    curl \
    wget \
    gdebi \
    #pybedtools dependency
    libz-dev \
    #samtools dependencies
    libbz2-dev \
    libncurses5-dev \
    git \
    python3.7 \
    python3.7-dev \
    libssl-dev \
    build-essential

RUN mkdir /software
WORKDIR /software
ENV PATH="/software:${PATH}"

# Install samtools dependency

RUN wget https://tukaani.org/xz/xz-5.2.3.tar.gz && tar -xvf xz-5.2.3.tar.gz
RUN cd xz-5.2.3 && ./configure && make && make install && rm ../xz-5.2.3.tar.gz

# Install minimap2

RUN curl -L https://github.com/lh3/minimap2/releases/download/v2.15/minimap2-2.15_x64-linux.tar.bz2 | tar -jxvf -
ENV PATH "/software/minimap2-2.15_x64-linux/:${PATH}"

# Install R 3.3.2

RUN wget https://cran.r-project.org/bin/linux/ubuntu/xenial/r-base-core_3.3.2-1xenial0_amd64.deb
RUN yes | gdebi r-base-core_3.3.2-1xenial0_amd64.deb

RUN wget https://cran.r-project.org/bin/linux/ubuntu/xenial/r-recommended_3.3.2-1xenial0_all.deb
RUN yes | gdebi r-recommended_3.3.2-1xenial0_all.deb

RUN wget https://cran.r-project.org/bin/linux/ubuntu/xenial/r-base_3.3.2-1xenial0_all.deb
RUN yes | gdebi r-base_3.3.2-1xenial0_all.deb

# clear apt lists
RUN rm -rf /var/lib/apt/lists/*

# Install R packages

RUN echo "r <- getOption('repos'); r['CRAN'] <- 'https://cloud.r-project.org'; options(repos = r);" > ~/.Rprofile && \
    Rscript -e "install.packages('ggplot2')" && \
    Rscript -e "install.packages('gridExtra')" && \
    Rscript -e "install.packages('readr')" && \
    Rscript -e "install.packages('reshape2')"

# Install TC dependencies
RUN python3.7 -m pip install --upgrade pip
RUN python3.7 -m pip install cython
RUN python3.7 -m pip install pybedtools==0.8.0 pyfasta==0.5.2 numpy pandas

# splice junction finding accessory script from TC still runs in python2 and requires pyfasta, which in turn requires numpy

RUN python -m pip install --upgrade pip
RUN python -m pip install pyfasta==0.5.2 numpy

# Install qc-utils to python 3.7

RUN python3.7 -m pip install qc-utils==19.8.1

# Install pandas and scipy (for correlations and genes detected calculations)

RUN python3.7 -m pip install pandas scipy

# Install bedtools 2.29

RUN wget https://github.com/arq5x/bedtools2/releases/download/v2.29.0/bedtools-2.29.0.tar.gz
RUN tar xzvf bedtools-2.29.0.tar.gz
RUN cd bedtools2/ && make
ENV PATH="/software/bedtools2/bin:${PATH}"

# Get transcriptclean v2.0.2

RUN git clone -b 'v2.0.2' --single-branch https://github.com/dewyman/TranscriptClean.git
RUN chmod 755 TranscriptClean/accessory_scripts/* TranscriptClean/TranscriptClean.py TranscriptClean/generate_report.R
ENV PATH "/software/TranscriptClean/accessory_scripts:/software/TranscriptClean:${PATH}"

# Install samtools 1.9

RUN git clone --branch 1.9 --single-branch https://github.com/samtools/samtools.git && \
    git clone --branch 1.9 --single-branch git://github.com/samtools/htslib.git && \
    cd samtools && make && make install && cd ../ && rm -rf samtools* htslib*

# Install TALON v5.0
RUN git clone -b 'v5.0' --single-branch https://github.com/mortazavilab/TALON.git
RUN chmod 755 /software/TALON/src/talon/initialize_talon_database.py /software/TALON/src/talon/dstruct.py /software/TALON/src/talon/talon.py /software/TALON/src/talon/post/create_abundance_file_from_database.py /software/TALON/src/talon/post/create_GTF_from_database.py /software/TALON/src/talon/post/filter_talon_transcripts.py
ENV PATH="/software/TALON/src/talon:/software/TALON/src/talon/post:${PATH}"

# make code within the repo available

RUN mkdir -p long-rna-seq-pipeline/src
COPY /src long-rna-seq-pipeline/src
ENV PATH="/software/long-rna-seq-pipeline/src:${PATH}"
ARG GIT_COMMIT_HASH
ENV GIT_HASH=${GIT_COMMIT_HASH}
ARG BRANCH
ENV BUILD_BRANCH=${BRANCH}
ARG BUILD_TAG
ENV MY_TAG=${BUILD_TAG}
