#!/bin/bash

set -e


git clone https://github.com/kpu/kenlm.git
mkdir kenlm/build

cd kenlm/build
cmake ..

num_procs=$(nproc)
make -j"${num_procs}"
cd ..

python setup.py bdist_wheel
