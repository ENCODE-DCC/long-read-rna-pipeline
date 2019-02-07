# Dockerfile for ENCODE-DCC long read rna seq pipeline
FROM ubuntu:16.04
MAINTAINER Otto Jolanki

RUN apt-get update && apt-get install -y software-properties-common
# RUN add-apt-repository -y ppa:deadsnakes/ppa
RUN apt-get install -y \
    python \
    cython \
    python-pip \
    curl \
    wget \
    gdebi \
    #pybedtools dependency
    libz-dev \
    bedtools=2.25.0-1 \
    #samtools dependencies
    libbz2-dev \
    libncurses5-dev \
    git

RUN mkdir /software
WORKDIR /software
ENV PATH="/software:${PATH}"

# Install minimap2

RUN curl -L https://github.com/lh3/minimap2/releases/download/v2.15/minimap2-2.15_x64-linux.tar.bz2 | tar -jxvf -
ENV PATH "/software//minimap2-2.15_x64-linux/:${PATH}"

# Install R 3.3.2

RUN wget https://cran.r-project.org/bin/linux/ubuntu/xenial/r-base-core_3.3.2-1xenial0_amd64.deb
RUN yes | gdebi r-base-core_3.3.2-1xenial0_amd64.deb

RUN wget https://cran.r-project.org/bin/linux/ubuntu/xenial/r-recommended_3.3.2-1xenial0_all.deb
RUN yes | gdebi r-recommended_3.3.2-1xenial0_all.deb

RUN wget https://cran.r-project.org/bin/linux/ubuntu/xenial/r-base_3.3.2-1xenial0_all.deb
RUN yes | gdebi r-base_3.3.2-1xenial0_all.deb

# Install R packages

RUN echo "r <- getOption('repos'); r['CRAN'] <- 'https://cloud.r-project.org'; options(repos = r);" > ~/.Rprofile && \
    Rscript -e "install.packages('ggplot2')" && \
    Rscript -e "install.packages('gridExtra')" && \
    Rscript -e "install.packages('readr')"

# Install Intervaltree 2.1.0

RUN pip install --upgrade pip
RUN pip install intervaltree==2.1.0 pybedtools==0.7.8 pyfasta==0.5.2

# Get transcriptclean v1.0.7

RUN git clone -b 'v1.0.7' --single-branch https://github.com/dewyman/TranscriptClean.git

# Install samtools dependency

RUN wget https://tukaani.org/xz/xz-5.2.3.tar.gz && tar -xvf xz-5.2.3.tar.gz
RUN cd xz-5.2.3 && ./configure && make && make install && rm ../xz-5.2.3.tar.gz

# Install samtools 1.9

RUN git clone --branch 1.9 --single-branch https://github.com/samtools/samtools.git && \
    git clone --branch 1.9 --single-branch git://github.com/samtools/htslib.git && \
    cd samtools && make && make install && cd ../ && rm -rf samtools* htslib*

# Forgotten dependencies
RUN pip install numpy pandas
ENTRYPOINT ["/bin/bash", "-c"]