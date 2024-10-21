#!/bin/bash

set -e


PATH=$HOME/miniforge3/bin:$PATH

install_python_env() {
    python_version=${1:-3.10}

    echo "Installing Miniforge..."
    system=$(uname)
    machine=$(uname -m)

    curl -L -O "https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-${system}-${machine}.sh"
    bash "Miniforge3-${system}-${machine}.sh" -b -u
    conda init bash
    python -m mamba.mamba init

    if [ -n "$(which zsh)" ]; then
        echo "Zsh found, initializing conda and mamba for zsh"
        zsh -c "conda init zsh"
        zsh -c "python -m mamba.mamba init zsh"
    fi

    conda config --set auto_activate_base true
    mamba install -y \
        "python=$python_version" \
        pip
}

cleanup() {
    system=$(uname)
    machine=$(uname -m)
    echo "Removing Miniforge installer...(Miniforge3-${system}-${machine}.sh)"

    rm -f "Miniforge3-${system}-${machine}.sh"
}


### Main Script ###

# Parse arguments
while [ $# -gt 0 ]; do
    case "$1" in
        # --python_version(-p): The version of Python to install, defaults to 3.10
        --python_version|-p)
            python_version=${2:-3.10}
            shift
            ;;
        # Error handling
        *)
            echo "Unrecognized argument: $1"
            exit 1
            ;;
    esac
    shift
done

echo "Installing Notebook Environment"

echo "Installing Python: $python_version"
install_python_env "$python_version"

echo "Cleaning up..."
cleanup

echo "Python installed at $HOME/miniforge3/bin"
