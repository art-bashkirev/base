FROM debian:stable-slim
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
ENV LANG=en_US.UTF-8

## Python Building Dependencies
RUN apt update && \
    apt install --yes --no-install-recommends \
        make build-essential libssl-dev zlib1g-dev \
        libbz2-dev libreadline-dev libsqlite3-dev \
        llvm wget unzip libncursesw5-dev xz-utils \
        tk-dev libxml2-dev libxmlsec1-dev libffi-dev \
        liblzma-dev

COPY .python-version /.python-version

RUN cd /tmp && \
    curl https://www.python.org/ftp/python/$(cat /.python-version)/Python-$(cat /.python-version).tgz --output Python.tgz && \
    tar xzf Python.tgz && \
    rm --force Python.tgz && \
    cd Python-* && \
    ./configure \
        --enable-optimizations && \
    make -j $(nproc) && \
    make install && \
    cd .. && \
    rm --force --recursive Python-* && \
    ln --relative --symbolic /usr/local/bin/pip3 /usr/local/bin/pip && \
    ln --relative --symbolic /usr/local/bin/python3 /usr/local/bin/python && \
    pip3 install --no-cache-dir --upgrade pip setuptools

## Installing essential dependencies 
RUN apt update && \
    apt install --yes --no-install-recommends \
        clang \
        coreutils \
        cowsay \
        dos2unix \
        dnsutils \
        gdb \
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
        vim \
        zip && \
    apt clean && \
    rm -rf /var/lib/apt/lists/*

RUN useradd --home-dir /home/codebase --shell /bin/bash codebase && \
    umask 0077 && \
    mkdir --parents /home/codebase && \
    chown --recursive codebase:codebase /home/codebase && \
    echo "\n# CS CLI" >> /etc/sudoers && \
    echo "codebase ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers && \
    echo "Defaults umask_override" >> /etc/sudoers && \
    echo "Defaults umask=0022" >> /etc/sudoers && \
    sed --expression="s/^Defaults\tsecure_path=.*/Defaults\t!secure_path/" --in-place /etc/sudoers


# Version the image (and any descendants)
ARG VCS_REF
RUN echo "$VCS_REF" > /etc/issue
ONBUILD USER root
ONBUILD ARG VCS_REF
ONBUILD RUN echo "$VCS_REF" >> /etc/issue
ONBUILD USER codebase


# Set user
USER codebase
WORKDIR /home/codebase
ENV WORKDIR=/home/codebase
