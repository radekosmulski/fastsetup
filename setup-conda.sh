#!/usr/bin/env bash
set -eou pipefail

case "$OSTYPE" in
  darwin*)
    case $(uname -m) in
      arm64)   DOWNLOAD=https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-MacOSX-arm64.sh; ;;
      *)       DOWNLOAD=https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-MacOSX-x86_64.sh; ;;
    esac ;;
  linux*)
    case $(uname -m) in
      aarch64) DOWNLOAD=https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-Linux-aarch64.sh; ;;
      *)       DOWNLOAD=https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-Linux-x86_64.sh; ;;
      esac ;;
  *)           echo "unknown: $OSTYPE" ;;
esac

case "$SHELL" in
  *bin/zsh*)   SHELL_NAME=zsh; ;;
  *bin/bash*)  SHELL_NAME=bash ;;
  *bin/fish*) SHELL_NAME=fish ;;
  *)        echo "unknown: $SHELL" ;;
esac

echo Downloading $DOWNLOAD
wget $DOWNLOAD
bash Miniforge3-*.sh -b

~/miniforge3/bin/conda init $SHELL_NAME

echo Please close and reopen your terminal.

