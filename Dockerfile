# Set the base image to Debian
FROM debian:latest

# File Author / Maintainer
MAINTAINER **nalcala** <**alcalan@fellows.iarc.fr**>

RUN mkdir -p /var/cache/apt/archives/partial && \
	touch /var/cache/apt/archives/lock && \
	chmod 640 /var/cache/apt/archives/lock && \
	apt-key adv --keyserver keyserver.ubuntu.com --recv-keys F76221572C52609D && \
	apt-get clean && \
	apt-get update -y && \

  # Install dependences
  DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y \
  make \
  g++ \
  zlib1g-dev \
  libncurses5-dev \
  git \
  wget \
  ca-certificates \
  python3-dev \
  python3-pip \
  bzip2 \
  libbz2-dev \
  liblzma-dev \
  libcurl4-openssl-dev \
  libfreetype6-dev \
  libpng12-dev \
  unzip && \

  # Install samtools specific version manually
  wget https://github.com/samtools/samtools/releases/download/1.3.1/samtools-1.3.1.tar.bz2 && \
  tar -jxf samtools-1.3.1.tar.bz2 && \
  cd samtools-1.3.1 && \
  make && \
  make install && \
  cd .. && \
  rm -rf samtools-1.3.1 samtools-1.3.1.tar.bz2 && \

  # Install FastQC
  wget http://www.bioinformatics.babraham.ac.uk/projects/fastqc/fastqc_v0.11.5.zip && \
  unzip fastqc_v0.11.5.zip && \
  cp -r FastQC /usr/local/bin/. && \
  ln -s /usr/local/bin/FastQC/fastqc /usr/local/bin/. && \
  rm -rf fastqc_v0.11.5.zip FastQC && \

  # Install cutadapt
  pip3 install --user --upgrade cutadapt && \

  # Install trim_galore
  wget https://github.com/FelixKrueger/TrimGalore/archive/0.4.3.tar.gz && \
  tar xvzf 0.4.3.tar.gz && \
  mv TrimGalore-0.4.3/trim_galore /usr/bin && \
  rm -rf TrimGalore-0.4.3 0.4.3.tar.gz && \

  # Install hisat2

  # Install htseq
  pip3 install numpy && \
  pip3 install HTSeq && \

  # Install multiqc
  pip3 install multiqc && \

  # Install STAR specific version manually
  wget https://github.com/samtools/samtools/releases/download/1.3.1/samtools-1.3.1.tar.bz2 && \
  tar -jxf samtools-1.3.1.tar.bz2 && \
  cd samtools-1.3.1 && \
  make && \
  make install && \
  cd .. && \
  rm -rf samtools-1.3.1 samtools-1.3.1.tar.bz2 && \

  # Install RSeQC
  pip install RSeQC

  # Install samblaster specific version manually
  wget https://github.com/GregoryFaust/samblaster/releases/download/v.0.1.24/samblaster-v.0.1.24.tar.gz && \
  tar -xzf samblaster-v.0.1.24.tar.gz && \
  cd samblaster-v.0.1.24 && \
  make && \
  cp samblaster /usr/local/bin/. && \
  cd .. && \
  rm -rf samblaster-v.0.1.24.tar.gz samblaster-v.0.1.24 && \

  # Install sambamba specific version manually
  wget https://github.com/lomereiter/sambamba/releases/download/v0.6.6/sambamba_v0.6.6_linux.tar.bz2 && \
  tar -jxf sambamba_v0.6.6_linux.tar.bz2 && \
  cp sambamba_v0.6.6 /usr/local/bin/sambamba && \
  rm -rf sambamba_v0.6.6_linux.tar.bz2 && \

  # Remove unnecessary dependences
  DEBIAN_FRONTEND=noninteractive apt-get remove -y \
  make \
  g++ \
  zlib1g-dev \
  libncurses5-dev \
  git \
  wget \
  ca-certificates \
  bzip2 \
  unzip && \

  # Clean
  DEBIAN_FRONTEND=noninteractive apt-get autoremove -y && \
  apt-get clean