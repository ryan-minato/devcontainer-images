#!/bin/bash

set -e

sudo apt-get update -y
sudo apt-get install -y \
    build-essential \
    libboost-all-dev \
    cmake \
    make \
    git \
    zlib1g-dev \
    libbz2-dev \
    liblzma-dev
pip install --no-cache-dir --upgrade wheel setuptools pybind11 pip
