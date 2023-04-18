#!/bin/bash
set -ex

: ${SOURCE_ROOT:?} ${INSTALL_ROOT:?} ${PETSC_VERSION:?} ${PYTHONPATH:?} ${BUILD_TYPE:?} ${PETSC_WITH_MKL}

DIR_SRC=${SOURCE_ROOT}/petsc

if [[ "${BUILD_TYPE}" == "Release" ]]
then
    DEBUGGING=0
else
    DEBUGGING=1
fi

DOWNLOAD_URL="https://ftp.mcs.anl.gov/pub/petsc/release-snapshots/petsc-${PETSC_VERSION}.tar.gz"


if [[ ! -d ${DIR_SRC} ]]; then
    (
        mkdir -p ${DIR_SRC}
        cd ${DIR_SRC}
        wget -O- ${DOWNLOAD_URL} | tar xz --strip-components=1
    )
fi

(
    cd ${DIR_SRC}
    # configure PETSc
    if [[ "${PETSC_WITH_MKL}" == "ON" ]]; then
        BLAS_LAPACK_LIB="--with-blas-lapack-dir=${INSTALL_ROOT}/mkl/mkl/2023.0.0/lib/intel64"
    else
        BLAS_LAPACK_LIB="--download-fblaslapack"
    fi

    OPTIONAL_PACKAGES="--download-elemental --download-metis --download-parmetis"
    MPI_LIB="--download-openmpi"
    #MPI_LIB=--with-mpi-dir=$HOME/build

    #--with-cc=gcc 
    #--with-fc=gfortran
    #--with-cxx=g++ 
    #--with-clanguage=cxx
    #--with-fc=0 
    #--download-f2cblaslapack 
    ${PYTHONPATH} configure --prefix=${INSTALL_ROOT}/petsc --with-debugging=${DEBUGGING} ${MPI_LIB} ${BLAS_LAPACK_LIB} --with-cmake-dir=${INSTALL_ROOT}/cmake/bin ${OPTIONAL_PACKAGES}
    make all check
)