#!/usr/bin/env bash
# https://lightgbm.readthedocs.io/en/latest/Installation-Guide.html#macos
# Mac Mojave, using Apple Clang

set -e

info () {
    printf "  [ \033[00;34m..\033[0m ] $1\n"
}

user () {
    printf "\r  [ \033[0;33m?\033[0m ] $1 "
}

success () {
    printf "\r\033[2K  [ \033[00;32mOK\033[0m ] $1\n"
}

fail () {
    printf "\r\033[2K  [\033[0;31mFAIL\033[0m] $1\n"
    echo ''
    exit
}

function display_usage {
    echo "Usage: $0 "
}

vercomp () {
    if [[ $1 == $2 ]]
    then
        return 0
    fi
    local IFS=.
    local i ver1=($1) ver2=($2)
    # fill empty fields in ver1 with zeros
    for ((i=${#ver1[@]}; i<${#ver2[@]}; i++))
    do
        ver1[i]=0
    done
    for ((i=0; i<${#ver1[@]}; i++))
    do
        if [[ -z ${ver2[i]} ]]
        then
            # fill empty fields in ver2 with zeros
            ver2[i]=0
        fi
        if ((10#${ver1[i]} > 10#${ver2[i]}))
        then
            return 1
        fi
        if ((10#${ver1[i]} < 10#${ver2[i]}))
        then
            return 2
        fi
    done
    return 0
}

# Validation
if [ "$#" -ne 0 ]; then
    display_usage
    fail "$# arguments found, 0 allowed"
fi

# Check Mac version
MAC_VERSION=$(sw_vers | grep ProductVersion |  awk '{print $NF}')
info "Mac version $MAC_VERSION"

# Check cmake
MIN_CMAKE_VERSION="3.12"
CMAKE_VERSION=$(cmake --version | grep version | awk '{print $NF}')

if [ -z "$CMAKE_VERSION" ]
then
    fail "cmake not found; brew install cmake"
fi

if vercomp "$CMAKE_VERSION" "$MIN_CMAKE_VERSION" -eq 2 ; then
    fail "$CMAKE_VERSION needs to be $MIN_CMAKE_VERSION or higher; brew upgrade cmake"
else
    success "cmake version $CMAKE_VERSION"
fi

# check libomp
LIBOMP_VERSION=$(brew ls --versions libomp | awk '{print $NF}')

if [ -z "$LIBOMP_VERSION" ]
then
    fail "libomp not found; brew install libomp"
else
    success "libomp version $LIBOMP_VERSION"
fi

# clone lightgbm from github
if [ -d "LightGBM" ]; then
    success "Found LightGBM folder"
else
    git clone --recursive https://github.com/microsoft/LightGBM
    if [ -d "LightGBM" ]; then
      success "Created LightGBM folder"
    fi
fi

# compile
cd LightGBM

# clone lightgbm from github
if [ -f "lightgbm" ]; then
    fail "lightgbm already exists"
fi

# Build if not already
if [ ! -d "build" ]; then
    mkdir build
fi

cd build

MOJAVE_VERSION="10.14"
if vercomp "$MAC_VERSION" "$MOJAVE_VERSION" -eq 2 ; then
    # For High Sierra or earlier (<= 10.13)
    cmake ..
    make -j4
else
    # For Mojave (10.14)
    cmake \
        -DOpenMP_C_FLAGS="-Xpreprocessor -fopenmp -I$(brew --prefix libomp)/include" \
        -DOpenMP_C_LIB_NAMES="omp" \
        -DOpenMP_CXX_FLAGS="-Xpreprocessor -fopenmp -I$(brew --prefix libomp)/include" \
        -DOpenMP_CXX_LIB_NAMES="omp" \
        -DOpenMP_omp_LIBRARY=$(brew --prefix libomp)/lib/libomp.dylib \
        ..
    make -j4
fi
