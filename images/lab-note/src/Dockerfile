ARG BASE_IMAGE=nvidia/cuda:12.4.1-cudnn-devel-ubuntu22.04

### Build the base image (Stage 1) ###
FROM ${BASE_IMAGE} AS base

RUN --mount=type=bind,source=./scripts/install_scripts/install_common_utils.sh,target=/tmp/scripts/install_scripts/install_common_utils.sh \
    --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    bash /tmp/scripts/install_scripts/install_common_utils.sh \
    && apt-get update -y \
    && apt-get install -y --upgrade \
        build-essential

# Use non-root user in the container
ARG USER=dev
ARG USER_UID=1000
ARG USER_GID=1000

RUN --mount=type=bind,source=./scripts/add_nonroot_user.sh,target=/tmp/scripts/add_nonroot_user.sh \
    --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    bash /tmp/scripts/add_nonroot_user.sh \
    --user ${USER} \
    --user_uid ${USER_UID} \
    --user_gid ${USER_GID} \
    --force
USER ${USER}
ENV HOME=/home/${USER}
WORKDIR /home/${USER}/workspace

# Install the required python packages
ARG PYTHON_VERSION=3.10

RUN --mount=type=bind,source=./scripts/install_scripts/install_miniforge.sh,target=/tmp/scripts/install_scripts/install_miniforge.sh \
    --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    bash /tmp/scripts/install_scripts/install_miniforge.sh \
        --python_version ${PYTHON_VERSION}
ENV PATH=${HOME}/miniforge3/bin:$PATH



### Build deps (Stage 2-1) ###
FROM base AS builder

RUN --mount=type=bind,source=./scripts/build_scripts/install_build_deps.sh,target=/tmp/scripts/install_build_deps.sh \
    --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    bash /tmp/scripts/install_build_deps.sh


### Build fastText (Stage 2-2) ###
FROM builder AS fast_text_builder

WORKDIR /workspace
RUN --mount=type=bind,source=./scripts/build_scripts/build_fasttext.sh,target=/tmp/scripts/build_fasttext.sh \
    --mount=type=cache,target=${HOME}/.miniforge3/pkgs,sharing=locked \
    --mount=type=cache,target=${HOME}/.cache/pip,sharing=locked \
    bash /tmp/scripts/build_fasttext.sh \
    && mkdir -p ./fastText/whl/ \
    && mkdir -p ./fastText/bin/ \
    && mv ./fastText/dist/*.whl ./fastText/whl/ \
    && mv ./fastText/fasttext ./fastText/bin/


### Build kenlm (Stage 2-3) ###
FROM builder AS kenlm_builder

WORKDIR /workspace
RUN --mount=type=bind,source=./scripts/build_scripts/build_kenlm.sh,target=/tmp/scripts/build_kenlm.sh \
    --mount=type=cache,target=${HOME}/.miniforge3/pkgs,sharing=locked \
    --mount=type=cache,target=${HOME}/.cache/pip,sharing=locked \
    bash /tmp/scripts/build_kenlm.sh \
    && mkdir -p ./kenlm/whl/ \
    && mkdir -p ./kenlm/bin/ \
    && mv ./kenlm/dist/*.whl ./kenlm/whl/ \
    && mv ./kenlm/build/bin/* ./kenlm/bin/


# # ### Build the final image (Stage 3-1) ###
FROM base AS final

ARG USE_CUDA=true
ARG CUDA_VERSION=12.4.1
ARG SKIP_RAPIDS=false

SHELL ["/bin/bash", "-c"]

RUN --mount=type=bind,source=./scripts/install_scripts/install_frameworks.sh,target=/tmp/scripts/install_frameworks.sh \
    --mount=type=cache,target=${HOME}/.miniforge3/pkgs,sharing=locked \
    --mount=type=cache,target=${HOME}/.cache/pip,sharing=locked \
    pip install --no-cache-dir --upgrade wheel setuptools pybind11 pip \
    && bash /tmp/scripts/install_frameworks.sh \
        --use_cuda ${USE_CUDA} \
        --cuda_version ${CUDA_VERSION} \
        --install_lightgbm \
        --install_xgboost \
        --install_catboost \
        --install_torch \
        --install_onnx \
    [[ ${SKIP_RAPIDS} == "true" ]] || bash /tmp/scripts/install_frameworks.sh --install_rapids

RUN --mount=type=bind,source=./requirements/requirements.txt,target=/tmp/requirements/requirements.txt \
    --mount=type=bind,source=./requirements/requirements_torch.txt,target=/tmp/requirements/requirements_torch.txt \
    --mount=type=cache,target=${HOME}/.miniforge3/pkgs,sharing=locked \
    --mount=type=cache,target=${HOME}/.cache/pip,sharing=locked \
    ${HOME}/miniforge3/bin/pip install --no-cache-dir \
        -r /tmp/requirements/requirements.txt \
        -r /tmp/requirements/requirements_torch.txt

## NLP Deps (Stage 3-2) ###
RUN --mount=type=bind,from=fast_text_builder,source=/workspace/fastText,target=/fastText \
    --mount=type=cache,target=${HOME}/.miniforge3/pkgs,sharing=locked \
    --mount=type=cache,target=${HOME}/.cache/pip,sharing=locked \
    ${HOME}/miniforge3/bin/pip install --no-cache-dir \
        --find-links /fastText/whl \
        fasttext

RUN --mount=type=bind,from=kenlm_builder,source=/workspace/kenlm,target=/kenlm \
    --mount=type=cache,target=${HOME}/.miniforge3/pkgs,sharing=locked \
    --mount=type=cache,target=${HOME}/.cache/pip,sharing=locked \
    ${HOME}/miniforge3/bin/pip install --no-cache-dir \
        --find-links /kenlm/whl \
        kenlm

ARG USE_CUDA=true
RUN --mount=type=bind,source=./requirements/requirements_nlp.txt,target=/tmp/requirements/requirements_nlp.txt \
    --mount=type=bind,source=./requirements/requirements_nlp_cuda.txt,target=/tmp/requirements/requirements_nlp_cuda.txt \
    --mount=type=cache,target=${HOME}/.miniforge3/pkgs,sharing=locked \
    --mount=type=cache,target=${HOME}/.cache/pip,sharing=locked \
    [[ ${USE_CUDA} == "true" ]] || ${HOME}/miniforge3/bin/pip install --no-cache-dir -r /tmp/requirements/requirements_nlp.txt \
    [[ ${USE_CUDA} == "true" ]] && ${HOME}/miniforge3/bin/pip install --no-cache-dir -r /tmp/requirements/requirements_nlp_cuda.txt
