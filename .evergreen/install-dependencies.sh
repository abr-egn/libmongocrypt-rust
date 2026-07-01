#!/bin/bash

set -o xtrace
set -o errexit

## Rust

export RUSTUP_HOME="${PROJECT_DIRECTORY}/.rustup"
export CARGO_HOME="${PROJECT_DIRECTORY}/.cargo"

# Make sure to use msvc toolchain rather than gnu, which is the default for cygwin
if [ "Windows_NT" == "$OS" ]; then
    export DEFAULT_HOST_OPTIONS='--default-host x86_64-pc-windows-msvc'
    # rustup/cargo need the native Windows paths; $PROJECT_DIRECTORY is a cygwin path
    export RUSTUP_HOME=$(cygpath ${RUSTUP_HOME} --windows)
    export CARGO_HOME=$(cygpath ${CARGO_HOME} --windows)
fi

#RUSTUP_URL="https://sh.rustup.rs"
RUSTUP_URL="https://raw.githubusercontent.com/rust-lang/rustup/refs/heads/main/rustup-init.sh"
curl "${RUSTUP_URL}" -sSf | sh -s -- -y --no-modify-path $DEFAULT_HOST_OPTIONS

# Cygwin has a bug with reporting symlink paths that breaks rustup; see
# https://github.com/rust-lang/rustup/issues/4239.  This works around it by replacing the
# symlinks with copies.
if [ "Windows_NT" == "$OS" ]; then
  pushd ${CARGO_HOME}/bin
  python3 ../../.evergreen/unsymlink.py
  popd
fi

# This file is not created by default on Windows
echo 'export PATH="$PATH:${CARGO_HOME}/bin"' >> ${CARGO_HOME}/env
echo "export CARGO_NET_GIT_FETCH_WITH_CLI=true" >> ${CARGO_HOME}/env

source ${CARGO_HOME}/env

## libmongocrypt
LIBMONGOCRYPT_TAG="1.19.2"

mkdir native
cd native
git clone https://github.com/mongodb/libmongocrypt --depth=1 --branch $LIBMONGOCRYPT_TAG

if [ "Windows_NT" == "$OS" ]; then
    # Windows requires its own ceremony
    . libmongocrypt/.evergreen/init.sh
    export VS_VERSION=15
    export VS_TARGET_ARCH=amd64
    export CMAKE_GENERATOR=Ninja
    bash "$EVG_DIR/env-run.sh" bash "$EVG_DIR/build_all.sh"
else
    ./libmongocrypt/.evergreen/compile.sh
fi

if [ "Windows_NT" == "$OS" ]; then
    chmod +x ${MONGOCRYPT_LIB_DIR}/../bin/*.dll
fi

## drivers-tools

if [[ -z "$DRIVERS_TOOLS" ]]; then
    echo >&2 "\$DRIVERS_TOOLS must be set"
    exit 1
fi

rm -rf $DRIVERS_TOOLS
git clone https://github.com/mongodb-labs/drivers-evergreen-tools.git $DRIVERS_TOOLS
