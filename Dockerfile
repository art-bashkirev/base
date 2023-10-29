# Stage 1: Base
FROM debian:stable-slim AS base
ARG DEBIAN_FRONTEND=noninteractive

RUN apt update && \
    apt upgrade --yes --no-install-recommends && \
    apt install --yes --no-install-recommends \
        curl \
        ca-certificates \
        locales && \
    locale-gen \
        en_US.UTF-8

# Locale setup
ENV LANG=C.UTF-8

# Stage 2: Python Building Dependencies
FROM base AS python-builder

RUN apt update && \
    apt upgrade --yes --no-install-recommends && \
    apt install --yes --no-install-recommends \
    git \
    xz-utils \
    build-essential \
    cmake \
    clang \
    lld \
    llvm \
    pkg-config \
    zlib1g-dev \
    libncurses5-dev \
    libsqlite3-dev \
    gdb \
    libgdbm-dev \
    libgdbm-compat-dev \
    libnss3-dev \
    libssl-dev \
    libreadline-dev \
    libffi-dev \
    libbz2-dev \
    lzma \
    liblzma-dev \
    lzma-dev \
    uuid-dev \
    tk-dev \
    xvfb \
    lcov \
    libclang-cpp-dev \
    libclang-rt-dev

COPY .python-version /.python-version

RUN cd /tmp && \
    curl https://www.python.org/ftp/python/$(cat /.python-version)/Python-$(cat /.python-version).tgz --output Python.tgz && \
    tar xzf Python.tgz && \
    rm --force Python.tgz && \
    cd Python-* && \
    CC=clang CXX=clang++ LD=ld.lld ./configure \
        --with-lto=full \
        --enable-optimizations \
        --with-computed-gotos && \
    make -j $(nproc) && \
    make install && \
    cd .. && \
    rm --force --recursive Python-* && \
    ln --relative --symbolic /usr/local/bin/pip3 /usr/local/bin/pip && \
    ln --relative --symbolic /usr/local/bin/python3 /usr/local/bin/python && \
    pip3 install --no-cache-dir --upgrade pip setuptools

# Stage 3: Final
FROM base AS final

COPY --from=python-builder /usr/local /usr/local

# Installing essential dependencies 
RUN apt update && \
    apt install --yes --no-install-recommends \
        coreutils \
        cowsay \
        cmake \
        curl \
        unzip \
        build-essential \
        dos2unix \
        dnsutils \
        git \
        git-lfs \
        jq \
        less \
        make \
        man \
        man-db \
        nano \
        openssh-client \
        psmisc \
        sudo \
        tzdata \
        valgrind \
        wget \
        vim \
        zip && \
    apt clean && \
    rm -rf /var/lib/apt/lists/*

RUN useradd --home-dir /home/code --shell /bin/bash code && \
    umask 0077 && \
    mkdir --parents /home/code && \
    chown --recursive code:code /home/code && \
    echo "\n# Codespace" >> /etc/sudoers && \
    echo "code ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers && \
    echo "Defaults umask_override" >> /etc/sudoers && \
    echo "Defaults umask=0022" >> /etc/sudoers && \
    sed \
        --expression="s/^Defaults\tsecure_path=.*/Defaults\t!secure_path/" \
        --in-place /etc/sudoers


RUN apt update && \
    apt upgrade --yes --no-install-recommends && \
    apt clean && \
    rm -rf /var/lib/apt/lists/*


# Version the image (and any descendants)
ARG VCS_REF
RUN echo "$VCS_REF" > /etc/issue
ONBUILD USER root
ONBUILD ARG VCS_REF
ONBUILD RUN echo "$VCS_REF" >> /etc/issue
ONBUILD USER code


# Set user
USER code
WORKDIR /home/code
ENV WORKDIR=/home/code
