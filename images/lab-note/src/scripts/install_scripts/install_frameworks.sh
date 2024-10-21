#!/bin/bash

set -e

# Default values
use_cuda=false
cuda_version=12.4.1

is_install_lightgbm=false
is_install_rapids=false
is_install_torch=false
is_install_onnx=false
is_install_spacy=false


# Parse arguments
while [ $# -gt 0 ]; do
    case "$1" in
        # --use_cuda: Use CUDA for GPU acceleration
        --use_cuda)
            use_cuda=$2
            shift
            ;;
        # --cuda_version: The version of CUDA to use, defaults to 12.4.1
        --cuda_version)
            cuda_version=$
            shift
            ;;
        # --install_lightgbm: Install LightGBM
        --install_lightgbm)
            is_install_lightgbm=true
            ;;
        # --install_rapids: Install RAPIDS
        --install_rapids)
            is_install_rapids=true
            ;;
        # --install_torch: Install PyTorch
        --install_torch)
            is_install_torch=true
            ;;
        # --install_onnx: Install ONNX
        --install_onnx)
            is_install_onnx=true
            ;;
        # --install_spacy: Install spaCy
        --install_spacy)
            is_install_spacy=true
            ;;
        # Error handling
        *)
            echo "Unrecognized argument: $1"
            exit 1
            ;;
    esac
    shift
done



install_lightgbm() {
    # NOTE: Patch for LightGBM
    sudo apt-get update
    sudo apt-get install -y --no-install-recommends \
        libomp-dev

    pip install --no-cache-dir lightgbm
}


install_rapids() {
    cuda_major=$(echo "$cuda_version" | cut -d'.' -f1)
    pip install --no-cache-dir \
        --extra-index-url=https://pypi.nvidia.com \
        cudf-cu${cuda_major} \
        dask-cudf-cu${cuda_major} \
        cuml-cu${cuda_major} \
        cugraph-cu${cuda_major}
}


install_torch() {
    if [ "$use_cuda" = true ]; then
        cuda_major_and_minor=$(echo "$cuda_version" | cut -d'.' -f1,2 | tr -d '.')
        # pip3 install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118
        pip install --no-cache-dir \
            --index-url https://download.pytorch.org/whl/cu${cuda_major_and_minor} \
            torch \
            torchvision \
            torchaudio
    else
        pip install --no-cache-dir \
            --index-url https://download.pytorch.org/whl/cpu \
            torch \
            torchvision \
            torchaudio
    fi
}

install_onnx() {
    # install onnx
    mamba install -y -c conda-forge onnx
    if [ "$use_cuda" = true ]; then
        cuda_major_version=$(echo "$cuda_version" | cut -d'.' -f1)
        if [ "${cuda_major_version}" -ge 12 ]; then
            pip install --no-cache-dir \
                --extra-index-url "https://aiinfra.pkgs.visualstudio.com/PublicPackages/_packaging/onnxruntime-cuda-${cuda_major_version}/pypi/simple/" \
                onnxruntime-gpu
        else
            pip install --no-cache-dir onnxruntime-gpu
        fi
    else
        pip install --no-cache-dir onnxruntime
    fi
}

install_spacy() {
    if [ "$use_cuda" = true ]; then
        cuda_major_version=$(echo "$cuda_version" | cut -d'.' -f1)
        pip install --no-cache-dir "spacy[cuda${cuda_major_version}x]"
    else
        pip install --no-cache-dir "spacy"
    fi
}

# Main Script
if [ "$is_install_lightgbm" = true ]; then
    echo "Installing LightGBM"
    install_lightgbm
    echo "Installed LightGBM"
fi

if [ "$is_install_rapids" = true ]; then
    echo "Installing RAPIDS"
    install_rapids
    echo "Installed RAPIDS"
fi

if [ "$is_install_torch" = true ]; then
    echo "Installing PyTorch"
    install_torch
    echo "Installed PyTorch"
fi

if [ "$is_install_onnx" = true ]; then
    echo "Installing ONNX"
    install_onnx
    echo "Installed ONNX"
fi

if [ "$is_install_spacy" = true ]; then
    echo "Installing spaCy"
    install_spacy
    echo "Installed spaCy"
fi

echo "Environment setup complete"
