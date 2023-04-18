#!/usr/bin/env bash

################################################################################
# Command-line help
################################################################################
print_usage_abort ()
{
    cat <<EOF >&2
SYNOPSIS
    ${0} {Release|Debug}
    {with-gcc|with-clang|with-CC|with-CC-clang}
    {with-mkl|without-mkl}
DESCRIPTION
    Download, configure, build, and install PETSc and its dependencies.
EOF
    exit 1
}

################################################################################
# Diagnostics
################################################################################
set -e
set -x

################################################################################
# Command-line options
################################################################################
# Determine build type
if [[ "$1" == "Release" || "$1" == "Debug" ]]
then
    export BUILD_TYPE=$1
    echo "Build Type: ${BUILD_TYPE}"

else
    echo 'Build type must be provided and has to be "Release" or "Debug"' >&2
    print_usage_abort
fi

# Determine compiler
if [[ "$2" == "with-gcc" ]]; then
    export PETSC_USE_CC_COMPILER=OFF
    export PETSC_WITH_CLANG=OFF
    echo "Using self-built gcc"
elif [[ "$2" == "with-clang" ]]; then
    export PETSC_USE_CC_COMPILER=OFF
    export PETSC_WITH_CLANG=ON
    echo "Using self-built clang "
elif [[ "$2" == "with-CC" ]]; then
    export PETSC_USE_CC_COMPILER=ON
    export PETSC_WITH_CLANG=OFF
    echo "Using CC / CXX compiler (but expecting it to be some kind of gcc)"
elif [[ "$2" == "with-CC-clang" ]]; then
    export PETSC_USE_CC_COMPILER=ON
    export PETSC_WITH_CLANG=ON
    echo "Using CC / CXX compiler (but expecting it to be some kind of clang)"
else
    echo 'Compiler must be specified with "with-gcc" or "with-clang" or "with-CC" or "with-CC-clang"' >&2
    print_usage_abort
fi
export PETSC_COMPILER_OPTION="$2"

# Determine BLAS backend
if [[ "$3" == "without-mkl" ]]; then
    export PETSC_WITH_MKL=OFF
    echo "MKL Backend: Disabled - use fblaslapack"
elif [[ "$3" == "with-mkl" ]]; then
    export PETSC_WITH_MKL=ON
    echo "MKL Backend: Enabled"
else
    echo 'BLAS backend must be specified and has to be "with-mkl" or "without-mkl"' >&2
    print_usage_abort
fi

################################################################################
# Configuration
################################################################################
# Script directory
export PETSC_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd )"
cd petsc_build_chain
# Set Build Configuration Parameters
source config.sh

################################################################################
# Create source and installation directories
################################################################################
mkdir -p ${SOURCE_ROOT} ${INSTALL_ROOT}

################################################################################
# Build tools
################################################################################
# Build Compiler and set Compiler Environment Variables
if [[ "${PETSC_COMPILER_OPTION}" == "with-gcc" ]]; then
    echo "Building GCC"
    ./build-gcc.sh
    echo "Configuring self-built GCC"
    source gcc-config.sh
elif [[ "${PETSC_COMPILER_OPTION}" == "with-clang" ]]; then
    echo "Building clang"
    ./build-clang.sh
    echo "Configuring self-built clang"
    source clang-config.sh
elif [[ "${PETSC_COMPILER_OPTION}" == "with-CC" ]]; then
    echo "Configuring GCC"
    source gcc-config.sh
elif [[ "${PETSC_COMPILER_OPTION}" == "with-CC-clang" ]]; then
    echo "Configuring clang"
    source clang-config.sh
fi

if [[ "${PETSC_WITH_MKL}" == "ON" ]]; then
    echo "Building MKL"
    ./build-mkl.sh
fi

echo "Building Python"
./build-python.sh
export PYTHONPATH="${INSTALL_ROOT}/python/bin/python3"

################################################################################
# PETSc
################################################################################
echo "Building PETSc"
./build-petsc.sh
