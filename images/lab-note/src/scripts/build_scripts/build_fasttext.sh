#!/bin/bash

set -e


pip install --no-cache-dir --upgrade wheel setuptools pybind11 pip
git clone https://github.com/facebookresearch/fastText.git

cd fastText

num_procs=$(nproc)
make -j"${num_procs}"

python setup.py bdist_wheel
